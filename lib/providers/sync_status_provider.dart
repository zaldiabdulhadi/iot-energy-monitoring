import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/remote/energy_remote_data_source.dart';
import '../services/energy_sync_service.dart';

/// Membungkus [EnergySyncService] menjadi state yang bisa ditampilkan.
///
/// Menyediakan jumlah jam yang belum terunggah, waktu sinkronisasi terakhir, dan
/// pesan error terakhir supaya layar Profil menampilkan angka yang sebenarnya
/// alih-alih badge dekoratif.
class SyncStatusProvider extends ChangeNotifier {
  SyncStatusProvider({required this.service, this.autoSyncInterval});

  final EnergySyncService service;

  /// Jeda antar sinkronisasi otomatis. Null mematikan timer.
  final Duration? autoSyncInterval;

  Timer? _timer;
  int _pending = 0;
  int _pendingDemo = 0;
  int _deferred = 0;
  DateTime? _lastSyncedAt;
  DateTime? _lastAttemptAt;
  String? _error;
  bool _syncing = false;

  bool get isEnabled => service.isEnabled;

  bool get isSyncing => _syncing;

  /// Jumlah jam yang belum pernah berhasil diunggah.
  int get pending => _pending;

  /// Jumlah jam simulasi yang tertahan di antrean dan tidak akan diunggah.
  int get pendingDemo => _pendingDemo;

  /// Jumlah jam yang gagal dan masih dalam masa backoff.
  int get deferred => _deferred;

  /// Waktu sinkronisasi yang berhasil terakhir, null kalau belum pernah.
  ///
  /// Dikembalikan apa adanya supaya diformat oleh UI lewat
  /// `MaterialLocalizations`, yang mengikuti bahasa perangkat.
  DateTime? get lastSyncedAt => _lastSyncedAt;

  DateTime? get lastAttemptAt => _lastAttemptAt;

  String? get error => _error;

  bool get hasPending => _pending > 0;

  /// Ringkasan singkat untuk subtitle di layar Profil.
  String get statusLabel {
    if (!isEnabled) return 'Sinkronisasi nonaktif';
    if (_syncing) return 'Menyinkronkan…';
    if (_error != null) return 'Gagal sinkronisasi';
    if (_pending > 0) return 'Menunggu $_pending jam';
    // Antrean yang isinya hanya jam simulasi. Ini bukan kondisi yang perlu
    // diperbaiki, jadi pesannya dibedakan dari "menunggu sinkron".
    if (_pendingDemo > 0) return 'Hanya data simulasi';
    if (_lastSyncedAt == null) return 'Belum pernah sinkron';
    return 'Tersinkron';
  }

  /// Membaca ulang jumlah antrean tanpa melakukan jaringan.
  Future<void> refreshPending() async {
    final deviceKey = await service.database.currentDeviceId();
    if (deviceKey == null) return;
    _pending = await service.database.countPending(deviceKey);
    _pendingDemo = await service.database.countPendingDemo(deviceKey);
    _deferred = await service.database.countDeferred(deviceKey);
    notifyListeners();
  }

  /// Menjalankan sinkronisasi manual. Aman dipanggil berulang.
  Future<void> syncNow() async {
    if (_syncing || !isEnabled) return;
    _syncing = true;
    _error = null;
    _lastAttemptAt = DateTime.now();
    notifyListeners();

    try {
      final report = await service.syncNow();
      _deferred = report.deferred;
      if (report.uploaded > 0) _lastSyncedAt = DateTime.now();
    } on EnergyRemoteException catch (error) {
      _error = error.message;
    } catch (error) {
      _error = 'Sinkronisasi gagal: $error';
    } finally {
      _syncing = false;
      await refreshPending();
    }
  }

  /// Mengaktifkan sinkronisasi otomatis dan langsung mencoba sekali.
  void startAutoSync() {
    final interval = autoSyncInterval;
    if (interval == null) return;
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => syncNow());
    unawaited(syncNow());
  }

  /// Dipanggil saat aplikasi kembali ke foreground.
  void onResumed() {
    unawaited(syncNow());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
