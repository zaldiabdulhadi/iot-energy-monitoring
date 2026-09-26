import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/local/app_database.dart';
import 'providers/energy_data_provider.dart';
import 'providers/energy_history_provider.dart';
import 'providers/sync_status_provider.dart';
import 'screens/home_shell.dart';
import 'services/energy_history_service.dart';
import 'services/energy_recorder.dart';
import 'services/energy_sync_service.dart';
import 'theme/app_theme.dart';

class SmartEnergyApp extends StatelessWidget {
  const SmartEnergyApp({
    super.key,
    required this.database,
    this.syncService,
  });

  final EnergyDatabase database;

  /// Null berarti sinkronisasi cloud dimatikan.
  final EnergySyncService? syncService;

  @override
  Widget build(BuildContext context) {
    final sync = syncService ?? EnergySyncService(database: database);
    final history = EnergyHistoryService(database: database);

    return MultiProvider(
      providers: [
        Provider<EnergyDatabase>.value(value: database),
        ChangeNotifierProvider(
          create: (_) => EnergyDataProvider(
            recorder: EnergyRecorder(
              database: database,
              pollInterval: const Duration(seconds: 5),
            ),
          )..startDemo(),
        ),
        ChangeNotifierProvider(
          create: (_) => SyncStatusProvider(
            service: sync,
            autoSyncInterval: const Duration(minutes: 5),
          )..startAutoSync(),
        ),
        // Ringkasan riwayat dimuat terpisah dari provider realtime supaya
        // pembacaan tiap 5 detik tidak ikut memicu rebuild grafik Analisis.
        ChangeNotifierProvider(
          create: (_) => EnergyHistoryProvider(service: history)..load(),
        ),
      ],
      child: MaterialApp(
        title: 'Smart Energy',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const _LifecycleSyncListener(child: HomeShell()),
      ),
    );
  }
}

/// Memicu `persistPendingHistory` saat aplikasi berhenti dan sinkronisasi ulang
/// saat kembali aktif.
///
/// Harus berada **di bawah** `MultiProvider` supaya bisa membaca provider
/// melalui `BuildContext`.
class _LifecycleSyncListener extends StatefulWidget {
  const _LifecycleSyncListener({required this.child});

  final Widget child;

  @override
  State<_LifecycleSyncListener> createState() => _LifecycleSyncListenerState();
}

class _LifecycleSyncListenerState extends State<_LifecycleSyncListener>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      // Menyimpan menit yang belum penuh supaya tidak hilang saat proses
      // dibunuh paksa oleh sistem.
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        unawaited(context.read<EnergyDataProvider>().persistPendingHistory());
      // Data baru bisa saja terkumpul selama aplikasi tidak aktif.
      case AppLifecycleState.resumed:
        context.read<SyncStatusProvider>().onResumed();
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
