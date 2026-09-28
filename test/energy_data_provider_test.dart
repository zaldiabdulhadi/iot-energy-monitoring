import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_energy/data/local/app_database.dart';
import 'package:smart_energy/models/energy_reading.dart';
import 'package:smart_energy/providers/energy_data_provider.dart';
import 'package:smart_energy/services/energy_api_client.dart';
import 'package:smart_energy/services/energy_recorder.dart';

/// Menunggu sampai [condition] terpenuhi, atau gagal setelah [timeout].
///
/// Dipakai untuk hal yang bergantung pada timer async, karena menunggu durasi
/// tetap membuat test ikut gagal kalau CPU sedang sibuk.
Future<void> _waitUntil(
  bool Function() condition,
  String description, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('$description (${timeout.inMilliseconds}ms tidak cukup)');
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  test(
    'provider memakai API dan mempertahankan data saat polling gagal',
    () async {
      var requestCount = 0;
      final client = MockClient((_) async {
        requestCount++;
        if (requestCount > 1) return http.Response('{}', 503);
        return http.Response(
          jsonEncode({
            'voltage': 221.0,
            'current': 5.0,
            'power': 1105.0,
            'energy': 9.2,
            'frequency': 50.1,
            'pf': 0.95,
          }),
          200,
        );
      });
      final provider = EnergyDataProvider(
        apiClient: EnergyApiClient(client: client),
        pollInterval: const Duration(milliseconds: 10),
      );
      addTearDown(provider.dispose);

      await provider.connect(endpoint: EnergyApiClient.defaultEndpoint);

      expect(provider.connected, isTrue);
      expect(provider.source, DataSource.api);
      expect(provider.currentKw, 1.105);
      expect(provider.powerFactor, 0.95);
      expect(provider.connectedEndpoint, EnergyApiClient.defaultEndpoint);

      // Menunggu kondisi nyata, bukan durasi tetap: timer 10ms bisa terlambat
      // saat suite berjalan di bawah beban CPU berat.
      await _waitUntil(
        () => requestCount >= 2 && provider.error != null,
        'polling tidak pernah mencoba ulang lalu gagal',
      );

      expect(provider.connected, isFalse);
      expect(provider.demoMode, isFalse);
      expect(provider.currentKw, 1.105);
      expect(provider.error, isNotNull);
    },
  );

  test('provider kembali ke demo setelah disconnect', () async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'voltage': 220.0,
          'current': 4.0,
          'power': 880.0,
          'energy': 8.0,
          'frequency': 50.0,
          'pf': 0.93,
        }),
        200,
      ),
    );
    final provider = EnergyDataProvider(
      apiClient: EnergyApiClient(client: client),
    );
    addTearDown(provider.dispose);

    await provider.connect(endpoint: EnergyApiClient.defaultEndpoint);
    await provider.disconnect();

    expect(provider.connected, isFalse);
    expect(provider.demoMode, isTrue);
    expect(provider.currentKw, isNot(0.88));
  });

  test('mode demo merekam sebagai data simulasi, ditandai is_demo', () async {
    final database = EnergyDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final provider = EnergyDataProvider(
      pollInterval: const Duration(milliseconds: 10),
      recorder: EnergyRecorder(
        database: database,
        pollInterval: const Duration(milliseconds: 10),
      ),
    );
    addTearDown(provider.dispose);

    provider.startDemo();
    // Syarat ini wajib ada sebelum memeriksa tabel. Tanpa itu, test bisa lolos
    // karena timer demo ternyata tidak pernah berjalan, bukan karena penandaan
    // asal-usul benar-benar bekerja. `recentPowerKw` hanya terisi lewat
    // `_tickDemo`, jadi panjangnya membuktikan sampel benar-benar dibuat.
    await _waitUntil(
      () => provider.recentPowerKw.length >= 3,
      'timer demo tidak menghasilkan sampel',
    );
    await provider.persistPendingHistory();

    // Demo sengaja direkam supaya riwayat dan analisis punya isi tanpa ESP.
    // Yang diperiksa di sini bukan erfolgt/tidaknya pencatatan, tapi apakah
    // setiap barisnya ditandai sebagai simulasi sehingga tidak bisa dibaca
    // sebagai pengukuran.
    final minutes = await database.select(database.minuteAggregates).get();
    expect(minutes, isNotEmpty);
    expect(minutes.every((row) => row.isDemo), isTrue);

    final queue = await database.select(database.hourlyQueue).get();
    for (final row in queue) {
      expect(row.isDemo, isTrue, reason: 'antrean harus ditandai simulasi');
    }
    final history = await database.select(database.hourlyHistory).get();
    for (final row in history) {
      expect(row.isDemo, isTrue, reason: 'riwayat harus ditandai simulasi');
    }
  });

  test('mode API tetap merekam ke database', () async {
    final database = EnergyDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'voltage': 220.0,
          'current': 4.0,
          'power': 880.0,
          'energy': 8.0,
          'frequency': 50.0,
          'pf': 0.93,
        }),
        200,
      ),
    );
    final provider = EnergyDataProvider(
      apiClient: EnergyApiClient(client: client),
      recorder: EnergyRecorder(database: database),
    );
    addTearDown(provider.dispose);

    await provider.connect(endpoint: EnergyApiClient.defaultEndpoint);
    await provider.persistPendingHistory();

    // Penyeimbang test sebelumnya: penandaan asal-usul harus memisahkan demo
    // dari API saja, bukan mematikan perekaman secara keseluruhan.
    final minutes = await database.select(database.minuteAggregates).get();
    expect(minutes, hasLength(1));
    expect(
      minutes.single.isDemo,
      isFalse,
      reason: 'sampel ESP tidak boleh ditandai sebagai simulasi',
    );
    expect(await database.select(database.localDevices).get(), hasLength(1));
  });

  test('sampel simulasi lalu ESP di menit sama menandai menit itu demo',
      () async {
    final database = EnergyDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    final now = DateTime.now();
    final reading = EnergyReading(
      voltage: 220,
      current: 4,
      power: 880,
      energy: 8,
      frequency: 50,
      powerFactor: 0.93,
    );

    // Dua sampel demo se menit, lalu sampel ESP di menit yang sama.
    final recorder = EnergyRecorder(
      database: database,
      pollInterval: const Duration(milliseconds: 10),
    );
    await recorder.record(reading, now: now, isDemo: true);
    await recorder.record(reading, now: now, isDemo: true);
    await recorder.record(reading, now: now, isDemo: false);
    await recorder.flush();

    // Kunci utamanya hanya (device, menit), jadi keduanya tidak bisa hidup
    // berdampingan. Menandai menit tercemar sebagai simulasi adalah satu-satunya
    // pilihan yang tidak membiarkan angka karangan lolos sebagai pengukuran.
    final minutes = await database.select(database.minuteAggregates).get();
    expect(minutes, hasLength(1));
    expect(minutes.single.isDemo, isTrue);
  });

  test('penanda is_demo tidak turun kembali pada menit yang sama', () async {
    final database = EnergyDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    final now = DateTime.now();
    final reading = EnergyReading(
      voltage: 220,
      current: 4,
      power: 880,
      energy: 8,
      frequency: 50,
      powerFactor: 0.93,
    );
    final recorder = EnergyRecorder(
      database: database,
      pollInterval: const Duration(milliseconds: 10),
    );

    // Sampel ESP lebih dulu supaya baris-minute terbentuk sebagai pengukuran,
    // baru sampel simulasi menyusulnya di menit yang sama.
    await recorder.record(reading, now: now, isDemo: false);
    await recorder.flush();
    await recorder.record(reading, now: now, isDemo: true);
    await recorder.flush();

    final minutes = await database.select(database.minuteAggregates).get();
    expect(minutes, hasLength(1));
    expect(
      minutes.single.isDemo,
      isTrue,
      reason: 'satu sampel simulasi harus menandai menit ini',
    );
  });
}
