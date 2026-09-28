enum EnergyDataQuality {
  complete('complete'),
  partial('partial'),
  estimated('estimated');

  const EnergyDataQuality(this.wireName);

  final String wireName;

  static EnergyDataQuality fromWire(String? value) {
    return EnergyDataQuality.values.firstWhere(
      (quality) => quality.wireName == value,
      orElse: () => EnergyDataQuality.partial,
    );
  }
}

class EnergyHourly {
  const EnergyHourly({
    required this.deviceKey,
    required this.hourStart,
    this.energyKwh = 0,
    this.powerSum = 0,
    this.powerMin,
    this.powerMax,
    this.voltageSum = 0,
    this.voltageMin,
    this.voltageMax,
    this.currentSum = 0,
    this.currentMax,
    this.frequencySum = 0,
    this.frequencyMin,
    this.frequencyMax,
    this.powerFactorSum = 0,
    this.powerFactorMin,
    this.sampleCount = 0,
    this.observedSeconds = 0,
    this.estimatedIntervals = 0,
    this.coveragePct = 0,
    this.quality = EnergyDataQuality.partial,
  });

  final String deviceKey;
  final DateTime hourStart;
  final double energyKwh;
  final double powerSum;
  final double? powerMin;
  final double? powerMax;
  final double voltageSum;
  final double? voltageMin;
  final double? voltageMax;
  final double currentSum;
  final double? currentMax;
  final double frequencySum;
  final double? frequencyMin;
  final double? frequencyMax;
  final double powerFactorSum;
  final double? powerFactorMin;
  final int sampleCount;
  final double observedSeconds;
  final int estimatedIntervals;
  final double coveragePct;
  final EnergyDataQuality quality;

  bool get isEmpty => sampleCount == 0;

  double get avgPowerW => _mean(powerSum);

  double get avgVoltage => _mean(voltageSum);

  double get avgCurrent => _mean(currentSum);

  double get avgFrequency => _mean(frequencySum);

  double get avgPowerFactor => _mean(powerFactorSum);

  double get estimatedRatio =>
      sampleCount == 0 ? 0 : estimatedIntervals / sampleCount;

  double get averageWattsFromEnergy {
    if (observedSeconds <= 0) return 0;
    return energyKwh / (observedSeconds / 3600) * 1000;
  }

  double co2At(double gridCo2KgPerKwh) => energyKwh * gridCo2KgPerKwh;

  double _mean(double sum) => sampleCount == 0 ? 0 : sum / sampleCount;

  /// Pemetaan ke kolom tabel `energy_hourly` di Postgres.
  ///
  /// Kolom *sync bookkeeping* lokal (`syncState`, `attempts`, `lastError`,
  /// `syncedAt`) sengaja tidak ikut karena itu urusan device, bukan server.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'device_id': deviceKey,
        'hour_start': hourStart.toUtc().toIso8601String(),
        'energy_kwh': energyKwh,
        'power_sum': powerSum,
        'power_min': powerMin,
        'power_max': powerMax,
        'voltage_sum': voltageSum,
        'voltage_min': voltageMin,
        'voltage_max': voltageMax,
        'current_sum': currentSum,
        'current_max': currentMax,
        'frequency_sum': frequencySum,
        'frequency_min': frequencyMin,
        'frequency_max': frequencyMax,
        'power_factor_sum': powerFactorSum,
        'power_factor_min': powerFactorMin,
        'sample_count': sampleCount,
        'observed_seconds': observedSeconds,
        'estimated_intervals': estimatedIntervals,
        'coverage_pct': coveragePct,
        'data_quality': quality.wireName,
      };

  factory EnergyHourly.fromJson(Map<String, dynamic> json) => EnergyHourly(
        deviceKey: json['device_id'] as String,
        hourStart: DateTime.parse(json['hour_start'] as String).toLocal(),
        energyKwh: _readDouble(json['energy_kwh']),
        powerSum: _readDouble(json['power_sum']),
        powerMin: _readNullableDouble(json['power_min']),
        powerMax: _readNullableDouble(json['power_max']),
        voltageSum: _readDouble(json['voltage_sum']),
        voltageMin: _readNullableDouble(json['voltage_min']),
        voltageMax: _readNullableDouble(json['voltage_max']),
        currentSum: _readDouble(json['current_sum']),
        currentMax: _readNullableDouble(json['current_max']),
        frequencySum: _readDouble(json['frequency_sum']),
        frequencyMin: _readNullableDouble(json['frequency_min']),
        frequencyMax: _readNullableDouble(json['frequency_max']),
        powerFactorSum: _readDouble(json['power_factor_sum']),
        powerFactorMin: _readNullableDouble(json['power_factor_min']),
        sampleCount: _readInt(json['sample_count']),
        observedSeconds: _readDouble(json['observed_seconds']),
        estimatedIntervals: _readInt(json['estimated_intervals']),
        coveragePct: _readDouble(json['coverage_pct']),
        quality: EnergyDataQuality.fromWire(json['data_quality'] as String?),
      );

  /// Postgres mengembalikan `double precision` sebagai JSON number, dan nilainya
  /// bisa berupa int maupun double tergantung presisinya. Keduanya diterima.
  static double _readDouble(Object? value) {
    if (value is! num) {
      throw FormatException('Nilai energi harus berupa angka, got $value.');
    }
    return value.toDouble();
  }

  static double? _readNullableDouble(Object? value) =>
      value == null ? null : _readDouble(value);

  static int _readInt(Object? value) {
    if (value is! num) {
      throw FormatException('Nilai jumlah harus berupa angka, got $value.');
    }
    return value.toInt();
  }
}
