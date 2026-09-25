class EnergyReading {
  const EnergyReading({
    required this.voltage,
    required this.current,
    required this.power,
    required this.energy,
    required this.frequency,
    required this.powerFactor,
  });

  factory EnergyReading.fromJson(Map<String, dynamic> json) {
    final powerFactor = _readNumber(json, 'pf');
    if (powerFactor < 0 || powerFactor > 1) {
      throw const FormatException('Nilai pf harus berada di antara 0 dan 1.');
    }

    return EnergyReading(
      voltage: _readNumber(json, 'voltage'),
      current: _readNumber(json, 'current'),
      power: _readNumber(json, 'power'),
      energy: _readNumber(json, 'energy'),
      frequency: _readNumber(json, 'frequency'),
      powerFactor: powerFactor,
    );
  }

  final double voltage;
  final double current;
  final double power;
  final double energy;
  final double frequency;
  final double powerFactor;

  static double _readNumber(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! num || !value.toDouble().isFinite) {
      throw FormatException('Field $key harus berupa angka.');
    }
    return value.toDouble();
  }
}
