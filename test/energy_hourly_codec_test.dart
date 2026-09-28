import 'package:flutter_test/flutter_test.dart';
import 'package:smart_energy/models/energy_hourly.dart';

void main() {
  final base = EnergyHourly(
    deviceKey: '3f2b9c1e-0000-4000-8000-000000000001',
    hourStart: DateTime(2026, 9, 25, 14),
  );

  group('EnergyHourly', () {
    test('toJson memetakan seluruh kolom tabel energy_hourly', () {
      final json = base.toJson();

      expect(json['device_id'], base.deviceKey);
      expect(json['hour_start'], base.hourStart.toUtc().toIso8601String());
      expect(json['data_quality'], 'partial');
      expect(json['energy_kwh'], 0);
      expect(json.keys, contains('power_min'));
      expect(json.keys, contains('frequency_max'));
      expect(json.keys, contains('power_factor_min'));
      expect(json.keys, contains('estimated_intervals'));
      expect(json['is_demo'], isFalse);
    });

    test('is_demo ikut terenkode dan didekode', () {
      final source = EnergyHourly(
        deviceKey: base.deviceKey,
        hourStart: DateTime(2026, 9, 25, 14),
        isDemo: true,
      );

      expect(source.toJson()['is_demo'], isTrue);
      expect(EnergyHourly.fromJson(source.toJson()).isDemo, isTrue);
    });

    test('baris lama tanpa is_demo dibaca sebagai pengukuran', () {
      final json = base.toJson()..remove('is_demo');

      expect(EnergyHourly.fromJson(json).isDemo, isFalse);
    });

    test('hour_start dikirim dalam UTC lalu dikembalikan sebagai waktu lokal', () {
      final decoded = EnergyHourly.fromJson(base.toJson());

      expect(decoded.hourStart, base.hourStart);
      expect(decoded.hourStart.isUtc, isFalse);
    });

    test('round trip mempertahankan seluruh nilai', () {
      final source = EnergyHourly(
        deviceKey: base.deviceKey,
        hourStart: DateTime(2026, 1, 31, 23),
        energyKwh: 1.2345,
        powerSum: 20000,
        powerMin: 0.4,
        powerMax: 0.9,
        voltageSum: 5300,
        voltageMin: 211.5,
        voltageMax: 228.25,
        currentSum: 87.5,
        currentMax: 4.2,
        frequencySum: 1200,
        frequencyMin: 49.8,
        frequencyMax: 50.3,
        powerFactorSum: 24,
        powerFactorMin: 0.88,
        sampleCount: 720,
        observedSeconds: 3595,
        estimatedIntervals: 3,
        coveragePct: 99.86,
        quality: EnergyDataQuality.estimated,
        isDemo: true,
      );

      final decoded = EnergyHourly.fromJson(source.toJson());

      expect(decoded.deviceKey, source.deviceKey);
      expect(decoded.hourStart, source.hourStart);
      expect(decoded.energyKwh, source.energyKwh);
      expect(decoded.powerMin, source.powerMin);
      expect(decoded.powerMax, source.powerMax);
      expect(decoded.voltageMin, source.voltageMin);
      expect(decoded.voltageMax, source.voltageMax);
      expect(decoded.currentMax, source.currentMax);
      expect(decoded.frequencyMin, source.frequencyMin);
      expect(decoded.frequencyMax, source.frequencyMax);
      expect(decoded.powerFactorMin, source.powerFactorMin);
      expect(decoded.sampleCount, source.sampleCount);
      expect(decoded.observedSeconds, source.observedSeconds);
      expect(decoded.estimatedIntervals, source.estimatedIntervals);
      expect(decoded.coveragePct, source.coveragePct);
      expect(decoded.quality, EnergyDataQuality.estimated);
      expect(decoded.isDemo, isTrue);
    });

    test('kolom min/max yang null tetap null setelah round trip', () {
      final decoded = EnergyHourly.fromJson(base.toJson());

      expect(decoded.powerMin, isNull);
      expect(decoded.powerMax, isNull);
      expect(decoded.voltageMin, isNull);
      expect(decoded.voltageMax, isNull);
      expect(decoded.currentMax, isNull);
      expect(decoded.frequencyMin, isNull);
      expect(decoded.frequencyMax, isNull);
      expect(decoded.powerFactorMin, isNull);
    });

    test('nilai numerik bertipe int dari Postgres diterima', () {
      final decoded = EnergyHourly.fromJson(<String, dynamic>{
        ...base.toJson(),
        'energy_kwh': 2,
        'observed_seconds': 3600,
        'sample_count': 720,
      });

      expect(decoded.energyKwh, 2.0);
      expect(decoded.observedSeconds, 3600.0);
      expect(decoded.sampleCount, 720);
    });

    test('data_quality di luar enum jatuh ke partial', () {
      final decoded = EnergyHourly.fromJson(<String, dynamic>{
        ...base.toJson(),
        'data_quality': 'entah',
      });

      expect(decoded.quality, EnergyDataQuality.partial);
    });
  });
}
