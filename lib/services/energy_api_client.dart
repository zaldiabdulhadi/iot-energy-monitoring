import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/energy_reading.dart';

class EnergyApiClient {
  EnergyApiClient({
    http.Client? client,
    this.timeout = const Duration(seconds: 3),
  }) : _client = client ?? http.Client();

  /// Server Flask dari `server/app.py`: port 5000 dan path `/api/data`.
  ///
  /// Host masih bisa diganti pengguna di tab Koneksi API ESP, tapi port dan
  /// path harus ikut server itu. Nilai lama masih menunjuk ke proyek lain
  /// (port 5001, `/api/air-quality`) sehingga polling selalu gagal diam-diam.
  static final Uri defaultEndpoint = Uri.parse(
    'http://192.168.1.19:5000/api/data',
  );

  final http.Client _client;
  final Duration timeout;

  Future<EnergyReading> fetch(Uri endpoint) async {
    final response = await _get(endpoint, timeout: timeout);
    // `jsonDecode` dan `fromJson` sama-sama melempar FormatException, dan itu
    // harus sampai ke pengguna sebagai EnergyApiException. Panggilan HTTP-nya
    // sudah selesai di atas, jadi dibungkus sendiri di sini.
    try {
      return EnergyReading.fromJson(_extractReading(jsonDecode(response.body)));
    } on FormatException catch (error) {
      throw EnergyApiException('Data API tidak valid: ${error.message}');
    }
  }

  /// Ambil satu halaman riwayat mentah dari server collector.
  ///
  /// Berbeda dari [fetch] yang hanya menjaga baris terbaru, halaman ini
  /// dikembalikan apa adanya supaya pemanggil bisa menyusun ulang seluruh
  /// riwayat menjadi baris per jam. [beforeId] menunjuk halaman berikutnya ke
  /// arah baris lama; null berarti mulai dari yang terbaru.
  Future<List<Map<String, dynamic>>> fetchHistory(
    Uri endpoint, {
    int? beforeId,
    int limit = 500,
  }) async {
    final uri = _withQuery(endpoint, {
      'limit': '$limit',
      if (beforeId != null) 'before_id': '$beforeId',
    });
    final response = await _get(uri, timeout: timeout);
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const EnergyApiException('Riwayat API harus berupa daftar JSON.');
    }
    return decoded.whereType<Map<String, dynamic>>().toList();
  }

  Future<http.Response> _get(Uri endpoint, {required Duration timeout}) async {
    if ((endpoint.scheme != 'http' && endpoint.scheme != 'https') ||
        endpoint.host.isEmpty) {
      throw const EnergyApiException('URL API ESP tidak valid.');
    }

    try {
      final response = await _client
          .get(endpoint, headers: _headersFor(endpoint))
          .timeout(timeout);
      if (response.statusCode != 200) {
        throw EnergyApiException(
          response.statusCode == 401
              ? 'API ESP menolak kunci. Cek api_key pada URL.'
              : 'API ESP merespons HTTP ${response.statusCode}.',
        );
      }
      return response;
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

  /// Key diambil dari query `api_key` lalu dikirim sebagai header.
  ///
  /// `server/app.py` menerima keduanya, tapi header lebih aman karena tidak
  /// ikut masuk ke log perantara. Query aslinya tetap dipakai apa adanya
  /// supaya URL yang sudah ditempel pengguna tetap berfungsi.
  static Map<String, String> _headersFor(Uri endpoint) {
    final key = endpoint.queryParameters['api_key'];
    if (key == null || key.isEmpty) return const {};
    return {'x-api-key': key};
  }

  static Uri _withQuery(Uri endpoint, Map<String, String> params) {
    final merged = {...endpoint.queryParameters, ...params};
    return endpoint.replace(queryParameters: merged.isEmpty ? null : merged);
  }

  /// Ambil satu bacaan dari berbagai bentuk respons yang dipakai server/ESP.
  ///
  /// `server/app.py` membalas daftar bacaan (urut `id DESC`) sedangkan ESP lama
  /// membalas objek tunggal, jadi keduanya harus diterima di polling yang sama.
  Map<String, dynamic> _extractReading(Object? decoded) {
    if (decoded is List) {
      if (decoded.isEmpty) {
        throw const FormatException('Belum ada data yang masuk dari ESP32.');
      }
      final newest = decoded.first;
      if (newest is! Map<String, dynamic>) {
        throw const FormatException('Respons API harus berisi objek JSON.');
      }
      return newest;
    }
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw const FormatException('Respons API harus berupa objek JSON.');
  }

  void close() => _client.close();
}

class EnergyApiException implements Exception {
  const EnergyApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
