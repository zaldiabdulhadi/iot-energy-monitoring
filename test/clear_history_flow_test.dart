import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_energy/app.dart';
import 'package:smart_energy/data/local/app_database.dart';
import 'package:smart_energy/models/energy_reading.dart';
import 'package:smart_energy/services/energy_recorder.dart';

/// Menguji alur "Hapus riwayat" dari tab Profil sampai efeknya terlihat di tab
/// Analisis.
///
/// Dua hal pernah salah di sini dan keduanya harus tertangkap: provider yang
/// disegarkan bukan instance yang dipakai tab Analisis sehingga angka lama
/// tetap tertinggal di layar, dan data contoh langsung mengisi ulang periode
/// yang barusan dikosongkan sehingga penghapusannya kelihatan tidak berhasil.
void main() {
  late EnergyDatabase database;

  /// Sumbu tetap supaya rekaman yang ditanam benar-benar berada di dalam
  /// jendela "Hari" yang dilihat layar Analisis.
  final seededHour = DateTime(2026, 3, 15, 10);

  setUp(() {
    database = EnergyDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  /// Menanam satu jam penuh pengukuran, lalu menutup jamnya supaya baris
  /// sampai ke antrean unggah sekaligus ke riwayat.
  Future<void> seedMeasuredHour() async {
    const reading = EnergyReading(
      voltage: 221,
      current: 4.5,
      power: 995,
      energy: 0.83,
      frequency: 50,
      powerFactor: 0.95,
    );
    final recorder = EnergyRecorder(database: database);
    for (var minute = 0; minute < 60; minute++) {
      await recorder.record(
        reading,
        now: seededHour.add(Duration(minutes: minute)),
        isDemo: false,
      );
    }
    await recorder.flush();
    await recorder.closeCompletedHours(
      now: seededHour.add(const Duration(hours: 1, seconds: 5)),
    );
  }

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize =
        const Size(400, 900) * tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      SmartEnergyApp(database: database, showIntroOnLaunch: false),
    );
    // Pompa dengan durasi eksplisit, bukan `pumpAndSettle`: aplikasi berjalan
    // dengan timer demo dan polling lima detik, jadi tidak akan pernah diam
    // cukup lama untuk `pumpAndSettle` selesai.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  /// Membuka tab lewat bilah navigasi dan memastikan tabnya benar-benar berganti.
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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final nav = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(nav.selectedIndex, expectedIndex, reason: 'tab $label tidak aktif');
  }

  /// Menggulir daftar tab aktif sampai [target] terbangun **dan** seluruhnya
  /// berada di dalam layar, lalu mengetiknya.
  ///
  /// Dua syarat itu berbeda: `ListView` hanya membangun anak yang terlihat, dan
  /// `scrollUntilVisible` bisa berhenti tepat di batas bawah sehingga hasil
  /// ketukan jatuh di luar pohon render.
  Future<void> tapVisible(WidgetTester tester, Finder target) async {
    final screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    // Bilah navigasi bawah menutupi sebagian layar, jadi titik jangkarnya
    // diturunkan supaya ketukan tidak jatuh di area yang tertutup.
    final safeBottom = screenHeight - 100;
    final list = find.byType(Scrollable).last;

    for (var attempt = 0; attempt < 25; attempt++) {
      if (target.evaluate().isNotEmpty) {
        final rect = tester.getRect(target.first);
        if (rect.top >= 0 && rect.bottom <= safeBottom) {
          await tester.tap(target.first);
          return;
        }
        final delta = rect.bottom > safeBottom
            ? rect.bottom - safeBottom + 12
            : -120.0;
        await tester.drag(list, Offset(0, -delta));
      } else {
        await tester.drag(list, const Offset(0, -160));
      }
      await tester.pump();
    }
    fail('tidak bisa membuat $target terlihat dan bisa diketuk');
  }

  /// Mengembalikan daftar ke atas.
  ///
  /// Tab disimpan di `IndexedStack`, jadi posisi gulirnya bertahan saat
  /// pengguna berpindah tab dan kembali. Tanpa dikembalikan ke atas, keadaan
  /// kosong yang berada di bagian atas tidak akan pernah dibangun.
  Future<void> scrollToTop(WidgetTester tester) async {
    final list = find.byType(Scrollable).last;
    for (var i = 0; i < 10; i++) {
      await tester.drag(list, const Offset(0, 600));
      await tester.pump();
    }
  }

  testWidgets('hapus riwayat di Profil mengosongkan tab Analisis',
      (tester) async {
    // Rekaman nyata ditanam sebelum aplikasi dibangun, supaya kondisi awal tab
    // Analisis benar-benar berisi angka yang harus hilang.
    await seedMeasuredHour();
    expect(await database.select(database.hourlyHistory).get(), isNotEmpty);

    await pumpApp(tester);
    await openTab(tester, Icons.analytics_outlined, 1, 'Analisis');

    // Prasyarat: riwayat ada, jadi yang diuji benar-benar penghapusannya dan
    // bukan sekadar tampilan kosong dari database yang memang belum terisi.
    expect(find.text('Belum ada riwayat untuk periode ini'), findsNothing);
    await tapVisible(tester, find.text('Rentang parameter'));
    expect(find.text('Rentang parameter'), findsOneWidget);

    await openTab(tester, Icons.person_outline_rounded, 2, 'Profil');
    await tapVisible(tester, find.text('Hapus riwayat'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Yang diketuk adalah tombol di dalam dialog: teks tile dan teks tombolnya
    // identik, jadi pencarian global akan menemukan dua widget sekaligus.
    final confirmButton = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Hapus riwayat'),
    );
    expect(confirmButton, findsOneWidget);
    await tester.tap(confirmButton);
    // Cukup untuk menutup dialog, menyelesaikan pemuatan ulang, dan memunculkan
    // snackbar. Tiga kali karena satu `pump` hanya memajukan satu frame.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));

    expect(await database.select(database.hourlyHistory).get(), isEmpty);

    await openTab(tester, Icons.analytics_outlined, 1, 'Analisis');
    await scrollToTop(tester);

    // Efek utama: riwayat hilang dan tidak diisi ulang dengan karangan. Kalau
    // ini gagal, penyebabnya salah satu dari dua bug yang di atas.
    expect(find.text('Belum ada riwayat untuk periode ini'), findsOneWidget);
    expect(find.text('Data contoh, bukan pengukuran'), findsNothing);
    expect(
      find.text('Rekomendasi smart'),
      findsNothing,
      reason: 'bagian rekomendasi hanya dibangun kalau ada ringkasan',
    );
  });
}
