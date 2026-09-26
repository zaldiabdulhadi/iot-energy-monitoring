import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../models/energy_metric.dart';
import '../models/energy_reading.dart';
import '../services/energy_api_client.dart';
import '../services/energy_recorder.dart';
import '../services/recommendation_engine.dart';

enum DataSource { demo, api }

/// Sumber status realtime dari ESP.
///
/// Isinya hanya enam metrik yang benar-benar dikirim JSON ESP. Tidak ada data
/// per perangkat: JSON itu tidak memuat identitas perangkat sama sekali, jadi
/// memecahnya jadi "AC 0,86 kW" hanya bisa dilakukan dengan mengarang angka.
class EnergyDataProvider extends ChangeNotifier {
  EnergyDataProvider({
    EnergyApiClient? apiClient,
    this.pollInterval = const Duration(seconds: 5),
    this.recorder,
  }) : _apiClient = apiClient ?? EnergyApiClient();

  final EnergyApiClient _apiClient;
  final EnergyRecorder? recorder;
  final Duration pollInterval;

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

  /// Pembacaan terakhir, apa pun sumbernya.
  EnergyReading? get reading => _reading;

  double get voltage => _reading?.voltage ?? 0;
  double get current => _reading?.current ?? 0;

  /// Daya dalam kilowatt. Nama ini dipakai langsung oleh pengujian, jadi
  /// Despite pembacaan di API memakai watt, konversi ke kilowatt tetap di sini.
  double get currentKw => (_reading?.power ?? 0) / 1000;

  /// Register kumulatif meter, bukan konsumsi satu periode.
  ///
  /// Nilai ini bertambah seumur hidup perangkat, jadi tidak boleh dipakai
  /// sebagai "kWh hari ini". Konsumsi per periode datang dari
  /// [EnergyHourly.energyKwh] lewat riwayat.
  double get energyCounter => _reading?.energy ?? 0;

  double get frequency => _reading?.frequency ?? 0;
  double get powerFactor => _reading?.powerFactor ?? 0;

  /// Enam metrik beserta penilaiannya terhadap rentang yang diharapkan.
  ///
  /// Mengembalikan daftar kosong saat belum ada pembacaan, supaya widget bisa
  /// membedakan "belum ada data" dari "data-nya di luar rentang".
  List<MetricReading> get liveMetrics {
    final current = _reading;
    if (current == null) return const [];
    return RecommendationEngine.classifyLive(current);
  }

  /// Metrik yang sedang keluar dari rentang sehat.
  List<MetricReading> get unhealthyMetrics =>
      liveMetrics.where((m) => !m.isHealthy).toList();

  /// True kalau semua metrik berbatas berada di dalam rentangnya.
  bool get isStable {
    final readings = liveMetrics;
    if (readings.isEmpty) return false;
    return !readings.any((m) => m.metric.isBounded && !m.isHealthy);
  }

  // Generator simulasi, hanya hidup di mode demo.
  final _DemoSignal _demo = _DemoSignal(math.Random(7));

  /// Daya dari sampel polling terakhir, untuk grafik singkat di dashboard.
  ///
  /// Berbeda dari riwayat per jam, ini benar-benar data mentah lima menit
  /// terakhir, jadi label grafiknya harus menyebut rentang itu dan bukan
  /// "hari".
  final List<double> _recentPowerKw = <double>[];

  static const int _recentPowerWindow = 60;

  List<double> get recentPowerKw => List.unmodifiable(_recentPowerKw);

  void _trackPower() {
    _recentPowerKw.add(currentKw);
    if (_recentPowerKw.length > _recentPowerWindow) {
      _recentPowerKw.removeAt(0);
    }
  }

  void startDemo() {
    if (_source != DataSource.demo) return;
    _demoTimer ??= Timer.periodic(pollInterval, (_) {
      _tickDemo();
      notifyListeners();
    });
    if (_reading == null) {
      _reading = _demo.sample(DateTime.now());
      _lastUpdated = DateTime.now();
    }
  }

  void _tickDemo() {
    final now = DateTime.now();
    final reading = _demo.sample(now);
    _reading = reading;
    _lastUpdated = now;
    _trackPower();
    recorder?.record(reading, now: now);
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
    _trackPower();
    recorder?.record(reading, now: _lastUpdated);
  }

  Future<void> persistPendingHistory() async {
    await recorder?.flush();
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
    _recentPowerKw.clear();
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

/// Pembangkit pembacaan tiruan untuk mode demo.
///
/// Modelnya memuat satu hari penuh supaya history per jam punya bentuk yang
/// masuk akal: pagi naik, siang tinggi, malam turun. Noise acak murni akan
/// menghasilkan garis yang datar sehingga rekomendasi tidak bermakna.
///
/// Nilainya tetap melewati [EnergyReading] dan [EnergyRecorder] yang sama dengan
/// data ESP, jadi riwayat, analisis, dan rekomendasi bisa didemokan tanpa
/// perangkat keras. Yang membedakan hanya sumbernya, bukan alurnya.
class _DemoSignal {
  _DemoSignal(this._rng);

  final math.Random _rng;

  /// Register kumulatif, ditahan antar sampel supaya `energy` berperilaku
  /// seperti meter sungguhan.
  double _counter = 8.6;

  /// Waktu sampel terakhir, untuk menghitung berapa kWh yang bertambah di
  /// antara dua pembacaan.
  ///
  /// Tanpa ini register-nya tidak pernah maju, dan `computeIntervalEnergy` akan
  /// menganggap setiap interval tidak punya meter yang bergerak sehingga seluruh
  /// riwayat demo ditandai "estimasi".
  DateTime? _lastSampleAt;

  /// Bentuk beban dasar per jam, dalam kilowatt.
  ///
  /// Indeks 0 sampai 23. Puncaknya di jam 19.00 dan titik terendah selepas
  /// tengah malam, seperti rumah tangga pada umumnya.
  static const _dailyShapeKw = <double>[
    0.32, 0.28, 0.26, 0.25, 0.26, 0.32, // 00-05
    0.48, 0.72, 0.86, 0.78, 0.70, 0.74, // 06-11
    0.82, 0.80, 0.76, 0.78, 0.88, 1.05, // 12-17
    1.24, 1.42, 1.38, 1.10, 0.72, 0.45, // 18-23
  ];

  EnergyReading sample(DateTime now) {
    final hour = now.hour;
    final base = _dailyShapeKw[hour];
    final wobble = 1 + (_rng.nextDouble() - 0.5) * 0.16;
    final power = (base * wobble).clamp(0.12, 3.2).toDouble();

    final voltage = (220.4 + (_rng.nextDouble() - 0.5) * 4.4)
        .clamp(208, 232)
        .toDouble();
    final powerFactor = 0.9 + _rng.nextDouble() * 0.09;
    final frequency = 50 + (_rng.nextDouble() - 0.5) * 0.16;

    // Arus dihitung dari S = P / PF. Meter sungguhan sudah memperhitungkan
    // faktor daya saat melaporkan arus, jadi angka di sini harus konsisten
    // dengan daya, tegangan, dan faktor daya yang lain.
    final current = (power * 1000 / (voltage * powerFactor)).clamp(0.0, 32.0);

    // Register maju sebesar daya dikali waktu sejak sampel terakhir. Dijepit
    // supaya lompatan waktu yang panjang, misalnya setelah aplikasi lama
    // tertidur, tidak langsung menambah ratusan kWh.
    final previousAt = _lastSampleAt;
    if (previousAt != null) {
      final raw = now.difference(previousAt);
      final elapsed = raw.isNegative ? Duration.zero : raw;
      final bounded = elapsed > const Duration(seconds: 30)
          ? const Duration(seconds: 30)
          : elapsed;
      _counter += power * (bounded.inMilliseconds / 3600000);
    }
    _lastSampleAt = now;

    return EnergyReading(
      voltage: voltage,
      current: current.toDouble(),
      power: power * 1000,
      energy: _counter,
      frequency: frequency,
      powerFactor: powerFactor,
    );
  }
}
