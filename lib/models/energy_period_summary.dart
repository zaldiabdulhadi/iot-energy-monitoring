import 'energy_metric.dart';

/// Periode analisis yang bisa dipilih pengguna.
///
/// Semuanya adalah jendela bergulir yang berakhir di akhir jam berjalan, bukan
/// kalender: "Hari" berarti 24 jam terakhir, bukan dari jam 00.00. Alasannya,
/// periode harian yang terpotong di tengah jalan akan terlihat selalu kurang
/// lengkap dan membuat perbandingan dengan periode sebelumnya tidak setara.
enum HistoryPeriod {
  day('Hari', '24 jam terakhir'),
  week('Minggu', '7 hari terakhir'),
  month('Bulan', '30 hari terakhir'),
  year('Tahun', '12 bulan terakhir');

  const HistoryPeriod(this.label, this.description);

  final String label;
  final String description;

  /// Panjang satu periode, dipakai untuk menghitung periode pembanding yang
  /// sama panjangnya.
  Duration get span => switch (this) {
        HistoryPeriod.day => const Duration(hours: 24),
        HistoryPeriod.week => const Duration(days: 7),
        HistoryPeriod.month => const Duration(days: 30),
        HistoryPeriod.year => const Duration(days: 365),
      };

  /// Berapa titik per jam yang menampilkan periode ini.
  ///
  /// Menentukan resolusi grafik: per jam untuk "Hari", per hari untuk
  /// "Minggu" dan "Bulan", per bulan untuk "Tahun".
  HistoryGranularity get granularity => switch (this) {
        HistoryPeriod.day => HistoryGranularity.hour,
        HistoryPeriod.week => HistoryGranularity.day,
        HistoryPeriod.month => HistoryGranularity.day,
        HistoryPeriod.year => HistoryGranularity.month,
      };

  /// Berapa baris per jam yang diharapkan kalau pengukuran berjalan penuh.
  /// Dipakai untuk mengukur seberapa lengkap sebuah periode.
  int get expectedHours => switch (this) {
        HistoryPeriod.day => 24,
        HistoryPeriod.week => 24 * 7,
        HistoryPeriod.month => 24 * 30,
        HistoryPeriod.year => 24 * 365,
      };
}

/// Resolusi pengelompokan baris per jam menjadi titik grafik.
enum HistoryGranularity { hour, day, month }

/// Satu titik grafik: sekumpulan baris per jam yang digabung.
class HistoryBucket {
  HistoryBucket({
    required this.from,
    required this.to,
    required this.label,
    required this.kwh,
    required this.observedHours,
    this.metrics = const {},
  });

  /// Rentang waktu yang diwakili bucket ini, setengah terbuka `[from, to)`.
  final DateTime from;
  final DateTime to;

  /// Label siap tampil, misalnya `14.00`, `Rab`, atau `Agu`.
  final String label;

  /// Konsumsi energi di rentang ini.
  final double kwh;

  /// Berapa baris per jam yang benar-benar punya sampel.
  final int observedHours;

  /// Rata-rata tiap metrik dalam bucket ini.
  final Map<EnergyMetric, double> metrics;

  bool get isEmpty => observedHours == 0;

  double? metricOf(EnergyMetric metric) => metrics[metric];
}

/// Ringkasan parameter untuk satu periode, dihitung dari riwayat nyata.
///
/// Semua angka berasal dari tabel `hourly_history`. Tidak ada konstanta tebakan:
/// kalau datanya belum cukup, `observedHours` yang kecil akan terlihat sehingga
/// UI menampilkan apa adanya alih-alih mengarang.
///
/// Pengecualiannya ada di [isDemo]: selama belum ada rekaman sama sekali, layar
/// Analisis boleh diisi data contoh supaya tampilannya bisa dinilai. Angka seperti
/// itu wajib dibedakan dari hasil pengukuran, jadi keduanya tidak pernah
/// dicampur dalam satu ringkasan.
class EnergyPeriodSummary {
  const EnergyPeriodSummary({
    required this.period,
    required this.from,
    required this.to,
    required this.totalKwh,
    required this.co2Kg,
    required this.peakPowerW,
    required this.peakHour,
    required this.averageCoveragePct,
    required this.estimatedRatio,
    required this.observedHours,
    required this.expectedHours,
    required this.buckets,
    required this.average,
    required this.minimums,
    required this.maximums,
    this.isDemo = false,
  });

  /// Ringkasan kosong untuk periode yang belum punya data.
  factory EnergyPeriodSummary.empty(
    HistoryPeriod period, {
    required DateTime from,
    required DateTime to,
  }) {
    return EnergyPeriodSummary(
      period: period,
      from: from,
      to: to,
      totalKwh: 0,
      co2Kg: 0,
      peakPowerW: 0,
      peakHour: null,
      averageCoveragePct: 0,
      estimatedRatio: 0,
      observedHours: 0,
      expectedHours: period.expectedHours,
      buckets: const [],
      average: const {},
      minimums: const {},
      maximums: const {},
    );
  }

  final HistoryPeriod period;
  final DateTime from;
  final DateTime to;

  /// Total konsumsi energi periode ini, hasil penjumlahan kWh per jam.
  final double totalKwh;

  /// Estimasi jejak karbon memakai faktor emisi grid perangkat.
  final double co2Kg;

  /// Daya tertinggi dalam periode ini, dalam watt.
  final double peakPowerW;

  /// Jam terjadi puncak daya, null kalau belum ada data.
  final DateTime? peakHour;

  /// Rata-rata coverage pengukuran dalam periode, 0 sampai 100.
  final double averageCoveragePct;

  /// Porsi interval yang diestimasi, 0 sampai 1.
  final double estimatedRatio;

  /// Berapa baris per jam yang benar-benar punya sampel.
  final int observedHours;

  /// Berapa baris per jam yang diharapkan kalau pengukuran penuh.
  final int expectedHours;

  /// Titik grafik untuk periode ini, terurut menaik.
  final List<HistoryBucket> buckets;

  /// Rata-rata tiap metrik dalam periode, dalam satuan tampil.
  final Map<EnergyMetric, double> average;
  final Map<EnergyMetric, double?> minimums;
  final Map<EnergyMetric, double?> maximums;

  /// True kalau angka ringkasan ini berasal dari data contoh, bukan rekaman ESP.
  ///
  /// Layar wajib menampilkan penanda selama ini true. Field lain seperti
  /// `observedHours` dan `averageCoveragePct` untuk data contoh hanya
  /// menggambarkan kelengkapan data contoh, bukan kelengkapan pengukuran.
  final bool isDemo;

  bool get isEmpty => observedHours == 0;

  /// Cukup untuk dianalisis? Satu baris per jam saja belum menghasilkan pola.
  bool get isAnalyzable => observedHours >= 2;

  /// Berapa persen periode yang benar-benar terpakai datanya.
  double get completenessPct =>
      expectedHours <= 0 ? 0 : (observedHours / expectedHours) * 100;

  /// Rata-rata satu metrik, null kalau metriknya tidak punya rata-rata.
  double? averageOf(EnergyMetric metric) => average[metric];

  /// Rata-rata daya dalam watt.
  double get averagePowerW => average[EnergyMetric.power] ?? 0;

  /// Rata-rata faktor daya, atau null kalau belum ada data.
  double? get averagePowerFactor => average[EnergyMetric.powerFactor];

  /// Selisih konsumsi terhadap periode sebelumnya, dalam persen.
  ///
  /// Null kalau periode pembanding tidak punya data, supaya UI bisa
  /// membedakan "turun 8%" dari "tidak ada pembanding".
  double? changePct(EnergyPeriodSummary? previous) {
    if (previous == null || previous.isEmpty || isEmpty) return null;
    if (previous.totalKwh <= 0) return null;
    return ((totalKwh - previous.totalKwh) / previous.totalKwh) * 100;
  }
}
