import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_energy/app.dart';

void main() {
  testWidgets('Smart Energy app renders dashboard', (tester) async {
    await tester.pumpWidget(const SmartEnergyApp());
    await tester.pump();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Perangkat'), findsOneWidget);
  });

  testWidgets('MQTT settings screen reachable from profile', (tester) async {
    await tester.pumpWidget(const SmartEnergyApp());
    await tester.pump();

    await tester.tap(find.text('Profil'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.drag(find.byType(ListView).last, const Offset(0, -900));
    await tester.pump(const Duration(milliseconds: 400));

    final tile = find.text('Koneksi MQTT');
    expect(tile, findsOneWidget);

    await tester.tapAt(tester.getCenter(tile));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Belum terhubung'), findsOneWidget);

    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Konfigurasi broker'), findsOneWidget);
  });
}