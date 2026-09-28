import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Lebar di bawah mana grid metrik diturunkan ke dua kolom.
///
/// 360 piksel adalah lebar perangkat yang paling umum. Di bawah itu, tiga
/// kolom membuat label membungkus atau meluap, sehingga turun ke dua kolom.
const double kNarrowBreakpoint = 360;

/// Lebar dari mana konten boleh memakai dua kolom di tablet.
const double kWideBreakpoint = 600;

/// Gutter adaptif: makin lebar layar, makin lega marginnya.
class Gutters {
  const Gutters._(this.horizontal, this.vertical);

  /// Memilih gutter berdasarkan lebar yang tersedia.
  factory Gutters.of(BuildContext context) =>
      Gutters.forWidth(MediaQuery.sizeOf(context).width);

  factory Gutters.forWidth(double width) {
    if (width >= kWideBreakpoint) {
      return const Gutters._(24, 28);
    }
    if (width >= kNarrowBreakpoint) {
      return const Gutters._(20, 20);
    }
    return const Gutters._(16, 16);
  }

  final double horizontal;
  final double vertical;

  EdgeInsets get all => EdgeInsets.fromLTRB(
        horizontal,
        vertical,
        horizontal,
        // Ekstra di bawah supaya kartu terakhir tidak menempel ke bilah navigasi.
        vertical + 16,
      );
}

/// Jumlah kolom grid metrik untuk lebar tertentu.
int metricColumnsFor(double width) =>
    width >= kNarrowBreakpoint ? 3 : 2;

/// Badan halaman yang aman dari notch dan bilah navigasi sistem.
///
/// Semua layar memakai [SafeBody] sebagai anak pertama [Scaffold.body] supaya
/// tidak ada layar yang lupa. `bottom` bisa dimatikan untuk halaman yang
/// memang punya elemen menempel di bawah.
class SafeBody extends StatelessWidget {
  const SafeBody({super.key, required this.child, this.bottom = true});

  final Widget child;
  final bool bottom;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: bottom,
      child: child,
    );
  }
}

/// Kartu dengan gaya yang sama di seluruh aplikasi.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.gradient,
    this.borderColor,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Color? borderColor;

  /// Warna isi kartu. Diabaikan kalau [gradient] diberikan, karena keduanya
  /// tidak bisa berlaku bersamaan pada satu `BoxDecoration`.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: gradient != null ? null : (color ?? AppColors.card),
      gradient: gradient,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: borderColor ?? AppColors.border),
      boxShadow: _shadow,
    );

    final content = Padding(padding: padding, child: child);
    if (onTap == null) return DecoratedBox(decoration: decoration, child: content);
    return DecoratedBox(
      decoration: decoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: content,
        ),
      ),
    );
  }

  static const List<BoxShadow> _shadow = [
    BoxShadow(
      color: Color(0x144F9D69),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];
}

/// Angka besar yang tidak akan pernah terpotong di layar tersempit.
///
/// `FittedBox` dengan `scaleDown` membuat angka menyusut mengikuti ruang yang
/// tersedia, bukan meluap. Teks angka lebih penting daripada teks biasa, jadi
/// menyhrink lebih dulu dan memotong sebagai pilihan terakhir.
class AdaptiveNumber extends StatelessWidget {
  const AdaptiveNumber({
    super.key,
    required this.value,
    this.suffix,
    this.fontSize = 28,
    this.color,
    this.textAlign,
  });

  /// Angka yang sudah diformat, misalnya `1.234,5`.
  final String value;

  /// Satuan, dicetak lebih kecil dan tidak ikut menyusut berlebihan.
  final String? suffix;

  final double fontSize;
  final Color? color;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: color ?? AppColors.textPrimary,
      height: 1.1,
    );
    final unit = TextStyle(
      fontSize: fontSize * 0.42,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
    );

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: textAlign == TextAlign.right
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: suffix == null
          ? Text(value, style: style, textAlign: textAlign)
          : Text.rich(
              TextSpan(
                text: '$value ',
                style: style,
                children: [TextSpan(text: suffix, style: unit)],
              ),
              textAlign: textAlign,
            ),
    );
  }
}
