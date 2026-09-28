import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_energy/app.dart';
import 'package:smart_energy/data/local/app_database.dart';

Future<void> _pumpApp(WidgetTester tester) async {
  final database = EnergyDatabase.forTesting(NativeDatabase.memory());
  addTearDown(database.close);
  // Layar instruksi dimatikan supaya test bisa langsung berinteraksi dengan
  // tab. Perilaku layar instruksinya sendiri diuji di `onboarding_test.dart`.
  await tester.pumpWidget(
    SmartEnergyApp(database: database, showIntroOnLaunch: false),
  );
  await tester.pump();
}

Future<void> _disposeApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

/// Scrollable list konten halaman yang sedang tampil.
///
/// `.last` dipilih karena kerangka aplikasi juga menyisipkan scrollable-nya
/// sendiri, sementara yang digulir di sini adalah list konten halaman.
Finder get _contentList => find.byType(Scrollable).last;

void main() {
  testWidgets('Smart Energy app renders dashboard', (tester) async {
    await _pumpApp(tester);

    expect(find.text('Dashboard'), findsOneWidget);
    // Tab "Perangkat" dihapus: aplikasi hanya memantau satu meter ESP, jadi
    // tidak ada lagi yang bisa dipilih di tab tersebut.
    expect(find.text('Perangkat'), findsNothing);
    expect(find.text('Analisis'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);

    await _disposeApp(tester);
  });

  testWidgets('API ESP settings reachable from profile', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Profil'));
    await tester.pump(const Duration(milliseconds: 300));

    // Sliver list hanya membangun anak yang berada di viewport, jadi tile yang
    // dicari harus digulir lebih dulu. scrollUntilVisible dipakai daripada drag
    // dengan offset tetap karena tinggi tiap tile ikut berubah ketika teks
    // subtitle memanjang, sehingga posisi pikselnya tidak stabil.
    final tile = find.text('Koneksi API ESP');
    await tester.scrollUntilVisible(tile, 200, scrollable: _contentList);
    await tester.pump(const Duration(milliseconds: 400));

    expect(tile, findsOneWidget);

    await tester.tap(tile);
    // Bukan pumpAndSettle: layar API ESP punya AnimationController yang
    // mengulang tanpa henti dan Timer.periodic untuk jam, jadi tidak pernah
    // sampai tenang.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Koneksi API ESP'),
      ),
      findsOneWidget,
    );
    expect(find.text('Mode demo aktif'), findsOneWidget);

    final section = find.text('Konfigurasi API');
    await tester.scrollUntilVisible(section, 200, scrollable: _contentList);
    await tester.pump(const Duration(milliseconds: 400));

    expect(section, findsOneWidget);
    expect(find.text('Format data ESP'), findsOneWidget);

    await _disposeApp(tester);
  });

  testWidgets('Analisis menandai data contoh, Dashboard tidak', (tester) async {
    await _pumpApp(tester);

    const banner = 'Data contoh, bukan pengukuran';
    expect(
      find.text(banner),
      findsNothing,
      reason: 'dashboard menampilkan pengukuran langsung, bukan data contoh',
    );

    await tester.tap(find.text('Analisis'));
    await tester.pump(const Duration(milliseconds: 300));

    // Meter kosong di test, jadi Analisis boleh menampilkan data contoh, tapi
    // hanya selama ditandai jelas.
    expect(find.text(banner), findsOneWidget);

    // Tidak boleh ada Rupiah di mana pun.
    expect(find.textContaining('Rp'), findsNothing);
    expect(find.textContaining('Biaya'), findsNothing);

    await _disposeApp(tester);
  });
}
