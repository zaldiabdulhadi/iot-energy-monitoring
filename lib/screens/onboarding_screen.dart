import 'package:flutter/material.dart';

import '../models/energy_metric.dart';
import '../theme/app_colors.dart';
import '../widgets/layout.dart';
import '../widgets/onboarding_slide.dart';

/// Fase logo yang muncul sebelum halaman instruksi.
///
/// Dipisah dari [OnboardingScreen] supaya perpindahan fase punya satu tempat
/// yang jelas: fase logo menyelesaikan animasinya sendiri lalu memanggil
/// [onFinished], dan layar induk yang mengganti isinya.
class AppSplashLogo extends StatefulWidget {
  const AppSplashLogo({super.key, required this.onFinished});

  /// Dipanggil sekali saat animasi logo selesai.
  final VoidCallback onFinished;

  @override
  State<AppSplashLogo> createState() => _AppSplashLogoState();
}

class _AppSplashLogoState extends State<AppSplashLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _fadeOut;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration)
      ..addStatusListener(_onStatus)
      ..forward();
    // Satu controller untuk seluruh fase logo: masuk di awal, tahan sebentar,
    // lalu menghilang sebelum selesai. Dua controller terpisah bisa keluar dari
    // sinkron dan membuat logo kabur tanpa pernah benar-benar hilang.
    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.3, curve: Curves.easeOut),
    );
    _fadeOut = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.7, 1, curve: Curves.easeIn),
    );
    _scale = Tween<double>(begin: 0.88, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.45, curve: Curves.easeOut),
      ),
    );
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) widget.onFinished();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static const Duration _duration = Duration(milliseconds: 1500);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryLight, AppColors.softMint],
          ),
        ),
        child: SafeBody(
          child: Center(
            // Opasitas dua tahap dikalikan oleh dua `FadeTransition` yang
            // bersarang, jadi tidak perlu controller tambahan untuk menghitung
            // hasil perkaliannya.
            child: FadeTransition(
              opacity: _fadeOut,
              child: FadeTransition(
                opacity: _fadeIn,
                child: ScaleTransition(
                  scale: _scale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Bentuk logo disamakan dengan blok logo di kartu
                      // Profil supaya identitas aplikasi sama sejak layar pertama.
                      Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryDark
                                  .withValues(alpha: 0.28),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Smart Energy',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Pemantau listrik ESP',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tiga halaman instruksi singkat yang muncul setiap kali aplikasi dibuka.
///
/// Isinya hanya menjelaskan apa yang benar-benar dilakukan aplikasi: angka yang
/// tampil berasal dari meter ESP, riwayat yang kurang ditampilkan apa adanya,
/// dan data tetap tersimpan lokal meski sinkronisasi gagal.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onFinished});

  /// Dipanggil saat pengguna menekan "Lewati" atau menyelesaikan halaman
  /// terakhir, supaya kerangka aplikasi bisa masuk ke aplikasi utamanya.
  final VoidCallback onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late final AnimationController _fadeController;
  late final Animation<double> _fade;
  int _page = 0;
  bool _showingSplash = true;

  /// Isi ketiga halaman. Label metrik diambil dari [EnergyMetric], bukan
  /// ditulis ulang di sini: enum itu satu-satunya sumber kebenaran nama dan
  /// satuan metrik.
  static final List<_IntroPage> _pages = [
    _IntroPage(
      icon: Icons.bolt_rounded,
      tint: AppColors.primaryDark,
      title: 'Enam metrik, satu layar',
      body: 'Smart Energy membaca meter PZEM-004T lewat ESP setiap lima '
          'detik. Enam metrik yang benar-benar dikirim meter ditampilkan apa '
          'adanya, lengkap dengan penanda bila keluar dari rentang sehat.',
      chips: [
        for (final metric in EnergyMetric.values)
          '${metric.label} · ${metric.unit}',
      ],
    ),
    _IntroPage(
      icon: Icons.analytics_rounded,
      tint: AppColors.cyanAccent,
      title: 'Riwayat yang bisa dibaca',
      body: 'Tab Analisis mengubah rekaman per jam menjadi grafik konsumsi dan '
          'tren untuk jendela 24 jam, 7 hari, 30 hari, dan 12 bulan. Kalau '
          'jarinya belum cukup, layar menjelaskan kekurangan itu, bukan '
          'mengisi angka perkiraan.',
    ),
    _IntroPage(
      icon: Icons.hub_rounded,
      tint: AppColors.deepGreen,
      title: 'Hubungkan, lalu sinkronkan',
      body: 'Isi alamat API ESP di tab Profil untuk mengganti mode demo dengan '
          'pengukuran sungguhan. Rekap per jam diunggah ke Supabase, sementara '
          'seluruh rekaman tetap tersimpan lokal di perangkat.',
    ),
  ];

  bool get _isLast => _page == _pages.length - 1;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _fade = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
  }

  /// Dipanggil [AppSplashLogo] saat fase logo selesai. Halaman baru dibangun
  /// setelah fase ini, bukan sebelumnya, supaya tombol dan titik indikator
  /// tidak ada di pohon widget selama logo masih tampil.
  void _handleSplashFinished() {
    setState(() => _showingSplash = false);
    _fadeController.forward(from: 0);
  }

  void _next() {
    if (_isLast) {
      widget.onFinished();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showingSplash) {
      return AppSplashLogo(onFinished: _handleSplashFinished);
    }

    final gutters = Gutters.of(context);

    return Scaffold(
      body: SafeBody(
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: widget.onFinished,
                  child: const Text('Lewati'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) => setState(() => _page = index),
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: gutters.horizontal,
                      ),
                      child: OnboardingSlide(
                        icon: page.icon,
                        tint: page.tint,
                        title: page.title,
                        body: page.body,
                        chips: page.chips,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              _buildDots(),
              const SizedBox(height: 18),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  gutters.horizontal,
                  0,
                  gutters.horizontal,
                  gutters.vertical,
                ),
                child: FilledButton(
                  onPressed: _next,
                  child: Text(_isLast ? 'Mulai' : 'Lanjut'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Indikator halaman. Titik aktif dibuat lebih lebar supaya posisinya jelas
  /// tanpa perlu angka, dan perubahan lebar dianimasikan supaya mengikuti
  /// gerakan halaman.
  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < _pages.length; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == _page ? 22 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: i == _page ? AppColors.primaryDark : AppColors.border,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
      ],
    );
  }
}

/// Data satu halaman instruksi, dipisahkan dari widgetnya supaya halamannya
/// bisa berasal dari satu daftar statis.
class _IntroPage {
  const _IntroPage({
    required this.icon,
    required this.tint,
    required this.title,
    required this.body,
    this.chips = const [],
  });

  final IconData icon;
  final Color tint;
  final String title;
  final String body;
  final List<String> chips;
}
