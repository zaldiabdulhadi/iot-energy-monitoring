import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_energy/data/local/app_database.dart';
import 'package:smart_energy/models/energy_hourly.dart';
import 'package:smart_energy/models/energy_period_summary.dart';
import 'package:smart_energy/providers/energy_history_provider.dart';
import 'package:smart_energy/providers/history_invalidator.dart';
import 'package:smart_energy/services/energy_history_service.dart';

void main() {
  late EnergyDatabase database;
  late EnergyHistoryService service;
  late HistoryInvalidator invalidator;
  late String deviceKey;

  // Sumbu tetap supaya "sebelum" dan "sesudah" dibandingkan pada waktu yang
  // sama, bukan pada dua jam berbeda.
  final now = DateTime(2026, 3, 15, 12, 30);

  setUp(() async {
    database = EnergyDatabase.forTesting(NativeDatabase.memory());
    service = EnergyHistoryService(database: database);
    invalidator = HistoryInvalidator();
    deviceKey = (await database.ensureLocalDevice()).localId;
  });

  tearDown(() {
    invalidator.dispose();
    return database.close();
  });

  Future<void> seedHour(DateTime hourStart) => database.upsertHistory(
        hourly: EnergyHourly(
          deviceKey: deviceKey,
          hourStart: hourStart,
          energyKwh: 0.5,
          powerSum: 1000 * 60,
          powerMin: 1000,
          powerMax: 1000,
          voltageSum: 220 * 60,
          currentSum: 4.5 * 60,
          frequencySum: 50 * 60,
          powerFactorSum: 0.95 * 60,
          sampleCount: 60,
          observedSeconds: 3600,
          coveragePct: 100,
        ),
        now: hourStart,
      );

  group('data contoh', () {
    test('periode kosong tetap diisi data contoh seperti sebelumnya', () async {
      // Menahan behavior lama: Analisis sengaja menampilkan karangan saat
      // belum ada rekaman sama sekali, supaya layarnya bisa dinilai.
      final provider = EnergyHistoryProvider(
        service: service,
        allowSyntheticWhenEmpty: true,
        invalidator: invalidator,
      );
      addTearDown(provider.dispose);

      await provider.load(now: now);

      expect(provider.isEmpty, isFalse);
      expect(provider.isDemo, isTrue);
    });

    test('provider tanpa data contoh tidak pernah menampilkan karangan',
        () async {
      // Dashboard dan Profil memakai instance tanpa izin karangan, jadi
      // invalidate dari tab lain tidak boleh mengubah aturan mereka.
      final provider = EnergyHistoryProvider(
        service: service,
        invalidator: invalidator,
      );
      addTearDown(provider.dispose);

      await provider.load(now: now);
      invalidator.invalidate();
      await Future<void>.delayed(Duration.zero);

      expect(provider.isEmpty, isTrue);
      expect(provider.isDemo, isFalse);
      expect(provider.summary?.totalKwh, 0);
    });
  });

  group('setelah riwayat dihapus', () {
    test('invalidasi memuat ulang dan menahan data contoh', () async {
      final provider = EnergyHistoryProvider(
        service: service,
        allowSyntheticWhenEmpty: true,
        invalidator: invalidator,
      );
      addTearDown(provider.dispose);
      await provider.load(now: now);
      expect(provider.isDemo, isTrue, reason: 'prasyarat: karangan tampil');

      // Baris yang dipegang provider sengaja dihapus supaya provider hanya
      // bisa dapat angka baru dari sinyal, bukan dari reload manual.
      await database.deleteDeviceData(deviceKey);
      invalidator.invalidate();
      await Future<void>.delayed(Duration.zero);

      // Tanpa penahan data contoh, layar akan langsung penuh 24 jam karangan
      // tepat setelah pengguna menekan tombol hapus.
      expect(provider.isEmpty, isTrue);
      expect(provider.isDemo, isFalse);
      expect(provider.summary?.totalKwh, 0);
    });

    test('penahan data contoh mati lagi setelah ada rekaman nyata', () async {
      final provider = EnergyHistoryProvider(
        service: service,
        allowSyntheticWhenEmpty: true,
        invalidator: invalidator,
      );
      addTearDown(provider.dispose);

      await provider.load(now: now);
      invalidator.invalidate();
      await Future<void>.delayed(Duration.zero);
      expect(provider.isEmpty, isTrue, reason: 'harus kosong setelah hapus');

      // Rekaman nyata yang sengaja diletakkan di luar jendela "Hari": hari ini
      // kosong, jadi perbedaan antara kosong dan karangan hanya terlihat lewat
      // efek penahan di langkah terakhir.
      await seedHour(DateTime(2026, 3, 10, 11));
      await provider.select(HistoryPeriod.week, now: now);
      expect(provider.isDemo, isFalse, reason: 'ada rekaman nyata di minggu ini');
      expect(provider.summary?.totalKwh, greaterThan(0));

      // Kembali ke "Hari" yang memang kosong. Kalau penahan masih menyala,
      // layar ini akan tetap kosong; karena sudah mati, karangan boleh muncul
      // lagi seperti sebelum pengguna menekan hapus.
      await provider.select(HistoryPeriod.day, now: now);
      expect(provider.isEmpty, isFalse);
      expect(provider.isDemo, isTrue);
    });

    test('berlangganan dihentikan saat provider dibuang', () async {
      var reloads = 0;
      final provider = EnergyHistoryProvider(
        service: service,
        allowSyntheticWhenEmpty: true,
        invalidator: invalidator,
      )..load();
      provider.addListener(() => reloads++);
      await provider.load(now: now);
      final before = reloads;

      provider.dispose();
      invalidator.invalidate();
      await Future<void>.delayed(Duration.zero);

      // Provider yang sudah dibuang tidak boleh memicu pemuatan ulang: kalau
      // iya, database dibaca tanpa ada yang menampilkan hasilnya.
      expect(reloads, before);
    });
  });
}
