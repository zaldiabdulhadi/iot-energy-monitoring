import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../models/energy_device.dart';
import '../models/energy_reading.dart';
import '../services/energy_api_client.dart';
import '../services/energy_recorder.dart';

enum DataSource { demo, api }

class EnergyDataProvider extends ChangeNotifier {
  EnergyDataProvider({
    EnergyApiClient? apiClient,
    this.pollInterval = const Duration(seconds: 5),
    this.recorder,
  }) : _apiClient = apiClient ?? EnergyApiClient();

  final EnergyApiClient _apiClient;
  final EnergyRecorder? recorder;
  final Duration pollInterval;
  final math.Random _rng = math.Random(42);

  Timer? _demoTimer;
  Timer? _pollTimer;
  bool _pollInFlight = false;

  /// Dipakai untuk menahan notifyListeners setelah dispose(), karena permintaan
  /// yang sudah berjalan tidak ikut terhenti oleh pembatalan timer.
  bool _disposed = false;
  DataSource _source = DataSource.demo;
  DataSource get source => _source;

  EnergyReading? _reading;
  Uri? _endpoint;

  bool _connected = false;
  bool get connected => _connected;

  bool _connecting = false;
  bool get connecting => _connecting;

  String? _error;
  String? get error => _error;

  Uri? _connectedEndpoint;
  Uri? get connectedEndpoint => _connectedEndpoint;

  Uri? get endpoint => _endpoint;

  DateTime? _connectedSince;
  DateTime? get connectedSince => _connectedSince;

  DateTime? _lastUpdated;
  DateTime? get lastUpdated => _lastUpdated;

  bool get demoMode => _source == DataSource.demo;

  double _demoKw = 1.24;
  double _voltage = 220.4;
  double _frequency = 50.02;
  double _powerFactor = 0.94;
  double _energyKwh = 8.6;
  double _demoSolarKw = 1.86;
  double _peakKw = 2.1;

  final List<double> _usageHistory = <double>[
    0.42,
    0.38,
    0.35,
    0.33,
    0.34,
    0.40,
    0.55,
    0.72,
    0.68,
    0.61,
    0.58,
    0.64,
    0.95,
    1.10,
    1.05,
    0.98,
    0.90,
    0.84,
    0.88,
    1.02,
    1.24,
    1.10,
    0.82,
    0.56,
  ];

  final List<EnergyDevice> _devices = EnergyDevice.seedData
      .map((device) => device.copyWith())
      .toList();
  List<EnergyDevice> get devices => List.unmodifiable(_devices);

  List<double> get usageHistory => List.unmodifiable(_usageHistory);

  double get currentKw => _source == DataSource.api && _reading != null
      ? _reading!.power / 1000
      : _demoKw;
  double get voltage => _source == DataSource.api && _reading != null
      ? _reading!.voltage
      : _voltage;
  double get current => _source == DataSource.api && _reading != null
      ? _reading!.current
      : currentKw * 1000 / voltage;
  double get energyToday => _source == DataSource.api && _reading != null
      ? _reading!.energy
      : _energyKwh;
  double get frequency => _source == DataSource.api && _reading != null
      ? _reading!.frequency
      : _frequency;
  double get powerFactor => _source == DataSource.api && _reading != null
      ? _reading!.powerFactor
      : _powerFactor;
  double get solarKw => _source == DataSource.api ? 0 : _demoSolarKw;
  double get peakToday => math.max(_peakKw, currentKw);

  bool get isStable =>
      powerFactor >= 0.9 &&
      voltage >= 210 &&
      voltage <= 230 &&
      frequency >= 49.5 &&
      frequency <= 50.5;

  void startDemo() {
    if (_source != DataSource.demo) return;
    _demoTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      _tickDemo();
      notifyListeners();
    });
  }

  void _tickDemo() {
    _demoKw = (_demoKw + (_rng.nextDouble() - 0.5) * 0.16)
        .clamp(0.5, 2.8)
        .toDouble();
    _voltage = (220.4 + (_rng.nextDouble() - 0.5) * 4.8)
        .clamp(212, 229)
        .toDouble();
    _frequency = 50 + (_rng.nextDouble() - 0.5) * 0.1;
    _powerFactor = 0.93 + _rng.nextDouble() * 0.04;
    _energyKwh += _demoKw * (1 / 3600);
    _demoSolarKw =
        (1.2 + math.sin(DateTime.now().millisecondsSinceEpoch / 60000) * 0.7)
            .clamp(0.2, 2.4)
            .toDouble();

    _pushHistory();
    _syncDevicePowers();
  }

  void _pushHistory() {
    _usageHistory.add(currentKw);
    if (_usageHistory.length > 24) {
      _usageHistory.removeAt(0);
    }
    if (currentKw > _peakKw) _peakKw = currentKw;
  }

  void _syncDevicePowers() {
    const baseByDevice = {
      'dev_01': 0.042,
      'dev_02': 0.30,
      'dev_03': 0.18,
      'dev_05': 0.42,
    };

    final totalBase = _devices
        .where((device) => device.isOn)
        .fold(0.0, (sum, device) => sum + (baseByDevice[device.id] ?? 0));

    final factor = totalBase > 0
        ? (currentKw / totalBase).clamp(0.3, 2.2)
        : 1.0;

    for (var i = 0; i < _devices.length; i++) {
      final device = _devices[i];
      if (device.id == 'dev_06') {
        _devices[i] = device.copyWith(isOn: true, powerDrawKw: -solarKw);
        continue;
      }
      if (!device.isOn) {
        _devices[i] = device.copyWith(powerDrawKw: 0);
        continue;
      }
      final base = baseByDevice[device.id] ?? 0.02;
      final noise = 1 + (_rng.nextDouble() - 0.5) * 0.1;
      _devices[i] = device.copyWith(
        powerDrawKw: (base * factor * noise).clamp(0.0, 3.0),
      );
    }
  }

  Future<void> connect({Uri? endpoint}) async {
    if (_connecting) return;

    final target = endpoint ?? _endpoint ?? EnergyApiClient.defaultEndpoint;
    if (_connected || _pollTimer != null) {
      await disconnect();
    }

    _connecting = true;
    _error = null;
    _endpoint = target;
    notifyListeners();

    try {
      final reading = await _apiClient.fetch(target);
      _source = DataSource.api;
      _applyReading(reading);
      _connected = true;
      _connectedEndpoint = target;
      _connectedSince = DateTime.now();
      _demoTimer?.cancel();
      _demoTimer = null;
      _startPolling();
    } on EnergyApiException catch (error) {
      _connected = false;
      _connectedEndpoint = null;
      _connectedSince = null;
      _error = error.message;
    } catch (_) {
      _connected = false;
      _connectedEndpoint = null;
      _connectedSince = null;
      _error = 'Terjadi kesalahan saat membaca API ESP.';
    } finally {
      _connecting = false;
      notifyListeners();
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(pollInterval, (_) => _poll());
  }

  Future<void> _poll() async {
    if (_pollInFlight || _source != DataSource.api || _endpoint == null) {
      return;
    }
    _pollInFlight = true;

    try {
      final reading = await _apiClient.fetch(_endpoint!);
      if (_disposed) return;
      _applyReading(reading);
      _connected = true;
      _connectedEndpoint = _endpoint;
      _error = null;
      _connectedSince ??= DateTime.now();
    } on EnergyApiException catch (error) {
      if (_disposed) return;
      _connected = false;
      _connectedEndpoint = null;
      _connectedSince = null;
      _error = error.message;
    } catch (_) {
      if (_disposed) return;
      _connected = false;
      _connectedEndpoint = null;
      _connectedSince = null;
      _error = 'Terjadi kesalahan saat memperbarui data API ESP.';
    } finally {
      _pollInFlight = false;
      // Pembatalan timer tidak menghentikan permintaan yang sedang berjalan,
      // jadi blok ini tetap bisa selesai setelah dispose() dipanggil.
      if (!_disposed) notifyListeners();
    }
  }

  void _applyReading(EnergyReading reading) {
    _reading = reading;
    _lastUpdated = DateTime.now();
    _pushHistory();
    _syncDevicePowers();
    recorder?.record(reading, now: _lastUpdated);
  }

  Future<void> persistPendingHistory() async {
    await recorder?.flush();
  }

  void setDeviceOn(String id, bool value) {
    final index = _devices.indexWhere((device) => device.id == id);
    if (index == -1) return;
    _devices[index] = _devices[index].copyWith(isOn: value);
    _syncDevicePowers();
    notifyListeners();
  }

  Future<void> disconnect() async {
    await persistPendingHistory();
    recorder?.reset();
    _pollTimer?.cancel();
    _pollTimer = null;
    _pollInFlight = false;
    _connected = false;
    _connecting = false;
    _connectedEndpoint = null;
    _connectedSince = null;
    _lastUpdated = null;
    _reading = null;
    _endpoint = null;
    _error = null;
    _source = DataSource.demo;
    startDemo();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _demoTimer?.cancel();
    _pollTimer?.cancel();
    _apiClient.close();
    super.dispose();
  }
}
