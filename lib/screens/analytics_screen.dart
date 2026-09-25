import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/energy_data_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/section_header.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _f = NumberFormat.decimalPattern('id');
  int _periodIndex = 1;

  static const _periods = ['Hari', 'Minggu', 'Bulan', 'Tahun'];

  static const List<double> _weekly = [4.8, 6.2, 5.4, 7.1, 6.8, 8.4, 7.6];
  static const List<double> _monthly = [
    132, 128, 141, 135, 146, 150, 138, 129, 121, 118, 124, 131,
  ];

  static const _labels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          Text(
            'Analisis',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Pola penggunaan energi rumah Anda',
            style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 18),
          _PeriodSelector(
            periods: _periods,
            index: _periodIndex,
            onChanged: (i) => setState(() => _periodIndex = i),
          ),
          const SizedBox(height: 18),
          _buildTotalCard(context.watch<EnergyDataProvider>()),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(
                  switch (_periodIndex) {
                    0 => Icons.schedule_rounded,
                    1 => Icons.calendar_view_week_rounded,
                    _ => Icons.calendar_month_rounded,
                  },
                  size: 18,
                  color: AppColors.primaryDark,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: SectionHeader(
                    title: switch (_periodIndex) {
                      0 => 'Konsumsi per jam',
                      1 => 'Konsumsi per hari',
                      _ => 'Konsumsi per bulan',
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildBarChart(),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const SectionHeader(title: 'Beban per kategori'),
          ),
          const SizedBox(height: 12),
          _buildCategoryBreakdown(),
          const SizedBox(height: 20),
          _buildEnergyTip(),
        ],
      ),
    );
  }

  Widget _buildTotalCard(EnergyDataProvider provider) {
    final dayTotal = provider.energyToday;
    final total = switch (_periodIndex) {
      0 => dayTotal,
      1 => dayTotal * 6.4,
      2 => dayTotal * 27.5,
      _ => dayTotal * 310,
    };
    final prevTotal = total * 1.081;
    final diff = ((total - prevTotal) / prevTotal) * 100;
    final weekThis = dayTotal * 6.4;
    final weekLast = weekThis * 1.09;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8F6EB), Color(0xFFF8FAF9)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Total penggunaan · ${_periods[_periodIndex]} ini',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.trending_down_rounded,
                      size: 13,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${diff.abs().toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _f.format(total),
                style: const TextStyle(
                  fontSize: 34,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepGreen,
                ),
              ),
              const SizedBox(width: 6),
              const Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Text(
                  'kWh',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'vs ${_f.format(prevTotal)} kWh',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _totalBar(
                label: 'Minggu ini',
                value: weekThis,
                pct: weekThis / weekLast,
                color: AppColors.primaryDark,
              ),
              const SizedBox(width: 14),
              _totalBar(
                label: 'Minggu lalu',
                value: weekLast,
                pct: weekLast / weekLast,
                color: AppColors.border,
                muted: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _totalBar({
    required String label,
    required double value,
    required double pct,
    required Color color,
    bool muted = false,
  }) {
    final normalized = (pct).clamp(0.0, 1.0);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  color: muted ? AppColors.textMuted : AppColors.textSecondary,
                ),
              ),
              Text(
                '${_f.format(value)} kWh',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: normalized,
              minHeight: 8,
              backgroundColor: AppColors.primaryLight,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    final (
      List<double> values,
      List<String> labels,
      double maxY,
      double width,
    ) = switch (_periodIndex) {
      0 => (List.generate(24, (h) => 0.35 + (h == 19 ? 0.9 : 0.0)), _hourBarLabels(), 1.4, 5.0),
      1 => (_weekly, _labels, 9.0, 18.0),
      2 => (_monthly, _monthLabels(), 160.0, 14.0),
      _ => (_monthly, _monthLabels(), 160.0, 14.0),
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppTheme.softShadow,
      ),
      child: SizedBox(
        height: 210,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY / 4,
              getDrawingHorizontalLine: (value) => FlLine(
                color: AppColors.border.withValues(alpha: 0.6),
                strokeWidth: 1,
                dashArray: [5, 5],
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (v, meta) => SideTitleWidget(
                    meta: meta,
                    child: Text(
                      maxY > 9 ? v.toStringAsFixed(0) : v.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 26,
                  getTitlesWidget: (v, meta) {
                    final i = v.toInt();
                    return SideTitleWidget(
                      meta: meta,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          i < labels.length ? labels[i] : '',
                          style: const TextStyle(
                            fontSize: 9.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < values.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: values[i],
                      color: i == values.length - 1
                          ? AppColors.cyanAccent
                          : AppColors.primary,
                      width: width,
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
          ),
        ),
      ),
    );
  }

  List<String> _hourBarLabels() {
    return [
      for (var h = 0; h < 24; h += 4) h.toString().padLeft(2, '0'),
    ];
  }

  List<String> _monthLabels() {
    return const ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
  }

  Widget _buildCategoryBreakdown() {
    const categories = [
      (name: 'Pendingin & AC', value: 38.4, color: AppColors.primaryDark),
      (name: 'Peranti dapur', value: 24.1, color: AppColors.primary),
      (name: 'Pencahayaan', value: 15.2, color: AppColors.cyanAccent),
      (name: 'EV & transportasi', value: 14.7, color: AppColors.success),
      (name: 'Lainnya', value: 7.6, color: AppColors.warning),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          SizedBox(
            height: 170,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 44,
                sectionsSpace: 4,
                startDegreeOffset: -90,
                sections: [
                  for (final c in categories)
                    PieChartSectionData(
                      value: c.value,
                      color: c.color,
                      radius: 52,
                      showTitle: false,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ...categories.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: c.color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      c.name,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '${_f.format(c.value)} kWh',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
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

  Widget _buildEnergyTip() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.eco_rounded,
              color: AppColors.primaryDark,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Wawasan hemat',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepGreen,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Perpindahan suhu AC 1°C menghasilkan penghematan energi ± 8% per bulan.',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.45,
                    color: AppColors.textSecondary.withValues(alpha: 0.95),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.periods,
    required this.index,
    required this.onChanged,
  });

  final List<String> periods;
  final int index;
  final ValueChanged<int> onChanged;

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
          for (var i = 0; i < periods.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: i == index ? AppColors.primaryDark : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    periods[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: i == index ? Colors.white : AppColors.textSecondary,
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