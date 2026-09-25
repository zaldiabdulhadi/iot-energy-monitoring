import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_energy/providers/energy_data_provider.dart';
import 'package:smart_energy/services/energy_api_client.dart';

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

      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(requestCount, greaterThanOrEqualTo(2));
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
}
