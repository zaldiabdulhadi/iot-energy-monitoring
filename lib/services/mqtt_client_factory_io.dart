import 'mqtt_client_io.dart';
import 'mqtt_connection.dart';

/// Membuat koneksi MQTT native (SecureSocket / TLS).
MqttConnection createMqttConnection() => MqttIoClient();