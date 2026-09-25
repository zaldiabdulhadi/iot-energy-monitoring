import 'dart:async';

/// Abstraction atas koneksi MQTT byte-level, independen dari platform.
///
/// Implementasi nyata dipilih lewat conditional import di mqtt_client_factory:
/// - native (Android/iOS/desktop) -> SecureSocket (TLS, port 8883)
/// - web                          -> WebSocket (WSS, port 8084)
abstract class MqttConnection {
  bool get connected;
  String? get lastError;

  /// Stream berisi snapshot nilai per topic ketika ada pesan masuk.
  Stream<Map<String, String>> get dataStream;

  /// Nilai terakhir per topic.
  Map<String, String> get latestData;

  /// Topik yang akan di-subscribe saat connect.
  List<String> get topics;

  Future<void> connect({
    required String host,
    required int port,
    required String username,
    required String password,
  });

  Future<void> disconnect();
}