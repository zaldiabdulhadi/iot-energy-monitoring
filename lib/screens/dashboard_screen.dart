import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/energy_device.dart';
import '../providers/energy_data_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/section_header.dart';
import '../widgets/status_pill.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static final _f = NumberFormat.decimalPattern('id');

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EnergyDataProvider>();

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
        children: [
          _buildHeader(context, provider),
          _HeroCard(provider: provider),
          const SizedBox(height: 20),
          _buildStatsRow(provider),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SectionHeader(
              title: 'Penggunaan Real-time',
              action: provider.connected ? 'Live · MQTT' : 'Demo · ${_f.format(provider.currentKw)} kW',
            ),
          ),
          const SizedBox(height: 12),
          _UsageChart(usage: provider.usageHistory, f: _f),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SectionHeader(
              title: 'Perangkat Energi',
              action: 'Lihat semua',
            ),
          ),
          const SizedBox(height: 12),
          _QuickDevices(devices: provider.devices),
          const SizedBox(height: 24),
          _buildRecommendation(provider),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, EnergyDataProvider provider) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
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
                  'Selamat pagi, Alex',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  provider.connected
                      ? 'Data realtime dari PZEM via MQTT'
                      : 'Simulasi energi aktif · ${provider.isStable ? 'kualitas daya stabil' : 'ada fluktuasi'}',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (provider.demoMode) ...[
            const SizedBox(width: 8),
            const StatusPill(label: 'Demo', tone: PillTone.info),
            const SizedBox(width: 8),
          ],
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(EnergyDataProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _StatCard(
            icon: Icons.bolt_rounded,
            iconColor: AppColors.warning,
            iconBg: AppColors.warning.withValues(alpha: 0.14),
            title: 'Puncak beban',
            value: provider.peakToday.toStringAsFixed(1),
            unit: 'kW · hari ini',
          ),
          const SizedBox(width: 12),
          _StatCard(
            icon: Icons.solar_power_rounded,
            iconColor: AppColors.primaryDark,
            iconBg: AppColors.primaryLight,
            title: 'Solar output',
            value: provider.solarKw.toStringAsFixed(2),
            unit: 'kW · aktif',
          ),
          const SizedBox(width: 12),
          _StatCard(
            icon: Icons.battery_full_rounded,
            iconColor: AppColors.cyanAccent,
            iconBg: AppColors.cyanAccent.withValues(alpha: 0.14),
            title: 'Kualitas daya',
            value: provider.isStable ? '99,8' : '96,5',
            unit: '% · Pf ${provider.powerFactor.toStringAsFixed(2)}',
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendation(EnergyDataProvider provider) {
    final ac = provider.devices.firstWhere(
      (d) => d.id == 'dev_02',
      orElse: () => provider.devices.first,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.cyanAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.cyanAccent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.lightbulb_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rekomendasi Smart',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepGreen,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    ac.isOn
                        ? 'Jadwalkan ${ac.name} mati 03:00–05:00 untuk hemat ± Rp 3.400/bulan.'
                        : 'Bebeban turun ${provider.currentKw.toStringAsFixed(2)} kW. Solar menutupi ${(provider.solarKw / (provider.currentKw + provider.solarKw) * 100).clamp(0, 100).toInt()}% kebutuhan.',
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
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.provider});

  final EnergyDataProvider provider;

  @override
  Widget build(BuildContext context) {
    final estimatedBill = provider.energyToday * 1650;
    final co2Saved = provider.energyToday * 0.42;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE8F6EB), Color(0xFFDDF3E3)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      StatusPill(
                        label: 'Live',
                        tone: PillTone.success,
                      ),
                      SizedBox(width: 8),
                      StatusPill(
                        label: 'Grid + Solar',
                        tone: PillTone.info,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.trending_down_rounded,
                        size: 15,
                        color: AppColors.primaryDark,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '-12%',
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _HeroGauge(currentKw: provider.currentKw),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _heroValue(
                  value: '${DashboardScreen._f.format(provider.energyToday)} kWh',
                  label: 'Hari ini',
                  color: AppColors.deepGreen,
                ),
                _heroValue(
                  value:
                      'Rp ${DashboardScreen._f.format(estimatedBill.round())}',
                  label: 'Estimasi biaya',
                  color: AppColors.primaryDark,
                ),
                _heroValue(
                  value: '${DashboardScreen._f.format(co2Saved)} kg',
                  label: 'CO₂ terhindar',
                  color: AppColors.cyanAccent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroValue({
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 15,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }
}

class _UsageChart extends StatelessWidget {
  const _UsageChart({required this.usage, required this.f});

  final List<double> usage;
  final NumberFormat f;

  @override
  Widget build(BuildContext context) {
    final minY = 0.0;
    final maxY = _niceMax(usage.isEmpty ? 1.4 : usage.reduce(mathMax));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        margin: const EdgeInsets.only(left: 12, right: 12),
        padding: const EdgeInsets.fromLTRB(16, 20, 20, 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: AppTheme.softShadow,
        ),
        child: SizedBox(
          height: 190,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: usage.isEmpty ? 23 : (usage.length - 1).toDouble(),
              minY: minY,
              maxY: maxY,
              gridData: FlGridData(
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
                    getTitlesWidget: (value, meta) => SideTitleWidget(
                      meta: meta,
                      child: Text(
                        value >= 1 ? '${value.toStringAsFixed(0)}k' : value.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 10,
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
                    interval: 6,
                    getTitlesWidget: (value, meta) => SideTitleWidget(
                      meta: meta,
                      child: Text(
                        value == 0 ? '0' : value.toStringAsFixed(0),
                        style: const TextStyle(
                          fontSize: 10,
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
                  getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                    return LineTooltipItem(
                      '${f.format(spot.y)} kW',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    );
                  }).toList(),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    for (var i = 0; i < usage.length; i++)
                      FlSpot(i.toDouble(), usage[i]),
                  ],
                  isCurved: true,
                  curveSmoothness: 0.4,
                  barWidth: 3,
                  color: AppColors.primaryDark,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primary.withValues(alpha: 0.45),
                        AppColors.primary.withValues(alpha: 0.02),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

double mathMax(double a, double b) => a > b ? a : b;

double _niceMax(double value) {
  if (value <= 1.4) return 1.4;
  final step = value > 5 ? 1.0 : 0.5;
  return (value / step).ceil() * step;
}

class _QuickDevices extends StatelessWidget {
  const _QuickDevices({required this.devices});

  final List<EnergyDevice> devices;

  @override
  Widget build(BuildContext context) {
    final list = devices.take(4).toList();
    return SizedBox(
      height: 148,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final d = list[index];
          final isSolar = d.powerDrawKw < 0;
          return Container(
            width: 168,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: AppTheme.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: d.iconBackground,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(d.icon, size: 19, color: isSolar ? AppColors.warning : AppColors.primaryDark),
                    ),
                    const Spacer(),
                    if (d.smartLabel != null)
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.cyanAccent,
                        size: 16,
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  d.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${d.powerDrawKw.abs().toStringAsFixed(2)} kW · ${d.room}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.value,
    required this.unit,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 10.5,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              unit,
              style: const TextStyle(
                fontSize: 9.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroGauge extends StatefulWidget {
  const _HeroGauge({required this.currentKw});

  final double currentKw;

  @override
  State<_HeroGauge> createState() => _HeroGaugeState();
}

class _HeroGaugeState extends State<_HeroGauge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  static const _maxKw = 5.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final fraction = (widget.currentKw / _maxKw).clamp(0.0, 1.0) * _animation.value;
        final percent = (widget.currentKw / _maxKw) * 100;
        return SizedBox(
          height: 172,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 164,
                height: 164,
                child: CircularProgressIndicator(
                  value: fraction,
                  strokeWidth: 12,
                  strokeCap: StrokeCap.round,
                  backgroundColor: Colors.white.withValues(alpha: 0.85),
                  color: AppColors.primaryDark,
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.currentKw.toStringAsFixed(2),
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepGreen,
                      fontFamily: 'Poppins',
                      letterSpacing: -1,
                    ),
                  ),
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'kW',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.bolt_rounded,
                        size: 16,
                        color: AppColors.warning,
                      ),
                    ],
                  ),
                  Text(
                    '${percent.toStringAsFixed(0)}% kapasitas',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}