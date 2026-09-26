import 'package:flutter/material.dart';

import '../services/recommendation_engine.dart';
import '../theme/app_colors.dart';
import 'layout.dart';

/// Satu rekomendasi smart yang berasal dari riwayat nyata.
class InsightCard extends StatelessWidget {
  const InsightCard({super.key, required this.insight});

  final EnergyInsight insight;

  @override
  Widget build(BuildContext context) {
    final tone = insight.severity.color;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      borderColor: tone.withValues(alpha: 0.28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(insight.severity.icon, size: 18, color: tone),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.body,
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.45,
                    color: AppColors.textSecondary,
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

/// Daftar kartu insight dengan jarak antar kartu.
class InsightList extends StatelessWidget {
  const InsightList({super.key, required this.insights, this.spacing = 10});

  final List<EnergyInsight> insights;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        for (var i = 0; i < insights.length; i++) ...[
          if (i > 0) SizedBox(height: spacing),
          InsightCard(insight: insights[i]),
        ],
      ],
    );
  }
}

/// Placeholder untuk kondisi yang belum punya cukup data.
///
/// Sengaja menjelaskan **kenapa** datanya belum cukup, bukan hanya
/// "tidak ada data", supaya pengguna tahu apa yang perlu dilakukan.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      child: Column(
        children: [
          Icon(icon, size: 38, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: action,
            ),
          ],
        ],
      ),
    );
  }
}
