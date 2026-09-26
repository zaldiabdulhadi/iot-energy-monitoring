import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_energy/data/local/app_database.dart';
import 'package:smart_energy/data/remote/energy_remote_data_source.dart';
import 'package:smart_energy/models/energy_hourly.dart';
import 'package:smart_energy/services/energy_sync_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Membangun respons tiruan PostgREST.
///
/// `request` wajib diisi manual: `MockClient` tidak mengisinya, sedangkan
/// PostgREST membacanya untuk menentukan metode HTTP sebelum mem-parse body.
http.Response postgrestReply(
  http.Request request,
  String body, {
  int status = 200,
}) {
  return http.Response(
    body,
    status,
    headers: const {'content-type': 'application/json'},
    request: request,
  );
}

List<Map<String, dynamic>> decodeHourlyBody(http.Request request) =>
    (jsonDecode(request.body) as List<dynamic>).cast<Map<String, dynamic>>();

bool isHourlyPath(http.Request request) =>
    request.url.path.endsWith('/energy_hourly');

EnergyHourly _hourly(String deviceKey, DateTime hourStart) => EnergyHourly(
      deviceKey: deviceKey,
      hourStart: hourStart,
      energyKwh: 1.5,
      powerSum: 18000,
      sampleCount: 720,
      observedSeconds: 3595,
      coveragePct: 99.86,
      quality: EnergyDataQuality.complete,
    );

void main() {
  late EnergyDatabase database;
  late String deviceKey;

  // Tiap SupabaseClient menjalankan isolate JSON-nya sendiri. Kalau tidak
  // ditutup, isolate menumpuk dan suite penuh jadi lambat.
  final clients = <SupabaseClient>[];

  SupabaseClient newClient(
    Future<http.Response> Function(http.Request request) handler, {
    Map<String, String>? headers,
  }) {
    final client = SupabaseClient(
      'https://contoh.supabase.co',
      'sb_publishable_uji',
      httpClient: MockClient(handler),
      headers: headers,
    );
    clients.add(client);
    return client;
  }

  setUp(() async {
    database = EnergyDatabase.forTesting(NativeDatabase.memory());
    deviceKey = (await database.ensureLocalDevice()).localId;
  });

  tearDown(() async {
    await database.close();
    for (final client in clients) {
      await client.dispose();
    }
    clients.clear();
  });

  EnergySyncService serviceWith(
    Future<http.Response> Function(http.Request request) handler, {
    Duration retention = const Duration(days: 30),
  }) {
    return EnergySyncService(
      database: database,
      remote: EnergyRemoteDataSource(newClient(handler)),
      retention: retention,
    );
  }

  Future<void> seedPendingHour(DateTime hourStart) => database.upsertHourly(
        hourly: _hourly(deviceKey, hourStart),
        now: hourStart.add(const Duration(minutes: 5)),
      );

  group('backoffFor', () {
    test('ganda setiap percobaan', () {
      expect(EnergySyncService.backoffFor(1), const Duration(seconds: 60));
      expect(EnergySyncService.backoffFor(2), const Duration(seconds: 120));
      expect(EnergySyncService.backoffFor(3), const Duration(seconds: 240));
      expect(EnergySyncService.backoffFor(4), const Duration(seconds: 480));
    });

    test('dibatasi dua jam untuk percobaan yang banyak', () {
      expect(EnergySyncService.backoffFor(20), const Duration(hours: 2));
      expect(EnergySyncService.backoffFor(50), const Duration(hours: 2));
    });
  });

  group('EnergySyncService', () {
    test('tidak melakukan apa-apa tanpa remote', () async {
      final service = EnergySyncService(database: database);

      expect(service.isEnabled, isFalse);
      final report = await service.syncNow();
      expect(report.uploaded, 0);
      expect(report.failed, 0);
      expect(report.deferred, 0);
    });

    test('mengunggah profil perangkat sebelum data jam', () async {
      final order = <String>[];
      final service = serviceWith((request) async {
        order.add(request.url.path);
        return postgrestReply(request, '[]');
      });

      await seedPendingHour(DateTime(2026, 9, 25, 10));
      await service.syncNow();

      expect(order.first, '/rest/v1/devices');
      expect(order, contains('/rest/v1/energy_hourly'));
    });

    test('payload perangkat memakai kolom tabel devices', () async {
      Map<String, dynamic>? payload;
      final service = serviceWith((request) async {
        if (request.url.path.endsWith('/devices')) {
          payload = jsonDecode(request.body) as Map<String, dynamic>;
        }
        return postgrestReply(request, '[]');
      });

      await service.syncNow();

      expect(payload, isNotNull);
      expect(payload!['id'], deviceKey);
      expect(payload!.keys, contains('tariff_per_kwh'));
      expect(payload!.keys, contains('grid_co2_kg_per_kwh'));
      expect(payload!.keys, contains('timezone'));
    });

    test('menandai baris synced setelah unggahan berhasil', () async {
      final uploaded = <Map<String, dynamic>>[];
      final service = serviceWith((request) async {
        if (isHourlyPath(request)) uploaded.addAll(decodeHourlyBody(request));
        return postgrestReply(request, '[]', status: 201);
      });

      await seedPendingHour(DateTime(2026, 9, 25, 10));
      final report = await service.syncNow();

      expect(report.uploaded, 1);
      expect(report.failed, 0);
      expect(await database.countPending(deviceKey), 0);
      expect(uploaded, hasLength(1));
      expect(uploaded.single['device_id'], deviceKey);
      expect(uploaded.single['data_quality'], 'complete');
    });

    test('upsert memakai device_id dan hour_start sebagai target konflik', () async {
      String? prefer;
      final service = serviceWith((request) async {
        if (isHourlyPath(request)) prefer = request.headers['Prefer'];
        return postgrestReply(request, '[]', status: 201);
      });

      await seedPendingHour(DateTime(2026, 9, 25, 10));
      await service.syncNow();

      expect(prefer, contains('resolution=merge-duplicates'));
    });

    test(
      'upsert meminta missing=default agar created_at tidak null',
      () async {
        // created_at dan updated_at berstatus NOT NULL DEFAULT now() di
        // Postgres. Tanpa Prefer: missing=default, PostgREST mengirim NULL
        // eksplisit untuk kolom yang absen di payload dan INSERT ditolak.
        final preferHeaders = <String, String>{};
        final service = serviceWith((request) async {
          preferHeaders[request.url.path] =
              request.headers['Prefer'] ?? '';
          return postgrestReply(request, '[]', status: 201);
        });

        await seedPendingHour(DateTime(2026, 9, 25, 10));
        await service.syncNow();

        expect(preferHeaders['/rest/v1/devices'], contains('missing=default'));
        expect(
          preferHeaders['/rest/v1/energy_hourly'],
          contains('missing=default'),
        );
      },
    );

    test('payload hourly tidak mengirim kolom sinkronisasi lokal', () async {
      final uploaded = <Map<String, dynamic>>[];
      final service = serviceWith((request) async {
        if (isHourlyPath(request)) uploaded.addAll(decodeHourlyBody(request));
        return postgrestReply(request, '[]', status: 201);
      });

      await seedPendingHour(DateTime(2026, 9, 25, 10));
      await service.syncNow();

      expect(uploaded, hasLength(1));
      for (final column in const [
        'sync_state',
        'attempts',
        'last_error',
        'synced_at',
        'next_attempt_at',
        'updated_at',
      ]) {
        expect(
          uploaded.single.keys,
          isNot(contains(column)),
          reason: '$column hanya urusan device',
        );
      }
    });

    test('mengirim banyak jam dalam satu permintaan', () async {
      var requests = 0;
      final service = serviceWith((request) async {
        if (isHourlyPath(request)) requests++;
        return postgrestReply(request, '[]', status: 201);
      });

      for (var h = 8; h < 12; h++) {
        await seedPendingHour(DateTime(2026, 9, 25, h));
      }
      final report = await service.syncNow();

      expect(report.uploaded, 4);
      expect(requests, 1);
    });

    test('gagal mengunggah menandai failed dan menambah attempts', () async {
      final service = serviceWith(
        (request) async => isHourlyPath(request)
            ? postgrestReply(request, 'boom', status: 500)
            : postgrestReply(request, '[]'),
      );

      final hourStart = DateTime(2026, 9, 25, 10);
      await seedPendingHour(hourStart);
      final report = await service.syncNow();

      expect(report.uploaded, 0);
      expect(report.failed, 1);
      expect(await database.countPending(deviceKey), 1);

      final row = await database.findHour(deviceKey, hourStart);
      expect(row, isNotNull);
      expect(row!.syncStateValue.name, 'failed');
      expect(row.attempts, 1);
      expect(row.lastError, contains('Gagal mengunggah data energi'));
      expect(row.nextAttemptAt, isNotNull);
      expect(await database.countDeferred(deviceKey), 1);
    });

    test('backoff menahan baris gagal sampai jadwalnya tiba', () async {
      final service = serviceWith(
        (request) async => isHourlyPath(request)
            ? postgrestReply(request, 'boom', status: 500)
            : postgrestReply(request, '[]'),
      );

      final hourStart = DateTime(2026, 9, 25, 10);
      await seedPendingHour(hourStart);
      await service.syncNow();

      final report = await service.syncNow();
      expect(report.uploaded, 0);
      expect(report.failed, 0);
      expect(report.deferred, 1);

      final row = await database.findHour(deviceKey, hourStart);
      expect(
        row!.attempts,
        1,
        reason: 'baris tidak boleh dicoba ulang sebelum backoff kedaluwarsa',
      );
      expect(await database.pendingHours(deviceKey, limit: 1), isEmpty);
    });

    test('percobaan lanjut berjalan setelah backoff kedaluwarsa', () async {
      var shouldFail = true;
      final service = serviceWith((request) async {
        if (isHourlyPath(request) && shouldFail) {
          return postgrestReply(request, 'boom', status: 500);
        }
        return postgrestReply(request, '[]', status: 201);
      });

      final hourStart = DateTime(2026, 9, 25, 10);
      await seedPendingHour(hourStart);
      await service.syncNow();

      // Mundurkan jadwal coba lagi supaya baris dianggap sudah jatuh tempo.
      await database.markFailed(
        deviceKey,
        hourStart,
        error: 'skenario uji',
        now: DateTime.now().subtract(const Duration(hours: 1)),
      );

      shouldFail = false;
      final report = await service.syncNow();
      expect(report.uploaded, 1);
      expect(await database.countPending(deviceKey), 0);
    });

    test('kegagalan berkepanjangan menaikkan attempts satu per percobaan', () async {
      final service = serviceWith(
        (request) async => isHourlyPath(request)
            ? postgrestReply(request, 'boom', status: 500)
            : postgrestReply(request, '[]'),
      );

      final hourStart = DateTime(2026, 9, 25, 10);
      await seedPendingHour(hourStart);

      for (var i = 1; i <= 3; i++) {
        // Mundurkan jadwal supaya baris selalu jatuh tempo saat syncNow jalan.
        await database.markFailed(
          deviceKey,
          hourStart,
          error: 'percobaan $i',
          now: DateTime.now().subtract(Duration(hours: i)),
        );
        await service.syncNow();
      }

      final row = await database.findHour(deviceKey, hourStart);
      expect(
        row!.attempts,
        6,
        reason: 'setiap iterasi menambah dua: satu manual dan satu dari syncNow',
      );
    });

    test('pruneSynced mempertahankan baris yang masih dalam retensi', () async {
      final service = serviceWith(
        (request) async => postgrestReply(request, '[]', status: 201),
      );

      final hourStart = DateTime(2026, 9, 25, 10);
      await seedPendingHour(hourStart);
      await service.syncNow();

      final kept = await database.hourlyBetween(
        deviceKey,
        DateTime(2026, 9, 25),
        DateTime(2026, 9, 26),
      );
      expect(kept, hasLength(1), reason: 'baru disinkronkan, belum kedaluwarsa');
    });

    test('pruneSynced menghapus baris synced yang melewati retensi', () async {
      final service = serviceWith(
        (request) async => postgrestReply(request, '[]', status: 201),
      );

      final hourStart = DateTime(2026, 9, 25, 10);
      await seedPendingHour(hourStart);
      await service.syncNow();

      // Tandai seolah-olah baris itu sudah tersinkron 40 hari lalu.
      await database.markSynced(
        deviceKey,
        hourStart,
        now: DateTime.now().subtract(const Duration(days: 40)),
      );

      // Antrean sudah kosong, jadi syncNow hanya menjalankan prune.
      await service.syncNow();

      final remaining = await database.hourlyBetween(
        deviceKey,
        DateTime(2026, 9, 25),
        DateTime(2026, 9, 26),
      );
      expect(remaining, isEmpty);
    });

    test('baris synced tidak diunggah ulang', () async {
      var uploads = 0;
      final service = serviceWith((request) async {
        if (isHourlyPath(request)) uploads++;
        return postgrestReply(request, '[]', status: 201);
      });

      await seedPendingHour(DateTime(2026, 9, 25, 10));
      await service.syncNow();
      expect(uploads, 1);

      final second = await service.syncNow();
      expect(second.uploaded, 0);
      expect(second.deferred, 0);
      expect(uploads, 1);
    });

    test('header x-sync-secret diteruskan ke backend', () async {
      String? seen;
      final service = EnergySyncService(
        database: database,
        remote: EnergyRemoteDataSource(
          newClient(
            (request) async {
              seen = request.headers['x-sync-secret'];
              return postgrestReply(request, '[]');
            },
            headers: const {'x-sync-secret': 'rahasia'},
          ),
        ),
      );

      await service.syncNow();
      expect(seen, 'rahasia');
    });
  });
}
