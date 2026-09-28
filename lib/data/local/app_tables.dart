import 'package:drift/drift.dart';

@DataClassName('LocalDeviceRow')
class LocalDevices extends Table {
  TextColumn get localId => text()();
  TextColumn get name => text().withDefault(const Constant('ESP Smart Energy'))();
  TextColumn get endpoint => text().nullable()();
  TextColumn get timezone => text().withDefault(const Constant('Asia/Jakarta'))();
  RealColumn get tariffPerKwh => real().withDefault(const Constant(1650))();
  RealColumn get gridCo2KgPerKwh => real().withDefault(const Constant(0.42))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {localId};
}

@DataClassName('MinuteAggregateRow')
class MinuteAggregates extends Table {
  TextColumn get deviceKey => text()();
  DateTimeColumn get minuteStart => dateTime()();
  RealColumn get energyKwh => real().withDefault(const Constant(0))();
  RealColumn get powerSum => real().withDefault(const Constant(0))();
  RealColumn get powerMin => real().nullable()();
  RealColumn get powerMax => real().nullable()();
  RealColumn get voltageSum => real().withDefault(const Constant(0))();
  RealColumn get voltageMin => real().nullable()();
  RealColumn get voltageMax => real().nullable()();
  RealColumn get currentSum => real().withDefault(const Constant(0))();
  RealColumn get currentMax => real().nullable()();
  RealColumn get frequencySum => real().withDefault(const Constant(0))();
  RealColumn get frequencyMin => real().nullable()();
  RealColumn get frequencyMax => real().nullable()();
  RealColumn get powerFactorSum => real().withDefault(const Constant(0))();
  RealColumn get powerFactorMin => real().nullable()();
  IntColumn get sampleCount => integer().withDefault(const Constant(0))();
  RealColumn get observedSeconds => real().withDefault(const Constant(0))();
  IntColumn get estimatedIntervals => integer().withDefault(const Constant(0))();

  /// Menandai menit ini sebagai hasil simulasi, bukan pengukuran ESP.
  ///
  /// Satu-satunya sumber nilai true adalah mode demo, jadi kolom ini adalah
  /// catatan asal-usul yang dibawa dari menit ke jam di
  /// [rollupMinutes](hourly_rollup.dart). Tanpa penanda ini, angka karangan
  /// akan tersimpan dengan bentuk yang persis sama seperti pengukuran.
  ///
  /// Default false supaya rekaman jalur ESP, termasuk data yang sudah tersimpan
  /// sebelum kolom ini ada, tidak ikut ditandai secara tidak sengaja.
  BoolColumn get isDemo => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {deviceKey, minuteStart};
}

/// Riwayat agregat per jam yang bersifat permanen.
///
/// Dipisahkan dari [HourlyQueue] karena keduanya punya umur yang berbeda.
/// `hourly_queue` hanya antrean transport: begitu jamnya berhasil diunggah,
/// `pruneSynced` menghapus barisnya. Kalau riwayat juga dibaca dari sana, data
/// historis ikut hilang setelah 30 hari dan analisis periode panjang mustahil
/// dilakukan. Tabel ini tidak pernah di-prune, jadi angka yang ditampilkan di
/// Analisis selalu berasal dari pengukuran, bukan sisa antrean.
///
/// Kolomnya sengaja meniru [HourlyQueue] tanpa *sync bookkeeping*
/// (`syncState`, `attempts`, `lastError`, `nextAttemptAt`) karena yang terakhir
/// itu urusan device, bukan data.
@TableIndex(name: 'hourly_history_bucket_idx', columns: {#deviceKey, #hourStart})
@DataClassName('HourlyHistoryRow')
class HourlyHistory extends Table {
  TextColumn get deviceKey => text()();
  DateTimeColumn get hourStart => dateTime()();
  RealColumn get energyKwh => real().withDefault(const Constant(0))();
  RealColumn get powerSum => real().withDefault(const Constant(0))();
  RealColumn get powerMin => real().nullable()();
  RealColumn get powerMax => real().nullable()();
  RealColumn get voltageSum => real().withDefault(const Constant(0))();
  RealColumn get voltageMin => real().nullable()();
  RealColumn get voltageMax => real().nullable()();
  RealColumn get currentSum => real().withDefault(const Constant(0))();
  RealColumn get currentMax => real().nullable()();
  RealColumn get frequencySum => real().withDefault(const Constant(0))();
  RealColumn get frequencyMin => real().nullable()();
  RealColumn get frequencyMax => real().nullable()();
  RealColumn get powerFactorSum => real().withDefault(const Constant(0))();
  RealColumn get powerFactorMin => real().nullable()();
  IntColumn get sampleCount => integer().withDefault(const Constant(0))();
  RealColumn get observedSeconds => real().withDefault(const Constant(0))();
  IntColumn get estimatedIntervals => integer().withDefault(const Constant(0))();
  RealColumn get coveragePct => real().withDefault(const Constant(0))();
  TextColumn get dataQuality =>
      text().withDefault(const Constant('partial'))();

  /// Dipertahankan dari [MinuteAggregates.isDemo] saat jam ditutup.
  ///
  /// Analytics memakai penanda ini untuk menandai angka yang bukan pengukuran.
  /// Sekali jam ditandai, nilainya tidak bisa kembali menjadi false: baris
  /// ditulis ulang dengan `insertOnConflictUpdate`, jadi jam yang tadinya
  /// sudah murni dan lalu tercemar simulasi akan ikut tercemar.
  BoolColumn get isDemo => boolean().withDefault(const Constant(false))();

  DateTimeColumn get recordedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {deviceKey, hourStart};
}

/// Antrean unggah: salinan per jam yang menunggu dikirim ke Supabase.
@TableIndex(
  name: 'hourly_queue_due_idx',
  columns: {#deviceKey, #syncState, #nextAttemptAt},
)
@DataClassName('HourlyQueueRow')
class HourlyQueue extends Table {
  TextColumn get deviceKey => text()();
  DateTimeColumn get hourStart => dateTime()();
  RealColumn get energyKwh => real().withDefault(const Constant(0))();
  RealColumn get powerSum => real().withDefault(const Constant(0))();
  RealColumn get powerMin => real().nullable()();
  RealColumn get powerMax => real().nullable()();
  RealColumn get voltageSum => real().withDefault(const Constant(0))();
  RealColumn get voltageMin => real().nullable()();
  RealColumn get voltageMax => real().nullable()();
  RealColumn get currentSum => real().withDefault(const Constant(0))();
  RealColumn get currentMax => real().nullable()();
  RealColumn get frequencySum => real().withDefault(const Constant(0))();
  RealColumn get frequencyMin => real().nullable()();
  RealColumn get frequencyMax => real().nullable()();
  RealColumn get powerFactorSum => real().withDefault(const Constant(0))();
  RealColumn get powerFactorMin => real().nullable()();
  IntColumn get sampleCount => integer().withDefault(const Constant(0))();
  RealColumn get observedSeconds => real().withDefault(const Constant(0))();
  IntColumn get estimatedIntervals => integer().withDefault(const Constant(0))();
  RealColumn get coveragePct => real().withDefault(const Constant(0))();
  TextColumn get dataQuality => text().withDefault(const Constant('partial'))();

  /// Dipertahankan dari [MinuteAggregates.isDemo] saat jam ditutup.
  ///
  /// Kolom ini yang dipakai [EnergySyncService] untuk menyaring baris
  /// simulasi sebelum unggah, sehingga data karangan tidak pernah mendarat di
  /// cloud seolah-olah hasil pengukuran. Baris yang tersaring tetap menunggu
  /// di antrean, bukan dihapus, jadi menyalakan penyertaan demo tidak
  /// menghilangkan apa pun yang sudah terekam.
  BoolColumn get isDemo => boolean().withDefault(const Constant(false))();

  TextColumn get syncState => text().withDefault(const Constant('pending'))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  /// Kapan baris ini boleh dicoba upload lagi. Null berarti sekarang juga.
  /// Dipakai untuk menerapkan backoff setelah kegagalan.
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {deviceKey, hourStart};
}
