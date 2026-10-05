import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/energy_metric.dart';
import '../models/energy_period_summary.dart';
import '../providers/energy_data_provider.dart';
import '../providers/energy_history_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/insight_card.dart';
import '../widgets/layout.dart';
import '../widgets/metric_tile.dart';
import '../widgets/section_header.dart';
import '../widgets/status_pill.dart';

/// Pemantauan enam parameter yang dikirim ESP, plus ringkasan konsumsi hari ini
/// dari riwayat.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final live = context.watch<EnergyDataProvider>();
    final history = context.watch<EnergyHistoryProvider>();
    final gutters = Gutters.of(context);

    return ListView(
      padding: gutters.all,
      children: [
        _Header(provider: live),
        SizedBox(height: gutters.vertical),
        _LiveMetricsCard(provider: live),
        const SizedBox(height: 18),
        _TodayCard(summary: history.summary, loading: history.isLoading),
        const SizedBox(height: 18),
        const SectionHeader(
          title: 'Kualitas daya',
          icon: Icons.health_and_safety_outlined,
        ),
        const SizedBox(height: 10),
        _PowerQualityCard(provider: live),
        const SizedBox(height: 18),
        SectionHeader(
          title: 'Rekomendasi smart',
          icon: Icons.lightbulb_outline_rounded,
        ),
        const SizedBox(height: 10),
        _RecommendationBlock(history: history),
        const SizedBox(height: 18),
        _LiveChartCard(provider: live),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.provider});

  final EnergyDataProvider provider;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final (String label, PillTone tone, IconData? icon) = switch (provider) {
      final p when p.connecting => (
          'Mengambil data',
          PillTone.info,
          Icons.sync_rounded,
        ),
      final p when p.connected => (
          'Data live dari ESP',
          PillTone.success,
          null,
        ),
      final p when p.demoMode => ('Mode simulasi', PillTone.warning, null),
      _ => (provider.error ?? 'Koneksi terputus', PillTone.critical, null),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(
            'A',
            style: textTheme.titleMedium?.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WattSerra',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              StatusPill(label: label, tone: tone, icon: icon),
            ],
          ),
        ),
        if (provider.lastUpdated != null)
          Flexible(
            child: Text(
              _ago(provider.lastUpdated!),
              textAlign: TextAlign.right,
              maxLines: 2,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textMuted,
              ),
            ),
          ),
      ],
    );
  }

  static String _ago(DateTime since) {
    final seconds = DateTime.now().difference(since).inSeconds;
    if (seconds < 5) return 'baru saja';
    if (seconds < 60) return '$seconds dtk lalu';
    final minutes = seconds ~/ 60;
    return '$minutes mnt lalu';
  }
}

/// Grid enam parameter, persis sesuai isi JSON ESP.
class _LiveMetricsCard extends StatelessWidget {
  const _LiveMetricsCard({required this.provider});

  final EnergyDataProvider provider;

  @override
  Widget build(BuildContext context) {
    final readings = provider.liveMetrics;

    if (readings.isEmpty) {
      return const EmptyState(
        icon: Icons.sensors_off_rounded,
        title: 'Belum ada pembacaan',
        body: 'Hubungkan perangkat ke hotspot ESP lalu ambil data untuk mulai '
            'memantau enam parameter ini.',
      );
    }

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Parameter live',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              const Text(
                '6 metrik',
                style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MetricGrid(
            tiles: [
              for (final reading in readings)
                MetricTile(
                  metric: reading.metric,
                  value: reading.value,
                  // Energi adalah register kumulatif, jadi label statusnya
                  // tidak berlaku dan diganti keterangan bahwa ini akumulator.
                  status: reading.metric == EnergyMetric.energy
                      ? null
                      : reading.status,
                  footnote: reading.metric == EnergyMetric.energy
                      ? 'counter meter'
                      : reading.metric.isBounded
                          ? reading.status.label
                          : 'terukur',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Konsumsi energi nyata untuk hari ini, dihitung dari riwayat per jam.
class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.summary, required this.loading});

  final EnergyPeriodSummary? summary;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading && summary == null) {
      return const AppCard(
        padding: EdgeInsets.symmetric(vertical: 28, horizontal: 18),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
        ),
      );
    }

    final data = summary;
    if (data == null || data.isEmpty) {
      return const EmptyState(
        icon: Icons.query_stats_rounded,
        title: 'Riwayat 24 jam belum terbentuk',
        body: 'Konsumsi per jam dihitung dari selisih register meter. Setelah '
            'satu jam penuh terisi, angkanya muncul di sini.',
      );
    }

    return AppCard(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE8F6EB), Color(0xFFDDF3E3)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Konsumsi 24 jam terakhir',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AdaptiveNumber(
            value: formatValue(data.totalKwh, 2),
            suffix: 'kWh',
            fontSize: 32,
            color: AppColors.deepGreen,
          ),
          const SizedBox(height: 4),
          Text(
            'dari ${data.observedHours} jam terekam'
            '${data.isAnalyzable ? '' : ' · perlu 2 jam untuk analisis'}',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          MetricGrid(
            tiles: [
              SummaryTile(
                label: 'Rata-rata daya',
                value: formatValue(data.averagePowerW, 1),
                suffix: 'W',
                icon: Icons.electric_meter_rounded,
                caption: 'seluruh periode',
              ),
              SummaryTile(
                label: 'Daya puncak',
                value: formatValue(data.peakPowerW, 1),
                suffix: 'W',
                icon: Icons.bolt_rounded,
                color: AppColors.warning,
                caption: data.peakHour == null
                    ? 'belum ada'
                    : 'pukul ${_hour(data.peakHour!)}',
              ),
              SummaryTile(
                label: 'Faktor daya',
                value: formatValue(data.averagePowerFactor ?? 0, 2),
                suffix: 'PF',
                icon: Icons.tune_rounded,
                caption: _pfCaption(data.averagePowerFactor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _pfCaption(double? pf) {
    if (pf == null) return 'belum ada';
    final bound = EnergyMetric.powerFactor.healthyLow!;
    return pf >= bound ? 'di atas target' : 'di bawah target $bound';
  }

  static String _hour(DateTime hour) =>
      '${hour.hour.toString().padLeft(2, '0')}.${hour.minute.toString().padLeft(2, '0')}';
}

/// Status tiap parameter berbatas, jujur soal mana yang bermasalah.
class _PowerQualityCard extends StatelessWidget {
  const _PowerQualityCard({required this.provider});

  final EnergyDataProvider provider;

  @override
  Widget build(BuildContext context) {
    final readings = provider.liveMetrics;
    if (readings.isEmpty) return const SizedBox.shrink();

    final bounded = readings.where((r) => r.metric.isBounded).toList();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  provider.isStable
                      ? 'Semua parameter dalam rentang'
                      : '${readings.where((r) => !r.isHealthy).length} parameter keluar dari rentang',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(
                label: provider.isStable ? 'Normal' : 'Perhatian',
                tone: provider.isStable ? PillTone.success : PillTone.warning,
                icon: provider.isStable
                    ? Icons.check_rounded
                    : Icons.error_outline_rounded,
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < bounded.length; i++) ...[
            _QualityRow(reading: bounded[i]),
            if (i < bounded.length - 1)
              const Divider(height: 18, color: AppColors.border),
          ],
        ],
      ),
    );
  }
}

class _QualityRow extends StatelessWidget {
  const _QualityRow({required this.reading});

  final MetricReading reading;

  @override
  Widget build(BuildContext context) {
    final tone = switch (reading.status) {
      MetricStatus.healthy => AppColors.success,
      MetricStatus.warning => AppColors.warning,
      MetricStatus.critical => AppColors.critical,
    };

    return Row(
      children: [
        Icon(reading.metric.icon, size: 16, color: AppColors.primaryDark),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reading.metric.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                'target ${reading.metric.healthyRangeLabel}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            '${formatValue(reading.value, reading.metric.decimals)} ${reading.metric.unit}',
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: tone),
          ),
        ),
      ],
    );
  }
}

class _RecommendationBlock extends StatelessWidget {
  const _RecommendationBlock({required this.history});

  final EnergyHistoryProvider history;

  @override
  Widget build(BuildContext context) {
    if (history.isLoading && history.summary == null) {
      return const AppCard(
        padding: EdgeInsets.symmetric(vertical: 24, horizontal: 18),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
        ),
      );
    }

    if (history.insights.isNotEmpty) {
      return InsightList(insights: history.insights);
    }

    return const EmptyState(
      icon: Icons.insights_rounded,
      title: 'Belum ada rekomendasi',
      body: 'Rekomendasi muncul setelah ada cukup riwayat untuk melihat pola '
          'puncak beban, faktor daya, dan tegangan.',
    );
  }
}

/// Grafik daya lima menit terakhir.
///
/// Rentangnya sengaja disebut "5 menit" dan bukan "24 jam": yang diplot adalah
/// sampel polling, sedangkan riwayat per jam ada di layar Analisis.
class _LiveChartCard extends StatelessWidget {
  const _LiveChartCard({required this.provider});

  final EnergyDataProvider provider;

  @override
  Widget build(BuildContext context) {
    final samples = provider.recentPowerW;
    if (samples.length < 2) return const SizedBox.shrink();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Daya 5 menit terakhir'),
          const SizedBox(height: 4),
          const Text(
            'Dari sampel polling ESP, bukan rata-rata per jam',
            style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (samples.length - 1).toDouble(),
                minY: 0,
                maxY: _niceMax(samples.reduce((a, b) => a > b ? a : b)),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.border.withValues(alpha: 0.6),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(
                  topTitles: AxisTitles(),
                  rightTitles: AxisTitles(),
                  bottomTitles: AxisTitles(),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.deepGreen,
                    getTooltipItems: (spots) => [
                      for (final spot in spots)
                        LineTooltipItem(
                          '${formatValue(spot.y, 1)} W',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < samples.length; i++)
                        FlSpot(i.toDouble(), samples[i]),
                    ],
                    isCurved: true,
                    curveSmoothness: 0.35,
                    barWidth: 2.5,
                    color: AppColors.primaryDark,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.4),
                          AppColors.primary.withValues(alpha: 0.02),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static double _niceMax(double value) {
    final step = value > 5 ? 1.0 : 0.5;
    return (value / step).ceil() * step;
  }
}
