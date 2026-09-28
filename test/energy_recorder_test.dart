import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_energy/data/local/app_database.dart';
import 'package:smart_energy/data/local/hourly_rollup.dart';
import 'package:smart_energy/data/local/interval_energy.dart';
import 'package:smart_energy/models/energy_hourly.dart';
import 'package:smart_energy/models/energy_reading.dart';
import 'package:smart_energy/models/energy_sync_state.dart';
import 'package:smart_energy/services/energy_recorder.dart';

const double kOneKwHourPerFiveSeconds = 1000 / 1000 * 5 / 3600;

EnergyReading reading({
  double power = 1000,
  required double energy,
  double voltage = 220,
  double current = 4.55,
  double frequency = 50,
  double powerFactor = 0.95,
}) =>
    EnergyReading(
      voltage: voltage,
      current: current,
      power: power,
      energy: energy,
      frequency: frequency,
      powerFactor: powerFactor,
    );

MinuteAggregateRow minuteRow({
  required String deviceKey,
  required DateTime minuteStart,
  double energyKwh = 0,
  double powerSum = 0,
  double? powerMin,
  double? powerMax,
  double voltageSum = 0,
  double? voltageMin,
  double? voltageMax,
  double currentSum = 0,
  double? currentMax,
  double frequencySum = 0,
  double? frequencyMin,
  double? frequencyMax,
  double powerFactorSum = 0,
  double? powerFactorMin,
  int sampleCount = 0,
  double observedSeconds = 0,
  int estimatedIntervals = 0,
}) =>
    MinuteAggregateRow(
      deviceKey: deviceKey,
      minuteStart: minuteStart,
      energyKwh: energyKwh,
      powerSum: powerSum,
      powerMin: powerMin,
      powerMax: powerMax,
      voltageSum: voltageSum,
      voltageMin: voltageMin,
      voltageMax: voltageMax,
      currentSum: currentSum,
      currentMax: currentMax,
      frequencySum: frequencySum,
      frequencyMin: frequencyMin,
      frequencyMax: frequencyMax,
      powerFactorSum: powerFactorSum,
      powerFactorMin: powerFactorMin,
      sampleCount: sampleCount,
      observedSeconds: observedSeconds,
      estimatedIntervals: estimatedIntervals,
    );

void main() {
  group('computeIntervalEnergy', () {
    test('memakai delta meter saat masuk akal', () {
      final result = computeIntervalEnergy(
        reading(energy: 10),
        reading(energy: 10 + kOneKwHourPerFiveSeconds),
        const Duration(seconds: 5),
      );

      expect(result.meterUsable, isTrue);
      expect(result.kwh, closeTo(kOneKwHourPerFiveSeconds, 1e-9));
    });

    test('fallback ke integrasi saat counter reset', () {
      final result = computeIntervalEnergy(
        reading(energy: 10),
        reading(energy: 0),
        const Duration(seconds: 5),
      );

      expect(result.meterUsable, isFalse);
      expect(result.kwh, closeTo(kOneKwHourPerFiveSeconds, 1e-9));
    });

    test('fallback ke integrasi saat loncatan meter tidak wajar', () {
      final result = computeIntervalEnergy(
        reading(energy: 10),
        reading(energy: 500),
        const Duration(seconds: 5),
      );

      expect(result.meterUsable, isFalse);
      expect(result.kwh, closeTo(kOneKwHourPerFiveSeconds, 1e-9));
    });

    test('fallback ke integrasi saat meter tidak bergerak', () {
      final result = computeIntervalEnergy(
        reading(energy: 10),
        reading(energy: 10),
        const Duration(seconds: 5),
      );

      expect(result.meterUsable, isFalse);
      expect(result.kwh, closeTo(kOneKwHourPerFiveSeconds, 1e-9));
    });

    test('durasi jam ikut dihitung', () {
      final result = computeIntervalEnergy(
        reading(power: 3600, energy: 0),
        reading(power: 3600, energy: 0),
        const Duration(hours: 1),
      );

      expect(result.kwh, closeTo(3.6, 1e-9));
    });
  });

  group('rollupMinutes', () {
    test('menjumlahkan energi dan menghitung rata-rata', () {
      final hourly = rollupMinutes(
        deviceKey: 'dev',
        hourStart: DateTime(2026, 9, 25, 10),
        rows: [
          minuteRow(
            deviceKey: 'dev',
            minuteStart: DateTime(2026, 9, 25, 10, 0),
            energyKwh: 0.5,
            powerSum: 12000,
            powerMin: 900,
            powerMax: 1100,
            voltageSum: 440,
            voltageMin: 219,
            voltageMax: 221,
            currentSum: 54,
            currentMax: 5.1,
            frequencySum: 100,
            frequencyMin: 49.9,
            frequencyMax: 50.1,
            powerFactorSum: 1.9,
            powerFactorMin: 0.93,
            sampleCount: 12,
            observedSeconds: 60,
          ),
          minuteRow(
            deviceKey: 'dev',
            minuteStart: DateTime(2026, 9, 25, 10, 1),
            energyKwh: 0.25,
            powerSum: 8000,
            powerMin: 700,
            powerMax: 900,
            sampleCount: 12,
            observedSeconds: 60,
          ),
        ],
      );

      expect(hourly.energyKwh, closeTo(0.75, 1e-9));
      expect(hourly.sampleCount, 24);
      expect(hourly.avgPowerW, closeTo(20000 / 24, 1e-9));
      expect(hourly.powerMin, 700);
      expect(hourly.powerMax, 1100);
      expect(hourly.avgVoltage, closeTo(440 / 24, 1e-9));
      expect(hourly.voltageMin, 219);
      expect(hourly.voltageMax, 221);
      expect(hourly.currentMax, 5.1);
      expect(hourly.frequencyMin, 49.9);
      expect(hourly.frequencyMax, 50.1);
      expect(hourly.avgPowerFactor, closeTo(1.9 / 24, 1e-9));
      expect(hourly.powerFactorMin, 0.93);
    });

    test('coverage penuh menghasilkan quality complete', () {
      final hourly = rollupMinutes(
        deviceKey: 'dev',
        hourStart: DateTime(2026, 9, 25, 10),
        rows: [
          minuteRow(
            deviceKey: 'dev',
            minuteStart: DateTime(2026, 9, 25, 10),
            sampleCount: 720,
            observedSeconds: 3600,
          ),
        ],
      );

      expect(hourly.coveragePct, closeTo(100, 1e-9));
      expect(hourly.quality, EnergyDataQuality.complete);
    });

    test('coverage sebagian menghasilkan quality partial', () {
      final hourly = rollupMinutes(
        deviceKey: 'dev',
        hourStart: DateTime(2026, 9, 25, 10),
        rows: [
          minuteRow(
            deviceKey: 'dev',
            minuteStart: DateTime(2026, 9, 25, 10),
            sampleCount: 60,
            observedSeconds: 300,
          ),
        ],
      );

      expect(hourly.coveragePct, closeTo(100 / 12, 1e-6));
      expect(hourly.quality, EnergyDataQuality.partial);
    });

    test('dominan hasil estimasi menghasilkan quality estimated', () {
      final hourly = rollupMinutes(
        deviceKey: 'dev',
        hourStart: DateTime(2026, 9, 25, 10),
        rows: [
          minuteRow(
            deviceKey: 'dev',
            minuteStart: DateTime(2026, 9, 25, 10),
            sampleCount: 720,
            observedSeconds: 3600,
            estimatedIntervals: 500,
          ),
        ],
      );

      expect(hourly.estimatedRatio, greaterThan(0.5));
      expect(hourly.quality, EnergyDataQuality.estimated);
    });

    test('observedSeconds tidak bisa melebihi satu jam', () {
      final hourly = rollupMinutes(
        deviceKey: 'dev',
        hourStart: DateTime(2026, 9, 25, 10),
        rows: [
          minuteRow(
            deviceKey: 'dev',
            minuteStart: DateTime(2026, 9, 25, 10, 0),
            sampleCount: 60,
            observedSeconds: 3000,
          ),
          minuteRow(
            deviceKey: 'dev',
            minuteStart: DateTime(2026, 9, 25, 10, 1),
            sampleCount: 60,
            observedSeconds: 3000,
          ),
        ],
      );

      expect(hourly.observedSeconds, 3600);
      expect(hourly.coveragePct, 100);
    });

    test('perhitungan biaya dan karbon memakai tarif configured', () {
      final hourly = rollupMinutes(
        deviceKey: 'dev',
        hourStart: DateTime(2026, 9, 25, 10),
        rows: [
          minuteRow(
            deviceKey: 'dev',
            minuteStart: DateTime(2026, 9, 25, 10),
            energyKwh: 2,
            sampleCount: 720,
            observedSeconds: 3600,
          ),
        ],
      );

      expect(hourly.co2At(0.42), closeTo(0.84, 1e-9));
      expect(hourly.averageWattsFromEnergy, closeTo(2000, 1e-9));
    });
  });

  group('EnergyRecorder', () {
    late EnergyDatabase database;
    late EnergyRecorder recorder;
    late String deviceKey;

    final hourStart = DateTime(2026, 9, 25, 10);

    setUp(() async {
      database = EnergyDatabase.forTesting(NativeDatabase.memory());
      recorder = EnergyRecorder(database: database);
      deviceKey = (await database.ensureLocalDevice()).localId;
    });

    tearDown(() => database.close());

    Future<void> feedHour({
      required DateTime start,
      int samples = 719,
      double watts = 1000,
    }) async {
      var meter = 0.0;
      for (var i = 0; i <= samples; i++) {
        if (i > 0) meter += watts / 1000 * 5 / 3600;
        await recorder.record(
          reading(power: watts, energy: meter),
          now: start.add(Duration(seconds: 5 * i)),
        );
      }
    }

    test('menyimpan satu baris per menit saat menit berganti', () async {
      await feedHour(start: hourStart, samples: 14);
      await recorder.flush();

      final rows = await database.minutesForHour(deviceKey, hourStart);
      expect(rows, hasLength(2));
      expect(rows.first.minuteStart, hourStart);
      expect(rows.first.sampleCount, 12);
      expect(rows.first.observedSeconds, closeTo(55, 1e-9));
      expect(rows.last.minuteStart, hourStart.add(const Duration(minutes: 1)));
      expect(rows.last.sampleCount, 3);
    });

    test('flush menyimpan menit yang belum penuh', () async {
      await recorder.record(reading(energy: 0), now: hourStart);
      await recorder.record(
        reading(energy: kOneKwHourPerFiveSeconds),
        now: hourStart.add(const Duration(seconds: 5)),
      );

      expect(await database.minutesForHour(deviceKey, hourStart), isEmpty);

      await recorder.flush();

      final rows = await database.minutesForHour(deviceKey, hourStart);
      expect(rows, hasLength(1));
      expect(rows.single.sampleCount, 2);
      expect(rows.single.energyKwh, closeTo(kOneKwHourPerFiveSeconds, 1e-9));
    });

    test('jam lengkap menghasilkan satu baris hourly pending', () async {
      await feedHour(start: hourStart);
      await recorder.flush();

      expect(
        await database.minutesForHour(deviceKey, hourStart),
        hasLength(60),
        reason: 'jam berjalan tidak boleh ditutup sebelum berganti jam',
      );

      final closed = await recorder.closeCompletedHours(
        now: hourStart.add(const Duration(hours: 1, seconds: 5)),
      );

      expect(closed, 1);

      final hourly = await database.hourlyBetween(
        deviceKey,
        hourStart,
        hourStart.add(const Duration(hours: 2)),
      );
      expect(hourly, hasLength(1));

      final row = hourly.single;
      expect(row.hourStart, hourStart);
      expect(row.energyKwh, closeTo(719 * kOneKwHourPerFiveSeconds, 1e-6));
      expect(row.sampleCount, 720);
      expect(row.coveragePct, closeTo(3595 / 36, 1e-6));
      expect(row.quality, EnergyDataQuality.complete);
      expect(row.powerMax, 1000);
      expect(row.avgVoltage, closeTo(220, 1e-9));
      expect(row.powerFactorMin, closeTo(0.95, 1e-9));
      expect(row.averageWattsFromEnergy, closeTo(1000, 1e-6));

      final pending = await database.pendingHours(deviceKey);
      expect(pending, hasLength(1));
      expect(pending.single.syncStateValue, EnergySyncState.pending);
      expect(await database.countPending(deviceKey), 1);

      expect(await database.minutesForHour(deviceKey, hourStart), isEmpty);
    });

    test('jam ditutup otomatis saat menit masuk ke jam berikutnya', () async {
      await feedHour(start: hourStart);

      expect(await database.countPending(deviceKey), 0);

      await recorder.record(
        reading(power: 1000, energy: 1),
        now: hourStart.add(const Duration(hours: 1)),
      );
      await recorder.flush();

      expect(await database.countPending(deviceKey), 1);
    });

    test('backfill menutup jam yang tertinggal saat aplikasi dibuka lagi',
        () async {
      await feedHour(start: hourStart);
      await recorder.flush();

      recorder.reset();
      expect(await database.countPending(deviceKey), 0);

      final closed = await recorder.closeCompletedHours(
        now: hourStart.add(const Duration(hours: 5)),
      );

      expect(closed, 1);
      expect(await database.countPending(deviceKey), 1);
    });

    test('disconnect panjang tidak menambah energi maupun durasi', () async {
      await recorder.record(reading(energy: 0), now: hourStart);
      await recorder.record(
        reading(energy: kOneKwHourPerFiveSeconds),
        now: hourStart.add(const Duration(seconds: 5)),
      );
      await recorder.record(
        reading(energy: 100),
        now: hourStart.add(const Duration(hours: 2)),
      );
      await recorder.flush();

      final hourly = await database.hourlyBetween(
        deviceKey,
        hourStart,
        hourStart.add(const Duration(hours: 3)),
      );

      expect(hourly, hasLength(1));
      expect(hourly.single.sampleCount, 2);
      expect(hourly.single.observedSeconds, closeTo(5, 1e-9));
      expect(hourly.single.coveragePct, closeTo(5 / 36, 1e-6));
      expect(
        hourly.single.energyKwh,
        closeTo(kOneKwHourPerFiveSeconds, 1e-9),
        reason: 'selama reconnect tidak ada energi yang bisa diatribusikan',
      );
      expect(hourly.single.quality, EnergyDataQuality.partial);
    });

    test('counter reset ditandai sebagai interval estimated', () async {
      await recorder.record(reading(energy: 50), now: hourStart);
      await recorder.record(
        reading(energy: 50 + kOneKwHourPerFiveSeconds),
        now: hourStart.add(const Duration(seconds: 5)),
      );
      await recorder.record(
        reading(energy: 0),
        now: hourStart.add(const Duration(seconds: 10)),
      );
      await recorder.flush();

      final rows = await database.minutesForHour(deviceKey, hourStart);
      expect(rows.single.estimatedIntervals, 1);
      expect(
        rows.single.energyKwh,
        closeTo(2 * kOneKwHourPerFiveSeconds, 1e-9),
      );
    });

    test('menit berjalan tetap dipakai untuk rata-rata tegangan', () async {
      await recorder.record(
        reading(energy: 0, voltage: 220),
        now: hourStart,
      );
      await recorder.record(
        reading(energy: 0, voltage: 230),
        now: hourStart.add(const Duration(minutes: 30)),
      );
      await recorder.flush();

      final rows = await database.minutesForHour(deviceKey, hourStart);
      expect(rows, hasLength(2));
      expect(rows.first.voltageMax, 220);
      expect(rows.last.voltageMax, 230);
    });

    test('rollup bersifat idempotent saat dijalankan dua kali', () async {
      await feedHour(start: hourStart);
      final now = hourStart.add(const Duration(hours: 1, seconds: 5));

      expect(await recorder.closeCompletedHours(now: now), 1);
      expect(await recorder.closeCompletedHours(now: now), 0);

      final hourly = await database.hourlyBetween(
        deviceKey,
        hourStart,
        hourStart.add(const Duration(hours: 2)),
      );
      expect(hourly, hasLength(1));
    });

    test('waktu tersimpan kembali sebagai instant yang sama', () async {
      final local = DateTime(2026, 9, 25, 10, 42, 13);
      await database.upsertMinute(
        minuteRow(
          deviceKey: deviceKey,
          minuteStart: local,
          sampleCount: 1,
        ),
      );

      final rows = await database.minutesForHour(deviceKey, hourStart);
      expect(rows.single.minuteStart.toUtc(), local.toUtc());
    });

    test('pruneSynced menghapus baris yang sudah lama tersinkron', () async {
      await feedHour(start: hourStart);
      await recorder.closeCompletedHours(
        now: hourStart.add(const Duration(hours: 1, seconds: 5)),
      );
      await database.markSynced(
        deviceKey,
        hourStart,
        now: hourStart.add(const Duration(hours: 2)),
      );

      expect(await database.countPending(deviceKey), 0);
      expect(
        await database.hourlyBetween(
          deviceKey,
          hourStart,
          hourStart.add(const Duration(hours: 3)),
        ),
        hasLength(1),
      );

      await database.pruneSynced(
        deviceKey: deviceKey,
        syncedBefore: hourStart.add(const Duration(hours: 3)),
      );

      expect(
        await database.hourlyBetween(
          deviceKey,
          hourStart,
          hourStart.add(const Duration(hours: 3)),
        ),
        isEmpty,
      );
    });

    test('markFailed menaikkan jumlah percobaan', () async {
      await feedHour(start: hourStart);
      await recorder.closeCompletedHours(
        now: hourStart.add(const Duration(hours: 1, seconds: 5)),
      );

      await database.markFailed(
        deviceKey,
        hourStart,
        error: 'jaringan tidak tersedia',
        now: hourStart.add(const Duration(hours: 2)),
      );
      await database.markFailed(
        deviceKey,
        hourStart,
        error: 'jaringan tidak tersedia',
        now: hourStart.add(const Duration(hours: 3)),
      );

      final rows = await database.pendingHours(deviceKey);
      expect(rows.single.syncStateValue, EnergySyncState.failed);
      expect(rows.single.attempts, 2);
      expect(rows.single.lastError, 'jaringan tidak tersedia');
      expect(await database.countPending(deviceKey), 1);
    });
  });
}
