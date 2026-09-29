import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_energy/services/energy_api_client.dart';

void main() {
  test('mem-parsing respons API ESP', () async {
    final client = MockClient((request) async {
      expect(request.url, EnergyApiClient.defaultEndpoint);
      return http.Response(
        jsonEncode({
          'voltage': 220.4,
          'current': 5.63,
          'power': 1246.8,
          'energy': 8.6,
          'frequency': 50.02,
          'pf': 0.94,
        }),
        200,
      );
    });
    final apiClient = EnergyApiClient(client: client);
    addTearDown(apiClient.close);

    final reading = await apiClient.fetch(EnergyApiClient.defaultEndpoint);

    expect(reading.voltage, 220.4);
    expect(reading.current, 5.63);
    expect(reading.power, 1246.8);
    expect(reading.energy, 8.6);
    expect(reading.frequency, 50.02);
    expect(reading.powerFactor, 0.94);
  });

  test('memakai bacaan terbaru dari respons berbentuk daftar', () async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode([
          {
            'id': 62,
            'created_at': '2026-09-28T19:18:00',
            'voltage': 213.0,
            'current': 0.0,
            'power': 0.0,
            'energy': 0.032,
            'frequency': 50.0,
            'pf': 0.0,
          },
          {
            'id': 61,
            'created_at': '2026-09-28T19:17:48',
            'voltage': 213.1,
            'current': 0.1,
            'power': 21.3,
            'energy': 0.031,
            'frequency': 49.9,
            'pf': 0.98,
          },
        ]),
        200,
      ),
    );
    final apiClient = EnergyApiClient(client: client);
    addTearDown(apiClient.close);

    final reading = await apiClient.fetch(EnergyApiClient.defaultEndpoint);

    expect(reading.voltage, 213.0);
    expect(reading.energy, 0.032);
    expect(reading.frequency, 50.0);
  });

  test('endpoint bawaan menunjuk server collector, bukan proyek lain', () {
    // Port dan path harus sama dengan `server/app.py`: port 5000, `/api/data`.
    // Nilai lama masih menunjuk port 5001 `/api/air-quality`, sehingga polling
    // selalu gagal tanpa petunjuk yang jelas.
    expect(EnergyApiClient.defaultEndpoint.port, 5000);
    expect(EnergyApiClient.defaultEndpoint.path, '/api/data');
  });

  test('menolak daftar kosong dari server', () async {
    final client = MockClient((_) async => http.Response('[]', 200));
    final apiClient = EnergyApiClient(client: client);
    addTearDown(apiClient.close);

    await expectLater(
      apiClient.fetch(EnergyApiClient.defaultEndpoint),
      throwsA(
        isA<EnergyApiException>().having(
          (error) => error.message,
          'message',
          contains('Belum ada data'),
        ),
      ),
    );
  });

  test('menolak respons HTTP unsuccessful', () async {
    final client = MockClient((_) async => http.Response('{}', 503));
    final apiClient = EnergyApiClient(client: client);
    addTearDown(apiClient.close);

    await expectLater(
      apiClient.fetch(EnergyApiClient.defaultEndpoint),
      throwsA(
        isA<EnergyApiException>().having(
          (error) => error.message,
          'message',
          'API ESP merespons HTTP 503.',
        ),
      ),
    );
  });

  test('menolak field JSON yang tidak valid', () async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'voltage': 220.4,
          'current': 5.63,
          'power': 1246.8,
          'energy': 8.6,
          'frequency': 50.02,
        }),
        200,
      ),
    );
    final apiClient = EnergyApiClient(client: client);
    addTearDown(apiClient.close);

    await expectLater(
      apiClient.fetch(EnergyApiClient.defaultEndpoint),
      throwsA(
        isA<EnergyApiException>().having(
          (error) => error.message,
          'message',
          contains('pf'),
        ),
      ),
    );
  });

  test('mengubah timeout menjadi pesan API yang jelas', () async {
    final client = MockClient((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return http.Response('{}', 200);
    });
    final apiClient = EnergyApiClient(
      client: client,
      timeout: const Duration(milliseconds: 1),
    );
    addTearDown(apiClient.close);

    await expectLater(
      apiClient.fetch(EnergyApiClient.defaultEndpoint),
      throwsA(
        isA<EnergyApiException>().having(
          (error) => error.message,
          'message',
          contains('tidak merespons'),
        ),
      ),
    );
  });

  group('fetchHistory', () {
    test('menyerahkan seluruh baris mentah apa adanya', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode([
            {
              'id': 62,
              'created_at': '2026-09-28T19:18:00',
              'voltage': 213.0,
              'current': 0.0,
              'power': 0.0,
              'energy': 0.032,
              'frequency': 50.0,
              'pf': 0.0,
            },
            {
              'id': 61,
              'created_at': '2026-09-28T19:17:48',
              'voltage': 213.1,
              'current': 0.1,
              'power': 21.3,
              'energy': 0.031,
              'frequency': 49.9,
              'pf': 0.98,
            },
          ]),
          200,
        ),
      );
      final apiClient = EnergyApiClient(client: client);
      addTearDown(apiClient.close);

      final rows = await apiClient.fetchHistory(
        EnergyApiClient.defaultEndpoint,
      );

      // Berbeda dengan `fetch`, tidak dipangkas jadi satu baris terbaru.
      expect(rows, hasLength(2));
      expect(rows.first['id'], 62);
      expect(rows.last['id'], 61);
    });

    test('meneruskan before_id dan limit ke server', () async {
      Uri? seen;
      final client = MockClient((request) async {
        seen = request.url;
        return http.Response('[]', 200);
      });
      final apiClient = EnergyApiClient(client: client);
      addTearDown(apiClient.close);

      await apiClient.fetchHistory(
        EnergyApiClient.defaultEndpoint,
        beforeId: 501,
        limit: 250,
      );

      expect(seen!.queryParameters['before_id'], '501');
      expect(seen!.queryParameters['limit'], '250');
    });

    test('tidak mengirim before_id pada halaman pertama', () async {
      Uri? seen;
      final client = MockClient((request) async {
        seen = request.url;
        return http.Response('[]', 200);
      });
      final apiClient = EnergyApiClient(client: client);
      addTearDown(apiClient.close);

      await apiClient.fetchHistory(EnergyApiClient.defaultEndpoint);

      expect(seen!.queryParameters.containsKey('before_id'), isFalse);
    });

    test('menjelaskan penyebab 401, bukan hanya nomor HTTP', () async {
      final client = MockClient((_) async => http.Response('{}', 401));
      final apiClient = EnergyApiClient(client: client);
      addTearDown(apiClient.close);

      await expectLater(
        apiClient.fetchHistory(EnergyApiClient.defaultEndpoint),
        throwsA(
          isA<EnergyApiException>().having(
            (error) => error.message,
            'message',
            contains('api_key'),
          ),
        ),
      );
    });

    test('menolak riwayat yang bukan daftar', () async {
      final client = MockClient((_) async => http.Response('{}', 200));
      final apiClient = EnergyApiClient(client: client);
      addTearDown(apiClient.close);

      await expectLater(
        apiClient.fetchHistory(EnergyApiClient.defaultEndpoint),
        throwsA(
          isA<EnergyApiException>().having(
            (error) => error.message,
            'message',
            contains('daftar JSON'),
          ),
        ),
      );
    });
  });
}
