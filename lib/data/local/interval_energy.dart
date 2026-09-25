import '../../models/energy_reading.dart';

const double kMeterToleranceFactor = 20;
const double kMeterSlackKwh = 0.005;

class IntervalEnergy {
  const IntervalEnergy({required this.kwh, required this.meterUsable});

  final double kwh;
  final bool meterUsable;
}

IntervalEnergy computeIntervalEnergy(
  EnergyReading previous,
  EnergyReading current,
  Duration elapsed, {
  double toleranceFactor = kMeterToleranceFactor,
  double slackKwh = kMeterSlackKwh,
}) {
  final hours = elapsed.inMicroseconds / Duration.microsecondsPerHour;
  final integrated =
      ((previous.power + current.power) / 2 / 1000) * hours;
  final delta = current.energy - previous.energy;

  final withinTolerance = delta > 0 && delta <= integrated * toleranceFactor + slackKwh;
  if (withinTolerance) {
    return IntervalEnergy(kwh: delta, meterUsable: true);
  }
  return IntervalEnergy(kwh: integrated, meterUsable: false);
}
