import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../data/local/app_database.dart';
import '../models/energy_metric.dart';
import '../models/energy_reading.dart';
import '../services/energy_api_client.dart';
import '../services/energy_history_backfill.dart';
import '../services/energy_recorder.dart';
import '../services/energy_server_discovery.dart';
import '../services/recommendation_engine.dart';
import 'history_invalidator.dart';

enum DataSource { demo, api }

/// Status impor riwayat dari server collector.
enum HistoryImportState {
  /// Belum pernah ada impor, atau ada yang gagal lalu sudah dicoba ulang.
  idle,

  /// Sedang berjalan sekarang.
  running,

  /// Impor terakhir selesai dan menulis riwayat.
  done,

  /// Impor terakhir gagal. Error tersimpan di
  /// [EnergyDataProvider.importError] dan bisa dicoba ulang.
  failed,
}

/// Sumber status realtime dari ESP.
///
/// Isinya hanya enam metrik yang benar-benar dikirim JSON ESP. Tidak ada data
/// per perangkat: JSON itu tidak memuat identitas perangkat sama sekali, jadi
/// memecahnya jadi "AC 860 W" hanya bisa dilakukan dengan mengarang angka.
class EnergyDataProvider extends ChangeNotifier {
  EnergyDataProvider({
    EnergyApiClient? apiClient,
    this.pollInterval = const Duration(seconds: 5),
    this.recorder,
    this.database,
    this.historyInvalidator,
    this.backfill,
    this.discovery,
    this.discoveryCooldown = const Duration(minutes: 2),
  }) : _apiClient = apiClient ?? EnergyApiClient();

  final EnergyApiClient _apiClient;
  final EnergyRecorder? recorder;
  final Duration pollInterval;

  /// Penarik riwayat lama dari server collector.
  ///
  /// Disuntikkan supaya bisa diganti objek palsu di test, dan supaya tab yang
  /// tidak butuh impor tidak membayar biaya paging-nya.
  final EnergyHistoryBackfill? backfill;

  /// Pencari collector di jaringan lokal, untuk penyambungan tanpa input.
  ///
  /// Null mematikan pencarian, dan itu yang dipakai test yang menguji percobaan
  /// ulang: tanpa itu, setiap panggilan [connect] akan menyapu 254 host.
  final EnergyServerDiscovery? discovery;

  /// Berapa lama pencarian baru diizinkan setelah penyapuan yang gagal.
  ///
  /// Tanpa jeda ini, [pollInterval] yang lima detik akan membuat aplikasi
  /// menembak 254 host berulang selama server mati.
  final Duration discoveryCooldown;

  /// Sumber endpoint tersimpan untuk [autoConnect].
  ///
  /// Null berarti fitur auto-connect mati, dan aplikasi hanya mengambil data
  /// setelah pengguna menekan tombol di layar Koneksi API ESP.
  final EnergyDatabase? database;

  /// Kabar ke semua pembaca riwayat bahwa angka mereka sudah usang.
  ///
  /// Disuntikkan, bukan dibuat sendiri, supaya satu instance dipakai bersama
  /// oleh provider di atas aplikasi dan provider milik tab Analisis. Tanpa ini,
  /// penghapusan di tab Profil hanya menyegarkan satu dari keduanya dan tab
  /// Analisis masih menampilkan angka lama. Null berarti tidak ada pembaca
  /// riwayat yang perlu diberi tahu, misal pada test yang tidak menyangkut
  /// tampilan.
  final HistoryInvalidator? historyInvalidator;

  Timer? _demoTimer;
  Timer? _pollTimer;
  Timer? _retryTimer;
  bool _pollInFlight = false;

  /// Impor riwayat hanya dicoba otomatis sekali per aplikasi, lewat [connect].
  ///
  /// Dicoba dari `connect` saja, bukan dari `_poll`: `_poll` berjalan tiap lima
  /// detik, jadi impor di sana akan mengulang paging seluruh riwayat server
  /// terus-menerus. [importHistoryNow] sengaja tidak mengeceknya, karena
  /// tombol manual harus bisa mengulang proses yang sama.
  bool _historyImported = false;

  /// Menjaga agar tidak ada dua impor yang berjalan bersamaan.
  ///
  /// Impor manual bisa ditekan saat impor otomatis masih jalan, dan keduanya
  /// menulis ke `minute_aggregates` dengan kunci yang sama.
  bool _importInFlight = false;

  HistoryImportState _importState = HistoryImportState.idle;
  BackfillProgress? _importProgress;
  String? _importError;
  DateTime? _lastImportAt;
  BackfillResult? _lastImportResult;

  /// Status impor terakhir, untuk ditampilkan di tab Analisis.
  HistoryImportState get importState => _importState;

  /// Kemajuan impor yang sedang berjalan, null kalau tidak ada yang jalan.
  BackfillProgress? get importProgress => _importProgress;

  /// Alasan impor terakhir gagal.
  ///
  /// Null ketika impor terakhir berhasil atau belum pernah dicoba. Isinya pesan
  /// asli dari server, bukan teks generik, supaya pengguna tahu apakah masalahnya
  /// 404, koneksi, atau JSON yang rusak.
  String? get importError => _importError;

  /// Kapan impor terakhir yang berhasil selesai.
  DateTime? get lastImportAt => _lastImportAt;

  /// Ringkasan impor terakhir yang berhasil.
  BackfillResult? get lastImportResult => _lastImportResult;

  /// True selama penyapuan jaringan sedang berjalan.
  ///
  /// Dipakai UI supaya "Mencari collector di jaringan…" tidak salah tampil
  /// sebagai "Mode demo aktif" keadaannya.
  bool get discovering => _discovering;
  bool _discovering = false;

  /// Batas bawah kapan penyapuan berikutnya boleh jalan.
  DateTime? _discoveryAllowedAfter;

  /// True selama percobaan otomatis masih diizinkan.
  ///
  /// Dipakai [disconnect] untuk membatalkan retry, supaya tombol "Putuskan
  /// Koneksi" tidak langsung ditimpa percobaan berikutnya.
  bool _autoConnectRequested = false;

  /// Berapa kali alamat yang tersimpan gagal sebelum dianggap tidak berlaku.
  ///
  /// DHCP sering memindahkan collector ke IP lain setelah server hidup
  /// semalaman. Kalau retry hanya menembak alamat lama selamanya, aplikasi
  /// tidak akan pernah pulih tanpa uninstall: alamat yang benar sudah ada,
  /// hanya tidak lagi diketahui.
  static const _failuresBeforeRescan = 2;
  int _knownEndpointFailures = 0;

  /// True kalau alamat aktif diketik pengguna, bukan hasil penyapuan.
  ///
  /// Alamat hasil discovery boleh dibuang lalu dicari ulang sendiri. Alamat
  /// yang diketik pengguna tidak: kalau salah itu kesalahan yang harus
  /// diperbaiki di layar pengaturan, bukan sesuatu yang hilang diam-diam.
  bool _endpointIsManual = false;

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

  /// Daya dalam watt, sama seperti yang dikirim meter.
  ///
  /// Nama ini dipakai langsung oleh pengujian.
  double get currentW => _reading?.power ?? 0;

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
  final List<double> _recentPowerW = <double>[];

  static const int _recentPowerWindow = 60;

  List<double> get recentPowerW => List.unmodifiable(_recentPowerW);

  void _trackPower() {
    _recentPowerW.add(currentW);
    if (_recentPowerW.length > _recentPowerWindow) {
      _recentPowerW.removeAt(0);
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

  /// Meneruskan sampel simulasi ke [recorder] dengan `isDemo: true`.
  ///
  /// Demo sengaja tetap direkam, bukan hanya menggerakkan metrik live, supaya
  /// riwayat dan analisis punya isi tanpa ESP terpasang. Yang mencegah angka
  /// karangan dibaca sebagai pengukuran adalah kolom penanda `is_demo` di
  /// skema lokal: `EnergySyncService` menyaringnya sebelum unggah, dan
  /// `EnergyHourly.isDemo` menandainya di UI. Sumber terukur masuk lewat
  /// [_applyReading] yang selalu memakai `isDemo: false`.
  void _tickDemo() {
    final now = DateTime.now();
    final reading = _demo.sample(now);
    _reading = reading;
    _lastUpdated = now;
    _trackPower();
    unawaited(recorder?.record(reading, now: now, isDemo: true));
  }

  /// Mengambil data dari perangkat memakai endpoint yang tersimpan.
  ///
  /// Dipanggil sekali saat aplikasi dibuka supaya pengguna tidak perlu menekan
  /// tombol setiap kali aplikasi dijalankan. Kalau perangkat belum terjangkau,
  /// percobaan diulang tiap [pollInterval] sampai berhasil, atau sampai
  /// pengguna memutus koneksi secara manual. Tanpa endpoint tersimpan aplikasi
  /// tetap di mode demo, sama seperti sebelumnya.
  ///
  /// Kalau endpoint belum pernah disimpan, aplikasi mencari collector di
  /// jaringan sendiri lewat [discoverAndConnect], jadi pengaturan awal tidak
  /// perlu URL dan api_key sama sekali.
  Future<void> autoConnect() async {
    final database = this.database;
    if (database == null || _disposed) return;

    final device =
        await (database.select(database.localDevices)).getSingleOrNull();
    final saved = parseEndpoint(device?.endpoint);

    _autoConnectRequested = true;
    if (_disposed) return;

    // Endpoint tersimpan dicoba lebih dulu: ini jalur tercepat dan paling
    // sering terjadi, karena sekali ditemukan alamatnya sudah disimpan untuk
    // launch berikutnya dan penyapuan tidak perlu jalan lagi.
    if (saved != null) {
      await connect(endpoint: saved);
      return;
    }
    await discoverAndConnect();
  }

  /// Mencari collector di jaringan lokal lalu menyambungkannya.
  ///
  /// Alamat yang ketemu langsung ditulis ke `local_devices.endpoint`, jadi
  /// pemanggilan berikutnya cukup jatuh ke [autoConnect] tanpa penyapuan. Kalau
  /// tidak ketemu, penyapuan berikutnya ditahan sampai [_discoveryCooldown]
  /// habis supaya percobaan ulang lima detik tidak jadi 254 request per menit.
  ///
  /// Dipisah dari [autoConnect] supaya bisa dipanggil dari UI tanpa mengubah
  /// endpoint yang tersimpan, yaitu untuk mencoba ulang secara sadar.
  Future<void> discoverAndConnect({bool force = false}) async {
    final database = this.database;
    final service = discovery;
    if (database == null || service == null || _disposed) return;
    if (_discovering || _connected) return;

    final now = DateTime.now();
    if (!force) {
      final allowedAfter = _discoveryAllowedAfter;
      if (allowedAfter != null && now.isBefore(allowedAfter)) return;
    }

    _discovering = true;
    notifyListeners();
    try {
      final found = await service.discover();
      if (_disposed) return;

      if (found == null) {
        _discoveryAllowedAfter = now.add(discoveryCooldown);
        // Error aplikasi dibiarkan apa adanya supaya pesan "Mode demo aktif"
        // tetap jujur: yang gagal adalah menemukan collector, bukan koneksi
        // ke endpoint yang sudah diketahui.
        return;
      }

      _discoveryAllowedAfter = null;
      await database.updateLocalDevice(
        localId: (await database.ensureLocalDevice()).localId,
        endpoint: found.endpoint.toString(),
      );
      if (_disposed) return;
      await connect(endpoint: found.endpoint);
    } finally {
      _discovering = false;
      if (!_disposed) notifyListeners();
    }
  }

  /// Menerjemahkan teks endpoint menjadi [Uri] yang bisa dipakai.
  ///
  /// Satu-satunya aturan validasi URL di aplikasi ini, dipakai juga oleh layar
  /// pengaturan dan dialog ganti perangkat. String yang rusak dianggap belum
  /// pernah dikonfigurasi, bukan error yang menggagalkan memulai aplikasi.
  static Uri? parseEndpoint(String? raw) {
    final endpoint = Uri.tryParse(raw?.trim() ?? '');
    if (endpoint == null ||
        (endpoint.scheme != 'http' && endpoint.scheme != 'https') ||
        endpoint.host.isEmpty) {
      return null;
    }
    return endpoint;
  }

  void _startRetry() {
    // Percobaan ulang hanya milik alur otomatis. Tombol manual yang gagal
    // tidak boleh meninggalkan timer berputar di belakang layar.
    if (!_autoConnectRequested) return;
    _retryTimer ??= Timer.periodic(pollInterval, (_) {
      if (!_autoConnectRequested || _disposed) return;
      if (_connecting || _source == DataSource.api) return;
      // Endpoint yang sudah diketahui dicoba langsung; itu satu request dan
      // mencakup kasus yang paling sering, yaitu server hidup tapi sedang
      //restart. Kalau tidak ada endpoint sama sekali, jalurnya adalah penyapuan
      // jaringan, dan itu sudah dijaga [_discoveryAllowedAfter] di dalam
      // [discoverAndConnect] supaya tidak mengulang 254 host tiap lima detik.
      if (_endpoint != null) {
        final attempted = _endpoint;
        unawaited(connect().then((_) => _noteKnownEndpointResult(attempted)));
        return;
      }
      unawaited(discoverAndConnect());
    });
  }

  /// Menandai hasil percobaan ke alamat yang sudah diketahui.
  ///
  /// Setelah [_failuresBeforeRescan] kegagalan berturut-turut, alamat lama
  /// dibuang supaya [_startRetry] jatuh ke jalur penyapuan pada tick
  /// berikutnya. Nilai di database sengaja tidak disentuh, jadi [autoConnect]
  /// masih sempat mencoba sekali lagi sebelum menyimpang ke discovery.
  void _noteKnownEndpointResult(Uri? attempted) {
    if (_disposed || attempted == null) return;
    if (_connected) return;
    if (_endpointIsManual || _endpoint != attempted) return;

    _knownEndpointFailures++;
    if (_knownEndpointFailures >= _failuresBeforeRescan) {
      _endpoint = null;
      _knownEndpointFailures = 0;
    }
  }

  void _stopRetry() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  Future<void> connect({Uri? endpoint, bool manual = false}) async {
    if (_connecting) return;

    final target = endpoint ?? _endpoint ?? EnergyApiClient.defaultEndpoint;
    if (_connected || _pollTimer != null) {
      await disconnect();
    }

    _connecting = true;
    _error = null;
    _endpoint = target;
    _endpointIsManual = manual;
    notifyListeners();

    try {
      final reading = await _apiClient.fetch(target);
      _source = DataSource.api;
      _applyReading(reading);
      _connected = true;
      _knownEndpointFailures = 0;
      _connectedEndpoint = target;
      _connectedSince = DateTime.now();
      _demoTimer?.cancel();
      _demoTimer = null;
      _startPolling();
      _stopRetry();
      unawaited(_importHistory(target));
    } on EnergyApiException catch (error) {
      _connected = false;
      _connectedEndpoint = null;
      _connectedSince = null;
      _error = error.message;
      _startRetry();
    } catch (_) {
      _connected = false;
      _connectedEndpoint = null;
      _connectedSince = null;
      _error = 'Terjadi kesalahan saat membaca API ESP.';
      _startRetry();
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
    unawaited(recorder?.record(reading, now: _lastUpdated, isDemo: false));
  }

/// Menarik riwayat yang sudah ada di server ke `hourly_history`.
  ///
  /// Prosesnya murni tambahan, jadi kegagalan apa pun di sini tidak boleh
  /// mengganggu pencatatan live. Error dicatat di [importError] supaya terbaca
  /// di tab Analisis, dan pembaca riwayat tetap diberi tahu setelah berhasil
  /// supaya tab itu ikut memuat ulang.
  ///
  /// Dipanggil otomatis sekali setelah koneksi pertama berhasil, dan bisa
  /// dipanggil ulang kapan saja lewat [importHistoryNow].
  Future<void> _importHistory(Uri endpoint) async {
    if (_historyImported || _importInFlight) return;
    _historyImported = true;
    await importHistoryNow(endpoint: endpoint);
  }

  /// Menjalankan impor riwayat server sekarang juga.
  ///
  /// Berbeda dari [_importHistory], method ini tidak mengecek
  /// [_historyImported], jadi tombol di tab Analisis selalu bisa mengulang
  /// proses yang sama. Aman dijalankan berkali-kali: `upsertMinute` dan
  /// `upsertHistory` sama-sama menimpa baris dengan kunci yang sama, jadi impor
  /// kedua menghasilkan angka yang sama persis dan bukan penjumlahan.
  ///
  /// [endpoint] dipakai eksplisit oleh panggilan otomatis. Tanpa itu, endpoint
  /// yang sedang terhubung dipakai, dan tanpa itu juga tombol di UI yang
  /// memanggil. Nilai balik melaporkan hasil akhirnya, sementara kegagalan
  /// dicatat di [importError] dan tidak dilempar supaya pemanggil UI tidak
  /// harus menangkap exception yang sama.
  Future<BackfillResult?> importHistoryNow({Uri? endpoint}) async {
    final service = backfill;
    if (service == null) return null;
    if (_importInFlight) return null;

    final target = endpoint ?? _connectedEndpoint ?? _endpoint;
    if (target == null) {
      _importState = HistoryImportState.failed;
      _importError = 'Belum ada server yang terhubung.';
      notifyListeners();
      return null;
    }

    _importInFlight = true;
    _importState = HistoryImportState.running;
    _importError = null;
    _importProgress = const BackfillProgress(phase: BackfillPhase.fetching);
    notifyListeners();

    try {
      final result = await service.run(
        target,
        onProgress: (progress) {
          _importProgress = progress;
          // Diperbarui ke layar hanya saat tahap berganti atau tiap sepuluh
          // persen, bukan tiap sampel. 11.400 sampel kalau semuanya dilaporkan
          // berarti 11.400 rebuild, sementara yang berubah di layar cuma angka
          // persen dan tahapnya.
          final fraction = progress.fraction;
          final phaseChanged = progress.phase != _lastReportedPhase;
          _lastReportedPhase = progress.phase;
          if (phaseChanged ||
              fraction != null &&
                  (_lastReportedFraction == null ||
                      (fraction - _lastReportedFraction!).abs() >= 0.1)) {
            _lastReportedFraction = fraction;
            if (!_disposed) notifyListeners();
          }
        },
      );

      if (_disposed) return result;

      _importProgress = null;
      _lastReportedFraction = null;
      if (result.isEmpty) {
        _importState = HistoryImportState.done;
        _lastImportResult = result;
        _lastImportAt = DateTime.now();
        return result;
      }

      _importState = HistoryImportState.done;
      _lastImportResult = result;
      _lastImportAt = DateTime.now();
      // Kabar pembaca riwayat supaya tab Analisis ikut memuat ulang.
      historyInvalidator?.invalidate();
      return result;
    } on EnergyApiException catch (error) {
      if (!_disposed) {
        _importState = HistoryImportState.failed;
        _importError = error.message;
        _importProgress = null;
        notifyListeners();
      }
      return null;
    } catch (error) {
      if (!_disposed) {
        _importState = HistoryImportState.failed;
        _importError = 'Gagal mengimpor riwayat: $error';
        _importProgress = null;
        debugPrint('Impor riwayat server gagal: $error');
        notifyListeners();
      }
      return null;
    } finally {
      _importInFlight = false;
    }
  }

  /// Persentase terakhir yang sudah dilaporkan ke UI.
  ///
  /// Disimpan sebagai angka, bukan dengan menghitung rebuild, supaya
  /// `notifyListeners` yang mahal itu hanya terpanggil saat memang ada yang
  /// berubah di layar.
  double? _lastReportedFraction;

/// Tahap terakhir yang dilaporkan, supaya perpindahan `fetching` ke
  /// `importing` selalu membangun ulang meski persentasenya kebetulan sama.
  BackfillPhase? _lastReportedPhase;

  Future<void> persistPendingHistory() async {
    await recorder?.flush();
  }

  Future<void> disconnect() async {
    await persistPendingHistory();
    recorder?.reset();
    _pollTimer?.cancel();
    _pollTimer = null;
    _pollInFlight = false;
    _autoConnectRequested = false;
    _stopRetry();
    _connected = false;
    _connecting = false;
    _connectedEndpoint = null;
    _connectedSince = null;
    _lastUpdated = null;
    _reading = null;
    _recentPowerW.clear();
    _endpoint = null;
    _error = null;
    _source = DataSource.demo;
    startDemo();
    notifyListeners();
  }

  /// Mengganti meter pengukuran dengan identitas perangkat yang baru.
  ///
  /// Rekaman meter lama dihapus, lalu `local_devices` diganti baris dengan
  /// `local_id` baru. Ini bukan sekadar mengganti URL: `device_key` yang
  /// menopang seluruh agregat berubah, sehingga grafik dan ringkasan yang
  /// menampilkan meter lama tidak bercampur dengan meter baru yang register
  /// kWh-nya me-reset.
  ///
  /// Endpoint kosong berarti aplikasi berhenti di mode demo sampai pengguna
  /// mengisinya di layar Koneksi API ESP. Endpoint yang diisi langsung dipakai
  /// untuk connect, termasuk percobaan ulang otomatisnya.
  Future<void> switchDevice({Uri? endpoint}) async {
    final database = this.database;
    if (database == null) {
      throw StateError('Ganti perangkat butuh database lokal.');
    }

    await persistPendingHistory();
    // Disconnect memulai ulang mode demo, jadi register simulasi harus disegarkan
    // lebih dulu: sampel pertama setelah switch membaca register meter lama.
    _demo.resetRegister();
    await disconnect();

    final previousKey = await database.currentDeviceId();
    if (previousKey != null) {
      await database.deleteDeviceData(previousKey);
    }
    await database.replaceLocalDevice(endpoint: endpoint?.toString());
    recorder?.reset();
    notifyListeners();
    // Setiap pembaca riwayat harus memuat ulang: yang di atas aplikasi dan
    // yang di tab Analisis, karena keduanya hidup di subtree berbeda.
    historyInvalidator?.invalidate();

    if (endpoint != null) {
      _autoConnectRequested = true;
      await connect(endpoint: endpoint, manual: true);
      return;
    }
    // Endpoint dikosongkan karena pengguna tidak punya URL manual. Daripada
    // berhenti di mode demo, cari collector di jaringan supaya tombol "Ganti
    // perangkat" tanpa URL berperilaku sama seperti pemasangan pertama.
    _autoConnectRequested = true;
    await discoverAndConnect(force: true);
  }

  /// Menghapus seluruh riwayat pengukuran perangkat yang sedang aktif.
  ///
  /// Bedanya dengan [switchDevice] ada di sini: meter dan endpoint-nya tetap,
  /// hanya angka yang hilang. Jadi polling tidak terputus, `device_key` tidak
  /// berubah, dan rekam baru mulai dari nol tanpa mencampur angka lama.
  ///
  /// Cakupannya hanya SQLite di HP. Supabase tidak pernah dihapus dari sini,
  /// dan itu disengaja: baris yang sudah terunggah dipangkas dari antrean
  /// setelah masa retensi, jadi HP bukan cadangan. Menghapus dari sisi server
  /// hanya boleh dilakukan di luar aplikasi, di mana datanya bisa diekspor
  /// lebih dulu.
  ///
  /// Antrean unggahan ikut terhapus karena isinya bagian dari riwayat yang
  /// diminta dihapus; baris yang sudah sampai ke server tetap ada di sana.
  Future<void> clearHistory() async {
    final database = this.database;
    if (database == null) {
      throw StateError('Hapus riwayat butuh database lokal.');
    }

    await persistPendingHistory();
    final deviceKey = await database.currentDeviceId();
    if (deviceKey == null) {
      return;
    }

    await database.deleteDeviceData(deviceKey);
    recorder?.reset();
    _recentPowerW.clear();
    // Register simulasi disegarkan supaya kWh setelah reset mulai dari nol,
    // sama seperti meter yang baru dipasang.
    _demo.resetRegister();
    notifyListeners();
    historyInvalidator?.invalidate();
  }

  @override
  void dispose() {
    _disposed = true;
    _demoTimer?.cancel();
    _pollTimer?.cancel();
    _stopRetry();
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

  /// Menyamakan kembali register kumulatif dan waktu sampel terakhir.
  ///
  /// Dipakai saat pengguna mengganti meter: register PZEM yang baru mulai dari
  /// nol harus menjadi baseline baru, bukan dibandingkan dengan angka meter
  /// sebelumnya.
  void resetRegister() {
    _counter = 0;
    _lastSampleAt = null;
  }

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
