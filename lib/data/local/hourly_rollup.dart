import '../../models/energy_hourly.dart';
import 'app_database.dart';

const double kSecondsPerHour = 3600;
const double kCompleteCoveragePct = 95;
const double kEstimatedRatioThreshold = 0.5;

EnergyHourly rollupMinutes({
  required String deviceKey,
  required DateTime hourStart,
  required List<MinuteAggregateRow> rows,
}) {
  var energyKwh = 0.0;
  var powerSum = 0.0;
  var voltageSum = 0.0;
  var currentSum = 0.0;
  var frequencySum = 0.0;
  var powerFactorSum = 0.0;
  var sampleCount = 0;
  var observedSeconds = 0.0;
  var estimatedIntervals = 0;

  double? powerMin;
  double? powerMax;
  double? voltageMin;
  double? voltageMax;
  double? currentMax;
  double? frequencyMin;
  double? frequencyMax;
  double? powerFactorMin;

  for (final row in rows) {
    energyKwh += row.energyKwh;
    powerSum += row.powerSum;
    voltageSum += row.voltageSum;
    currentSum += row.currentSum;
    frequencySum += row.frequencySum;
    powerFactorSum += row.powerFactorSum;
    sampleCount += row.sampleCount;
    observedSeconds += row.observedSeconds;
    estimatedIntervals += row.estimatedIntervals;

    powerMin = _lower(powerMin, row.powerMin);
    powerMax = _higher(powerMax, row.powerMax);
    voltageMin = _lower(voltageMin, row.voltageMin);
    voltageMax = _higher(voltageMax, row.voltageMax);
    currentMax = _higher(currentMax, row.currentMax);
    frequencyMin = _lower(frequencyMin, row.frequencyMin);
    frequencyMax = _higher(frequencyMax, row.frequencyMax);
    powerFactorMin = _lower(powerFactorMin, row.powerFactorMin);
  }

  final observed = observedSeconds.clamp(0.0, kSecondsPerHour);
  final coveragePct = observed / kSecondsPerHour * 100;
  final estimatedRatio =
      sampleCount == 0 ? 0.0 : estimatedIntervals / sampleCount;

  final quality = estimatedRatio > kEstimatedRatioThreshold
      ? EnergyDataQuality.estimated
      : coveragePct >= kCompleteCoveragePct
          ? EnergyDataQuality.complete
          : EnergyDataQuality.partial;

  return EnergyHourly(
    deviceKey: deviceKey,
    hourStart: hourStart,
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
    observedSeconds: observed,
    estimatedIntervals: estimatedIntervals,
    coveragePct: coveragePct,
    quality: quality,
  );
}

double? _lower(double? current, double? candidate) {
  if (candidate == null) return current;
  if (current == null) return candidate;
  return candidate < current ? candidate : current;
}

double? _higher(double? current, double? candidate) {
  if (candidate == null) return current;
  if (current == null) return candidate;
  return candidate > current ? candidate : current;
}
