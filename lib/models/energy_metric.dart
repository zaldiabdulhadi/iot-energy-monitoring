import 'package:flutter/material.dart';

import 'energy_hourly.dart';
import 'energy_reading.dart';

/// Hasil penilaian satu metrik terhadap rentang yang diharapkan.
enum MetricStatus {
  healthy('Normal'),
  warning('Perhatian'),
  critical('Di luar rentang');

  const MetricStatus(this.label);

  final String label;
}

/// Enam metrik yang dikirim ESP, lengkap dengan definisi tampilannya.
///
/// Ini satu-satunya sumber kebenaran tentang field JSON yang dipakai aplikasi.
/// Layar tidak boleh mendefinisikan label, satuan, pembulatan, atau rentang
/// sehat sendiri: begitu suatu angka didefinisikan di dua tempat, salah satunya
/// pasti akan basi.
enum EnergyMetric {
  voltage(
    jsonKey: 'voltage',
    label: 'Tegangan',
    unit: 'V',
    icon: Icons.bolt_rounded,
    decimals: 1,
    healthyLow: 210,
    healthyHigh: 230,
  ),
  current(
    jsonKey: 'current',
    label: 'Arus',
    unit: 'A',
    icon: Icons.waves_rounded,
    decimals: 2,
  ),
  power(
    jsonKey: 'power',
    label: 'Daya',
    // Meter sudah melaporkan watt, jadi satuan tampil ikut watt tanpa konversi.
    unit: 'W',
    icon: Icons.electric_meter_rounded,
    decimals: 1,
  ),
  energy(
    jsonKey: 'energy',
    label: 'Energi',
    unit: 'kWh',
    icon: Icons.energy_savings_leaf_rounded,
    decimals: 2,
  ),
  frequency(
    jsonKey: 'frequency',
    label: 'Frekuensi',
    unit: 'Hz',
    icon: Icons.speed_rounded,
    decimals: 2,
    healthyLow: 49.7,
    healthyHigh: 50.3,
  ),
  powerFactor(
    jsonKey: 'pf',
    label: 'Faktor daya',
    unit: 'PF',
    icon: Icons.tune_rounded,
    decimals: 2,
    healthyLow: 0.9,
  );

  const EnergyMetric({
    required this.jsonKey,
    required this.label,
    required this.unit,
    required this.icon,
    required this.decimals,
    this.healthyLow,
    this.healthyHigh,
  });

  /// Nama field di JSON ESP. Hanya faktor daya yang berbeda: `pf`.
  final String jsonKey;
  final String label;
  final String unit;
  final IconData icon;

  /// Digit setelah koma untuk format angka.
  final int decimals;

  /// Batas bawah rentang sehat, null berarti tidak dievaluasi.
  final double? healthyLow;

  /// Batas atas rentang sehat, null berarti tidak dievaluasi.
  final double? healthyHigh;

  bool get isBounded => healthyLow != null || healthyHigh != null;

  /// Deskripsi rentang untuk UI, null kalau metrik ini tidak punya batas.
  String? get healthyRangeLabel {
    final low = healthyLow;
    final high = healthyHigh;
    if (low == null && high == null) return null;
    if (low != null && high != null) {
      return '$low-$high $unit';
    }
    if (high != null) return '<= $high $unit';
    return '>= ${low!} $unit';
  }

  /// Menilai satu nilai metrik dalam satuan tampil.
  ///
  /// Batas yang dilampaui sedikit masih dianggap [MetricStatus.warning] supaya
  /// pengguna melihat tren mendekat batas sebelum benar-benar keluar. Hanya
  /// pelanggaran lebih dari 5% dari rentang yang naik ke
  /// [MetricStatus.critical].
  MetricStatus classify(double value) {
    final low = healthyLow;
    final high = healthyHigh;
    if (low == null && high == null) return MetricStatus.healthy;

    if (low != null && value < low) {
      // Metrik yang hanya punya batas bawah, seperti faktor daya, tidak punya
      // [healthyHigh] untuk diturunkan rentangnya. Memakai batas bawahnya
      // sendiri sebagai rentang membuat aturan 5% berarti "5% dari batas":
      // faktor daya 0,86 masih peringatan, 0,85 ke bawah sudah kritis.
      final span = high != null ? high - low : low;
      return (low - value) / (span <= 0 ? 1 : span) > 0.05
          ? MetricStatus.critical
          : MetricStatus.warning;
    }
    if (high != null && value > high) {
      final span = high - (low ?? 0);
      return (value - high) / (span <= 0 ? 1 : span) > 0.05
          ? MetricStatus.critical
          : MetricStatus.warning;
    }
    return MetricStatus.healthy;
  }

  /// Nilai metrik ini dari satu pembacaan langsung ESP.
  double readLive(EnergyReading reading) => switch (this) {
        EnergyMetric.voltage => reading.voltage,
        EnergyMetric.current => reading.current,
        EnergyMetric.power => reading.power,
        EnergyMetric.energy => reading.energy,
        EnergyMetric.frequency => reading.frequency,
        EnergyMetric.powerFactor => reading.powerFactor,
      };

  /// Rata-rata metrik ini pada satu agregat per jam, dalam satuan tampil.
  ///
  /// [EnergyHourly] sudah menyimpan daya dalam watt, sama dengan satuan metrik
  /// ini, jadi tidak ada konversi lagi di sini.
  double avgOf(EnergyHourly hourly) => switch (this) {
        EnergyMetric.voltage => hourly.avgVoltage,
        EnergyMetric.current => hourly.avgCurrent,
        EnergyMetric.power => hourly.avgPowerW,
        EnergyMetric.frequency => hourly.avgFrequency,
        EnergyMetric.powerFactor => hourly.avgPowerFactor,
        // Energi adalah akumulator, bukan rata-rata. Rata-ratanya tidak
        // bermakna, jadi pemanggil harus memakai [EnergyHourly.energyKwh].
        EnergyMetric.energy => hourly.energyKwh,
      };

  /// Batas bawah metrik ini pada satu jam, null kalau tidak direkam.
  ///
  /// Arus hanya menyimpan maksimum di tabel, dan faktor daya hanya menyimpan
  /// minimum, jadi untuk keduanya nilai pasangannya memang tidak ada. UI harus
  /// menampilkan rentang setengah jadi, bukan mengarang angka.
  double? minOf(EnergyHourly hourly) => switch (this) {
        EnergyMetric.voltage => hourly.voltageMin,
        EnergyMetric.current => null,
        EnergyMetric.power => hourly.powerMin,
        EnergyMetric.frequency => hourly.frequencyMin,
        EnergyMetric.powerFactor => hourly.powerFactorMin,
        EnergyMetric.energy => null,
      };

  /// Batas atas metrik ini pada satu jam, null kalau tidak direkam.
  double? maxOf(EnergyHourly hourly) => switch (this) {
        EnergyMetric.voltage => hourly.voltageMax,
        EnergyMetric.current => hourly.currentMax,
        EnergyMetric.power => hourly.powerMax,
        EnergyMetric.frequency => hourly.frequencyMax,
        EnergyMetric.powerFactor => null,
        EnergyMetric.energy => null,
      };

  /// Metrik yang punya bentuk rata-rata per jam, yaitu semua kecuali energi.
  ///
  /// Energi dijumlahkan, bukan dirata-ratakan, jadi tidak punya "rata-rata per
  /// jam" yang bisa ditampilkan di tabel parameter.
  static List<EnergyMetric> get tracked => const [
        EnergyMetric.voltage,
        EnergyMetric.current,
        EnergyMetric.power,
        EnergyMetric.frequency,
        EnergyMetric.powerFactor,
      ];
}

/// Satu metrik lengkap dengan nilai dan penilaiannya.
///
/// Dipakai provider supaya UI bisa merender grid metrik tanpa mengetahui apa pun
/// tentang ambang batas: daftar metrik dan statusnya sudah dihitung di satu
/// tempat.
class MetricReading {
  const MetricReading({
    required this.metric,
    required this.value,
    required this.status,
  });

  final EnergyMetric metric;

  /// Nilai dalam satuan tampil, jadi daya sudah dalam watt.
  final double value;
  final MetricStatus status;

  bool get isHealthy => status == MetricStatus.healthy;
}
