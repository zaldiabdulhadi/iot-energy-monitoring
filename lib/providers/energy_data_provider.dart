import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../config/energy_topics.dart';
import '../models/energy_device.dart';
import '../services/mqtt_client_factory.dart';
import '../services/mqtt_connection.dart';

/// Sumber data aktif saat ini.
enum DataSource { demo, mqtt }

/// Sumber data energi realtime.
///
/// - Mode [DataSource.demo]: simulasi dummy berjalan otomatis (timer 1 detik)
///   sehingga UI langsung terlihat hidup tanpa broker.
/// - Mode [DataSource.mqtt]: nilai dibaca dari topic MQTT (PZEM-004T).
///   Nilai yang belum tersedia di broker otomatis di-*fallback* ke nilai
///   simulasi terakhir, jadi layar tidak pernah kosong saat connect.
class EnergyDataProvider extends ChangeNotifier {
  MqttConnection? _connection;
  StreamSubscription<Map<String, String>>? _dataSub;
  Timer? _demoTimer;

  DataSource _source = DataSource.demo;
  DataSource get source => _source;

  bool _connected = false;
  bool get connected => _connected;

  bool _connecting = false;
  bool get connecting => _connecting;

  String? _error;
  String? get error => _error;

  String? _connectedHost;
  String? get connectedHost => _connectedHost;

  DateTime? _connectedSince;
  DateTime? get connectedSince => _connectedSince;

  bool get demoMode => _source == DataSource.demo;

  final math.Random _rng = math.Random(42);

  double _demoKw = 1.24;
  double _voltage = 220.4;
  double _frequency = 50.02;
  double _powerFactor = 0.94;
  double _energyKwh = 8.6;
  double _solarKw = 1.86;
  double _peakKw = 2.1;

  final Map<String, String> _mqttValues = {};
  final List<double> _usageHistory = <double>[0.42, 0.38, 0.35, 0.33, 0.34, 0.40, 0.55, 0.72, 0.68, 0.61, 0.58, 0.64, 0.95, 1.10, 1.05, 0.98, 0.90, 0.84, 0.88, 1.02, 1.24, 1.10, 0.82, 0.56];

  final List<EnergyDevice> _devices = EnergyDevice.seedData.map((d) => d.copyWith()).toList();
  List<EnergyDevice> get devices => List.unmodifiable(_devices);

  List<double> get usageHistory => List.unmodifiable(_usageHistory);

  double get currentKw => _liveOrDemo(EnergyTopics.power, _demoKw, scale: 1 / 1000);
  double get voltage => _liveOrDemo(EnergyTopics.voltage, _voltage);
  double get current => _liveOrDemo(EnergyTopics.current, currentKw * 1000 / voltage, scale: 1);
  double get energyToday => _liveOrDemo(EnergyTopics.energy, _energyKwh);
  double get frequency => _liveOrDemo(EnergyTopics.frequency, _frequency);
  double get powerFactor => _liveOrDemo(EnergyTopics.powerFactor, _powerFactor);
  double get solarKw => _liveOrDemo(EnergyTopics.solarPower, _solarKw, scale: 1 / 1000);
  double get peakToday => math.max(_peakKw, currentKw);

  bool get isStable =>
      powerFactor >= 0.9 &&
      voltage >= 210 &&
      voltage <= 230 &&
      frequency >= 49.5 &&
      frequency <= 50.5;

  double _liveOrDemo(String topic, double demoValue, {double scale = 1}) {
    final raw = _mqttValues[topic];
    if (raw != null) {
      final parsed = double.tryParse(raw);
      if (parsed != null) return parsed * scale;
    }
    return demoValue;
  }

  /// Memulai simulasi dummy. Dipanggil sekali saat app dibuka.
  void startDemo() {
    _demoTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      _tickDemo();
      notifyListeners();
    });
  }

  void _tickDemo() {
    _demoKw = (_demoKw + (_rng.nextDouble() - 0.5) * 0.16)
        .clamp(0.5, 2.8)
        .toDouble();
    _voltage = (220.4 + (_rng.nextDouble() - 0.5) * 4.8).clamp(212, 229).toDouble();
    _frequency = 50 + (_rng.nextDouble() - 0.5) * 0.1;
    _powerFactor = 0.93 + _rng.nextDouble() * 0.04;
    _energyKwh += _demoKw * (1 / 3600);
    _solarKw = (1.2 + math.sin(DateTime.now().millisecondsSinceEpoch / 60000) * 0.7)
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
        .where((d) => d.isOn)
        .fold(0.0, (sum, d) => sum + (baseByDevice[d.id] ?? 0));

    final reference = _source == DataSource.demo ? _demoKw : currentKw;
    final factor = totalBase > 0 ? (reference / totalBase).clamp(0.3, 2.2) : 1.0;

    for (var i = 0; i < _devices.length; i++) {
      final d = _devices[i];
      if (d.id == 'dev_06') {
        _devices[i] = d.copyWith(
          isOn: true,
          powerDrawKw: -solarKw,
        );
        continue;
      }
      if (!d.isOn) {
        _devices[i] = d.copyWith(powerDrawKw: 0);
        continue;
      }
      final base = baseByDevice[d.id] ?? 0.02;
      final noise = 1 + (_rng.nextDouble() - 0.5) * 0.1;
      _devices[i] = d.copyWith(
        powerDrawKw: (base * factor * noise).clamp(0.0, 3.0),
      );
    }
  }

  Future<void> connect({
    required String host,
    required int port,
    required String username,
    required String password,
  }) async {
    if (_connecting) return;

    if (_connected) {
      await disconnect();
    }

    _connecting = true;
    _error = null;
    notifyListeners();

    _connection = createMqttConnection();
    _dataSub = _connection!.dataStream.listen((latest) {
      _applyLatest(latest);
    });

    await _connection!.connect(
      host: host,
      port: port,
      username: username,
      password: password,
    );

    _connected = _connection!.connected;
    _connecting = false;
    _error = _connection!.lastError;

    if (_connected) {
      _source = DataSource.mqtt;
      _connectedHost = host;
      _connectedSince = DateTime.now();
    } else {
      _connection = null;
    }
    notifyListeners();
  }

  void _applyLatest(Map<String, String> latest) {
    for (final topic in EnergyTopics.all) {
      final raw = latest[topic];
      if (raw == null || raw == '--') continue;
      final parsed = double.tryParse(raw);
      if (parsed != null) {
        _mqttValues[topic] = raw;
      }
    }
    _pushHistory();
    _syncDevicePowers();
    notifyListeners();
  }

  void setDeviceOn(String id, bool value) {
    final index = _devices.indexWhere((d) => d.id == id);
    if (index == -1) return;
    _devices[index] = _devices[index].copyWith(isOn: value);
    _syncDevicePowers();
    notifyListeners();
  }

  Future<void> disconnect() async {
    await _dataSub?.cancel();
    _dataSub = null;
    if (_connection != null) {
      await _connection!.disconnect();
      _connection = null;
    }
    _connected = false;
    _connecting = false;
    _connectedHost = null;
    _connectedSince = null;
    _source = DataSource.demo;
    _mqttValues.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _demoTimer?.cancel();
    _demoTimer = null;
    _dataSub?.cancel();
    _connection?.disconnect();
    super.dispose();
  }
}