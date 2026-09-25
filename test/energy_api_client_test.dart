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
}
