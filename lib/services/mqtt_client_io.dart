import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../config/energy_topics.dart';
import 'mqtt_connection.dart';

/// Implementasi MQTT native via SecureSocket (TLS), pola sama seperti
/// MqttTlsService di repo tumbuhin — host/port/kredensial parametrik.
class MqttIoClient implements MqttConnection {
  SecureSocket? _socket;
  StreamSubscription<List<int>>? _sub;
  StreamController<Map<String, String>>? _controller;
  Timer? _pingTimer;
  Completer<bool>? _completer;

  static const String clientIdPrefix = 'SmartEnergy-';
  static const Duration _timeout = Duration(seconds: 15);

  bool _connected = false;

  @override
  bool get connected => _connected;

  String? _lastError;

  @override
  String? get lastError => _lastError;

  @override
  Stream<Map<String, String>> get dataStream => _controller!.stream;

  final Map<String, String> _latestData = {
    for (final t in EnergyTopics.all) t: '--',
  };

  @override
  Map<String, String> get latestData => Map.unmodifiable(_latestData);

  @override
  List<String> get topics => EnergyTopics.all;

  int _nextId = 1;
  int get _id => _nextId++;

  Uint8List _encodeLength(int length) {
    final bytes = <int>[];
    do {
      int digit = length % 128;
      length ~/= 128;
      if (length > 0) digit |= 0x80;
      bytes.add(digit);
    } while (length > 0);
    return Uint8List.fromList(bytes);
  }

  Uint8List _encodeString(String s) {
    final encoded = utf8.encode(s);
    final len = Uint8List(2);
    len[0] = (encoded.length >> 8) & 0xff;
    len[1] = encoded.length & 0xff;
    return Uint8List.fromList([...len, ...encoded]);
  }

  Uint8List _connectPacket(String clientId, String username, String password) {
    final variableHeader = Uint8List.fromList([
      0x00, 0x04, 0x4D, 0x51, 0x54, 0x54, // "MQTT"
      0x04, // protocol level 3.1.1
      0xC2, // username + password flags
      0x00, 0x3C, // keep alive 60s
    ]);
    final payload = Uint8List.fromList([
      ..._encodeString(clientId),
      ..._encodeString(username),
      ..._encodeString(password),
    ]);
    final remaining = Uint8List.fromList([...variableHeader, ...payload]);
    final lengthField = _encodeLength(remaining.length);
    final fixedHeader = Uint8List.fromList([0x10, ...lengthField]);
    return Uint8List.fromList([...fixedHeader, ...remaining]);
  }

  Uint8List _subscribePacket(List<String> topics) {
    final packetId = _id;
    var payload = Uint8List.fromList([
      (packetId >> 8) & 0xff,
      packetId & 0xff,
    ]);
    for (final topic in topics) {
      payload = Uint8List.fromList([
        ...payload,
        ..._encodeString(topic),
        0x01, // QoS 1
      ]);
    }
    final lengthField = _encodeLength(payload.length);
    final fixedHeader = Uint8List.fromList([0x82, ...lengthField]);
    return Uint8List.fromList([...fixedHeader, ...payload]);
  }

  Uint8List _pingPacket() => Uint8List.fromList([0xC0, 0x00]);

  final Uint8List _buffer = Uint8List(0);

  void _onData(List<int> data) {
    final bytes = Uint8List.fromList([..._buffer, ...data]);
    var pos = 0;
    while (pos < bytes.length) {
      if (bytes.length - pos < 2) break;
      final type = bytes[pos] >> 4;
      var len = 0;
      var multiplier = 1;
      var i = pos + 1;
      while (i < bytes.length) {
        len += (bytes[i] & 0x7F) * multiplier;
        multiplier *= 128;
        if ((bytes[i] & 0x80) == 0) break;
        i++;
      }
      if (i >= bytes.length) break;
      final headerLen = i - pos + 1;
      final totalLen = headerLen + len;
      if (bytes.length < pos + totalLen) break;

      final packet = bytes.sublist(pos, pos + totalLen);
      _parsePacket(type, packet, headerLen);
      pos += totalLen;
    }
  }

  void _parsePacket(int type, Uint8List packet, int headerLen) {
    if (type == 2) {
      final connack = packet.sublist(headerLen);
      final returnCode = connack[1];
      if (returnCode == 0) {
        _connected = true;
        _completer?.complete(true);
      } else {
        const codes = {
          1: 'protocol version tidak didukung',
          2: 'identifier ditolak',
          3: 'broker tidak tersedia',
          4: 'username atau password salah',
          5: 'tidak diizinkan',
        };
        _lastError =
            'Koneksi ditolak broker: ${codes[returnCode] ?? 'kode $returnCode'}';
        _completer?.completeError(StateError(_lastError!));
      }
    } else if (type == 3) {
      final payloadData = packet.sublist(headerLen);
      var p = 0;
      final topicLen = (payloadData[p] << 8) | payloadData[p + 1];
      p += 2;
      final topic = utf8.decode(payloadData.sublist(p, p + topicLen));
      p += topicLen;
      final value = utf8.decode(payloadData.sublist(p));
      _latestData[topic] = value;
      _controller?.add(Map.from(_latestData));
    }
  }

  @override
  Future<void> connect({
    required String host,
    required int port,
    required String username,
    required String password,
  }) async {
    _lastError = null;
    if (_connected) return;

    _controller = StreamController<Map<String, String>>.broadcast();
    _completer = Completer<bool>();

    try {
      final clientId = '$clientIdPrefix${DateTime.now().millisecondsSinceEpoch}';

      _socket = await SecureSocket.connect(
        host,
        port,
        onBadCertificate: (cert) => true,
        timeout: _timeout,
      );

      _sub = _socket!.listen(
        _onData,
        onError: (e) {
          if (!_completer!.isCompleted) {
            _lastError = 'Socket error: $e';
            _completer!.completeError(StateError(_lastError!));
          }
        },
        onDone: () {
          _connected = false;
          _pingTimer?.cancel();
        },
        cancelOnError: false,
      );

      _socket!.add(_connectPacket(clientId, username, password));

      await _completer!.future.timeout(_timeout);
    } catch (e) {
      _lastError = 'Koneksi gagal: $e';
      _connected = false;
      _socket?.close();
      _socket = null;
      return;
    }

    _socket!.add(_subscribePacket(EnergyTopics.all));

    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _socket?.add(_pingPacket());
    });
  }

  @override
  Future<void> disconnect() async {
    _pingTimer?.cancel();
    await _sub?.cancel();
    _socket?.close();
    _socket = null;
    _connected = false;
    await _controller?.close();
    _latestData.updateAll((key, value) => '--');
  }
}