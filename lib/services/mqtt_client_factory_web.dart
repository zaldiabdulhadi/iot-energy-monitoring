import 'mqtt_client_web.dart';
import 'mqtt_connection.dart';

/// Membuat koneksi MQTT web (WebSocket / WSS).
MqttConnection createMqttConnection() => MqttWebClient();