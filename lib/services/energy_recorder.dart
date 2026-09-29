import 'dart:async';

import '../data/local/app_database.dart';
import '../data/local/hourly_rollup.dart';
import '../data/local/interval_energy.dart';
import '../models/energy_reading.dart';
import '../utils/bucket_time.dart';

const int kGapToleranceFactor = 3;
const double kMaxObservedSecondsPerMinute = 60;

class EnergyRecorder {
  EnergyRecorder({
    required this.database,
    this.pollInterval = const Duration(seconds: 5),
  });

  final EnergyDatabase database;
  final Duration pollInterval;

  Future<void> _tail = Future<void>.value();
  _MinuteBuffer? _buffer;
  EnergyReading? _previous;
  DateTime? _previousAt;
  String? _deviceKey;

  /// Asal-usul sampel yang terakhir diterima, dipakai mendeteksi perpindahan
  /// antara mode demo dan ESP. Null berarti belum ada sampel sama sekali.
  bool? _lastIsDemo;

  Future<void> record(
    EnergyReading reading, {
    DateTime? now,
    bool isDemo = false,
  }) {
    final timestamp = now ?? DateTime.now();
    return _serialize(() => _record(reading, timestamp, isDemo: isDemo));
  }

  Future<void> flush() => _serialize(_flush);

  Future<int> closeCompletedHours({DateTime? now}) {
    final timestamp = now ?? DateTime.now();
    return _serialize(() => _closeCompletedHours(timestamp));
  }

  /// Membuang semua state yang menempel pada satu perangkat.
  ///
  /// [_deviceKey] ikut dikosongkan karena device itu hasil baca database dan
  /// sudah di-memois: tanpa itu, rekaman setelah pengguna mengganti meter
  /// masih ditulis memakai identitas perangkat lama.
  void reset() {
    _buffer = null;
    _previous = null;
    _previousAt = null;
    _lastIsDemo = null;
    _deviceKey = null;
  }

  Future<T> _serialize<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _tail = _tail
        .then((_) => action().then(completer.complete, onError: completer.completeError))
        .catchError((Object _) {});
    return completer.future;
  }

  Future<void> _record(
    EnergyReading reading,
    DateTime timestamp, {
    bool isDemo = false,
  }) async {
    final deviceKey = await _device();
    final minuteStart = floorToMinute(timestamp);

    if (_buffer != null && _buffer!.minuteStart != minuteStart) {
      await _persistBuffer(deviceKey);
      await _closeCompletedHours(timestamp);
    }

    // Satu menit tidak bisa menyimpan dua asal-usul sekaligus: kunci utamanya
    // hanya `(device_key, minute_start)`, jadi memecah buffer saat pergantian
    // mode hanya akan membuat penulisan kedua menimpa yang pertama. Aturannya
    // satu menit sekali tercemar simulasi menjadi simulasi, dan penandanya tidak
    // pernah turun lagi. Ini juga alasan `upsertMinute` menjaga `is_demo`
    // secara monoton.
    //
    // Yang tetap perlu dipotong adalah `_previous`: energi interval antara dua
    // sampel berbeda asal-usul tidak bermakna, jadi sampel pertama setelah
    // perpindahan hanya menyumbang tegangan, arus, dan daya.
    if (_lastIsDemo != isDemo) {
      _previous = null;
      _previousAt = null;
      _lastIsDemo = isDemo;
    }

    var intervalKwh = 0.0;
    var meterUsable = true;
    var observedDelta = 0.0;

    final previous = _previous;
    final previousAt = _previousAt;
    if (previous != null && previousAt != null) {
      final elapsed = timestamp.difference(previousAt);
      final maxGap = pollInterval * kGapToleranceFactor;
      if (elapsed > Duration.zero && elapsed <= maxGap) {
        final result = computeIntervalEnergy(previous, reading, elapsed);
        intervalKwh = result.kwh;
        meterUsable = result.meterUsable;
        observedDelta = elapsed.inMilliseconds / 1000;
      }
    }

    final existing = _buffer;
    final buffer = existing != null && existing.minuteStart == minuteStart
        ? existing
        : (_buffer = _MinuteBuffer(minuteStart));
    if (isDemo) buffer.isDemo = true;
    buffer.add(
      reading,
      intervalKwh: intervalKwh,
      meterUsable: meterUsable,
      observedDelta: observedDelta,
    );

    _previous = reading;
    _previousAt = timestamp;
  }

  Future<void> _flush() async {
    final buffer = _buffer;
    if (buffer == null || buffer.sampleCount == 0) return;
    final deviceKey = await _device();
    await _persistBuffer(deviceKey);
  }

  Future<int> _closeCompletedHours(DateTime timestamp) async {
    final deviceKey = await _device();
    final currentHour = floorToHour(timestamp);
    final buckets = await database.hourBucketsBefore(deviceKey, currentHour);

    var closed = 0;
    for (final bucket in buckets) {
      final rows = await database.minutesForHour(deviceKey, bucket);
      if (rows.isEmpty) continue;
      final hourly = rollupMinutes(
        deviceKey: deviceKey,
        hourStart: bucket,
        rows: rows,
      );
      // Dua tujuan dengan umur berbeda: antrean untuk diunggah ke Supabase dan
      // riwayat permanen untuk dianalisis di aplikasi. Keduanya idempotent, jadi
      // jam yang ter-rollup dua kali hanya memperbarui nilainya.
      await database.upsertHourly(hourly: hourly, now: timestamp);
      await database.upsertHistory(hourly: hourly, now: timestamp);
      await database.deleteMinutesForHour(deviceKey, bucket);
      closed += 1;
    }
    return closed;
  }

  Future<void> _persistBuffer(String deviceKey) async {
    final buffer = _buffer;
    if (buffer == null || buffer.sampleCount == 0) {
      _buffer = null;
      return;
    }
    await database.upsertMinute(buffer.toRow(deviceKey));
    _buffer = null;
    _lastIsDemo = buffer.isDemo;
  }

  Future<String> _device() async {
    return _deviceKey ??= (await database.ensureLocalDevice()).localId;
  }
}

class _MinuteBuffer {
  _MinuteBuffer(this.minuteStart);

  final DateTime minuteStart;

  /// Dinaikkan, tidak pernah diturunkan: satu sampel simulasi sudah cukup
  /// untuk membuat seluruh menit ini ditandai sebagai simulasi.
  bool isDemo = false;

  double energyKwh = 0;
  double powerSum = 0;
  double voltageSum = 0;
  double currentSum = 0;
  double frequencySum = 0;
  double powerFactorSum = 0;
  double? powerMin;
  double? powerMax;
  double? voltageMin;
  double? voltageMax;
  double? currentMax;
  double? frequencyMin;
  double? frequencyMax;
  double? powerFactorMin;
  int sampleCount = 0;
  double observedSeconds = 0;
  int estimatedIntervals = 0;

  void add(
    EnergyReading reading, {
    required double intervalKwh,
    required bool meterUsable,
    required double observedDelta,
  }) {
    energyKwh += intervalKwh;
    powerSum += reading.power;
    voltageSum += reading.voltage;
    currentSum += reading.current;
    frequencySum += reading.frequency;
    powerFactorSum += reading.powerFactor;
    powerMin = _lower(powerMin, reading.power);
    powerMax = _higher(powerMax, reading.power);
    voltageMin = _lower(voltageMin, reading.voltage);
    voltageMax = _higher(voltageMax, reading.voltage);
    currentMax = _higher(currentMax, reading.current);
    frequencyMin = _lower(frequencyMin, reading.frequency);
    frequencyMax = _higher(frequencyMax, reading.frequency);
    powerFactorMin = _lower(powerFactorMin, reading.powerFactor);
    sampleCount += 1;
    observedSeconds = (observedSeconds + observedDelta)
        .clamp(0.0, kMaxObservedSecondsPerMinute);
    if (!meterUsable && intervalKwh > 0) {
      estimatedIntervals += 1;
    }
  }

  MinuteAggregateRow toRow(String deviceKey) => MinuteAggregateRow(
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
        isDemo: isDemo,
      );
}

double? _lower(double? current, double candidate) =>
    current == null || candidate < current ? candidate : current;

double? _higher(double? current, double candidate) =>
    current == null || candidate > current ? candidate : current;
