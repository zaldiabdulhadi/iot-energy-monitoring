import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_energy/data/local/app_database.dart';
import 'package:smart_energy/models/energy_period_summary.dart';
import 'package:smart_energy/providers/energy_history_provider.dart';
import 'package:smart_energy/services/energy_history_service.dart';

/// Mengunci batas antara data contoh dan data pengukuran.
///
/// Data contoh sengaja hanya diizinkan untuk tab Analisis. Kalau bocor ke
/// Dashboard atau Profil, seseorang bisa mengira meter sedang melaporkan angka
/// padahal tidak ada yang terekam, jadi kedua hal di bawah ini diuji langsung
/// pada level provider, bukan hanya di level tampilan.
void main() {
  late EnergyDatabase database;
  late EnergyHistoryService service;
  late DateTime now;

  setUp(() async {
    database = EnergyDatabase.forTesting(NativeDatabase.memory());
    service = EnergyHistoryService(database: database);
    now = DateTime(2026, 3, 15, 12, 30);
  });

  tearDown(() => database.close());

  group('provider yang mengizinkan data contoh', () {
    test('mengisi periode kosong dan menandai isDemo', () async {
      final provider = EnergyHistoryProvider(
        service: service,
        allowSyntheticWhenEmpty: true,
      );
      await provider.load(now: now);

      expect(provider.isEmpty, isFalse);
      expect(provider.isDemo, isTrue);
      expect(provider.summary!.totalKwh, greaterThan(0));
    });

    test('tetap menampilkan data kosong tanpa izin', () async {
      final provider = EnergyHistoryProvider(service: service);
      await provider.load(now: now);

      expect(provider.isEmpty, isTrue);
      expect(provider.isDemo, isFalse);
      expect(provider.summary, isNotNull);
    });

    test('rekomendasi tetap bisa disusun dari data contoh', () async {
      final provider = EnergyHistoryProvider(
        service: service,
        allowSyntheticWhenEmpty: true,
      );
      await provider.load(now: now);

      // Tampilan yang sedang dinilai harus utuh: bukan cuma angka, tapi juga
      // bagian rekomendasi.
      expect(provider.insights, isNotEmpty);
    });

    test('berganti periode tetap memakai data contoh', () async {
      final provider = EnergyHistoryProvider(
        service: service,
        allowSyntheticWhenEmpty: true,
      );
      await provider.load(now: now);
      await provider.select(HistoryPeriod.week, now: now);

      expect(provider.selectedPeriod, HistoryPeriod.week);
      expect(provider.isDemo, isTrue);
      expect(provider.summary!.buckets.length, 7);
    });
  });
}
