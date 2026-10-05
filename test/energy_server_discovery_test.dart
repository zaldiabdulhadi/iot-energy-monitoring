import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_energy/services/energy_server_discovery.dart';

/// Jawaban `/health` yang diberikan collector sungguhan di server.
http.Response health({
  required String service,
  int rows = 10,
  String? lastSeen,
}) =>
    http.Response(
      jsonEncode({
        'status': 'ok',
        'service': service,
        'rows': rows,
        'last_seen': lastSeen,
      }),
      200,
    );

EnergyServerDiscovery discovery(
  Future<http.Response> Function(http.Request request) handler, {
  List<String>? hosts,
  int port = 5000,
  Duration budget = const Duration(seconds: 6),
}) =>
    EnergyServerDiscovery(
      port: port,
      overallBudget: budget,
      candidates: () async => hosts ?? const ['192.168.1.19'],
      client: MockClient((request) async => handler(request)),
    );

void main() {
  group('penanda collector', () {
    test('hanya /health dengan service yang tepat yang diterima', () async {
      final probed = <String>[];
      final service = discovery((request) async {
        probed.add(request.url.toString());
        if (request.url.path != EnergyServerDiscovery.healthPath) {
          return http.Response('[]', 200);
        }
        return health(service: EnergyServerDiscovery.serviceName, rows: 11416);
      });

      final found = await service.discover();
      service.close();

      expect(found, isNotNull);
      expect(found!.rows, 11416);
      expect(
        probed,
        contains('http://192.168.1.19:5000${EnergyServerDiscovery.healthPath}'),
      );
    });

    test('port di luar default ikut dipakai', () async {
      // Server bisa jalan di port lain, dan salah port berarti tidak menemukan
      // apa pun tanpa error yang bisa dibaca dari stack trace.
      final service = discovery(
        (request) async => health(service: EnergyServerDiscovery.serviceName),
        port: 5050,
      );

      final found = await service.discover();
      service.close();

      expect(found?.endpoint.port, 5050);
      expect(found?.endpoint.path, EnergyServerDiscovery.dataPath);
    });

    test('layanan lain di port yang sama tidak ikut terpakai', () async {
      // Ini alasan utama penanda `service` ada: backend mana pun bisa binds
      // ke port 5000, dan membaca JSON yang salah bentuk tidak akan pernah
      // menghasilkan error yang bisa dibaca pengguna.
      final service = discovery(
        (request) async => health(service: 'nginx'),
      );

      expect(await service.discover(), isNull);
      service.close();
    });

    test('status non-200 dan JSON rusak diabaikan tanpa menggagalkan sapuan',
        () async {
      final service = discovery(
        (request) async => http.Response('<html>502</html>', 502),
      );

      expect(await service.discover(), isNull);
      service.close();
    });
  });

  group('pilihan collector', () {
    test('yang punya data paling baru yang dipilih', () async {
      final service = discovery(
        (request) async {
          if (request.url.host == '192.168.1.7') {
            return health(
              service: EnergyServerDiscovery.serviceName,
              lastSeen: '2026-10-05T00:00:35',
            );
          }
          if (request.url.host == '192.168.1.19') {
            return health(
              service: EnergyServerDiscovery.serviceName,
              lastSeen: '2026-10-04T23:59:35',
            );
          }
          return http.Response('', 404);
        },
        hosts: const ['192.168.1.19', '192.168.1.7'],
      );

      final found = await service.discover();
      service.close();

      expect(found?.endpoint.host, '192.168.1.7');
    });

    test('collector kosong kalah dari yang sudah punya data', () async {
      // `rows` tidak dipakai sebagai pemilah, jadi satu-satunya pembeda yang
      // jujur adalah waktu sampel terakhir.
      final service = discovery(
        (request) async {
          if (request.url.host == '192.168.1.7') {
            return health(service: EnergyServerDiscovery.serviceName);
          }
          if (request.url.host == '192.168.1.19') {
            return health(
              service: EnergyServerDiscovery.serviceName,
              lastSeen: '2026-10-04T23:00:00',
            );
          }
          return http.Response('', 404);
        },
        hosts: const ['192.168.1.7', '192.168.1.19'],
      );

      final found = await service.discover();
      service.close();

      expect(found?.endpoint.host, '192.168.1.19');
    });

    test('last_seen sama menghasilkan pilihan yang tidak berganti', () async {
      final same = health(
        service: EnergyServerDiscovery.serviceName,
        lastSeen: '2026-10-05T00:00:35',
      );
      final hosts = ['192.168.1.19', '192.168.1.7'];

      Future<String?> run() async {
        final service = discovery((_) async => same, hosts: hosts);
        final found = await service.discover();
        service.close();
        return found?.endpoint.host;
      }

      // `List.sort` tidak stabil. Kalau seri tidak dipecah dengan aturan lain,
      // host yang terpilih bisa berganti antar penyapuan pada data yang persis
      // sama, dan endpoint yang tersimpan ikut berubah-ubah.
      expect(await run(), '192.168.1.19');
      expect(await run(), '192.168.1.19');
    });
  });

  group('batasan sapuan', () {
    test('host mati tidak menggagalkan sapuan', () async {
      final service = discovery((request) async {
        if (request.url.host == '192.168.1.7') {
          return health(service: EnergyServerDiscovery.serviceName);
        }
        throw http.ClientException('connection refused', request.url);
      }, hosts: const ['192.168.1.1', '192.168.1.7']);

      expect((await service.discover())?.endpoint.host, '192.168.1.7');
      service.close();
    });

    test('jaringan tanpa host privat dianggap tidak ada collector', () async {
      var calls = 0;
      final service = discovery(
        (_) async {
          calls++;
          return http.Response('', 404);
        },
        hosts: const [],
      );

      expect(await service.discover(), isNull);
      expect(calls, 0, reason: 'tidak ada yang perlu diperiksa');
      service.close();
    });

    test('probe timeout tidak menggagalkan sapuan', () async {
      final service = discovery(
        (request) async {
          if (request.url.host == '192.168.1.7') {
            return health(service: EnergyServerDiscovery.serviceName);
          }
          await Future<void>.delayed(const Duration(seconds: 5));
          return http.Response('', 200);
        },
        hosts: const ['192.168.1.1', '192.168.1.7'],
      );

      expect((await service.discover())?.endpoint.host, '192.168.1.7');
      service.close();
    });

    test('anggaran habis menghentikan sapuan dan dianggap tidak ketemu',
        () async {
      var calls = 0;
      final service = discovery(
        (_) async {
          calls++;
          await Future<void>.delayed(const Duration(milliseconds: 40));
          // Tidak ada yang benar-benar collector, supaya satu-satunya cara
          // `discover` berhenti adalah anggaran, bukan penemuan.
          return http.Response('', 404);
        },
        // 300 host dengan kelompok 10 dan anggaran 60ms: hanya kelompok
        // pertama yang sempat selesai sebelum anggaran habis.
        hosts: [for (var i = 1; i <= 300; i++) '192.168.1.$i'],
        budget: const Duration(milliseconds: 60),
      );

      expect(await service.discover(), isNull);
      expect(calls, lessThan(300), reason: 'sisanya memang tidak diperiksa');
      service.close();
    });
  });
}