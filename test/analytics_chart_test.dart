import 'package:drift/native.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:smart_energy/data/local/app_database.dart';
import 'package:smart_energy/models/energy_hourly.dart';
import 'package:smart_energy/models/energy_period_summary.dart';
import 'package:smart_energy/providers/energy_data_provider.dart';
import 'package:smart_energy/providers/energy_history_provider.dart';
import 'package:smart_energy/screens/analytics_screen.dart';
import 'package:smart_energy/services/energy_api_client.dart';
import 'package:smart_energy/services/energy_history_service.dart';

/// Mengembalikan batang consumption chart beserta sumbu Y-nya.
({List<BarChartRodData> rods, double maxY}) readConsumptionChart(
  WidgetTester tester,
) {
  final chart = tester.widget<BarChart>(find.byType(BarChart).first);
  final data = chart.data;
  return (
    rods: [
      for (final group in data.barGroups) ...group.barRods,
    ],
    maxY: data.maxY,
  );
}

void main() {
  late EnergyDatabase database;
  late EnergyHistoryService service;
  late String deviceKey;

  Future<void> seedHour(DateTime hourStart, double energyKwh) async {
    await database.upsertHistory(
      hourly: EnergyHourly(
        deviceKey: deviceKey,
        hourStart: hourStart,
        energyKwh: energyKwh,
        powerSum: 1000 * 60,
        powerMin: 1000,
        powerMax: 1000,
        voltageSum: 220 * 60,
        voltageMin: 220,
        voltageMax: 220,
        currentSum: 4.5 * 60,
        currentMax: 4.5,
        frequencySum: 50 * 60,
        frequencyMin: 50,
        frequencyMax: 50,
        powerFactorSum: 0.95 * 60,
        powerFactorMin: 0.95,
        sampleCount: 60,
        observedSeconds: 3600,
        coveragePct: 100,
      ),
      now: hourStart,
    );
  }

  Future<void> showDay(WidgetTester tester, DateTime now) async {
    final history = EnergyHistoryProvider(service: service);
    await history.select(HistoryPeriod.day, now: now);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<EnergyHistoryProvider>.value(value: history),
          // Kartu impor riwayat di bawah grafik membaca status impor dari
          // provider ini, jadi layar tidak bisa dirakit tanpa-nya.
          ChangeNotifierProvider<EnergyDataProvider>(
            create: (_) => EnergyDataProvider(
              apiClient: EnergyApiClient(
                client: MockClient((_) async => http.Response('[]', 200)),
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: AnalyticsScreen())),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() async {
    database = EnergyDatabase.forTesting(NativeDatabase.memory());
    deviceKey = (await database.ensureLocalDevice()).localId;
    service = EnergyHistoryService(database: database);
  });

  tearDown(() => database.close());

  testWidgets('batang memakai satuan yang sama dengan maxY pada periode hari',
      (tester) async {
    // Periode "Hari" ditampilkan dalam watt-hour, jadi batang harus ikut
    // dikali 1000. Sebelum diperbaiki, `toY` masih kilowatt-hour sementara
    // `maxY` sudah watt-hour, sehingga batang tergambar seribu kali pendek.
    final now = DateTime(2026, 9, 29, 13);
    await seedHour(DateTime(2026, 9, 29, 9), 0.85);
    await seedHour(DateTime(2026, 9, 29, 10), 0.42);
    await seedHour(DateTime(2026, 9, 29, 11), 0.61);
    await seedHour(DateTime(2026, 9, 29, 12), 0.30);

    await showDay(tester, now);

    final chart = readConsumptionChart(tester);
    expect(chart.rods, isNotEmpty);

    // Setiap batang harus bisa mengisi sumbu, tidak selalu lebih kecil dari 1%.
    for (final rod in chart.rods) {
      if (rod.toY == 0) continue;
      expect(
        rod.toY / chart.maxY,
        greaterThan(0.02),
        reason: 'batang ${rod.toY} diabaikan dibanding maxY ${chart.maxY}',
      );
      expect(rod.toY, lessThanOrEqualTo(chart.maxY));
    }
  });

  testWidgets('batas sumbu ikut naik seribu kali dari kilowatt-hour',
      (tester) async {
    final now = DateTime(2026, 9, 29, 13);
    await seedHour(DateTime(2026, 9, 29, 9), 0.85);
    await seedHour(DateTime(2026, 9, 29, 10), 0.42);

    await showDay(tester, now);

    // Puncak 0,85 kWh = 850 Wh, jadi maxY harus di kisaran watt-hour.
    final chart = readConsumptionChart(tester);
    expect(chart.maxY, greaterThan(100));
  });

  testWidgets('perbandingan tinggi batang mengikuti perbandingan nilainya',
      (tester) async {
    // Dua jam dengan rasio 1:4. Kalau batang benar-benar mengikuti nilainya,
    // tinggi gambar dua batang itu juga harus berbanding lurus 1:4.
    final now = DateTime(2026, 9, 29, 13);
    await seedHour(DateTime(2026, 9, 29, 9), 0.10);
    await seedHour(DateTime(2026, 9, 29, 10), 0.40);

    await showDay(tester, now);

    final chart = readConsumptionChart(tester);
    final filled = chart.rods.where((rod) => rod.toY > 0).toList();
    expect(filled, hasLength(2));

    final low = filled.reduce((a, b) => a.toY < b.toY ? a : b);
    final high = filled.reduce((a, b) => a.toY > b.toY ? a : b);
    expect(low.toY, closeTo(100, 1e-6));
    expect(high.toY, closeTo(400, 1e-6));
    expect(high.toY / low.toY, closeTo(4.0, 1e-6));
  });
}
