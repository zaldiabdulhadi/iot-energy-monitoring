import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Isi satu halaman instruksi: kartu ilustrasi, judul, dan penjelasan singkat.
///
/// Ilustrasi memakai ikon Material di atas kartu gradasi, bukan gambar, supaya
/// tidak perlu aset baru dan warnanya otomatis ikut [AppColors].
class OnboardingSlide extends StatelessWidget {
  const OnboardingSlide({
    super.key,
    required this.icon,
    required this.tint,
    required this.title,
    required this.body,
    this.chips = const [],
  });

  final IconData icon;

  /// Aksen halaman ini. Dipakai untuk badge ikon, gradasi kartu, dan titik
  /// indikator, sehingga tiap halaman bisa dibedakan tanpa gambar.
  final Color tint;

  final String title;

  /// Penjelasan singkat, satu atau dua kalimat.
  final String body;

  /// Label pendek di bawah teks, misalnya nama keenam metrik yang dikirim ESP.
  final List<String> chips;

  /// Tinggi kartu ilustrasi. Dikunci, bukan mengikuti lebar layar, supaya di
  /// tablet 600 dp kartu tidak melebar seperti banner dan teks tetap punya
  /// ruang di bawahnya.
  static const double _visualHeight = 190;

  /// Batas lebar kartu supaya tidak melar di layar lebar.
  static const double _maxVisualWidth = 420;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: SizedBox(
            height: _visualHeight,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxVisualWidth),
              child: _buildVisual(),
            ),
          ),
        ),
        const SizedBox(height: 26),
        // Teks dibungkus scroll, bukan Expanded: di layar pendek teks inilah
        // yang pertama kali tidak muat, sementara kartu ilustrasi lebih baik
        // tetap utuh di atas.
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.55,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (chips.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final chip in chips) _SlideChip(label: chip),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Kartu gradasi dengan badge ikon di tengah dan dua lingkaran dekoratif.
  Widget _buildVisual() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tint.withValues(alpha: 0.13), AppColors.backgroundSecondary],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppTheme.softShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Dua lingkaran ini murni dekoratif. Diletakkan sebelum badge di
          // dalam `Stack` supaya tergambar di bawahnya, bukan menutupi ikon.
          Positioned(
            right: -34,
            top: -26,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tint.withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -30,
            child: Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: tint.withValues(alpha: 0.22), width: 2),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(icon, size: 44, color: tint),
            ),
          ),
        ],
      ),
    );
  }
}

/// Label kecil di bawah teks halaman instruksi.
class _SlideChip extends StatelessWidget {
  const _SlideChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
