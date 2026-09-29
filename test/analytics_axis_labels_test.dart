import 'package:drift/native.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_energy/data/local/app_database.dart';
import 'package:smart_energy/models/energy_hourly.dart';
import 'package:smart_energy/models/energy_period_summary.dart';
import 'package:smart_energy/providers/energy_history_provider.dart';
import 'package:smart_energy/screens/analytics_screen.dart';
import 'package:smart_energy/services/energy_history_service.dart';

/// Lebar label sumbu bawah yang benar-benar terender, diurutkan dari kiri.
///
/// Hanya sumbu bawah yang diambil: sumbu kiri grafik garis memang sengaja
/// berdekatan dan tidak boleh ikut diuji aturan yang sama.
List<(String, Rect)> bottomLabels(WidgetTester tester, Finder chart) {
  final result = <(String, Rect)>[];
  for (final element
      in find
          .descendant(of: chart, matching: find.byType(SideTitleWidget))
          .evaluate()) {
    final title = element.widget as SideTitleWidget;
    if (title.meta.axisSide != AxisSide.bottom) continue;
    final text = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byElementPredicate((e) => e == element),
            matching: find.byType(Text),
          ),
        )
        .map((t) => t.data ?? '')
        .join();
    if (text.isEmpty) continue;
    final box = element.renderObject! as RenderBox;
    result.add((text, box.localToGlobal(Offset.zero) & box.size));
  }
  result.sort((a, b) => a.$2.left.compareTo(b.$2.left));
  return result;
}

/// Pasangan label yang saling menindih, ditulis sebagai teks yang bisa dibaca
/// saat test gagal.
List<String> overlaps(List<(String, Rect)> labels) {
  final found = <String>[];
  for (var i = 1; i < labels.length; i++) {
    if (labels[i].$2.left < labels[i - 1].$2.right) {
      found.add('${labels[i - 1].$1} / ${labels[i].$1}');
    }
  }
  return found;
}

void main() {
  late EnergyDatabase database;
  late EnergyHistoryService service;
  late String deviceKey;

  /// Satu baris per jam untuk seluruh periode, supaya grafik batang dan garis
  /// sama-sama punya data nyata tanpa tanda bintang data contoh.
  Future<void> seedHistory(DateTime now) async {
    for (var back = 0; back < 40; back++) {
      final hour = now.subtract(Duration(hours: back));
      final samples = 60;
      final watts = 800.0 + back * 11;
      await database.upsertHistory(
        hourly: EnergyHourly(
          deviceKey: deviceKey,
          hourStart: DateTime(hour.year, hour.month, hour.day, hour.hour),
          energyKwh: 0.4 + back * 0.03,
          powerSum: watts * samples,
          powerMin: watts - 20,
          powerMax: watts + 20,
          voltageSum: 214.0 * samples,
          voltageMin: 210,
          voltageMax: 219,
          currentSum: 0.3 * samples,
          currentMax: 0.42,
          frequencySum: 50.0 * samples,
          frequencyMin: 49.8,
          frequencyMax: 50.2,
          powerFactorSum: 0.9 * samples,
          powerFactorMin: 0.85,
          sampleCount: samples,
          observedSeconds: 3600,
          coveragePct: 100,
        ),
        now: hour,
      );
    }
  }

  Future<void> showScreen(WidgetTester tester, HistoryPeriod period) async {
    final history = EnergyHistoryProvider(service: service);
    await history.select(period);
    await tester.pumpWidget(
      ChangeNotifierProvider<EnergyHistoryProvider>.value(
        value: history,
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

  // Lebar 320 adalah ponsel sempit yang paling sering jadi tempat label
  // bertabrakan; 600 adalah tablet.
  for (final width in [320.0, 360.0, 400.0, 600.0]) {
    group('sumbu bawah di ${width.toInt()}dp', () {
      for (final period in HistoryPeriod.values) {
        testWidgets('${period.label} tidak menindih labelnya', (tester) async {
          tester.view.physicalSize = Size(width, 1400);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          final now = DateTime(2026, 9, 29, 13);
          await seedHistory(now);
          await showScreen(tester, period);

          for (final chart in [find.byType(BarChart), find.byType(LineChart)]) {
            final labels = bottomLabels(tester, chart);
            expect(
              overlaps(labels),
              isEmpty,
              reason: 'label sumbu bawah bertumpuk pada ${period.label} '
                  'lebar ${width.toInt()}dp',
            );
          }
        });
      }
    });
  }

  testWidgets('label tetap digambar, tidak dihilangkan semua', (tester) async {
    // Penjaga agar test di atas bisa lulus karena menyaring terlalu banyak
    // label sampai tidak ada yang tersisa sama sekali.
    tester.view.physicalSize = const Size(600, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await seedHistory(DateTime(2026, 9, 29, 13));
    await showScreen(tester, HistoryPeriod.day);

    final labels = bottomLabels(tester, find.byType(BarChart));
    expect(labels, isNotEmpty);
    expect(labels.length, greaterThan(1));
  });

  testWidgets('label jam tidak pernah menindih meski huruf diperbesar',
      (tester) async {
    // Label dihitung dari teks yang dirender, jadi pengguna yang memperbesar
    // huruf harus tetap dapat membaca sumbunya.
    tester.view.physicalSize = const Size(320, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await seedHistory(DateTime(2026, 9, 29, 13));
    final history = EnergyHistoryProvider(service: service);
    await history.select(HistoryPeriod.day);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
        child: ChangeNotifierProvider<EnergyHistoryProvider>.value(
          value: history,
          child: const MaterialApp(home: Scaffold(body: AnalyticsScreen())),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final labels = bottomLabels(tester, find.byType(BarChart));
    expect(overlaps(labels), isEmpty);
  });
}
