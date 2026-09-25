import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_energy/app.dart';
import 'package:smart_energy/data/local/app_database.dart';

Future<void> _pumpApp(WidgetTester tester) async {
  final database = EnergyDatabase.forTesting(NativeDatabase.memory());
  addTearDown(database.close);
  await tester.pumpWidget(SmartEnergyApp(database: database));
  await tester.pump();
}

Future<void> _disposeApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

void main() {
  testWidgets('Smart Energy app renders dashboard', (tester) async {
    await _pumpApp(tester);

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Perangkat'), findsOneWidget);

    await _disposeApp(tester);
  });

  testWidgets('API ESP settings reachable from profile', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Profil'));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.drag(find.byType(ListView).last, const Offset(0, -900));
    await tester.pump(const Duration(milliseconds: 400));

    final tile = find.text('Koneksi API ESP');
    expect(tile, findsOneWidget);

    await tester.tapAt(tester.getCenter(tile));
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

    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Konfigurasi API'), findsOneWidget);
    expect(find.text('Format data ESP'), findsOneWidget);

    await _disposeApp(tester);
  });
}
