import 'package:flutter_test/flutter_test.dart';
import 'package:smart_energy/models/energy_hourly.dart';
import 'package:smart_energy/models/energy_metric.dart';
import 'package:smart_energy/models/energy_reading.dart';
import 'package:smart_energy/services/recommendation_engine.dart';

void main() {
  group('satuan metrik', () {
    test('setiap metrik punya kunci JSON yang tersedia di ESP', () {
      // Enam field JSON inilah satu-satunya sumber angka di aplikasi ini.
      expect(
        EnergyMetric.values.map((m) => m.jsonKey).toSet(),
        {'voltage', 'current', 'power', 'energy', 'frequency', 'pf'},
      );
    });

    test('setiap metrik memakai satuan yang sama dengan meter', () {
      // Tidak ada konversi di enum: daya tetap watt, register energi tetap kWh.
      expect(EnergyMetric.power.unit, 'W');
      expect(EnergyMetric.energy.unit, 'kWh');
      expect(EnergyMetric.voltage.unit, 'V');
      expect(EnergyMetric.current.unit, 'A');
      expect(EnergyMetric.frequency.unit, 'Hz');
      expect(EnergyMetric.powerFactor.unit, 'PF');
    });

    test('label rentang menyisakan spasi sebelum satuan', () {
      expect(EnergyMetric.voltage.healthyRangeLabel, '210.0-230.0 V');
      // Faktor daya hanya punya batas bawah.
      expect(EnergyMetric.powerFactor.healthyRangeLabel, '>= 0.9 PF');
    });
  });

  group('klasifikasi batas', () {
    test('nilai di dalam rentang dianggap sehat', () {
      expect(EnergyMetric.voltage.classify(220), MetricStatus.healthy);
      expect(EnergyMetric.voltage.classify(210), MetricStatus.healthy);
      expect(EnergyMetric.voltage.classify(230), MetricStatus.healthy);
      expect(EnergyMetric.frequency.classify(50), MetricStatus.healthy);
      expect(EnergyMetric.powerFactor.classify(0.95), MetricStatus.healthy);
      expect(EnergyMetric.powerFactor.classify(0.9), MetricStatus.healthy);
    });

    test('pelanggaran kecil memberi peringatan, bukan kritis', () {
      // Rentang tegangan 20 V, jadi 5%-nya 1 V: 231 V masih peringatan.
      expect(EnergyMetric.voltage.classify(231), MetricStatus.warning);
      expect(EnergyMetric.frequency.classify(50.32), MetricStatus.warning);
      // Penurunan kecil faktor daya dari 0,9 harus peringatan, bukan kritis.
      // Tanpa toleransi berbasis batas bawah, apa pun di bawah 0,9 akan
      // langsung dilaporkan kritis.
      expect(EnergyMetric.powerFactor.classify(0.86), MetricStatus.warning);
    });

    test('pelanggaran besar naik ke status kritis', () {
      // 232 V melewati 5% dari rentang 20 V.
      expect(EnergyMetric.voltage.classify(232), MetricStatus.critical);
      expect(EnergyMetric.frequency.classify(50.4), MetricStatus.critical);
      expect(EnergyMetric.powerFactor.classify(0.8), MetricStatus.critical);
    });

    test('metrik tanpa ambang selalu sehat', () {
      expect(EnergyMetric.power.classify(0), MetricStatus.healthy);
      expect(EnergyMetric.power.classify(9999), MetricStatus.healthy);
      expect(EnergyMetric.current.classify(0), MetricStatus.healthy);
      expect(EnergyMetric.energy.classify(123456), MetricStatus.healthy);
    });
  });

  group('konversi dari pembacaan langsung', () {
    final reading = EnergyReading(
      voltage: 225,
      current: 3.2,
      power: 1800,
      energy: 4210,
      frequency: 49.9,
      powerFactor: 0.93,
    );

    test('nilai metrik mengikuti satuan yang ditampilkan', () {
      expect(EnergyMetric.power.readLive(reading), 1800);
      expect(EnergyMetric.energy.readLive(reading), 4210);
    });

    test('classifyLive mempertahankan daya dalam watt', () {
      final byMetric = {
        for (final r in RecommendationEngine.classifyLive(reading))
          r.metric: r,
      };

      // 1800 W harus tampil dan dinilai sebagai 1800, bukan 1,8.
      expect(byMetric[EnergyMetric.power]!.value, closeTo(1800, 1e-9));
      expect(byMetric[EnergyMetric.voltage]!.value, closeTo(225, 1e-9));
      expect(byMetric[EnergyMetric.voltage]!.isHealthy, isTrue);
      expect(byMetric[EnergyMetric.frequency]!.isHealthy, isTrue);
    });
  });

  group('agregat per jam', () {
    EnergyHourly hourlyWithPower(double sum, {int samples = 60}) => EnergyHourly(
          deviceKey: 'test',
          hourStart: DateTime(2026, 3, 15),
          powerSum: sum,
          powerMin: sum / samples,
          powerMax: sum / samples,
          voltageSum: 220.0 * samples,
          sampleCount: samples,
        );

    test('rata-rata dan batas daya tetap dalam watt', () {
      // 180.000 W dibagi 60 sampel = 3000 W.
      final hourly = hourlyWithPower(180000);

      expect(EnergyMetric.power.avgOf(hourly), closeTo(3000, 1e-9));
      expect(EnergyMetric.power.minOf(hourly), closeTo(3000, 1e-9));
      expect(EnergyMetric.power.maxOf(hourly), closeTo(3000, 1e-9));
    });

    test('batas yang tidak direkam tetap null, bukan nol', () {
      final hourly = hourlyWithPower(180000);

      expect(EnergyMetric.powerFactor.maxOf(hourly), isNull);
      expect(EnergyMetric.current.minOf(hourly), isNull);
      expect(EnergyMetric.energy.minOf(hourly), isNull);
    });

    test('tracked tidak memuat energi karena energi dijumlahkan', () {
      expect(EnergyMetric.tracked, isNot(contains(EnergyMetric.energy)));
      expect(EnergyMetric.tracked.length, 5);
    });
  });
}
