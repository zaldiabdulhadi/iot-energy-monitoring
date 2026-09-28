import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_energy/data/local/app_database.dart';
import 'package:smart_energy/models/energy_hourly.dart';
import 'package:smart_energy/models/energy_metric.dart';
import 'package:smart_energy/models/energy_period_summary.dart';
import 'package:smart_energy/services/energy_history_service.dart';

void main() {
  late EnergyDatabase database;
  late EnergyHistoryService service;
  late String deviceKey;

  /// Sumbu tetap supaya hasil bucket bisa dibandingkan tanpa bergantung zona
  /// waktu mesin.
  final now = DateTime(2026, 3, 15, 12, 30);

  setUp(() async {
    database = EnergyDatabase.forTesting(NativeDatabase.memory());
    service = EnergyHistoryService(database: database);
    deviceKey = (await database.ensureLocalDevice()).localId;
  });

  tearDown(() => database.close());

  /// Menulis satu baris riwayat per jam.
  ///
  /// [powerW] dalam watt dan disimpan apa adanya ke kolom agregat, jadi
  /// `powerSum` disetel ke nilai jam itu supaya rata-rata per jamnya tepat.
  Future<void> seedHour(
    DateTime hourStart, {
    double energyKwh = 0.5,
    double powerW = 1000,
    double voltage = 220,
    double current = 4.5,
    double frequency = 50,
    double powerFactor = 0.95,
    int sampleCount = 60,
  }) async {
    final row = EnergyHourly(
      deviceKey: deviceKey,
      hourStart: hourStart,
      energyKwh: energyKwh,
      // `avgPowerW` diturunkan dari powerSum/sampleCount, jadi jumlah harus
      // berskala dengan jumlah sampel supaya rata-rata per jamnya sama dengan
      // nilai yang diminta.
      powerSum: powerW * sampleCount,
      powerMin: powerW,
      powerMax: powerW,
      voltageSum: voltage * sampleCount,
      voltageMin: voltage,
      voltageMax: voltage,
      currentSum: current * sampleCount,
      currentMax: current,
      frequencySum: frequency * sampleCount,
      frequencyMin: frequency,
      frequencyMax: frequency,
      powerFactorSum: powerFactor * sampleCount,
      powerFactorMin: powerFactor,
      sampleCount: sampleCount,
      observedSeconds: 3600,
      coveragePct: 100,
    );
    await database.upsertHistory(hourly: row, now: hourStart);
  }

  group('rentang periode', () {
    test('periode hari adalah jendela 24 jam yang berakhir di batas jam',
        () async {
      final report = await service.report(HistoryPeriod.day, now: now);

      // Bukan kalender: 24 jam terakhir dihitung mundur dari ujung jam berjalan.
      expect(report.summary.to, DateTime(2026, 3, 15, 13));
      expect(report.summary.from, DateTime(2026, 3, 14, 13));
      expect(
        report.summary.to.difference(report.summary.from),
        const Duration(hours: 24),
      );
    });

    test('periode pembanding berjarak sama panjangnya', () async {
      await seedHour(DateTime(2026, 3, 10));
      await seedHour(DateTime(2026, 3, 3));

      final report = await service.report(HistoryPeriod.week, now: now);

      final currentSpan = report.summary.to.difference(report.summary.from);
      final previousSpan =
          report.previous!.to.difference(report.previous!.from);
      expect(currentSpan, const Duration(days: 7));
      expect(previousSpan, currentSpan);
      // Periode sebelumnya berada tepat sebelum periode sekarang.
      expect(report.previous!.to, report.summary.from);
    });

    test('tidak ada data menghasilkan ringkasan kosong, bukan angka tebasan',
        () async {
      final report = await service.report(HistoryPeriod.day, now: now);

      expect(report.summary.isEmpty, isTrue);
      expect(report.summary.totalKwh, 0);
      expect(report.summary.observedHours, 0);
      // Ringkasan kosong bukan data contoh, jadi tidak boleh memakai jalur itu.
      expect(report.summary.isDemo, isFalse);
    });
  });

  group('kelengkapan data', () {
    test('jam yang terekam dihitung terhadap jam yang diharapkan', () async {
      await seedHour(DateTime(2026, 3, 15, 0));
      await seedHour(DateTime(2026, 3, 15, 1));

      final report = await service.report(HistoryPeriod.day, now: now);

      expect(report.summary.observedHours, 2);
      expect(report.summary.expectedHours, 24);
      expect(report.summary.isAnalyzable, isTrue);
    });
  });

  group('satuan metrik', () {
    test('rata-rata dan batas daya dikonversi dari watt ke kW', () async {
      // 3000 W = 3 kW. Kalau divisor tidak diterapkan, angka ini akan tampil
      // sebagai 3000 kW di kartu ringkasan.
      await seedHour(DateTime(2026, 3, 15, 10), powerW: 3000);

      final report = await service.report(HistoryPeriod.day, now: now);
      final summary = report.summary;

      expect(summary.averageOf(EnergyMetric.power), closeTo(3.0, 1e-9));
      expect(summary.averagePowerKw, closeTo(3.0, 1e-9));
      expect(summary.maximums[EnergyMetric.power], closeTo(3.0, 1e-9));
      expect(summary.minimums[EnergyMetric.power], closeTo(3.0, 1e-9));
    });

    test('metrik tanpa pembatas tidak menghasilkan nilai batas', () async {
      await seedHour(DateTime(2026, 3, 15, 10));

      final report = await service.report(HistoryPeriod.day, now: now);
      final summary = report.summary;

      // Tabel hanya menyimpan minimum PF dan maksimum arus, jadi pasangannya
      // harus null, bukan 0.
      expect(summary.minimums[EnergyMetric.powerFactor], isNotNull);
      expect(summary.maximums[EnergyMetric.powerFactor], isNull);
      expect(summary.maximums[EnergyMetric.current], isNotNull);
      expect(summary.minimums[EnergyMetric.current], isNull);
    });
  });

  group('pembagian bucket', () {
    test('periode hari menghasilkan 24 bucket per jam', () async {
      await seedHour(DateTime(2026, 3, 14, 13), energyKwh: 0.5);

      final report = await service.report(HistoryPeriod.day, now: now);
      final buckets = report.summary.buckets;

      expect(buckets.length, 24);
      expect(buckets.first.label, '13.00');
      expect(buckets.last.label, '12.00');
    });

    test('periode minggu menghasilkan 7 bucket per hari', () async {
      await seedHour(DateTime(2026, 3, 10));

      final report = await service.report(HistoryPeriod.week, now: now);

      expect(report.summary.buckets.length, 7);
      // 9 Maret 2026 adalah Senin.
      expect(report.summary.buckets.first.label, 'Sen');
    });

    test('periode tahun memakai batas bulan kalender, bukan 30 hari', () async {
      await seedHour(DateTime(2025, 6, 10));
      // Tanggal di lima hari terakhir periode. Dengan bucket 30 hari, batas
      // terakhirnya jatuh di 27 Maret 2026 sehingga baris ini terlewat.
      await seedHour(DateTime(2026, 3, 30), energyKwh: 7);

      final report = await service.report(HistoryPeriod.year, now: now);
      final buckets = report.summary.buckets;

      // 1 April 2025 sampai 1 April 2026 adalah 12 bulan kalender utuh.
      expect(buckets.first.from, DateTime(2025, 4));
      expect(buckets.last.to, DateTime(2026, 4));
      expect(buckets.length, 12);
      // Label bulan harus cocok dengan bulan yang benar-benar diplot.
      expect(buckets.first.label, 'Apr');
      expect(buckets[1].label, 'Mei');
      expect(buckets.last.label, 'Mar');
      // Bucket tidak boleh tumpang tindih maupun bolong.
      for (var i = 0; i < buckets.length - 1; i++) {
        expect(buckets[i].to, buckets[i + 1].from);
      }
      // Baris di ujung periode masuk ke total dan ke bucket terakhir.
      expect(report.summary.totalKwh, greaterThan(7));
      expect(buckets.last.kwh, closeTo(7, 1e-9));
    });

    test('konsumsi tiap bucket adalah jumlah jam di dalamnya', () async {
      await seedHour(DateTime(2026, 3, 15, 0), energyKwh: 0.4);
      await seedHour(DateTime(2026, 3, 15, 1), energyKwh: 0.6);
      await seedHour(DateTime(2026, 3, 15, 2), energyKwh: 1.0);

      final report = await service.report(HistoryPeriod.day, now: now);
      final buckets = report.summary.buckets;

      // Jendela "24 jam terakhir" mulai 14 Maret pukul 13.00, jadi jam 0, 1,
      // dan 2 bukan bucket paling awal. Bucket dicari lewat rentangnya supaya
      // test tidak bergantung pada posisi indeks.
      double kwhAt(int hour) {
        final target = DateTime(2026, 3, 15, hour);
        return buckets
            .firstWhere(
              (b) => !target.isBefore(b.from) && target.isBefore(b.to),
            )
            .kwh;
      }

      expect(kwhAt(0), closeTo(0.4, 1e-9));
      expect(kwhAt(1), closeTo(0.6, 1e-9));
      expect(kwhAt(2), closeTo(1.0, 1e-9));
      expect(buckets.first.isEmpty, isTrue);
    });

    test('total konsumsi sama dengan jumlah seluruh bucket', () async {
      for (var h = 0; h < 6; h++) {
        await seedHour(DateTime(2026, 3, 15, h), energyKwh: 0.25);
      }

      final report = await service.report(HistoryPeriod.day, now: now);
      final bucketSum = report.summary.buckets
          .fold<double>(0, (total, bucket) => total + bucket.kwh);

      expect(report.summary.totalKwh, closeTo(1.5, 1e-9));
      expect(bucketSum, closeTo(report.summary.totalKwh, 1e-9));
    });
  });

  group('perbandingan periode', () {
    test('kenaikan konsumsi dihitung dari periode sebelumnya', () async {
      // Periode saat ini: 6 jam x 1 kWh.
      for (var h = 6; h < 12; h++) {
        await seedHour(DateTime(2026, 3, 15, h), energyKwh: 1);
      }
      // Periode sebelumnya: 6 jam x 0.5 kWh.
      for (var h = 0; h < 6; h++) {
        await seedHour(DateTime(2026, 3, 14, h), energyKwh: 0.5);
      }

      final report = await service.report(HistoryPeriod.day, now: now);

      expect(report.summary.totalKwh, closeTo(6, 1e-9));
      expect(report.previous!.totalKwh, closeTo(3, 1e-9));
      expect(report.summary.changePct(report.previous), closeTo(100, 1e-9));
    });

    test('perbandingan dengan periode kosong menghasilkan null', () async {
      await seedHour(DateTime(2026, 3, 15, 10));

      final report = await service.report(HistoryPeriod.day, now: now);

      expect(report.summary.changePct(report.previous), isNull);
    });
  });

  group('data contoh', () {
    test('tidak dipakai kalau pemanggil tidak memintanya', () async {
      final report = await service.report(HistoryPeriod.day, now: now);

      expect(report.summary.isEmpty, isTrue);
      expect(report.summary.isDemo, isFalse);
      expect(report.previous, isNull);
    });

    test('mengisi periode kosong dan menandai dirinya sebagai contoh', () async {
      final report = await service.report(
        HistoryPeriod.day,
        now: now,
        synthetic: true,
      );

      expect(report.summary.isDemo, isTrue);
      expect(report.summary.isEmpty, isFalse);
      expect(report.summary.totalKwh, greaterThan(0));
      // 24 titik per jam supaya grafik dan tabelnya langsung terisi.
      expect(report.summary.buckets.length, 24);
      expect(
        report.summary.buckets.every((b) => !b.isEmpty),
        isTrue,
        reason: 'setiap jam harus punya titik supaya grafik tidak bolong',
      );
    });

    test('periode sebelumnya juga diisi agar perbandingan tetap ada', () async {
      final report = await service.report(
        HistoryPeriod.day,
        now: now,
        synthetic: true,
      );

      expect(report.previous, isNotNull);
      expect(report.previous!.isDemo, isTrue);
      expect(report.previous!.totalKwh, greaterThan(0));
    });

    test('tidak pernah menggantikan rekaman yang benar-benar ada', () async {
      await seedHour(DateTime(2026, 3, 15, 10));

      final report = await service.report(
        HistoryPeriod.day,
        now: now,
        synthetic: true,
      );

      // Isi tetap persis satu jam yang tersimpan, bukan 24 jam rekaan.
      expect(report.summary.observedHours, 1);
      expect(report.summary.isDemo, isFalse);
    });

    test('nilai metriknya masuk rentang meter yang wajar', () async {
      final report = await service.report(
        HistoryPeriod.day,
        now: now,
        synthetic: true,
      );
      final summary = report.summary;

      expect(summary.averageOf(EnergyMetric.voltage), inInclusiveRange(210, 240));
      expect(summary.averageOf(EnergyMetric.frequency), inInclusiveRange(49.5, 50.5));
      expect(summary.averageOf(EnergyMetric.powerFactor), greaterThanOrEqualTo(0.9));
      expect(summary.averagePowerKw, inInclusiveRange(0.1, 1.5));
      expect(
        EnergyMetric.powerFactor.classify(summary.averagePowerFactor!),
        MetricStatus.healthy,
        reason: 'data contoh tidak boleh terlihat seperti gangguan PF',
      );
    });
  });
}
