import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../models/energy_hourly.dart';
import '../../models/energy_sync_state.dart';
import '../../utils/bucket_time.dart';
import 'app_tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [LocalDevices, MinuteAggregates, HourlyHistory, HourlyQueue],
)
class EnergyDatabase extends _$EnergyDatabase {
  EnergyDatabase() : super(driftDatabase(name: 'smart_energy'));

  EnergyDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(hourlyQueue, hourlyQueue.nextAttemptAt);
            await m.createIndex(hourlyQueueDueIdx);
          }
          if (from < 3) {
            // Riwayat dipisah dari antrean supaya pruning tidak ikut menghapus
            // data historis. Baris lama di `hourly_queue` yang masih ada ikut
            // dicadangkan supaya riwayat tidak mulai dari nol setelah upgrade.
            await m.createTable(hourlyHistory);
            await m.createIndex(hourlyHistoryBucketIdx);
            await customStatement(
              'INSERT INTO hourly_history (device_key, hour_start, energy_kwh, '
              'power_sum, power_min, power_max, voltage_sum, voltage_min, '
              'voltage_max, current_sum, current_max, frequency_sum, '
              'frequency_min, frequency_max, power_factor_sum, '
              'power_factor_min, sample_count, observed_seconds, '
              'estimated_intervals, coverage_pct, data_quality, recorded_at) '
              'SELECT device_key, hour_start, energy_kwh, power_sum, power_min, '
              'power_max, voltage_sum, voltage_min, voltage_max, current_sum, '
              'current_max, frequency_sum, frequency_min, frequency_max, '
              'power_factor_sum, power_factor_min, sample_count, '
              'observed_seconds, estimated_intervals, coverage_pct, '
              'data_quality, updated_at FROM hourly_queue',
            );
          }
          if (from < 4) {
            // Penanda asal-usul data. Default false membuat `addColumn`
            // menandai seluruh baris lama sebagai pengukuran, yang memang
            // benar: data sebelum kolom ini hanya bisa berasal dari ESP.
            await m.addColumn(minuteAggregates, minuteAggregates.isDemo);
            await m.addColumn(hourlyQueue, hourlyQueue.isDemo);
            await m.addColumn(hourlyHistory, hourlyHistory.isDemo);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  Future<LocalDeviceRow> ensureLocalDevice() async {
    final existing = await select(localDevices).get();
    if (existing.isNotEmpty) return existing.first;

    await into(localDevices).insert(
      LocalDevicesCompanion.insert(
        localId: generateLocalId(),
        createdAt: toStorage(DateTime.now()),
      ),
    );
    return select(localDevices).getSingle();
  }

  /// Id perangkat yang sudah terdaftar, null kalau belum pernah dibuat.
  ///
  /// Berbeda dengan [ensureLocalDevice] yang sekaligus membuat baris baru, ini
  /// murni pembacaan sehingga aman dipanggil dari UI.
  Future<String?> currentDeviceId() async {
    final existing = await select(localDevices).get();
    return existing.isEmpty ? null : existing.first.localId;
  }

  /// Menghapus seluruh rekaman milik satu perangkat.
  ///
  /// Dipakai saat pengguna mengganti meter: angka satu meter tidak boleh
  /// bercampur dengan meter lain di grafik dan ringkasan yang sama. Baris
  /// perangkat lain tidak tersentuh karena setiap baris di ketiga tabel
  /// dikunci dengan `device_key`.
  Future<void> deleteDeviceData(String deviceKey) async {
    await transaction(() async {
      await (delete(minuteAggregates)
            ..where((t) => t.deviceKey.equals(deviceKey)))
          .go();
      await (delete(hourlyQueue)..where((t) => t.deviceKey.equals(deviceKey))).go();
      await (delete(hourlyHistory)
            ..where((t) => t.deviceKey.equals(deviceKey)))
          .go();
    });
  }

  /// Mengganti baris perangkat dengan identitas baru.
  ///
  /// Baris lama dihapus dan digantikan `local_id` baru supaya meter berikutnya
  /// tercatat sebagai perangkat yang berbeda, bukan melanjutkan meter lama.
  /// Keduanya terjadi dalam satu transaksi karena [ensureLocalDevice] dan
  /// [currentDeviceId] selalu membaca baris pertama: dua baris yang hidup
  /// bersamaan membuat "perangkat aktif" jadi tidak pasti.
  Future<LocalDeviceRow> replaceLocalDevice({
    String? endpoint,
    String? name,
  }) async {
    return transaction(() async {
      await delete(localDevices).go();
      await into(localDevices).insert(
        LocalDevicesCompanion.insert(
          localId: generateLocalId(),
          createdAt: toStorage(DateTime.now()),
          name: Value(name ?? 'ESP Smart Energy'),
          endpoint: Value(endpoint),
        ),
      );
      return select(localDevices).getSingle();
    });
  }

  Future<void> updateLocalDevice({
    required String localId,
    String? name,
    String? endpoint,
    double? tariffPerKwh,
    double? gridCo2KgPerKwh,
  }) async {
    await (update(localDevices)..where((t) => t.localId.equals(localId))).write(
      LocalDevicesCompanion(
        name: name == null ? const Value.absent() : Value(name),
        endpoint: endpoint == null ? const Value.absent() : Value(endpoint),
        tariffPerKwh: tariffPerKwh == null
            ? const Value.absent()
            : Value(tariffPerKwh),
        gridCo2KgPerKwh: gridCo2KgPerKwh == null
            ? const Value.absent()
            : Value(gridCo2KgPerKwh),
      ),
    );
  }

  /// Menyimpan agregat satu menit, menimpa baris dengan kunci yang sama.
  ///
  /// `is_demo` bersifat monoton: kalau baris yang sudah ada ditandai demo,
  /// penulisan berikutnya tidak boleh mengembalikannya jadi false. Ini penting
  /// karena kunci utamanya hanya `(device_key, minute_start)`, jadi satu menit
  /// yang sempat menerima sampel simulasi lalu menerima sampel ESP akan menimpa
  /// baris yang sama. Tanpa aturan ini, rekaman karangan bisa tersimpan
  /// seolah-olah pengukuran asli.
  ///
  /// Pembacaan-then-menulis aman karena semua penulisan menit melewati
  /// [_EnergyRecorder] antrean tunggal](energy_recorder.dart).
  Future<void> upsertMinute(MinuteAggregateRow row) async {
    final existing = await (select(minuteAggregates)
          ..where(
            (t) =>
                t.deviceKey.equals(row.deviceKey) &
                t.minuteStart.equals(toStorage(row.minuteStart)),
          ))
        .getSingleOrNull();

    await into(minuteAggregates).insertOnConflictUpdate(
      MinuteAggregatesCompanion(
        deviceKey: Value(row.deviceKey),
        minuteStart: Value(toStorage(row.minuteStart)),
        energyKwh: Value(row.energyKwh),
        powerSum: Value(row.powerSum),
        powerMin: Value(row.powerMin),
        powerMax: Value(row.powerMax),
        voltageSum: Value(row.voltageSum),
        voltageMin: Value(row.voltageMin),
        voltageMax: Value(row.voltageMax),
        currentSum: Value(row.currentSum),
        currentMax: Value(row.currentMax),
        frequencySum: Value(row.frequencySum),
        frequencyMin: Value(row.frequencyMin),
        frequencyMax: Value(row.frequencyMax),
        powerFactorSum: Value(row.powerFactorSum),
        powerFactorMin: Value(row.powerFactorMin),
        sampleCount: Value(row.sampleCount),
        observedSeconds: Value(row.observedSeconds),
        estimatedIntervals: Value(row.estimatedIntervals),
        isDemo: Value((existing?.isDemo ?? false) || row.isDemo),
      ),
    );
  }

  Future<List<MinuteAggregateRow>> minutesForHour(
    String deviceKey,
    DateTime hourStart,
  ) async {
    final start = toStorage(hourStart);
    final end = toStorage(hourStart.add(const Duration(hours: 1)));
    return (select(minuteAggregates)
          ..where(
            (t) =>
                t.deviceKey.equals(deviceKey) &
                t.minuteStart.isBiggerOrEqualValue(start) &
                t.minuteStart.isSmallerThanValue(end),
          )
          ..orderBy([(t) => OrderingTerm(expression: t.minuteStart)]))
        .get();
  }

  Future<List<DateTime>> hourBucketsBefore(
    String deviceKey,
    DateTime before,
  ) async {
    final query = select(minuteAggregates)
      ..where(
        (t) =>
            t.deviceKey.equals(deviceKey) &
            t.minuteStart.isSmallerThanValue(toStorage(before)),
      );

    final rows = await query.get();
    final buckets = rows
        .map((row) => floorToHour(fromStorage(row.minuteStart)))
        .toSet()
        .toList()
      ..sort();
    return buckets;
  }

  Future<void> upsertHourly({
    required EnergyHourly hourly,
    required DateTime now,
  }) async {
    await into(hourlyQueue).insertOnConflictUpdate(
      HourlyQueueCompanion(
        deviceKey: Value(hourly.deviceKey),
        hourStart: Value(toStorage(hourly.hourStart)),
        energyKwh: Value(hourly.energyKwh),
        powerSum: Value(hourly.powerSum),
        powerMin: Value(hourly.powerMin),
        powerMax: Value(hourly.powerMax),
        voltageSum: Value(hourly.voltageSum),
        voltageMin: Value(hourly.voltageMin),
        voltageMax: Value(hourly.voltageMax),
        currentSum: Value(hourly.currentSum),
        currentMax: Value(hourly.currentMax),
        frequencySum: Value(hourly.frequencySum),
        frequencyMin: Value(hourly.frequencyMin),
        frequencyMax: Value(hourly.frequencyMax),
        powerFactorSum: Value(hourly.powerFactorSum),
        powerFactorMin: Value(hourly.powerFactorMin),
        sampleCount: Value(hourly.sampleCount),
        observedSeconds: Value(hourly.observedSeconds),
        estimatedIntervals: Value(hourly.estimatedIntervals),
        coveragePct: Value(hourly.coveragePct),
        dataQuality: Value(hourly.quality.wireName),
        isDemo: Value(hourly.isDemo),
        syncState: const Value('pending'),
        nextAttemptAt: const Value(null),
        updatedAt: Value(toStorage(now)),
      ),
    );
  }

  Future<void> deleteMinutesForHour(String deviceKey, DateTime hourStart) async {
    final start = toStorage(hourStart);
    final end = toStorage(hourStart.add(const Duration(hours: 1)));
    await (delete(minuteAggregates)..where(
          (t) =>
              t.deviceKey.equals(deviceKey) &
              t.minuteStart.isBiggerOrEqualValue(start) &
              t.minuteStart.isSmallerThanValue(end),
        ))
        .go();
  }

  /// Menyimpan satu jam ke riwayat permanen.
  ///
  /// Dipanggil bersama [upsertHourly] di penutup jam: keduanya menulis data
  /// yang sama, tapi ke tabel dengan umur yang berbeda.
  Future<void> upsertHistory({
    required EnergyHourly hourly,
    required DateTime now,
  }) async {
    await into(hourlyHistory).insertOnConflictUpdate(
      HourlyHistoryCompanion(
        deviceKey: Value(hourly.deviceKey),
        hourStart: Value(toStorage(hourly.hourStart)),
        energyKwh: Value(hourly.energyKwh),
        powerSum: Value(hourly.powerSum),
        powerMin: Value(hourly.powerMin),
        powerMax: Value(hourly.powerMax),
        voltageSum: Value(hourly.voltageSum),
        voltageMin: Value(hourly.voltageMin),
        voltageMax: Value(hourly.voltageMax),
        currentSum: Value(hourly.currentSum),
        currentMax: Value(hourly.currentMax),
        frequencySum: Value(hourly.frequencySum),
        frequencyMin: Value(hourly.frequencyMin),
        frequencyMax: Value(hourly.frequencyMax),
        powerFactorSum: Value(hourly.powerFactorSum),
        powerFactorMin: Value(hourly.powerFactorMin),
        sampleCount: Value(hourly.sampleCount),
        observedSeconds: Value(hourly.observedSeconds),
        estimatedIntervals: Value(hourly.estimatedIntervals),
        coveragePct: Value(hourly.coveragePct),
        dataQuality: Value(hourly.quality.wireName),
        isDemo: Value(hourly.isDemo),
        recordedAt: Value(toStorage(now)),
      ),
    );
  }

  /// Membaca riwayat dalam rentang setengah terbuka `[from, to)`.
  ///
  /// Berbeda dengan [hourlyBetween] yang membaca antrean, ini tidak terpengaruh
  /// [pruneSynced] dan jadi sumber angka untuk layar Analisis.
  Future<List<EnergyHourly>> historyBetween(
    String deviceKey,
    DateTime from,
    DateTime to,
  ) async {
    final rows = await (select(hourlyHistory)
          ..where(
            (t) =>
                t.deviceKey.equals(deviceKey) &
                t.hourStart.isBiggerOrEqualValue(toStorage(from)) &
                t.hourStart.isSmallerThanValue(toStorage(to)),
          )
          ..orderBy([(t) => OrderingTerm(expression: t.hourStart)]))
        .get();
    return rows.map((row) => row.toDomain()).toList();
  }

  /// Rentang waktu yang benar-benar punya baris di riwayat.
  ///
  /// Dipakai supaya ringkasan periode bisa melompati periode kosong di awal
  /// pemakaian, alih-alih melaporkan nol sementara.
  Future<(DateTime?, DateTime?)> historyBounds(String deviceKey) async {
    final earliest = hourlyHistory.hourStart.min();
    final latest = hourlyHistory.hourStart.max();
    final row = await (selectOnly(hourlyHistory)
          ..addColumns([earliest, latest])
          ..where(hourlyHistory.deviceKey.equals(deviceKey)))
        .getSingle();
    return (
      row.read(earliest) == null ? null : fromStorage(row.read(earliest)!),
      row.read(latest) == null ? null : fromStorage(row.read(latest)!),
    );
  }

  /// Tarif dan faktor karbon milik perangkat ini.
  ///
  /// Nilai default di [_defaultDeviceSettings] dipakai kalau baris perangkat
  /// belum pernah dibuat, supaya analisis tetap bisa jalan sebelum sinkronisasi
  /// pertama.
  Future<DeviceSettings> currentSettings() async {
    final id = await currentDeviceId();
    if (id == null) return DeviceSettings._defaultDeviceSettings;
    final row = await (select(localDevices)
          ..where((t) => t.localId.equals(id)))
        .getSingleOrNull();
    if (row == null) return DeviceSettings._defaultDeviceSettings;
    return DeviceSettings(
      tariffPerKwh: row.tariffPerKwh,
      gridCo2KgPerKwh: row.gridCo2KgPerKwh,
    );
  }

  Future<List<EnergyHourly>> hourlyBetween(
    String deviceKey,
    DateTime from,
    DateTime to,
  ) async {
    final rows = await (select(hourlyQueue)
          ..where(
            (t) =>
                t.deviceKey.equals(deviceKey) &
                t.hourStart.isBiggerOrEqualValue(toStorage(from)) &
                t.hourStart.isSmallerThanValue(toStorage(to)),
          )
          ..orderBy([(t) => OrderingTerm(expression: t.hourStart)]))
        .get();
    return rows.map((row) => row.toDomain()).toList();
  }

  /// Baris yang menunggu diunggah ke Supabase, sudah jatuh tempo.
  ///
  /// Baris `failed` ikut diambil selama [now] sudah melewati `next_attempt_at`,
  /// sehingga backoff setelah kegagalan benar-benar dihormati.
  /// Bila [includeDemo] false, jam bertanda simulasi dilewati.
  ///
  /// Saringan ada di query, bukan setelah baris ditarik, supaya antrean yang
  /// seluruhnya berisi data demo tidak membuat pemanggil mengambil batch
  /// penuh yang lalu dibuang.
  Future<List<HourlyQueueRow>> pendingHours(
    String deviceKey, {
    int limit = 50,
    DateTime? now,
    bool includeDemo = false,
  }) async {
    final cutoff = toStorage(now ?? DateTime.now());
    return (select(hourlyQueue)
          ..where(
            (t) =>
                t.deviceKey.equals(deviceKey) &
                t.syncState.isIn(const ['pending', 'failed']) &
                (t.nextAttemptAt.isNull() |
                    t.nextAttemptAt.isSmallerOrEqualValue(cutoff)) &
                (includeDemo ? const Constant(true) : t.isDemo.equals(false)),
          )
          ..orderBy([(t) => OrderingTerm(expression: t.hourStart)])
          ..limit(limit))
        .get();
  }

  /// Jumlah jam yang benar-benar akan dicoba diunggah.
  ///
  /// Jam simulasi sengaja tidak dihitung. They akan tetap menggantung di
  /// antrean selamanya karena [EnergySyncService] menyaringnya, jadi menghitungnya
  /// membuat label "Menunggu N jam" tidak pernah nol dan terlihat seperti
  /// sinkronisasi yang macet padahal tidak ada. Untuk transparansi, jumlahnya
  /// tersedia terpisah lewat [countPendingDemo].
  Future<int> countPending(String deviceKey) async {
    final row = await customSelect(
      'SELECT COUNT(*) AS c FROM hourly_queue '
      'WHERE device_key = ? AND sync_state IN (?, ?) AND NOT is_demo',
      variables: [
        Variable<String>(deviceKey),
        const Variable<String>('pending'),
        const Variable<String>('failed'),
      ],
      readsFrom: {hourlyQueue},
    ).getSingle();
    return row.read<int>('c');
  }

  /// Jam simulasi yang masih menggantung di antrean, dipisah dari
  /// [countPending].
  ///
  /// Baris ini tidak akan pernah diunggah selama `includeDemo` false, jadi
  /// jumlahnya dibaca terpisah supaya badge antrean tidak ikut menghitungnya.
  Future<int> countPendingDemo(String deviceKey) async {
    final row = await customSelect(
      'SELECT COUNT(*) AS c FROM hourly_queue '
      'WHERE device_key = ? AND sync_state IN (?, ?) AND is_demo',
      variables: [
        Variable<String>(deviceKey),
        const Variable<String>('pending'),
        const Variable<String>('failed'),
      ],
      readsFrom: {hourlyQueue},
    ).getSingle();
    return row.read<int>('c');
  }

  /// Baris `failed` yang masih dalam masa backoff, jadi belum giliran diunggah.
  Future<int> countDeferred(String deviceKey, {DateTime? now}) async {    final cutoff = toStorage(now ?? DateTime.now());
    final row = await customSelect(
      'SELECT COUNT(*) AS c FROM hourly_queue '
      "WHERE device_key = ? AND sync_state = 'failed' "
      'AND next_attempt_at IS NOT NULL AND next_attempt_at > ?',
      variables: [Variable<String>(deviceKey), Variable<DateTime>(cutoff)],
      readsFrom: {hourlyQueue},
    ).getSingle();
    return row.read<int>('c');
  }

  /// Satu baris hourly berdasarkan kunci utamanya, tanpa memfilter backoff.
  ///
  /// Berguna untuk memeriksa status sinkronisasi sebuah jam secara spesifik,
  /// termasuk jam yang masih dalam masa tunda.
  Future<HourlyQueueRow?> findHour(String deviceKey, DateTime hourStart) {
    return (select(hourlyQueue)
          ..where(
            (t) =>
                t.deviceKey.equals(deviceKey) &
                t.hourStart.equals(toStorage(hourStart)),
          ))
        .getSingleOrNull();
  }

  Future<void> markSynced(
    String deviceKey,
    DateTime hourStart, {
    required DateTime now,
  }) async {
    await (update(hourlyQueue)..where(
          (t) =>
              t.deviceKey.equals(deviceKey) &
              t.hourStart.equals(toStorage(hourStart)),
        ))
        .write(
      HourlyQueueCompanion(
        syncState: const Value('synced'),
        syncedAt: Value(toStorage(now)),
        lastError: const Value(null),
        nextAttemptAt: const Value(null),
        updatedAt: Value(toStorage(now)),
      ),
    );
  }

  /// Menandai satu jam gagal diunggah dan menjadwalkannya coba lagi.
  ///
  /// `attempts` dinaikkan di level SQL (`attempts = attempts + 1`) supaya tetap
  /// benar walau dua proses menandai baris yang sama bersamaan. Versi
  /// sebelumnya melakukan read-modify-write dalam dua round-trip sehingga
  /// `attempts` bisa hilang.
  Future<void> markFailed(
    String deviceKey,
    DateTime hourStart, {
    required String error,
    required DateTime now,
    Duration backoff = Duration.zero,
  }) async {
    await customUpdate(
      'UPDATE hourly_queue SET sync_state = ?, attempts = attempts + 1, '
      'last_error = ?, next_attempt_at = ?, updated_at = ? '
      'WHERE device_key = ? AND hour_start = ?',
      variables: [
        const Variable<String>('failed'),
        Variable<String>(error),
        Variable<DateTime>(toStorage(now.add(backoff))),
        Variable<DateTime>(toStorage(now)),
        Variable<String>(deviceKey),
        Variable<DateTime>(toStorage(hourStart)),
      ],
      updates: {hourlyQueue},
    );
  }

  Future<void> pruneSynced({
    required String deviceKey,
    required DateTime syncedBefore,
  }) async {
    await (delete(hourlyQueue)..where(
          (t) =>
              t.deviceKey.equals(deviceKey) &
              t.syncState.equals('synced') &
              t.syncedAt.isSmallerThanValue(toStorage(syncedBefore)),
        ))
        .go();
  }
}

String generateLocalId() {
  final rng = Random.secure();
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// Parameter turunan yang dipakai untuk mengubah energi menjadi rupiah dan CO₂.
///
/// Disimpan per perangkat di `local_devices` (dan ikut terunggah ke tabel
/// `devices`) supaya biaya yang ditampilkan mengikuti tarif yang benar-benar
/// berlaku, bukan konstanta yang tertanam di layar.
class DeviceSettings {
  const DeviceSettings({
    required this.tariffPerKwh,
    required this.gridCo2KgPerKwh,
  });

  /// Nilai yang sama dengan default kolom di [LocalDevices].
  static const _defaultDeviceSettings = DeviceSettings(
    tariffPerKwh: 1650,
    gridCo2KgPerKwh: 0.42,
  );

  final double tariffPerKwh;
  final double gridCo2KgPerKwh;
}

extension HourlyHistoryRowMapper on HourlyHistoryRow {
  EnergyHourly toDomain() => EnergyHourly(
        deviceKey: deviceKey,
        hourStart: fromStorage(hourStart),
        energyKwh: energyKwh,
        powerSum: powerSum,
        powerMin: powerMin,
        powerMax: powerMax,
        voltageSum: voltageSum,
        voltageMin: voltageMin,
        voltageMax: voltageMax,
        currentSum: currentSum,
        currentMax: currentMax,
        frequencySum: frequencySum,
        frequencyMin: frequencyMin,
        frequencyMax: frequencyMax,
        powerFactorSum: powerFactorSum,
        powerFactorMin: powerFactorMin,
        sampleCount: sampleCount,
        observedSeconds: observedSeconds,
        estimatedIntervals: estimatedIntervals,
        coveragePct: coveragePct,
        quality: EnergyDataQuality.fromWire(dataQuality),
        isDemo: isDemo,
      );
}

extension HourlyQueueRowMapper on HourlyQueueRow {
  EnergyHourly toDomain() => EnergyHourly(
        deviceKey: deviceKey,
        hourStart: fromStorage(hourStart),
        energyKwh: energyKwh,
        powerSum: powerSum,
        powerMin: powerMin,
        powerMax: powerMax,
        voltageSum: voltageSum,
        voltageMin: voltageMin,
        voltageMax: voltageMax,
        currentSum: currentSum,
        currentMax: currentMax,
        frequencySum: frequencySum,
        frequencyMin: frequencyMin,
        frequencyMax: frequencyMax,
        powerFactorSum: powerFactorSum,
        powerFactorMin: powerFactorMin,
        sampleCount: sampleCount,
        observedSeconds: observedSeconds,
        estimatedIntervals: estimatedIntervals,
        coveragePct: coveragePct,
        quality: EnergyDataQuality.fromWire(dataQuality),
        isDemo: isDemo,
      );

  EnergySyncState get syncStateValue => EnergySyncState.fromWire(syncState);

  /// Bentuk payload yang dikirim ke tabel `energy_hourly` di Postgres.
  Map<String, dynamic> toUploadJson() => toDomain().toJson();
}
