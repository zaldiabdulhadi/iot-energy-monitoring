import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/energy_metric.dart';
import '../theme/app_colors.dart';
import 'layout.dart';
import 'status_pill.dart';

/// Kartu satu parameter: label, angka, satuan, dan status terhadap rentang.
///
/// Angka memakai [AdaptiveNumber] supaya tidak pernah meluap, dan label
/// dipat satu baris supaya tinggi grid tetap seragam antar-kartu.
class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.metric,
    required this.value,
    this.status,
    this.footnote,
  });

  final EnergyMetric metric;
  final double value;
  final MetricStatus? status;

  /// Keterangan kecil di bawah angka, misalnya `rata-rata` atau `min 210,1`.
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final flagged = status == MetricStatus.warning ||
        status == MetricStatus.critical;
    final tone = switch (status) {
      null => AppColors.textPrimary,
      MetricStatus.healthy => AppColors.success,
      MetricStatus.warning => AppColors.warning,
      MetricStatus.critical => AppColors.critical,
    };

    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(metric.icon, size: 15, color: AppColors.primaryDark),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (flagged) ...[
                const SizedBox(width: 4),
                Icon(Icons.error_outline_rounded, size: 13, color: tone),
              ],
            ],
          ),
          const SizedBox(height: 8),
          AdaptiveNumber(
            value: formatValue(value, metric.decimals),
            suffix: metric.unit,
            fontSize: 19,
            color: AppColors.textPrimary,
          ),
          const SizedBox(height: 3),
          Text(
            footnote ?? (status?.label ?? ''),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9.5,
              color: status == null ? AppColors.textMuted : tone,
              fontWeight: status == null ? FontWeight.w400 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Memformat angka dengan pemisah ribuan gaya Indonesia.
String formatValue(double value, int decimals) =>
    NumberFormat.decimalPatternDigits(
      locale: 'id',
      decimalDigits: decimals,
    ).format(value);

/// Grid metrik dengan jumlah kolom yang menyesuaikan lebar layar.
///
/// Menerima widget apa pun, jadi kartu metrik dan kartu ringkasan bisa berada
/// dalam grid yang sama. `shrinkWrap` dan fisika non-gulir supaya bisa dipakai
/// di dalam `ListView` tanpa membuat layout unbounded.
class MetricGrid extends StatelessWidget {
  const MetricGrid({
    super.key,
    required this.tiles,
    this.spacing = 10,
  });

  final List<Widget> tiles;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    if (tiles.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = metricColumnsFor(constraints.maxWidth);
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          // Rasio hanya stabil di tiga kolom; dua kolom butuh ruang vertikal
          // lebih supaya satuan dan catatan tidak terpotong.
          childAspectRatio: columns == 3 ? 1.18 : 1.32,
          children: tiles,
        );
      },
    );
  }
}

/// Kartu ringkasan satu angka dengan label dan keterangan.
class SummaryTile extends StatelessWidget {
  const SummaryTile({
    super.key,
    required this.label,
    required this.value,
    this.suffix,
    this.caption,
    this.icon,
    this.color,
    this.onTap,
  });

  final String label;
  final String value;
  final String? suffix;
  final String? caption;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: color ?? AppColors.primaryDark),
                const SizedBox(width: 5),
              ],
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          AdaptiveNumber(
            value: value,
            suffix: suffix,
            fontSize: 18,
            color: color ?? AppColors.textPrimary,
          ),
          if (caption != null) ...[
            const SizedBox(height: 2),
            Text(
              caption!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9.5,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Lencana perubahan persentase, untuk tren konsumsi.
class TrendBadge extends StatelessWidget {
  const TrendBadge({super.key, required this.percent});

  final double percent;

  @override
  Widget build(BuildContext context) {
    final up = percent >= 0;
    return StatusPill(
      label: '${up ? '+' : '-'}${percent.abs().toStringAsFixed(1)}%',
      tone: up ? PillTone.warning : PillTone.success,
      icon: up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
    );
  }
}
