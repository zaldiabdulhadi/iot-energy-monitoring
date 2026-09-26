import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_energy/app.dart';
import 'package:smart_energy/data/local/app_database.dart';
import 'package:smart_energy/widgets/layout.dart';

/// Lebar layar yang harus aman: ponsel kecil 320 dp, ponsel umum 400 dp, dan
/// tablet dasar 600 dp.
const _widths = <String, double>{
  'ponsel 320': 320,
  'ponsel 400': 400,
  'tablet 600': 600,
};

void main() {
  /// Membangun aplikasi dengan ukuran layar tertentu.
  Future<void> pumpAt(WidgetTester tester, double width) async {
    // Tinggi 800 cukup untuk memuat bilah navigasi bawah beserta labelnya
    // pada lebar 320 dp. Kalau viewport terlalu pendek, ketukan pada tab
    // jatuh di luar layar dan pengujian overflow-nya jadi tidak berarti.
    tester.view.physicalSize =
        Size(width, 800) * tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);

    final database = EnergyDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await tester.pumpWidget(SmartEnergyApp(database: database));
    await tester.pump();
  }

  /// Membuka tab lewat bilah navigasi lalu memastikan tabnya benar-benar
  /// berganti.
  ///
  /// Ketukan diarahkan ke ikon, bukan ke teks label: di bawah 340 dp bilah
  /// navigasi menyembunyikan labelnya, jadi teksnya ada di pohon widget tetapi
  /// tidak terlihat dan tidak bisa diketuk. Tanpa pemeriksaan [selectedIndex],
  /// ketukan yang meleset tetap membuat test lulus tanpa menguji apa pun.
  Future<void> openTab(
    WidgetTester tester,
    IconData icon,
    int expectedIndex,
    String label,
  ) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(icon),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    final nav = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(nav.selectedIndex, expectedIndex, reason: 'tab $label tidak aktif');
  }

  /// Menggulir beberapa kali supaya bagian bawah tiap tab ikut dibangun.
  Future<void> scrollToEnd(WidgetTester tester) async {
    final list = find.byType(Scrollable).last;
    for (var i = 0; i < 6; i++) {
      await tester.drag(list, const Offset(0, -600));
      await tester.pump();
    }
  }

  for (final entry in _widths.entries) {
    group('lebar ${entry.key} dp', () {
      testWidgets('dashboard tidak overflow', (tester) async {
        await pumpAt(tester, entry.value);

        expect(tester.takeException(), isNull);
        await scrollToEnd(tester);
        expect(tester.takeException(), isNull);
      });

      testWidgets('tab analisis tidak overflow', (tester) async {
        await pumpAt(tester, entry.value);
        await openTab(tester, Icons.analytics_outlined, 1, 'Analisis');

        expect(tester.takeException(), isNull);
        await scrollToEnd(tester);
        expect(tester.takeException(), isNull);
      });

      testWidgets('tab profil tidak overflow', (tester) async {
        await pumpAt(tester, entry.value);
        await openTab(tester, Icons.person_outline_rounded, 2, 'Profil');

        expect(tester.takeException(), isNull);
        await scrollToEnd(tester);
        expect(tester.takeException(), isNull);
      });
    });
  }

  group('bilah navigasi', () {
    testWidgets('label tab muat di dalam bilah saat label ditampilkan',
        (tester) async {
      // Label hanya tampil mulai 340 dp, jadi lebar 400 yang dipakai di sini.
      tester.view.physicalSize =
          const Size(400, 800) * tester.view.devicePixelRatio;
      addTearDown(tester.view.resetPhysicalSize);

      final database = EnergyDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      await tester.pumpWidget(SmartEnergyApp(database: database));
      await tester.pump();

      final bar = tester.getRect(find.byType(NavigationBar));
      for (final label in ['Dashboard', 'Analisis', 'Profil']) {
        final rect = tester.getRect(find.text(label));
        expect(
          bar.contains(rect.topLeft) && bar.contains(rect.bottomRight),
          isTrue,
          reason: 'label "$label" keluar dari bilah navigasi: '
              '$rect di luar $bar',
        );
      }
    });
  });

  group('gutter dan jumlah kolom', () {
    test('gutter menyempit di layar sempit dan melebar di tablet', () {
      expect(Gutters.forWidth(320).horizontal, 16);
      expect(Gutters.forWidth(400).horizontal, 20);
      expect(Gutters.forWidth(600).horizontal, 24);
      expect(Gutters.forWidth(320).vertical, 16);
      expect(Gutters.forWidth(600).vertical, 28);
    });

    test('jumlah kolom metric menyesuaikan lebar', () {
      // Di bawah 360 dp hanya dua kolom supaya kartu tidak tergerus.
      expect(metricColumnsFor(320), 2);
      // Mulai 360 dp naik ke tiga kolom.
      expect(metricColumnsFor(360), 3);
      expect(metricColumnsFor(400), 3);
      expect(metricColumnsFor(600), 3);
      // Tidak pernah lebih dari tiga kolom supaya kartu tidak terlalu lebar.
      expect(metricColumnsFor(1000), 3);
    });
  });
}
