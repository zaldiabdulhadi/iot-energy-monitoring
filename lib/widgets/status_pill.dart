import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum PillTone { success, warning, critical, info, neutral }

/// Pill status kecil untuk indikator sumber data dan kondisi sistem.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    this.tone = PillTone.neutral,
    this.icon,
  });

  final String label;
  final PillTone tone;
  final IconData? icon;

  Color get _color {
    switch (tone) {
      case PillTone.success:
        return AppColors.success;
      case PillTone.warning:
        return AppColors.warning;
      case PillTone.critical:
        return AppColors.critical;
      case PillTone.info:
        return AppColors.info;
      case PillTone.neutral:
        return AppColors.primaryDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = _color.withValues(alpha: 0.14);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: _color),
            const SizedBox(width: 5),
          ] else ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: _color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          // Label dipotong dengan elipsis, bukan memaksa pill melebar. Tanpa
          // ini, pill di dalam baris yang sempit akan meluber melewati tepi
          // kartu di layar 320 dp.
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}