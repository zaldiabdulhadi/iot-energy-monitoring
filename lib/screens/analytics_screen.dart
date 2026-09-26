import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/energy_metric.dart';
import '../models/energy_period_summary.dart';
import '../providers/energy_history_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/insight_card.dart';
import '../widgets/layout.dart';
import '../widgets/metric_tile.dart';
import '../widgets/section_header.dart';

/// Analisis riwayat: konsumsi per periode, rentang tiap parameter, dan
/// rekomendasi yang dihitung dari angka itu.
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  EnergyMetric _chartMetric = EnergyMetric.power;

  @override
  Widget build(BuildContext context) {
    final history = context.watch<EnergyHistoryProvider>();
    final gutters = Gutters.of(context);
    final summary = history.summary;

    return ListView(
      padding: gutters.all,
      children: [
        Text(
          'Analisis',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Dari riwayat per jam yang tercatat di perangkat',
          style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
        ),
        const SizedBox(height: 16),
        _PeriodSelector(
          selected: history.selectedPeriod,
          onChanged: (period) => history.select(period),
        ),
        const SizedBox(height: 16),
        if (history.error != null)
          EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Riwayat tidak terbaca',
            body: '${history.error}',
          )
        else if (summary == null || history.isEmpty)
          const EmptyState(
            icon: Icons.query_stats_rounded,
            title: 'Belum ada riwayat untuk periode ini',
            body: 'Data muncul setelah satu jam penuh tercatat. Untuk periode '
                'lebih panjang, aplikasi perlu berjalan beberapa waktu.',
          )
        else ...[
          _SummaryCard(summary: summary, previous: history.previous),
          const SizedBox(height: 18),
          _ConsumptionChart(summary: summary),
          const SizedBox(height: 18),
          _MetricHistoryChart(
            summary: summary,
            metric: _chartMetric,
            onMetricChanged: (m) => setState(() => _chartMetric = m),
          ),
          const SizedBox(height: 18),
          const SectionHeader(
            title: 'Rentang parameter',
            icon: Icons.table_rows_outlined,
          ),
          const SizedBox(height: 10),
          _ParameterTable(summary: summary),
          const SizedBox(height: 18),
          const SectionHeader(
            title: 'Rekomendasi smart',
            icon: Icons.lightbulb_outline_rounded,
          ),
          const SizedBox(height: 10),
          if (history.isThin)
            const EmptyState(
              icon: Icons.hourglass_empty_rounded,
              title: 'Data masih sedikit',
              body: 'Perlu minimal dua jam terekam sebelum pola bisa dibaca. '
                  'Kembali beberapa saat lagi.',
            )
          else if (history.insights.isEmpty)
            const EmptyState(
              icon: Icons.check_circle_outline_rounded,
              title: 'Tidak ada yang perlu dikerjakan',
              body: 'Semua parameter berada di rentang yang wajar untuk '
                  'periode ini.',
            )
          else
            InsightList(insights: history.insights),
        ],
      ],
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.selected, required this.onChanged});

  final HistoryPeriod selected;
  final ValueChanged<HistoryPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (final period in HistoryPeriod.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(period),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
                  decoration: BoxDecoration(
                    color: period == selected
                        ? AppColors.primaryDark
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      period.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: period == selected
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Total konsumsi, biaya, dan perbandingan dengan periode sebelumnya.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary, required this.previous});

  final EnergyPeriodSummary summary;
  final EnergyPeriodSummary? previous;

  @override
  Widget build(BuildContext context) {
    final change = summary.changePct(previous);

    return AppCard(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE8F6EB), Color(0xFFF8FAF9)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total ${summary.period.label.toLowerCase()} · '
                  '${summary.period.description}',
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              if (change != null) ...[
                const SizedBox(width: 8),
                Flexible(child: TrendBadge(percent: change)),
              ],
            ],
          ),
          const SizedBox(height: 10),
          AdaptiveNumber(
            value: formatValue(summary.totalKwh, 2),
            suffix: 'kWh',
            fontSize: 32,
            color: AppColors.deepGreen,
          ),
          const SizedBox(height: 4),
          Text(
            change == null
                ? 'Belum ada periode sebelumnya untuk dibandingkan'
                : 'dibanding ${formatValue(previous!.totalKwh, 2)} kWh '
                    'periode sebelumnya',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          MetricGrid(
            tiles: [
              SummaryTile(
                label: 'Biaya',
                value: formatValue(summary.cost, 0),
                suffix: 'Rp',
                icon: Icons.payments_outlined,
                caption: 'tarif perangkat',
              ),
              SummaryTile(
                label: 'Rata-rata daya',
                value: formatValue(summary.averagePowerKw, 2),
                suffix: 'kW',
                icon: Icons.bolt_rounded,
                caption: 'seluruh periode',
              ),
              SummaryTile(
                label: 'Jejak karbon',
                value: formatValue(summary.co2Kg, 1),
                suffix: 'kg',
                icon: Icons.eco_outlined,
                caption: 'faktor grid',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _CoverageRow(summary: summary),
        ],
      ),
    );
  }
}

/// Kelengkapan data, karena angka lain di kartu ini bergantung padanya.
class _CoverageRow extends StatelessWidget {
  const _CoverageRow({required this.summary});

  final EnergyPeriodSummary summary;

  @override
  Widget build(BuildContext context) {
    // Berapa jam benar-benar terekam dibanding jam yang diharapkan periode ini.
    final expected = summary.expectedHours;
    final ratio = expected <= 0 ? 0.0 : summary.observedHours / expected;
    final pct = (ratio * 100).clamp(0.0, 100.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${summary.observedHours} dari ${summary.expectedHours} jam '
                'terekam',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            Text(
              '${pct.toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: pct / 100,
            minHeight: 6,
            backgroundColor: AppColors.primaryLight,
            color: pct >= 90 ? AppColors.primaryDark : AppColors.warning,
          ),
        ),
      ],
    );
  }
}

/// Konsumsi per bucket: per jam, per hari, atau per bulan sesuai periode.
class _ConsumptionChart extends StatelessWidget {
  const _ConsumptionChart({required this.summary});

  final EnergyPeriodSummary summary;

  @override
  Widget build(BuildContext context) {
    final buckets = summary.buckets;
    final filled = buckets.where((b) => !b.isEmpty).toList();
    if (filled.length < 2) {
      return const AppCard(
        padding: EdgeInsets.symmetric(vertical: 22, horizontal: 18),
        child: Text(
          'Butuh minimal dua titik data untuk menggambar grafik.',
          style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
        ),
      );
    }

    final maxY = _niceMax(
      filled.map((b) => b.kwh).reduce((a, b) => a > b ? a : b),
    );
    final peak = filled.reduce((a, b) => b.kwh > a.kwh ? b : a);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Konsumsi ${_unitOf(summary.period)}',
            action: 'puncak ${formatValue(peak.kwh, 2)} kWh',
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 190,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barGroups: [
                  for (final bucket in buckets)
                    BarChartGroupData(
                      x: buckets.indexOf(bucket),
                      barRods: [
                        BarChartRodData(
                          toY: bucket.kwh,
                          width: _barWidth(buckets.length),
                          color: bucket.isEmpty
                              ? AppColors.border
                              : bucket == peak
                                  ? AppColors.cyanAccent
                                  : AppColors.primary,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxY,
                            color: AppColors.primaryLight,
                          ),
                        ),
                      ],
                    ),
                ],
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.border.withValues(alpha: 0.6),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      // Setiap bucket diberi label hanya kalau muat, supaya
                      // label tidak saling tumpang tindih di layar sempit.
                      interval: _labelInterval(buckets.length),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= buckets.length) {
                          return const SizedBox.shrink();
                        }
                        return SideTitleWidget(
                          meta: meta,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              buckets[index].label,
                              style: const TextStyle(
                                fontSize: 9,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.deepGreen,
                    getTooltipItem: (group, _, rod, _) {
                      final bucket = buckets[group.x];
                      return BarTooltipItem(
                        '${bucket.label}\n${formatValue(rod.toY, 2)} kWh',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 11.5,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _unitOf(HistoryPeriod period) => switch (period) {
        HistoryPeriod.day => 'per jam',
        HistoryPeriod.week || HistoryPeriod.month => 'per hari',
        HistoryPeriod.year => 'per bulan',
      };

  /// Lebar batang mengecil seiring bertambahnya jumlah bucket.
  static double _barWidth(int count) {
    if (count <= 8) return 16;
    if (count <= 16) return 9;
    if (count <= 26) return 6;
    return 4;
  }

  /// Berapa banyak bucket yang dilewati antar label sumbu bawah.
  static double _labelInterval(int count) {
    if (count <= 8) return 1;
    if (count <= 14) return 2;
    if (count <= 24) return 4;
    if (count <= 31) return 5;
    return 1;
  }

  static double _niceMax(double value) {
    if (value <= 0) return 1;
    final step = value > 20 ? 5.0 : (value > 5 ? 1.0 : 0.5);
    return (value / step).ceil() * step;
  }
}

/// Garis rata-rata satu parameter sepanjang periode.
class _MetricHistoryChart extends StatelessWidget {
  const _MetricHistoryChart({
    required this.summary,
    required this.metric,
    required this.onMetricChanged,
  });

  final EnergyPeriodSummary summary;
  final EnergyMetric metric;
  final ValueChanged<EnergyMetric> onMetricChanged;

  @override
  Widget build(BuildContext context) {
    final filled = summary.buckets.where((b) => !b.isEmpty).toList();
    if (filled.length < 2) return const SizedBox.shrink();

    final values = [for (final b in filled) b.metricOf(metric) ?? 0];
    final average = summary.averageOf(metric) ?? 0;
    final maxY = _niceMax(values.reduce((a, b) => a > b ? a : b));

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Sejarah parameter',
            icon: Icons.show_chart_rounded,
          ),
          const SizedBox(height: 12),
          _MetricChips(
            selected: metric,
            onChanged: onMetricChanged,
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 170,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (filled.length - 1).toDouble(),
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.border.withValues(alpha: 0.6),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                ),
                borderData: FlBorderData(show: false),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: average.clamp(0, maxY),
                      color: AppColors.cyanAccent,
                      strokeWidth: 1.4,
                      dashArray: [6, 4],
                    ),
                  ],
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      interval: _labelInterval(filled.length),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= filled.length) {
                          return const SizedBox.shrink();
                        }
                        return SideTitleWidget(
                          meta: meta,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              filled[index].label,
                              style: const TextStyle(
                                fontSize: 9,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      getTitlesWidget: (value, meta) => SideTitleWidget(
                        meta: meta,
                        child: Text(
                          formatValue(value, value >= 10 ? 0 : 1),
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.deepGreen,
                    getTooltipItems: (spots) => [
                      for (final spot in spots)
                        LineTooltipItem(
                          '${formatValue(spot.y, metric.decimals)} ${metric.unit}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 11.5,
                          ),
                        ),
                    ],
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < filled.length; i++)
                        FlSpot(i.toDouble(), values[i]),
                    ],
                    isCurved: true,
                    curveSmoothness: 0.3,
                    barWidth: 2.5,
                    color: AppColors.primaryDark,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.35),
                          AppColors.primary.withValues(alpha: 0.02),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 14,
                height: 2,
                color: AppColors.cyanAccent,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'rata-rata ${formatValue(average, metric.decimals)} '
                  '${metric.unit}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static double _labelInterval(int count) {
    if (count <= 8) return 1;
    if (count <= 14) return 2;
    if (count <= 24) return 4;
    return 5;
  }

  static double _niceMax(double value) {
    if (value <= 0) return 1;
    final step = value > 20 ? 5.0 : (value > 5 ? 1.0 : 0.5);
    return (value / step).ceil() * step;
  }
}

/// Pemilih parameter untuk grafik sejarah.
class _MetricChips extends StatelessWidget {
  const _MetricChips({required this.selected, required this.onChanged});

  final EnergyMetric selected;
  final ValueChanged<EnergyMetric> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: EnergyMetric.tracked.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final metric = EnergyMetric.tracked[index];
          final isSelected = metric == selected;
          return GestureDetector(
            onTap: () => onChanged(metric),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryDark : AppColors.card,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSelected ? AppColors.primaryDark : AppColors.border,
                ),
              ),
              child: Text(
                metric.label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Tabel rata-rata, minimum, dan maksimum tiap parameter dalam periode.
class _ParameterTable extends StatelessWidget {
  const _ParameterTable({required this.summary});

  final EnergyPeriodSummary summary;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                flex: 4,
                child: Text(
                  'Parameter',
                  style: _headerStyle,
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Rata-rata',
                  textAlign: TextAlign.right,
                  style: _headerStyle,
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Rentang',
                  textAlign: TextAlign.right,
                  style: _headerStyle,
                ),
              ),
              const Expanded(
                flex: 2,
                child: SizedBox.shrink(),
              ),
            ],
          ),
          const Divider(height: 18, color: AppColors.border),
          for (final metric in EnergyMetric.tracked) ...[
            _ParameterRow(metric: metric, summary: summary),
            if (metric != EnergyMetric.tracked.last)
              const Divider(height: 14, color: AppColors.border),
          ],
        ],
      ),
    );
  }

  static const _headerStyle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
  );
}

class _ParameterRow extends StatelessWidget {
  const _ParameterRow({required this.metric, required this.summary});

  final EnergyMetric metric;
  final EnergyPeriodSummary summary;

  @override
  Widget build(BuildContext context) {
    final average = summary.averageOf(metric);
    final min = summary.minimums[metric];
    final max = summary.maximums[metric];
    final status = average == null
        ? MetricStatus.healthy
        : metric.classify(average);
    final tone = switch (status) {
      MetricStatus.healthy => AppColors.textPrimary,
      MetricStatus.warning => AppColors.warning,
      MetricStatus.critical => AppColors.critical,
    };

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Row(
            children: [
              Icon(metric.icon, size: 15, color: AppColors.primaryDark),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            average == null
                ? '-'
                : '${formatValue(average, metric.decimals)} ${metric.unit}',
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: tone,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            _rangeLabel(min, max),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Align(
            alignment: Alignment.centerRight,
            child: metric.isBounded
                ? Icon(
                    status == MetricStatus.healthy
                        ? Icons.check_circle_rounded
                        : Icons.error_outline_rounded,
                    size: 15,
                    color: status == MetricStatus.healthy
                        ? AppColors.success
                        : tone,
                  )
                : const Icon(Icons.remove_rounded, size: 15, color: AppColors.border),
          ),
        ),
      ],
    );
  }

  /// Rentang hanya ditampilkan kalau kedua ujungnya ada.
  ///
  /// Arus hanya punya maksimum dan faktor daya hanya punya minimum, jadi
  /// menampilkan "0,00" sebagai ujung yang tidak pernah diukur akan mengarang
  /// angka.
  static String _rangeLabel(double? min, double? max) {
    if (min != null && max != null) {
      return '${min.toStringAsFixed(1)}-${max.toStringAsFixed(1)}';
    }
    if (max != null) return '<= ${max.toStringAsFixed(1)}';
    if (min != null) return '>= ${min.toStringAsFixed(1)}';
    return '-';
  }
}
