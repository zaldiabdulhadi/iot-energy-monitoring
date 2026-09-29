import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_energy/data/local/app_database.dart';
import 'package:smart_energy/models/energy_hourly.dart';
import 'package:smart_energy/models/energy_period_summary.dart';
import 'package:smart_energy/services/energy_csv_exporter.dart';
import 'package:smart_energy/services/energy_export_target.dart';
import 'package:smart_energy/services/energy_history_service.dart';

/// Catat semua yang diminta ke exporter tanpa menyentuh Android.
class _FakeTarget implements EnergyExportTarget {
  final List<String> savedNames = <String>[];
  final List<String> sharedNames = <String>[];
  final List<String> sharedSubjects = <String>[];
  Uint8List? lastBytes;

  @override
  Future<String> saveToDownloads(String fileName, Uint8List bytes) async {
    savedNames.add(fileName);
    lastBytes = bytes;
    return 'Download/SmartEnergy/$fileName';
  }

  @override
  Future<void> share(
    String fileName,
    Uint8List bytes, {
    String? subject,
    String? text,
    Rect? origin,
  }) async {
    sharedNames.add(fileName);
    sharedSubjects.add(subject ?? '');
  }
}

void main() {
  late EnergyDatabase database;
  late EnergyHistoryService service;
  late _FakeTarget target;
  late String deviceKey;

  // Sumbu tetap supaya nama berkas dan isi CSV bisa dibandingkan persis.
  final now = DateTime(2026, 3, 15, 12, 30);

  setUp(() async {
    database = EnergyDatabase.forTesting(NativeDatabase.memory());
    service = EnergyHistoryService(database: database);
    target = _FakeTarget();
    deviceKey = (await database.ensureLocalDevice()).localId;
  });

  tearDown(() => database.close());

  Future<void> seedHour(
    DateTime hourStart, {
    double energyKwh = 0.5,
    double powerW = 1200,
    bool isDemo = false,
  }) async {
    await database.upsertHistory(
      hourly: EnergyHourly(
        deviceKey: deviceKey,
        hourStart: hourStart,
        energyKwh: energyKwh,
        powerSum: powerW * 60,
        powerMin: powerW,
        powerMax: powerW,
        voltageSum: 220 * 60,
        voltageMin: 218,
        voltageMax: 223,
        currentSum: 5.4 * 60,
        currentMax: 6.1,
        frequencySum: 50 * 60,
        frequencyMin: 49.9,
        frequencyMax: 50.1,
        powerFactorSum: 0.95 * 60,
        powerFactorMin: 0.92,
        sampleCount: 60,
        observedSeconds: 3600,
        coveragePct: 100,
        isDemo: isDemo,
      ),
      now: hourStart,
    );
  }

  group('isi csv', () {
    test('satu baris per jam dengan seluruh kolom', () {
      final csv = buildHourlyCsv(<EnergyHourly>[
        EnergyHourly(
          deviceKey: deviceKey,
          hourStart: DateTime(2026, 3, 15, 10),
          energyKwh: 0.75,
          powerSum: 1200 * 60,
          powerMin: 900,
          powerMax: 1500,
          voltageSum: 220 * 60,
          voltageMin: 218,
          voltageMax: 223,
          currentSum: 5.4 * 60,
          currentMax: 6.1,
          frequencySum: 50 * 60,
          frequencyMin: 49.9,
          frequencyMax: 50.1,
          powerFactorSum: 0.95 * 60,
          powerFactorMin: 0.92,
          sampleCount: 60,
          observedSeconds: 3600,
          coveragePct: 100,
        ),
      ]);

      final lines = csv.trimRight().split('\n');
      expect(lines, hasLength(2));
      expect(
        lines.first.split(';'),
        containsAll(<String>['waktu', 'kwh', 'daya_rata_w', 'cakupan_persen']),
      );

      final cells = lines.last.split(';');
      expect(cells, hasLength(21));
      expect(cells[0], DateTime(2026, 3, 15, 10).toIso8601String());
      // Pemisah koma dan desimal koma: bentuk yang langsung benar di Excel
      // versi Indonesia tanpa wizard impor.
      expect(cells[1], '0.750');
      expect(cells[2], '1200.000');
      expect(cells[3], '900.000');
      expect(cells[14], '0.920');
      expect(cells[15], '60');
      expect(cells[16], '3600');
      expect(cells[18], '100.0');
      expect(cells[19], 'partial');
      expect(cells[20], '0');
    });

    test('nilai kosong tetap kolom kosong, bukan nol', () {
      // Baris tanpa min/max tidak boleh mengarang angka: sel kosong jauh lebih
      // jujur daripada 0 yang terlihat seperti pengukuran.
      final csv = buildHourlyCsv(<EnergyHourly>[
        EnergyHourly(
          deviceKey: deviceKey,
          hourStart: DateTime(2026, 3, 15, 10),
          energyKwh: 0.25,
          powerSum: 600 * 60,
          sampleCount: 60,
          observedSeconds: 3600,
        ),
      ]);

      final cells = csv.trimRight().split('\n').last.split(';');
      expect(cells[1], '0.250');
      expect(cells[2], '600.000');
      expect(cells[3], isEmpty, reason: 'daya minimum tidak pernah diukur');
      expect(cells[7], isEmpty, reason: 'tegangan maksimum tidak pernah diukur');
      expect(cells[11], isEmpty, reason: 'frekuensi minimum tidak diukur');
    });

    test('data simulasi ditandai di kolom is_demo', () {
      final csv = buildHourlyCsv(<EnergyHourly>[
        EnergyHourly(
          deviceKey: deviceKey,
          hourStart: DateTime(2026, 3, 15, 10),
          energyKwh: 0.5,
          powerSum: 1000 * 60,
          sampleCount: 60,
          isDemo: true,
        ),
      ]);

      expect(csv.trimRight().split('\n').last.split(';').last, '1');
    });
  });

  group('ekspor periode', () {
    test('menyimpan berkas per jam ke Downloads lalu membagikannya', () async {
      await seedHour(DateTime(2026, 3, 15, 10));
      await seedHour(DateTime(2026, 3, 15, 11));
      // Di luar jendela 24 jam, jadi tidak boleh ikut terunduh.
      await seedHour(DateTime(2026, 3, 13, 10));

      final exporter = EnergyCsvExporter(
        database: database,
        history: service,
        target: target,
      );
      final result = await exporter.export(HistoryPeriod.day, now: now);

      expect(result.rowCount, 2);
      expect(result.from, DateTime(2026, 3, 14, 13));
      expect(result.to, DateTime(2026, 3, 15, 13));
      expect(result.fileName, 'smart-energy_day_20260315-1300.csv');
      expect(result.location, contains('smart-energy_day_20260315-1300.csv'));

      expect(target.savedNames, <String>[result.fileName]);
      expect(target.sharedNames, <String>[result.fileName]);
      expect(target.sharedSubjects.single, isNotEmpty);

      final lines = utf8
          .decode(target.lastBytes!)
          .trimRight()
          .split('\n');
      expect(lines, hasLength(3), reason: 'header + dua jam');
      expect(lines[1].contains('2026-03-15T10:00:00.000'), isTrue);
      expect(lines[2].contains('2026-03-15T11:00:00.000'), isTrue);
    });

    test('nama berkas memakai periode yang dipilih', () async {
      await seedHour(DateTime(2026, 3, 15, 10));

      final exporter = EnergyCsvExporter(
        database: database,
        history: service,
        target: target,
      );

      // Stempel nama berkas mengikuti ujung jendela periode itu: "Hari" berakhir
      // di batas jam, "Minggu" dan "Bulan" di tengah malam.
      expect(
        (await exporter.export(HistoryPeriod.day, now: now)).fileName,
        'smart-energy_day_20260315-1300.csv',
      );
      expect(
        (await exporter.export(HistoryPeriod.week, now: now)).fileName,
        'smart-energy_week_20260316-0000.csv',
      );
      expect(
        (await exporter.export(HistoryPeriod.month, now: now)).fileName,
        'smart-energy_month_20260316-0000.csv',
      );
    });

    test('tanpa data pada periode itu menjelaskan alasannya', () async {
      // Ada riwayat, tapi di luar jendela 7 hari. Resultan file kosong akan
      // disalahartikan sebagai kerusakan, jadi harus ditolak dengan alasan.
      await seedHour(DateTime(2026, 1, 1, 10));

      final exporter = EnergyCsvExporter(
        database: database,
        history: service,
        target: target,
      );

      await expectLater(
        exporter.export(HistoryPeriod.week, now: now),
        throwsA(
          isA<EnergyExportException>().having(
            (error) => error.message,
            'message',
            contains('Belum ada data'),
          ),
        ),
      );
      expect(target.savedNames, isEmpty);
    });

    test('tanpa perangkat terdaftar ditolak sebelum membaca database', () async {
      final emptyDatabase = EnergyDatabase.forTesting(NativeDatabase.memory());
      addTearDown(emptyDatabase.close);

      final exporter = EnergyCsvExporter(
        database: emptyDatabase,
        history: EnergyHistoryService(database: emptyDatabase),
        target: target,
      );

      await expectLater(
        exporter.export(HistoryPeriod.day, now: now),
        throwsA(
          isA<EnergyExportException>().having(
            (error) => error.message,
            'message',
            contains('perangkat'),
          ),
        ),
      );
      expect(target.savedNames, isEmpty);
    });

    test('baris kosong tidak ikut ditulis', () async {
      await seedHour(DateTime(2026, 3, 15, 10));
      await database.upsertHistory(
        hourly: EnergyHourly(
          deviceKey: deviceKey,
          hourStart: DateTime(2026, 3, 15, 11),
        ),
        now: DateTime(2026, 3, 15, 11),
      );

      final exporter = EnergyCsvExporter(
        database: database,
        history: service,
        target: target,
      );
      final result = await exporter.export(HistoryPeriod.day, now: now);

      expect(result.rowCount, 1);
      final lines = utf8.decode(target.lastBytes!).trimRight().split('\n');
      expect(lines, hasLength(2));
    });
  });
}
