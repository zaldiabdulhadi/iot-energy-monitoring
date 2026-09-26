import 'dart:math' as math;

import '../data/local/app_database.dart';
import '../data/remote/energy_remote_data_source.dart';
import '../utils/bucket_time.dart';

/// Hasil satu siklus sinkronisasi.
class EnergySyncReport {
  const EnergySyncReport({
    required this.uploaded,
    required this.failed,
    required this.deferred,
  });

  const EnergySyncReport.idle()
      : uploaded = 0,
        failed = 0,
        deferred = 0;

  /// Jumlah jam yang berhasil diunggah.
  final int uploaded;

  /// Jumlah jam yang gagal diunggah dan dijadwalkan ulang dengan backoff.
  final int failed;

  /// Jumlah jam yang masih menunggu giliran karena backoff belum kedaluwarsa.
  final int deferred;

  bool get didWork => uploaded > 0 || failed > 0;
}

/// Mengunggah agregat per jam dari antrean lokal ke Supabase.
///
/// Siklusnya: ambil baris yang jatuh tempo dari `hourly_queue`, kirim dalam satu
/// batch, lalu tandai tiap baris sebagai `synced` atau `failed`. Baris yang
/// gagal dijadwalkan ulang dengan backoff eksponensial lewat `next_attempt_at`
/// supaya tidak membanjiri backend saat jaringan sedang mati.
class EnergySyncService {
  EnergySyncService({
    required this.database,
    this.remote,
    this.batchSize = 200,
    this.retention = const Duration(days: 30),
  });
  final EnergyDatabase database;
  final EnergyRemoteDataSource? remote;
  final int batchSize;
  final Duration retention;

  bool _running = false;

  bool get isRunning => _running;

  /// Benar bila backend dikonfigurasi lewat `--dart-define` dan bisa dipakai.
  bool get isEnabled => remote != null;

  /// Menjalankan sinkronisasi sampai antrean kosong atau tidak ada lagi
  /// kemajuan. Pemanggilan yang bertabrakan akan dilewati, bukan ditumpuk.
  Future<EnergySyncReport> syncNow() async {
    final backend = remote;
    if (backend == null) return const EnergySyncReport.idle();
    if (_running) return const EnergySyncReport.idle();

    _running = true;
    try {
      final device = await database.ensureLocalDevice();
      // Wajib lebih dulu: ada foreign key energy_hourly.device_id -> devices.id.
      await backend.upsertDevice(device);

      final now = DateTime.now();
      var uploaded = 0;
      var failed = 0;

      // Beberapa batch bila antrean menumpuk, misalnya saat backfill pertama.
      while (true) {
        final rows = await database.pendingHours(
          device.localId,
          limit: batchSize,
          now: now,
        );
        if (rows.isEmpty) break;

        final succeeded = await _uploadBatch(backend, rows, now: now);
        uploaded += succeeded;
        failed += rows.length - succeeded;

        // Kalau tidak ada satu pun yang berhasil, sisa baris yang sama sudah
        // dijadwalkan ulang dengan backoff. Hentikan agar tidak langsung
        // mencoba baris yang sama lagi.
        if (succeeded == 0) break;
      }

      await database.pruneSynced(
        deviceKey: device.localId,
        syncedBefore: DateTime.now().subtract(retention),
      );

      return EnergySyncReport(
        uploaded: uploaded,
        failed: failed,
        deferred: await database.countDeferred(device.localId, now: now),
      );
    } finally {
      _running = false;
    }
  }

  /// Mengirim satu batch lalu menandai hasilnya. Mengembalikan jumlah sukses.
  ///
  /// Batch bersifat all-or-nothing: kalau unggahannya gagal, seluruh baris di
  /// batch itu ditandai gagal.
  Future<int> _uploadBatch(
    EnergyRemoteDataSource remote,
    List<HourlyQueueRow> rows, {
    required DateTime now,
  }) async {
    try {
      await remote.upsertHourly(rows.map((row) => row.toUploadJson()).toList());
    } on EnergyRemoteException catch (error) {
      for (final row in rows) {
        await database.markFailed(
          row.deviceKey,
          fromStorage(row.hourStart),
          error: error.message,
          now: now,
          backoff: backoffFor(row.attempts + 1),
        );
      }
      return 0;
    }

    for (final row in rows) {
      await database.markSynced(
        row.deviceKey,
        fromStorage(row.hourStart),
        now: now,
      );
    }
    return rows.length;
  }

  /// Backoff eksponensial: 60 detik, lalu 120, 240... dibatasi 2 jam.
  ///
  /// [attempts] adalah jumlah kegagalan yang sudah tercatat sebelum percobaan
  /// ini, sehingga kegagalan pertama menghasilkan jeda 60 detik.
  static Duration backoffFor(int attempts) {
    final exponent = math.min(math.max(attempts, 1), 8);
    return Duration(seconds: math.min(30 * (1 << exponent), 7200));
  }
}
