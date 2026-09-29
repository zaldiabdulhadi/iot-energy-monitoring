import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_energy/data/local/app_database.dart';
import 'package:smart_energy/models/energy_reading.dart';
import 'package:smart_energy/providers/energy_data_provider.dart';
import 'package:smart_energy/providers/history_invalidator.dart';
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

http.Response _reading([Map<String, dynamic> fields = const {}]) {
  return http.Response(
    jsonEncode({
      'voltage': 213.0,
      'current': 1.2,
      'power': 255.6,
      'energy': 0.032,
      'frequency': 50.0,
      'pf': 0.95,
      ...fields,
    }),
    200,
  );
}

Future<void> saveEndpoint(EnergyDatabase database, String endpoint) async {
  final device = await database.ensureLocalDevice();
  await database.updateLocalDevice(localId: device.localId, endpoint: endpoint);
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
      expect(provider.currentW, 1105);
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
      expect(provider.currentW, 1105);
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
    expect(provider.currentW, isNot(880));
  });

  group('auto-connect dari endpoint tersimpan', () {
    const savedEndpoint = 'http://192.168.1.19:5000/api/data?api_key=kunci';

    test('mengambil data dan melanjutkan polling setelah aplikasi dibuka',
        () async {
      final database = EnergyDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      await saveEndpoint(database, savedEndpoint);

      var requestCount = 0;
      final client = MockClient((_) async {
        requestCount++;
        return _reading();
      });
      final provider = EnergyDataProvider(
        apiClient: EnergyApiClient(client: client),
        database: database,
        pollInterval: const Duration(milliseconds: 10),
      );
      addTearDown(provider.dispose);

      await provider.autoConnect();

      expect(provider.connected, isTrue);
      expect(provider.demoMode, isFalse);
      expect(provider.connectedEndpoint, Uri.parse(savedEndpoint));
      expect(requestCount, 1);

      await _waitUntil(
        () => requestCount >= 3,
        'polling tidak berjalan setelah auto-connect',
      );
      expect(provider.connected, isTrue);
    });

    test('tanpa endpoint tersimpan aplikasi tetap di mode demo', () async {
      final database = EnergyDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);

      var requestCount = 0;
      final client = MockClient((_) async {
        requestCount++;
        return _reading();
      });
      final provider = EnergyDataProvider(
        apiClient: EnergyApiClient(client: client),
        database: database,
        pollInterval: const Duration(milliseconds: 10),
      );
      addTearDown(provider.dispose);
      provider.startDemo();

      await provider.autoConnect();

      expect(requestCount, 0);
      expect(provider.demoMode, isTrue);
      expect(provider.connected, isFalse);
    });

    test('endpoint rusak di database tidak membuat permintaan', () async {
      final database = EnergyDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      await saveEndpoint(database, 'alamat bukan url');

      var requestCount = 0;
      final client = MockClient((_) async {
        requestCount++;
        return _reading();
      });
      final provider = EnergyDataProvider(
        apiClient: EnergyApiClient(client: client),
        database: database,
        pollInterval: const Duration(milliseconds: 10),
      );
      addTearDown(provider.dispose);

      await provider.autoConnect();

      expect(requestCount, 0);
      expect(provider.demoMode, isTrue);
    });

    test('percobaan diulang tiap interval sampai perangkat terjangkau',
        () async {
      final database = EnergyDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      await saveEndpoint(database, savedEndpoint);

      var requestCount = 0;
      final client = MockClient((_) async {
        requestCount++;
        // Dua percobaan pertama gagal, meniru perangkat yang belum hidup.
        if (requestCount <= 2) return http.Response('{}', 503);
        return _reading();
      });
      final provider = EnergyDataProvider(
        apiClient: EnergyApiClient(client: client),
        database: database,
        pollInterval: const Duration(milliseconds: 10),
      );
      addTearDown(provider.dispose);

      await provider.autoConnect();

      expect(provider.connected, isFalse);
      expect(provider.error, isNotNull);

      await _waitUntil(
        () => provider.connected,
        'percobaan ulang tidak pernah berhasil',
      );
      expect(requestCount, greaterThanOrEqualTo(3));
    });

    test('disconnect menghentikan percobaan ulang', () async {
      final database = EnergyDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      await saveEndpoint(database, savedEndpoint);

      var requestCount = 0;
      final client = MockClient((_) async {
        requestCount++;
        return http.Response('{}', 503);
      });
      final provider = EnergyDataProvider(
        apiClient: EnergyApiClient(client: client),
        database: database,
        pollInterval: const Duration(milliseconds: 10),
      );
      addTearDown(provider.dispose);

      await provider.autoConnect();
      await _waitUntil(
        () => requestCount >= 2,
        'percobaan ulang tidak pernah terjadi',
      );

      await provider.disconnect();
      final afterDisconnect = requestCount;
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(
        requestCount,
        afterDisconnect,
        reason: 'timer percobaan ulang harus berhenti saat disconnect',
      );
    });

    test('kegagalan dari tombol manual tidak menyisakan percobaan otomatis',
        () async {
      var requestCount = 0;
      final client = MockClient((_) async {
        requestCount++;
        return http.Response('{}', 503);
      });
      final provider = EnergyDataProvider(
        apiClient: EnergyApiClient(client: client),
        pollInterval: const Duration(milliseconds: 10),
      );
      addTearDown(provider.dispose);

      await provider.connect(endpoint: EnergyApiClient.defaultEndpoint);
      expect(requestCount, 1);

      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(requestCount, 1, reason: 'hanya alur otomatis yang mengulang');
    });
  });

  group('ganti perangkat pengukuran', () {
    const savedEndpoint = 'http://192.168.1.19:5000/api/data?api_key=kunci';
    final sample = EnergyReading(
      voltage: 213,
      current: 1.2,
      power: 255,
      energy: 0.032,
      frequency: 50,
      powerFactor: 0.95,
    );

    /// Merekam satu jam penuh supaya ketiganya terisi: minute, antrean
    /// unggah, dan riwayat.
    Future<void> seedHistory(EnergyRecorder recorder, DateTime hourStart) async {
      for (var minute = 0; minute < 60; minute++) {
        await recorder.record(
          sample,
          now: hourStart.add(Duration(minutes: minute)),
          isDemo: false,
        );
      }
      await recorder.flush();
      await recorder.closeCompletedHours(
        now: hourStart.add(const Duration(hours: 1, seconds: 5)),
      );
    }

    test('menghapus rekaman lama dan memakai identitas perangkat baru',
        () async {
      final database = EnergyDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      await saveEndpoint(database, savedEndpoint);

      final recorder = EnergyRecorder(
        database: database,
        pollInterval: const Duration(seconds: 5),
      );
      await seedHistory(recorder, DateTime(2026, 3, 15, 10));

      final oldKey = await database.currentDeviceId();
      // Menutup jam memindahkan minute ke antrean dan riwayat, jadi yang tersisa
      // adalah dua tabel itu.
      expect(await database.select(database.hourlyQueue).get(), isNotEmpty);
      expect(await database.select(database.hourlyHistory).get(), isNotEmpty);

      final provider = EnergyDataProvider(
        apiClient: EnergyApiClient(client: MockClient((_) async => _reading())),
        recorder: recorder,
        database: database,
        pollInterval: const Duration(milliseconds: 10),
      );
      addTearDown(provider.dispose);

      await provider.switchDevice();

      final newKey = await database.currentDeviceId();
      expect(newKey, isNotNull);
      expect(newKey, isNot(oldKey));

      // Cuma satu baris perangkat yang boleh hidup: ensureLocalDevice selalu
      // membaca baris pertama, jadi dua baris membuat perangkat aktif ambigu.
      final devices = await database.select(database.localDevices).get();
      expect(devices, hasLength(1));
      expect(devices.single.localId, newKey);
      expect(devices.single.endpoint, isNull);

      expect(await database.select(database.minuteAggregates).get(), isEmpty);
      expect(await database.select(database.hourlyQueue).get(), isEmpty);
      expect(await database.select(database.hourlyHistory).get(), isEmpty);
    });

    test('rekaman sesudah penggantian memakai identitas baru', () async {
      final database = EnergyDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      await saveEndpoint(database, savedEndpoint);

      final recorder = EnergyRecorder(
        database: database,
        pollInterval: const Duration(seconds: 5),
      );
      final provider = EnergyDataProvider(
        apiClient: EnergyApiClient(client: MockClient((_) async => _reading())),
        recorder: recorder,
        database: database,
        pollInterval: const Duration(milliseconds: 10),
      );
      addTearDown(provider.dispose);

      await provider.switchDevice();
      final newKey = await database.currentDeviceId();

      await recorder.record(sample, now: DateTime.now(), isDemo: false);
      await recorder.flush();

      final minutes = await database.select(database.minuteAggregates).get();
      expect(minutes, isNotEmpty);
      expect(
        minutes.every((row) => row.deviceKey == newKey),
        isTrue,
        reason: 'rekaman baru tidak boleh memakai device_key lama',
      );
    });

    test('endpoint baru langsung dipakai setelah penggantian', () async {
      final database = EnergyDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      await saveEndpoint(database, savedEndpoint);

      final client = MockClient((_) async => _reading());
      final provider = EnergyDataProvider(
        apiClient: EnergyApiClient(client: client),
        database: database,
        pollInterval: const Duration(milliseconds: 10),
      );
      addTearDown(provider.dispose);

      await provider.switchDevice(endpoint: Uri.parse(savedEndpoint));

      expect(provider.connected, isTrue);
      expect(provider.connectedEndpoint, Uri.parse(savedEndpoint));
      final device = await database.select(database.localDevices).getSingle();
      expect(device.endpoint, savedEndpoint);
    });

    test('tanpa endpoint berhenti di mode demo tanpa permintaan', () async {
      final database = EnergyDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      await saveEndpoint(database, savedEndpoint);

      var requestCount = 0;
      final client = MockClient((_) async {
        requestCount++;
        return _reading();
      });
      final provider = EnergyDataProvider(
        apiClient: EnergyApiClient(client: client),
        database: database,
        pollInterval: const Duration(milliseconds: 10),
      );
      addTearDown(provider.dispose);

      await provider.switchDevice();

      expect(requestCount, 0);
      expect(provider.demoMode, isTrue);
      expect(provider.connected, isFalse);
      expect(
        (await database.select(database.localDevices).getSingle()).endpoint,
        isNull,
      );
    });

    test('deleteDeviceData tidak menyentuh perangkat lain', () async {
      final database = EnergyDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);

      final recorder = EnergyRecorder(
        database: database,
        pollInterval: const Duration(seconds: 5),
      );
      await seedHistory(recorder, DateTime(2026, 3, 15, 10));
      final oldKey = (await database.currentDeviceId())!;

      await database.replaceLocalDevice(endpoint: 'http://meter-baru');
      // Recorder mememois device_key, jadi penggantian harus announcing
      // dirinya lewat reset(); switchDevice() melakukan hal yang sama.
      recorder.reset();
      final newKey = await database.currentDeviceId();
      await seedHistory(recorder, DateTime(2026, 3, 16, 10));

      expect(
        (await database.select(database.hourlyHistory).get())
            .any((row) => row.deviceKey == newKey),
        isTrue,
        reason: 'recorder harus merekam ke perangkat yang baru',
      );

      await database.deleteDeviceData(oldKey);

      final history = await database.select(database.hourlyHistory).get();
      expect(history, isNotEmpty);
      expect(history.every((row) => row.deviceKey == newKey), isTrue);
    });
  });

  group('hapus riwayat tanpa mengganti perangkat', () {
    const savedEndpoint = 'http://192.168.1.19:5000/api/data?api_key=kunci';
    test('mengosongkan rekaman tapi meter dan endpoint tetap', () async {
      final database = EnergyDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      await saveEndpoint(database, savedEndpoint);

      final recorder = EnergyRecorder(
        database: database,
        pollInterval: const Duration(seconds: 5),
      );
      final sample = EnergyReading(
        voltage: 221,
        current: 1.2,
        power: 255,
        energy: 0.032,
        frequency: 50,
        powerFactor: 0.95,
      );
      for (var minute = 0; minute < 60; minute++) {
        await recorder.record(
          sample,
          now: DateTime(2026, 3, 15, 10, minute),
          isDemo: false,
        );
      }
      await recorder.flush();
      await recorder.closeCompletedHours(
        now: DateTime(2026, 3, 15, 11, 0, 5),
      );
      expect(await database.select(database.hourlyHistory).get(), isNotEmpty);
      expect(await database.select(database.hourlyQueue).get(), isNotEmpty);

      final provider = EnergyDataProvider(
        apiClient: EnergyApiClient(client: MockClient((_) async => _reading())),
        recorder: recorder,
        database: database,
        pollInterval: const Duration(milliseconds: 10),
      );
      addTearDown(provider.dispose);

      final keyBefore = await database.currentDeviceId();
      await provider.clearHistory();

      // Meter yang aktif tidak boleh ikut hilang: kalau device_key ikut
      // berubah, rekam sesudah reset akan tercampur dengan data lama yang
      // seharusnya sudah dihapus.
      expect(await database.currentDeviceId(), keyBefore);
      final device = await database.select(database.localDevices).getSingle();
      expect(device.localId, keyBefore);
      expect(device.endpoint, savedEndpoint);

      expect(await database.select(database.hourlyHistory).get(), isEmpty);
      expect(await database.select(database.hourlyQueue).get(), isEmpty);
      expect(await database.select(database.minuteAggregates).get(), isEmpty);
    });

    test('polling tetap berjalan dan memakai device_key yang sama', () async {
      final database = EnergyDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      await saveEndpoint(database, savedEndpoint);

      final recorder = EnergyRecorder(
        database: database,
        pollInterval: const Duration(seconds: 5),
      );
      final provider = EnergyDataProvider(
        apiClient: EnergyApiClient(client: MockClient((_) async => _reading())),
        recorder: recorder,
        database: database,
        pollInterval: const Duration(milliseconds: 10),
      );
      addTearDown(provider.dispose);

      await provider.connect(endpoint: Uri.parse(savedEndpoint));
      await provider.clearHistory();
      await _waitUntil(
        () => provider.connected,
        'koneksi tidak bertahan setelah riwayat dihapus',
      );

      await _waitUntil(
        () => provider.recentPowerW.isNotEmpty,
        'polling berhenti setelah riwayat dihapus',
      );
      await provider.persistPendingHistory();

      final minutes = await database.select(database.minuteAggregates).get();
      expect(minutes, isNotEmpty);
      final key = await database.currentDeviceId();
      expect(
        minutes.every((row) => row.deviceKey == key),
        isTrue,
      );
    });

    test('tanpa perangkat terdaftar tidak melempar error', () async {
      final database = EnergyDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final provider = EnergyDataProvider(
        recorder: EnergyRecorder(
          database: database,
          pollInterval: const Duration(milliseconds: 10),
        ),
        database: database,
        pollInterval: const Duration(milliseconds: 10),
      );
      addTearDown(provider.dispose);

      await provider.clearHistory();

      expect(await database.currentDeviceId(), isNull);
    });

    test('kedua aksi destruktif memberi tahu pembaca riwayat', () async {
      // Invalidator adalah satu-satunya jalan supaya tab Analisis tahu bahwa
      // angkanya sudah usang. Kalau salah satu aksi forgets memanggilnya,
      // penghapusan di Profil tidak akan terlihat di tab lain.
      final database = EnergyDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      await saveEndpoint(database, savedEndpoint);

      final invalidator = HistoryInvalidator();
      addTearDown(invalidator.dispose);
      var calls = 0;
      invalidator.addListener(() => calls++);

      final provider = EnergyDataProvider(
        apiClient: EnergyApiClient(client: MockClient((_) async => _reading())),
        recorder: EnergyRecorder(
          database: database,
          pollInterval: const Duration(milliseconds: 10),
        ),
        database: database,
        historyInvalidator: invalidator,
        pollInterval: const Duration(milliseconds: 10),
      );
      addTearDown(provider.dispose);

      await provider.clearHistory();
      expect(calls, 1, reason: 'hapus riwayat harus invalidate sekali');

      await provider.switchDevice();
      expect(calls, 2, reason: 'ganti perangkat harus invalidate sekali');
    });

    test('polling biasa tidak membangkitkan invalidasi', () async {
      // Kalau invalidator ikut berbunyi saat polling, tab Analisis akan
      // dibangun ulang setiap lima detik tanpa ada yang berubah.
      final database = EnergyDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);

      final invalidator = HistoryInvalidator();
      addTearDown(invalidator.dispose);
      var calls = 0;
      invalidator.addListener(() => calls++);

      final provider = EnergyDataProvider(
        apiClient: EnergyApiClient(client: MockClient((_) async => _reading())),
        database: database,
        historyInvalidator: invalidator,
        pollInterval: const Duration(milliseconds: 10),
      );
      addTearDown(provider.dispose);

      await provider.connect(endpoint: Uri.parse(savedEndpoint));
      await _waitUntil(
        () => provider.recentPowerW.length >= 3,
        'polling tidak berjalan',
      );

      expect(calls, 0);
    });
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
    // asal-usul benar-benar bekerja. `recentPowerW` hanya terisi lewat
    // `_tickDemo`, jadi panjangnya membuktikan sampel benar-benar dibuat.
    await _waitUntil(
      () => provider.recentPowerW.length >= 3,
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
