import 'package:flutter/material.dart';

import '../models/energy_metric.dart';
import '../models/energy_period_summary.dart';
import '../models/energy_reading.dart';

/// Tingkat keparahan sebuah insight yang dihasilkan mesin.
enum InsightSeverity { info, positive, warning, critical }

extension InsightSeverityTone on InsightSeverity {
  Color get color => switch (this) {
        InsightSeverity.info => const Color(0xFF6EA8D7),
        InsightSeverity.positive => const Color(0xFF65B891),
        InsightSeverity.warning => const Color(0xFFF4C95D),
        InsightSeverity.critical => const Color(0xFFE87575),
      };

  IconData get icon => switch (this) {
        InsightSeverity.info => Icons.lightbulb_outline_rounded,
        InsightSeverity.positive => Icons.trending_down_rounded,
        InsightSeverity.warning => Icons.error_outline_rounded,
        InsightSeverity.critical => Icons.warning_amber_rounded,
      };
}

/// Satu rekomendasi atau temuan yang bisa ditindaklanjuti.
class EnergyInsight {
  const EnergyInsight({
    required this.severity,
    required this.title,
    required this.body,
    this.metric,
  });

  final InsightSeverity severity;
  final String title;
  final String body;

  /// Metrik yang jadi dasar temuan ini, null untuk temuan lintas metrik.
  final EnergyMetric? metric;
}

/// Mengubah ringkasan riwayat menjadi rekomendasi konkret.
///
/// Murni tanpa akses ke widget atau jaringan supaya setiap aturan bisa diuji
/// langsung. Dua aturan berlaku di seluruh fungsi ini:
///
/// - Insight yang datanya belum cukup **dihilangkan**, bukan ditampilkan
///   dengan tebakan. Percakapan(short) yang salah lebih buruk daripada diam.
/// - Tidak ada angka yang tidak bisa ditelusuri ke [EnergyPeriodSummary].
class RecommendationEngine {
  const RecommendationEngine();

  /// Minimal pengukuran sebelum tren layak dilaporkan.
  static const int _minHoursForTrend = 6;

  /// Kenaikan konsumsi yang layak diperingatkan sebelum jadi kebiasaan.
  static const double _trendThresholdPct = 5;

  /// Coverage di bawah ini berarti sebagian besar angka hasil interpolasi.
  static const double _coverageThresholdPct = 95;

  static const double _minConsumptionForShiftHint = 0.5;

  List<EnergyInsight> build({
    required EnergyPeriodSummary summary,
    EnergyPeriodSummary? previous,
  }) {
    if (summary.isEmpty) return const [];

    return [
      ..._peakHourInsight(summary),
      ..._powerFactorInsight(summary),
      ..._voltageInsight(summary),
      ..._frequencyInsight(summary),
      ..._trendInsight(summary, previous),
      ..._dataQualityInsight(summary),
    ];
  }

  /// Dua bucket dengan konsumsi tertinggi, untuk saran geser beban.
  ///
  /// Memakai bucket tampilan, bukan baris per jam, supaya sarannya cocok dengan
  /// grafik yang sedang dilihat pengguna: "hari Rabu" untuk periode Mingguan,
  /// "pukul 19.00" untuk periode Harian.
  ({HistoryBucket first, HistoryBucket second})? topWindows(
    EnergyPeriodSummary summary,
  ) {
    final filled = summary.buckets.where((b) => !b.isEmpty).toList();
    if (filled.length < 2) return null;
    filled.sort((a, b) => b.kwh.compareTo(a.kwh));
    return (first: filled[0], second: filled[1]);
  }

  List<EnergyInsight> _peakHourInsight(EnergyPeriodSummary summary) {
    final top = topWindows(summary);
    if (top == null) return const [];
    if (top.first.kwh < _minConsumptionForShiftHint) return const [];
    if (summary.totalKwh <= 0) return const [];

    final share = top.first.kwh / summary.totalKwh * 100;
    final granularity = summary.period.granularity;
    final where = switch (granularity) {
      HistoryGranularity.hour => 'pukul ${_hourLabel(top.first.from)}',
      HistoryGranularity.day => 'hari ${top.first.label}',
      HistoryGranularity.month => 'bulan ${top.first.label}',
    };
    final second = top.second.kwh > 0
        ? 'wilayah ${top.second.label} menyusul '
            '(${_kwh(top.second.kwh)} kWh). '
        : '';
    final shiftHint = granularity == HistoryGranularity.hour
        ? 'Memindahkan beban yang bisa ditunda ke jam sepi di sekitar '
            'pukul 01.00-04.00 memangkas biaya tanpa mengurangi kenyamanan.'
        : 'Jam-jam sepi di periode ini justru paling murah untuk menjalankan '
            'beban berat.';

    return [
      EnergyInsight(
        severity: InsightSeverity.info,
        title: 'Konsumsi tertinggi di $where',
        body: 'Bagian itu menyerap ${_kwh(top.first.kwh)} kWh, '
            '${share.toStringAsFixed(0)}% dari total '
            '${summary.period.label.toLowerCase()}. '
            '$second$shiftHint',
        metric: EnergyMetric.power,
      ),
    ];
  }

  List<EnergyInsight> _powerFactorInsight(EnergyPeriodSummary summary) {
    final pf = summary.averagePowerFactor;
    if (pf == null) return const [];

    final bound = EnergyMetric.powerFactor.healthyLow!;
    if (pf >= bound) {
      return [
        EnergyInsight(
          severity: InsightSeverity.positive,
          title: 'Faktor daya sehat',
          body: 'Rata-rata $pf berada di atas ambang $bound. Beban bekerja '
              'efisien dan lebih sedikit energi terbuang jadi panas.',
          metric: EnergyMetric.powerFactor,
        ),
      ];
    }

    final worst = summary.minimums[EnergyMetric.powerFactor];
    final worstNote = worst == null
        ? ''
        : ' Nilai terendah $worst tercatat saat beban paling besar.';
    return [
      EnergyInsight(
        severity: pf < bound * 0.8
            ? InsightSeverity.warning
            : InsightSeverity.info,
        title: 'Faktor daya di bawah target',
        body: 'Rata-rata $pf, target minimal $bound. Beban reaktif cukup '
            'besar sehingga kabel dan trafo bekerja lebih panas.$worstNote '
            'Periksa motor lama dan pertimbangkan kompensator.',
        metric: EnergyMetric.powerFactor,
      ),
    ];
  }

  List<EnergyInsight> _voltageInsight(EnergyPeriodSummary summary) {
    final min = summary.minimums[EnergyMetric.voltage];
    final max = summary.maximums[EnergyMetric.voltage];
    if (min == null && max == null) return const [];

    final low = EnergyMetric.voltage.healthyLow!;
    final high = EnergyMetric.voltage.healthyHigh!;
    final breached = (min != null && min < low) || (max != null && max > high);

    if (!breached) {
      return [
        EnergyInsight(
          severity: InsightSeverity.positive,
          title: 'Tegangan stabil',
          body: 'Tegangan bertahan di $_range(min, max) V sepanjang periode, '
              'di dalam rentang $low-$high V.',
          metric: EnergyMetric.voltage,
        ),
      ];
    }

    final outside = <String>[
      if (min != null && min < low) 'turun ke $min V',
      if (max != null && max > high) 'naik ke $max V',
    ].join(' dan ');
    return [
      EnergyInsight(
        severity: min != null && min < low * 0.95
            ? InsightSeverity.critical
            : InsightSeverity.warning,
        title: 'Tegangan keluar dari rentang',
        body: 'Tegangan $outside, di luar rentang $low-$high V. Tegangan rendah '
            'berarti arus naik untuk daya yang sama sehingga kabel lebih cepat '
            'panas. Periksa sambungan dan ukuran MCB.',
        metric: EnergyMetric.voltage,
      ),
    ];
  }

  List<EnergyInsight> _frequencyInsight(EnergyPeriodSummary summary) {
    final min = summary.minimums[EnergyMetric.frequency];
    final max = summary.maximums[EnergyMetric.frequency];
    if (min == null && max == null) return const [];

    final low = EnergyMetric.frequency.healthyLow!;
    final high = EnergyMetric.frequency.healthyHigh!;
    if ((min == null || min >= low) && (max == null || max <= high)) {
      return const [];
    }

    return [
      EnergyInsight(
        severity: InsightSeverity.warning,
        title: 'Frekuensi menyimpang',
        body: 'Frekuensi bergerak di $_range(min, max) Hz, keluar dari '
            'rentang $low-$high Hz. Penyimpangan sekecil ini biasanya datang '
            'dari generator atau beban besar yang ikut dinyalakan.',
        metric: EnergyMetric.frequency,
      ),
    ];
  }

  List<EnergyInsight> _trendInsight(
    EnergyPeriodSummary summary,
    EnergyPeriodSummary? previous,
  ) {
    if (previous == null || previous.isEmpty) return const [];
    if (summary.observedHours < _minHoursForTrend) return const [];
    if (previous.observedHours < _minHoursForTrend) return const [];

    final change = summary.changePct(previous);
    if (change == null || change.abs() < _trendThresholdPct) return const [];

    final period = summary.period.label.toLowerCase();
    final down = change < 0;
    final changeText = '${change.abs().toStringAsFixed(1)}%';

    // Rata-rata per hari hanya bermakna kalau periodenya memang lebih dari satu
    // hari. Untuk periode "Hari", pembandingnya adalah total hari itu sendiri,
    // bukan total dibagi 7 yang akan mengarang angka dari luar periode.
    final days = summary.period.span.inDays;
    final lead = days > 1 ? 'Rata-rata harian' : 'Konsumsi harian';
    final before = previous.totalKwh / days;
    final after = summary.totalKwh / days;

    return [
      EnergyInsight(
        severity: down ? InsightSeverity.positive : InsightSeverity.warning,
        title: down
            ? 'Konsumsi $period turun $changeText'
            : 'Konsumsi $period naik $changeText',
        body: down
            ? '$lead turun dari ${_kwh(before)} menjadi ${_kwh(after)} kWh. '
                'Pola ini layak dijaga.'
            : '$lead naik dari ${_kwh(before)} menjadi ${_kwh(after)} kWh. '
                'Kalau tidak ada perubahan di rumah, periksa perangkat yang '
                'menyala lama.',
      ),
    ];
  }

  /// Peringatan kualitas data.
  ///
  /// Ini bukan rekomendasi, tapi nilainya penting: kalau coverage jelek, angka
  /// lain di layar ini berbasis interpolasi dan pengguna perlu tahu.
  List<EnergyInsight> _dataQualityInsight(EnergyPeriodSummary summary) {
    if (summary.observedHours < _minHoursForTrend) return const [];

    final coverage = summary.averageCoveragePct;
    final weakCoverage = coverage < _coverageThresholdPct;
    final weakSamples = summary.estimatedRatio > 0.5;
    if (!weakCoverage && !weakSamples) return const [];

    final parts = <String>[
      if (weakCoverage)
        'coverage pengukuran ${coverage.toStringAsFixed(0)}%'
          '(di bawah ${_coverageThresholdPct.toStringAsFixed(0)}%)',
      if (weakSamples)
        '${(summary.estimatedRatio * 100).toStringAsFixed(0)}% interval '
            'diestimasi karena meter tidak maju',
    ];

    return [
      EnergyInsight(
        severity: InsightSeverity.warning,
        title: 'Sebagian angka periode ini adalah estimasi',
        body: 'Rincian: ${parts.join(' dan ')}. Penyebab paling umum koneksi '
            'ke ESP terputus sementara. Angka tren masih berguna sebagai arah, '
            'tapi jangan dipakai untuk tagihan.',
      ),
    ];
  }

  /// Menilai satu pembacaan langsung terhadap rentang setiap metrik.
  ///
  /// Menghasilkan keenam metrik, termasuk yang tidak punya batas (arus, daya,
  /// energi) yang selalu `healthy`. Widget cukup menampilkan daftarnya tanpa
  /// perlu tahu metrik mana yang punya ambang batas.
  static List<MetricReading> classifyLive(EnergyReading reading) {
    return [
      for (final metric in EnergyMetric.values)
        MetricReading(
          metric: metric,
          value: metric.readLive(reading) / metric.divisor,
          status: metric.classify(metric.readLive(reading)),
        ),
    ];
  }

  static String _hourLabel(DateTime hour) =>
      '${hour.hour.toString().padLeft(2, '0')}.${hour.minute.toString().padLeft(2, '0')}';

  static String _kwh(double value) => value.toStringAsFixed(2);

  static String _range(double? min, double? max) {
    if (min != null && max != null) return '$min-$max';
    if (min != null) return '>=$min';
    if (max != null) return '<=$max';
    return 'tidak terukur';
  }
}
