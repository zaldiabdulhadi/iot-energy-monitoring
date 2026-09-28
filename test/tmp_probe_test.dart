import 'package:drift/native.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_energy/data/local/app_database.dart';
import 'package:smart_energy/models/energy_period_summary.dart';
import 'package:smart_energy/providers/energy_history_provider.dart';
import 'package:smart_energy/screens/analytics_screen.dart';
import 'package:smart_energy/services/energy_history_service.dart';

/// Lebar label yang terender, dikelompokkan per baris(sumbu).
List<(String, Rect)> _labelsIn(WidgetTester tester, Finder chart) {
  final result = <(String, Rect)>[];
  for (final element in find.descendant(of: chart, matching: find.byType(SideTitleWidget)).evaluate()) {
    final box = element.renderObject! as RenderBox;
    final title = element.widget as SideTitleWidget;
    if (title.meta.axisSide != AxisSide.bottom) continue;
    final text = tester
        .widgetList<Text>(find.descendant(
          of: find.byElementPredicate((e) => e == element),
          matching: find.byType(Text),
        ))
        .map((t) => t.data ?? '')
        .join();
    if (text.isEmpty) continue;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    result.add((text, rect));
  }
  result.sort((a, b) => a.$2.left.compareTo(b.$2.left));
  return result;
}

void main() {
  for (final width in [320.0, 360.0, 400.0, 600.0]) {
    for (final period in HistoryPeriod.values) {
      testWidgets('sumbu bawah ${period.label} di ${width}dp', (tester) async {
        tester.view.physicalSize = Size(width, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final database = EnergyDatabase.forTesting(NativeDatabase.memory());
        addTearDown(database.close);
        final history = EnergyHistoryProvider(
          service: EnergyHistoryService(database: database),
          allowSyntheticWhenEmpty: true,
        );
        await history.load();
        history.select(period);

        await tester.pumpWidget(
          ChangeNotifierProvider<EnergyHistoryProvider>.value(
            value: history,
            child: const MaterialApp(home: Scaffold(body: AnalyticsScreen())),
          ),
        );
        await tester.pump();

        for (final chart in [find.byType(BarChart), find.byType(LineChart)]) {
          final labels = _labelsIn(tester, chart);
          debugPrint('--- ${period.label} @${width}dp ${chart.evaluate().isEmpty ? "line" : "bar"} '
              '(${labels.length} label) ---');
          for (final (text, rect) in labels) {
            debugPrint('  "$text" x=${rect.left.toStringAsFixed(1)}..'
                '${rect.right.toStringAsFixed(1)} y=${rect.top.toStringAsFixed(1)}');
          }
          for (var i = 1; i < labels.length; i++) {
            if (labels[i].$2.left < labels[i - 1].$2.right) {
              debugPrint('  !! TUMPANG TINDIH: ${labels[i - 1].$1} / ${labels[i].$1}');
            }
          }
        }
      });
    }
  }
}
