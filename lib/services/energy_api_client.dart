import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/energy_reading.dart';

class EnergyApiClient {
  EnergyApiClient({
    http.Client? client,
    this.timeout = const Duration(seconds: 3),
  }) : _client = client ?? http.Client();

  static final Uri defaultEndpoint = Uri.parse(
    'http://192.168.4.1/api/air-quality',
  );

  final http.Client _client;
  final Duration timeout;

  Future<EnergyReading> fetch(Uri endpoint) async {
    if ((endpoint.scheme != 'http' && endpoint.scheme != 'https') ||
        endpoint.host.isEmpty) {
      throw const EnergyApiException('URL API ESP tidak valid.');
    }

    try {
      final response = await _client.get(endpoint).timeout(timeout);
      if (response.statusCode != 200) {
        throw EnergyApiException(
          'API ESP merespons HTTP ${response.statusCode}.',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Respons API harus berupa objek JSON.');
      }
      return EnergyReading.fromJson(decoded);
    } on TimeoutException {
      throw const EnergyApiException(
        'ESP tidak merespons. Periksa hotspot dan URL API.',
      );
    } on http.ClientException {
      throw const EnergyApiException(
        'Tidak dapat terhubung ke API ESP. Periksa hotspot dan URL API.',
      );
    } on FormatException catch (error) {
      throw EnergyApiException('Data API tidak valid: ${error.message}');
    }
  }

  void close() => _client.close();
}

class EnergyApiException implements Exception {
  const EnergyApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
