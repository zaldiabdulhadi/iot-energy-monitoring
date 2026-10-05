import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_energy/app.dart';
import 'package:smart_energy/data/local/app_database.dart';
import 'package:smart_energy/screens/onboarding_screen.dart';
import 'package:smart_energy/widgets/app_wordmark.dart';

/// Lebar layar yang harus aman, sama seperti `layout_test.dart`.
const _widths = <String, double>{
  'ponsel 320': 320,
  'ponsel 400': 400,
  'tablet 600': 600,
};

/// Teks halaman pertama, dipakai sebagai penanda bahwa fase logo sudah selesai.
const _firstPageTitle = 'Enam metrik, satu layar';

void main() {
  /// Membangun aplikasi dengan layar instruksi aktif.
  ///
  /// Layar instruksi muncul di setiap pembukaan, jadi test yang memeriksa
  /// logo, tombol, dan titik harus lewat fase itu, bukan melewatinya.
  Future<void> pumpIntro(
    WidgetTester tester, {
    double? width,
    double height = 800,
  }) async {
    if (width != null) {
      tester.view.physicalSize =
          Size(width, height) * tester.view.devicePixelRatio;
      addTearDown(tester.view.resetPhysicalSize);
    }

    final database = EnergyDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await tester.pumpWidget(SmartEnergyApp(database: database));
    await tester.pump();
  }

  /// Menunggu fase logo selesai dan halaman instruksi benar-benar tampil.
  ///
  /// Bukan `pumpAndSettle`: aplikasi tetap menyalakan timer polling metrik
  /// sepanjang hidup, jadi tidak ada momen yang bisa disebut "tenang".
  Future<void> skipSplash(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> disposeApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  testWidgets('fase logo muncul lalu diganti halaman instruksi',
      (tester) async {
    await pumpIntro(tester);

    expect(find.byType(AppSplashLogo), findsOneWidget);
    expect(find.byType(AppWordmark), findsOneWidget);
    // Tombol halaman instruksi belum boleh ada: kalau dibangun bersamaan
    // dengan logo, "Lewati" bisa ditekan saat belum ada yang boleh dibaca.
    expect(find.text('Lewati'), findsNothing);

    await skipSplash(tester);

    expect(find.byType(AppSplashLogo), findsNothing);
    expect(find.text(_firstPageTitle), findsOneWidget);
    expect(find.text('Lewati'), findsOneWidget);

    await disposeApp(tester);
  });

  testWidgets('tombol berubah jadi Mulai hanya di halaman terakhir',
      (tester) async {
    await pumpIntro(tester);
    await skipSplash(tester);

    expect(find.text('Lanjut'), findsOneWidget);
    expect(find.text('Mulai'), findsNothing);

    // Satu tap baru memindahkan halaman ke index 1, masih belum terakhir.
    await tester.tap(find.text('Lanjut'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Lanjut'), findsOneWidget);
    expect(find.text('Mulai'), findsNothing);
    expect(find.text('Riwayat yang bisa dibaca'), findsOneWidget);

    await tester.tap(find.text('Lanjut'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Mulai'), findsOneWidget);
    expect(find.text('Lanjut'), findsNothing);
    expect(find.text('Hubungkan, lalu sinkronkan'), findsOneWidget);

    await disposeApp(tester);
  });

  testWidgets('Lewati langsung membuka aplikasi utama', (tester) async {
    // "Lewati" diuji terpisah dari tombol utama supaya kegagalan salah satu
    // tidak menutupi kegagalan yang lain.
    await pumpIntro(tester);
    await skipSplash(tester);

    await tester.tap(find.text('Lewati'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);

    await disposeApp(tester);
  });

  testWidgets('tombol terakhir juga membuka aplikasi utama', (tester) async {
    await pumpIntro(tester);
    await skipSplash(tester);

    for (final label in ['Lanjut', 'Lanjut']) {
      await tester.tap(find.text(label));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    await tester.tap(find.text('Mulai'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text(_firstPageTitle), findsNothing);

    await disposeApp(tester);
  });

  testWidgets('slide pertama mencantumkan enam metrik dari enum',
      (tester) async {
    await pumpIntro(tester);
    await skipSplash(tester);

    // Label diambil dari `EnergyMetric`, jadi test ini ikut gagal kalau enum
    // berubah dan slide tidak ikut menyesuaikan diri.
    for (final label in [
      'Tegangan · V',
      'Arus · A',
      'Daya · W',
      'Energi · kWh',
      'Frekuensi · Hz',
      'Faktor daya · PF',
    ]) {
      expect(find.text(label), findsOneWidget, reason: 'chip "$label" hilang');
    }

    await disposeApp(tester);
  });

  for (final entry in _widths.entries) {
    testWidgets('halaman instruksi tidak overflow di ${entry.key} dp',
        (tester) async {
      // Tinggi 640 dipilih cukup pendek untuk memastikan teks yang tidak muat
      // digulir di dalam halamannya, bukan membuat halaman melebar atau
      // meluap.
      await pumpIntro(tester, width: entry.value, height: 640);
      await skipSplash(tester);

      expect(tester.takeException(), isNull);

      for (final label in ['Lanjut', 'Lanjut']) {
        await tester.tap(find.text(label));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull);
      }

      await disposeApp(tester);
    });
  }
}
