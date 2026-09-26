
import '../data/local/app_database.dart';
import '../models/energy_hourly.dart';
import '../models/energy_metric.dart';
import '../models/energy_period_summary.dart';
import '../utils/bucket_time.dart';

/// Hasil satu permintaan analisis: periode yang dipilih beserta pembandingnya.
class HistoryReport {
  const HistoryReport({
    required this.summary,
    required this.previous,
  });

  final EnergyPeriodSummary summary;

  /// Periode dengan panjang yang sama, tepat sebelum [summary].
  ///
  /// Null kalau riwayat belum cukup lama untuk dibandingkan.
  final EnergyPeriodSummary? previous;
}

/// Mengubah riwayat per jam di SQLite menjadi ringkasan per periode.
///
/// Ini lapisan yang dibaca layar Analisis. Semuanya diturunkan dari
/// `hourly_history`, bukan dari nilai yang di-hardcode: kalau riwayat kosong,
/// hasilnya [EnergyPeriodSummary.empty] dan bukan angka tebasan.
class EnergyHistoryService {
  const EnergyHistoryService({required this.database});

  final EnergyDatabase database;

  /// Memuat riwayat lalu meringkasnya untuk satu periode.
  ///
  /// [now] bisa diinjeksi supaya hasilnya deterministik saat diuji.
  Future<HistoryReport> report(
    HistoryPeriod period, {
    DateTime? now,
  }) async {
    final reference = now ?? DateTime.now();
    final deviceKey = await database.currentDeviceId();
    if (deviceKey == null) {
      // Tidak ada meter terdaftar, jadi tidak ada riwayat. Tarif tetap
      // diambil supaya ringkasan kosong tidak menampilkan biaya 0 yang
      // berbeda dari asumsi yang dipakai di ringkasan berisi data.
      final settings = await database.currentSettings();
      return HistoryReport(
        summary: EnergyPeriodSummary.empty(
          period,
          from: _rangeStart(period, reference),
          to: reference,
          tariffPerKwh: settings.tariffPerKwh,
        ),
        previous: null,
      );
    }

    final to = _rangeEnd(period, reference);
    final from = _rangeStart(period, reference);
    final span = to.difference(from);

    final currentRows = await database.historyBetween(deviceKey, from, to);
    final previousRows = span > Duration.zero
        ? await database.historyBetween(
            deviceKey,
            from.subtract(span),
            from,
          )
        : const <EnergyHourly>[];

    final settings = await database.currentSettings();
    final summary = _summarize(
      period: period,
      from: from,
      to: to,
      rows: currentRows,
      settings: settings,
    );

    return HistoryReport(
      summary: summary,
      previous: previousRows.isEmpty
          ? null
          : _summarize(
              period: period,
              from: from.subtract(span),
              to: from,
              rows: previousRows,
              settings: settings,
            ),
    );
  }

  /// Batas atas periode, setengah terbuka.
  ///
  /// Untuk "Hari" dipakai ujung jam berjalan, supaya ada tepat 24 titik per jam
  /// yang sejajar dengan batas jam dan tidak ada titik dari jam yang belum
  /// terjadi.
  DateTime _rangeEnd(HistoryPeriod period, DateTime now) =>
      switch (period.granularity) {
        HistoryGranularity.hour =>
          floorToHour(now).add(const Duration(hours: 1)),
        HistoryGranularity.day => DateTime(
            now.year,
            now.month,
            now.day,
          ).add(const Duration(days: 1)),
        HistoryGranularity.month => DateTime(now.year, now.month + 1, 1),
      };

  DateTime _rangeStart(HistoryPeriod period, DateTime now) =>
      _rangeEnd(period, now).subtract(period.span);

  EnergyPeriodSummary _summarize({
    required HistoryPeriod period,
    required DateTime from,
    required DateTime to,
    required List<EnergyHourly> rows,
    required DeviceSettings settings,
  }) {
    final usable = rows.where((row) => !row.isEmpty).toList();
    if (usable.isEmpty) {
      return EnergyPeriodSummary.empty(
        period,
        from: from,
        to: to,
        tariffPerKwh: settings.tariffPerKwh,
      );
    }

    var totalKwh = 0.0;
    var observedSeconds = 0.0;
    var estimatedIntervals = 0;
    var sampleCount = 0;
    var peakPowerKw = 0.0;
    DateTime? peakHour;

    final minimums = <EnergyMetric, double>{};
    final maximums = <EnergyMetric, double>{};
    final sums = <EnergyMetric, double>{};

    for (final row in usable) {
      totalKwh += row.energyKwh;
      observedSeconds += row.observedSeconds;
      estimatedIntervals += row.estimatedIntervals;
      sampleCount += row.sampleCount;

      if (row.powerMax != null && row.powerMax! > peakPowerKw) {
        peakPowerKw = row.powerMax!;
        peakHour = row.hourStart;
      }

      for (final metric in EnergyMetric.tracked) {
        final mean = metric.avgOf(row);
        sums[metric] = (sums[metric] ?? 0) + mean;

        final min = metric.minOf(row);
        if (min != null) {
          final current = minimums[metric];
          if (current == null || min < current) minimums[metric] = min;
        }
        final max = metric.maxOf(row);
        if (max != null) {
          final current = maximums[metric];
          if (current == null || max > current) maximums[metric] = max;
        }
      }
    }

    // Rata-rata dihitung per jumlah baris per jam. Baris per jam sudah
    // menyimpan total tiap metrik beserta `sampleCount`-nya, jadi menimbang per
    // sampel mentah butuh kolom yang tidak ada di tabel mana pun.
    final average = <EnergyMetric, double>{
      for (final metric in EnergyMetric.tracked)
        if (sums.containsKey(metric))
          metric: sums[metric]! / usable.length,
    };

    final boundedObserved =
        observedSeconds.clamp(0.0, usable.length * 3600).toDouble();

    return EnergyPeriodSummary(
      period: period,
      from: from,
      to: to,
      totalKwh: totalKwh,
      cost: totalKwh * settings.tariffPerKwh,
      tariffPerKwh: settings.tariffPerKwh,
      co2Kg: totalKwh * settings.gridCo2KgPerKwh,
      peakPowerKw: peakPowerKw / 1000,
      peakHour: peakHour,
      averageCoveragePct:
          usable.isEmpty ? 0 : (boundedObserved / (usable.length * 3600)) * 100,
      estimatedRatio: sampleCount == 0 ? 0 : estimatedIntervals / sampleCount,
      observedHours: usable.length,
      expectedHours: period.expectedHours,
      buckets: _buildBuckets(period, from, to, usable),
      average: average,
      minimums: minimums,
      maximums: maximums,
    );
  }

  /// Mengelompokkan baris per jam menjadi titik grafik sesuai resolusi periode.
  List<HistoryBucket> _buildBuckets(
    HistoryPeriod period,
    DateTime from,
    DateTime to,
    List<EnergyHourly> rows,
  ) {
    final edges = _bucketEdges(period, from, to);
    return [
      for (var i = 0; i < edges.length - 1; i++)
        _bucketFor(period, edges[i], edges[i + 1], rows),
    ];
  }

  /// Batas waktu tiap bucket.
  ///
  /// Untuk granularitas bulan, batasnya batas kalender sungguhan, bukan
  /// `Duration(days: 30)`. Versi 30 hari menghasilkan dua kesalahan: 12 bucket
  /// hanya menutup 360 hari sehingga 5 hari terakhir periode setahun terlewat,
  /// dan label bulan pada bucket itu tidak cocok dengan rentang yang diplot.
  ///
  /// Bucket pertama dan terakhir boleh terpotong karena periodenya memang
  /// dipotong di [from] dan [to].
  List<DateTime> _bucketEdges(HistoryPeriod period, DateTime from, DateTime to) {
    switch (period.granularity) {
      case HistoryGranularity.hour:
        return [
          for (var i = 0; i <= 24; i++) from.add(Duration(hours: i)),
        ];
      case HistoryGranularity.day:
        return [
          for (var i = 0; i <= period.span.inDays; i++)
            from.add(Duration(days: i)),
        ];
      case HistoryGranularity.month:
        final edges = <DateTime>[];
        var edge = DateTime(from.year, from.month);
        edges.add(edge);
        while (edge.isBefore(to)) {
          edge = DateTime(edge.year, edge.month + 1);
          edges.add(edge);
        }
        return edges;
    }
  }

  HistoryBucket _bucketFor(
    HistoryPeriod period,
    DateTime from,
    DateTime to,
    List<EnergyHourly> rows,
  ) {
    final inRange = rows
        .where((row) => !row.hourStart.isBefore(from) && row.hourStart.isBefore(to))
        .toList();

    var kwh = 0.0;
    final sums = <EnergyMetric, double>{};
    for (final row in inRange) {
      kwh += row.energyKwh;
      for (final metric in EnergyMetric.tracked) {
        sums[metric] = (sums[metric] ?? 0) + metric.avgOf(row);
      }
    }

    return HistoryBucket(
      from: from,
      to: to,
      label: _labelOf(period, from),
      kwh: kwh,
      observedHours: inRange.length,
      metrics: inRange.isEmpty
          ? const {}
          : {
              for (final metric in EnergyMetric.tracked)
                if (sums.containsKey(metric))
                  metric: sums[metric]! / inRange.length,
            },
    );
  }

  /// Label sumbu untuk satu bucket.
  ///
  /// Nama bulan dan hari ditulis dari daftar lokal, bukan `DateFormat` locale
  /// `'id'`. `DateFormat` untuk locale selain `en` melempar `LocaleDataException`
  /// kalau `initializeDateFormatting` belum dipanggil, dan layanan ini juga
  /// dipakai dari test yang tidak menjalankan `main()`.
  String _labelOf(HistoryPeriod period, DateTime from) => switch (period) {
        HistoryPeriod.day => '${from.hour.toString().padLeft(2, '0')}.00',
        HistoryPeriod.week => _weekdays[from.weekday - 1],
        HistoryPeriod.month => '${from.day} ${_months[from.month - 1]}',
        HistoryPeriod.year => _months[from.month - 1],
      };

  static const _weekdays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
}
