import 'package:flutter/material.dart';

/// Wordmark aplikasi, dipakai di layar pembuka dan kartu Profil.
///
/// Sumbernya `assets/brand/wordmark.png`: lambang dan tulisan "WattSerra"
/// sudah berada dalam satu file, jadi layar tidak perlu merangkai logo dan
/// judulnya secara terpisah.
class AppWordmark extends StatelessWidget {
  const AppWordmark({super.key, required this.width, this.height});

  /// Lebar wordmark dalam piksel logis.
  ///
  /// Tingginya diturunkan dari [aspectRatio] supaya proporsi file asli tetap
  /// terjaga di ukuran berapa pun.
  final double width;

  /// Batas tinggi opsional untuk tempat yang punya tinggi terbatas,
  /// misalnya kartu Profil. Kalau null, tinggi hanya dibatasi proporsi.
  final double? height;

  /// Proporsi file: 1301 x 823 setelah padding transparan dipangkas.
  static const double aspectRatio = 1301 / 823;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/brand/wordmark.png',
      width: width,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );
  }
}
