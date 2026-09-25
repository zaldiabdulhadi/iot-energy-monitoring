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

  double costAt(double tariffPerKwh) => energyKwh * tariffPerKwh;

  double co2At(double gridCo2KgPerKwh) => energyKwh * gridCo2KgPerKwh;

  double _mean(double sum) => sampleCount == 0 ? 0 : sum / sampleCount;
}
