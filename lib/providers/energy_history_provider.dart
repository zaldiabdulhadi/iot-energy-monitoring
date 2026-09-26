import 'package:flutter/foundation.dart';

import '../models/energy_period_summary.dart';
import '../services/energy_history_service.dart';
import '../services/recommendation_engine.dart';

/// Menyimpan ringkasan riwayat per periode untuk ditampilkan layar Analisis.
///
/// Sengaja memakai satu periode aktif, bukan memuat semuanya sekaligus: pilihan
/// periode adalah hal yang jarang berubah, dan memuat satu periode membuat
/// layar pertama hampir instan.
class EnergyHistoryProvider extends ChangeNotifier {
  EnergyHistoryProvider({
    required this.service,
    this.engine = const RecommendationEngine(),
    this.selectedPeriod = HistoryPeriod.day,
  });

  final EnergyHistoryService service;
  final RecommendationEngine engine;
  /// Periode yang sedang dipilih pengguna.
  HistoryPeriod selectedPeriod;

  EnergyPeriodSummary? _summary;
  EnergyPeriodSummary? _previous;
  List<EnergyInsight> _insights = const [];
  bool _loading = false;
  Object? _error;
  int _requestId = 0;

  EnergyPeriodSummary? get summary => _summary;
  EnergyPeriodSummary? get previous => _previous;
  List<EnergyInsight> get insights => _insights;
  bool get isLoading => _loading;
  Object? get error => _error;

  /// True saat periode aktif belum punya satu pun baris per jam.
  bool get isEmpty => _summary?.isEmpty ?? false;

  /// True saat periode aktif punya data tapi belum cukup untuk dianalisis.
  bool get isThin => !isEmpty && !(_summary?.isAnalyzable ?? false);

  /// Memuat ulang periode aktif.
  Future<void> load({DateTime? now}) async {
    final id = ++_requestId;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final report = await service.report(selectedPeriod, now: now);
      // Permintaan lama yang selesai belakangan harus diabaikan, kalau tidak
      // hasil yang lebih baru akan tertimpa oleh hasil yang lebih lamanya.
      if (id != _requestId) return;

      _summary = report.summary;
      _previous = report.previous;
      _insights = engine.build(
        summary: report.summary,
        previous: report.previous,
      );
      _error = null;
    } catch (error) {
      if (id != _requestId) return;
      _error = error;
    } finally {
      if (id == _requestId) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  /// Mengganti periode dan langsung memuatnya.
  Future<void> select(HistoryPeriod period, {DateTime? now}) async {
    if (period == selectedPeriod && _summary != null) return;
    selectedPeriod = period;
    await load(now: now);
  }

  /// Memuat ulang tanpa mengubah pilihan periode.
  Future<void> refresh({DateTime? now}) => load(now: now);
}
