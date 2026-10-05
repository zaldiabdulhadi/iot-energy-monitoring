import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_energy/data/local/app_database.dart';
import 'package:smart_energy/models/energy_reading.dart';
import 'package:smart_energy/services/energy_api_client.dart';
import 'package:smart_energy/services/energy_history_backfill.dart';

/// Satu baris mentah seperti yang ditulis `server/app.py`.
Map<String, dynamic> serverRow({
  required int id,
  required String createdAt,
  double voltage = 214.0,
  double current = 0.2,
  double power = 35.0,
  double energy = 0.17,
  double frequency = 50.0,
  double pf = 0.58,
}) =>
    {
      'id': id,
      'created_at': createdAt,
      'voltage': voltage,
      'current': current,
      'power': power,
      'energy': energy,
      'frequency': frequency,
      'pf': pf,
    };

void main() {
  late EnergyDatabase database;
  late String deviceKey;

  // Client yang melayani daftar halaman satu per satu secara berurutan.
  // Paging yang melewati jumlah halaman akan menerima halaman kosong.
  EnergyApiClient clientServing(
    List<List<Map<String, dynamic>>> pages, {
    void Function(Uri url)? onRequest,
  }) {
    var call = 0;
    return EnergyApiClient(
      client: MockClient((request) async {
        onRequest?.call(request.url);
        final page = call < pages.length ? pages[call] : <Map<String, dynamic>>[];
        call += 1;
        return http.Response(jsonEncode(page), 200);
      }),
    );
  }

  setUp(() async {
    database = EnergyDatabase.forTesting(NativeDatabase.memory());
    deviceKey = (await database.ensureLocalDevice()).localId;
  });

  tearDown(() => database.close());

  test('mengubah sampel server menjadi baris per jam di hourly_history',
      () async {
    // 12 sampel 5 detik sekali di dalam satu jam.
    final base = DateTime(2026, 9, 29, 10);
    final rows = <Map<String, dynamic>>[
      for (var i = 11; i >= 0; i--)
        serverRow(
          id: 100 + i,
          // Register kumulatif naik 0,00001 kWh tiap sampel.
          createdAt: base
              .add(Duration(seconds: 5 * i))
              .toIso8601String()
              .substring(0, 19),
          energy: 0.10 + 0.00001 * i,
        ),
    ];
    final apiClient = clientServing([rows]);
    addTearDown(apiClient.close);

    final service = EnergyHistoryBackfill(
      database: database,
      apiClient: apiClient,
    );
    final result = await service.run(
      Uri.parse('http://server:5000/api/data?api_key=kunci'),
      now: DateTime(2026, 9, 29, 13),
    );

    expect(result.samples, 12);
    expect(result.hours, 1);

    final history = await database.historyBetween(
      deviceKey,
      DateTime(2026, 9, 29),
      DateTime(2026, 9, 30),
    );
    expect(history, hasLength(1));
    expect(history.single.hourStart, base);
    expect(history.single.sampleCount, 12);
    // Sebelas interval 5 detik, masing-masing 0,00001 kWh.
    expect(history.single.energyKwh, closeTo(0.00011, 1e-9));
    expect(history.single.avgPowerW, closeTo(35.0, 1e-6));
    expect(history.single.isDemo, isFalse);
  });

  test('menghalaman seluruh riwayat sampai id terkecil', () async {
    // Dua halaman penuh supaya jalur "halaman masih penuh, lanjut lagi" ikut
    // diuji, lalu satu halaman kosong sebagai penanda habis.
    // Semua baris sengaja bertimestamp sama supaya 1000 sampel ini jatuh di satu
    // menit dan test tetap cepat.
    List<Map<String, dynamic>> page(int count, int startId) =>
        List<Map<String, dynamic>>.generate(
          count,
          (i) => serverRow(id: startId - i, createdAt: '2026-09-29T10:00:00'),
        );
    final first = page(500, 1000);
    final second = page(500, 500);
    expect(first, hasLength(500));
    expect(second, hasLength(500));

    final seen = <Uri>[];
    final apiClient = clientServing([first, second, []], onRequest: seen.add);
    addTearDown(apiClient.close);

    final service = EnergyHistoryBackfill(
      database: database,
      apiClient: apiClient,
    );
    await service.run(
      Uri.parse('http://server:5000/api/data?api_key=kunci'),
      now: DateTime(2026, 9, 29, 13),
    );

    expect(seen, hasLength(3));
    expect(seen[0].queryParameters['before_id'], isNull);
    expect(seen[0].queryParameters['limit'], '500');
    expect(seen[1].queryParameters['before_id'], '501');
    expect(seen[2].queryParameters['before_id'], '1');
  });

  test('halaman yang lebih pendek dari batas langsung mengakhiri paging',
      () async {
    final seen = <Uri>[];
    final apiClient = clientServing(
      [
        List<Map<String, dynamic>>.generate(
          500,
          (i) => serverRow(id: 1000 - i, createdAt: '2026-09-29T10:00:00'),
        ),
        [serverRow(id: 500, createdAt: '2026-09-29T10:00:00')],
        [serverRow(id: 499, createdAt: '2026-09-29T10:00:00')],
      ],
      onRequest: seen.add,
    );
    addTearDown(apiClient.close);

    await EnergyHistoryBackfill(database: database, apiClient: apiClient).run(
      Uri.parse('http://server:5000/api/data?api_key=kunci'),
      now: DateTime(2026, 9, 29, 13),
    );

    // H kedua cuma berisi satu baris, jadi baris id 499 tidak pernah diminta.
    expect(seen, hasLength(2));
    expect(seen.last.queryParameters['before_id'], '501');
  });

  test('mengirim API key sebagai header x-api-key', () async {
    String? seen;
    final watching = EnergyApiClient(
      client: MockClient((request) async {
        seen = request.headers['x-api-key'];
        return http.Response('[]', 200);
      }),
    );
    addTearDown(watching.close);

    await EnergyHistoryBackfill(database: database, apiClient: watching).run(
      Uri.parse('http://server:5000/api/data?api_key=a5ffbd89'),
      now: DateTime(2026, 9, 29, 13),
    );

    expect(seen, 'a5ffbd89');
  });

  test('tidak menyentuh jam yang sedang berjalan', () async {
    // Sampel pada jam 12, sedangkan jam berjalan adalah 12.
    final rows = [
      serverRow(
        id: 2,
        createdAt: DateTime(2026, 9, 29, 12, 30).toIso8601String().substring(0, 19),
      ),
      serverRow(
        id: 1,
        createdAt: DateTime(2026, 9, 29, 11, 30).toIso8601String().substring(0, 19),
      ),
    ];
    final apiClient = clientServing([rows]);
    addTearDown(apiClient.close);

    final service = EnergyHistoryBackfill(database: database, apiClient: apiClient);
    final result = await service.run(
      Uri.parse('http://server:5000/api/data?api_key=kunci'),
      now: DateTime(2026, 9, 29, 12, 45),
    );

    // Hanya sampel jam 11 yang diimpor; jam 12 masih milik recorder live.
    expect(result.samples, 1);
    final history = await database.historyBetween(
      deviceKey,
      DateTime(2026, 9, 29),
      DateTime(2026, 9, 30),
    );
    expect(history.map((row) => row.hourStart), [DateTime(2026, 9, 29, 11)]);
  });

  test('menghapus menit sementara sehingga tidak tertinggal di antrean', () async {
    final base = DateTime(2026, 9, 29, 10);
    final rows = <Map<String, dynamic>>[
      for (var i = 5; i >= 0; i--)
        serverRow(
          id: 10 + i,
          createdAt: base
              .add(Duration(seconds: 5 * i))
              .toIso8601String()
              .substring(0, 19),
          energy: 0.10 + 0.00001 * i,
        ),
    ];
    final apiClient = clientServing([rows]);
    addTearDown(apiClient.close);

    final service = EnergyHistoryBackfill(database: database, apiClient: apiClient);
    await service.run(
      Uri.parse('http://server:5000/api/data?api_key=kunci'),
      now: DateTime(2026, 9, 29, 13),
    );

    final minutes = await database.minutesForHour(deviceKey, base);
    expect(minutes, isEmpty);
  });

  test('menjalankan ulang memberi hasil yang sama, tidak menggandakan energi',
      () async {
    final base = DateTime(2026, 9, 29, 10);
    final rows = <Map<String, dynamic>>[
      for (var i = 5; i >= 0; i--)
        serverRow(
          id: 10 + i,
          createdAt: base
              .add(Duration(seconds: 5 * i))
              .toIso8601String()
              .substring(0, 19),
          energy: 0.10 + 0.00001 * i,
        ),
    ];
    final apiClient = clientServing([rows, rows]);
    addTearDown(apiClient.close);

    final service = EnergyHistoryBackfill(database: database, apiClient: apiClient);
    final endpoint = Uri.parse('http://server:5000/api/data?api_key=kunci');
    await service.run(endpoint, now: DateTime(2026, 9, 29, 13));
    await service.run(endpoint, now: DateTime(2026, 9, 29, 13));

    final history = await database.historyBetween(
      deviceKey,
      DateTime(2026, 9, 29),
      DateTime(2026, 9, 30),
    );
    expect(history, hasLength(1));
    expect(history.single.energyKwh, closeTo(0.00005, 1e-9));
  });

  test('respons kosong tidak melempar error', () async {
    final apiClient = clientServing([[]]);
    addTearDown(apiClient.close);

    final service = EnergyHistoryBackfill(database: database, apiClient: apiClient);
    final result = await service.run(
      Uri.parse('http://server:5000/api/data?api_key=kunci'),
      now: DateTime(2026, 9, 29, 13),
    );

    expect(result.isEmpty, isTrue);
    expect(result.samples, 0);
  });

  test('baris dengan angka rusak dilewati, bukan menggagalkan impor', () async {
    final base = DateTime(2026, 9, 29, 10);
    final rows = <Map<String, dynamic>>[
      serverRow(
        id: 3,
        createdAt: base.add(const Duration(seconds: 5)).toIso8601String().substring(0, 19),
      ),
      // `pf` di luar 0..1 ditolak EnergyReading.fromJson.
      serverRow(
        id: 2,
        createdAt: base.toIso8601String().substring(0, 19),
        pf: 3.0,
      ),
    ];
    final apiClient = clientServing([rows]);
    addTearDown(apiClient.close);

    final service = EnergyHistoryBackfill(database: database, apiClient: apiClient);
    final result = await service.run(
      Uri.parse('http://server:5000/api/data?api_key=kunci'),
      now: DateTime(2026, 9, 29, 13),
    );

    expect(result.samples, 1);
  });

  test('melaporkan jumlah jam sesuai baris yang benar-benar ditulis', () async {
    // Tiga jam, masing-masing dengan beberapa sampel. Nilai balik
    // `closeCompletedHours` hanya menghitung sisa saat panggilan terakhir, jadi
    // angka yang dilaporkan harus dihitung dari sampel agar tidak nol.
    final rows = <Map<String, dynamic>>[
      for (var hour = 8; hour <= 10; hour++)
        for (var i = 4; i >= 0; i--)
          serverRow(
            id: (hour * 100) + i,
            createdAt: DateTime(2026, 9, 29, hour, 0, 5 * i)
                .toIso8601String()
                .substring(0, 19),
            energy: 0.10 + 0.00001 * i,
          ),
    ];
    final apiClient = clientServing([rows]);
    addTearDown(apiClient.close);

    final service = EnergyHistoryBackfill(database: database, apiClient: apiClient);
    final result = await service.run(
      Uri.parse('http://server:5000/api/data?api_key=kunci'),
      now: DateTime(2026, 9, 29, 13),
    );

    expect(result.samples, 15);
    expect(result.hours, 3);
    final history = await database.historyBetween(
      deviceKey,
      DateTime(2026, 9, 29),
      DateTime(2026, 9, 30),
    );
    expect(history, hasLength(result.hours));
  });

  test('EnergyReading terbaca dari baris server apa adanya', () {
    final reading = EnergyReading.fromJson(serverRow(
      id: 1,
      createdAt: '2026-09-29T10:00:00',
    ));
    expect(reading.voltage, 214.0);
    expect(reading.powerFactor, 0.58);
  });

  group('progres impor', () {
    EnergyHistoryBackfill backfillFilling(EnergyApiClient apiClient) =>
        EnergyHistoryBackfill(database: database, apiClient: apiClient);

    // 120 sampel memberi 3 laporan: 49, 99, dan 119. Angka 50 pertama tidak
    // dilaporkan karena indeks berbasis nol dan laporan pertama jatuh di
    // sampel ke-50.
    List<Map<String, dynamic>> spreadSamples() {
      final base = DateTime(2026, 9, 29, 8);
      return [
        for (var i = 0; i < 120; i++)
          serverRow(
            id: 5000 - i,
            createdAt: base
                .add(Duration(seconds: 5 * i))
                .toIso8601String()
                .substring(0, 19),
            energy: 0.20 + 0.00001 * i,
          ),
      ];
    }

    test('tahap pengambilan lebih dulu, lalu tahap impor', () async {
      final apiClient = clientServing([spreadSamples()]);
      addTearDown(apiClient.close);

      final phases = <BackfillPhase>[];
      await backfillFilling(apiClient).run(
        Uri.parse('http://server:5000/api/data'),
        now: DateTime(2026, 9, 29, 13),
        onProgress: (progress) => phases.add(progress.phase),
      );

      // Urutannya penting: UI menampilkan tahap pengambilan sampai totalnya
      // diketahui, lalu melompat ke tahap impor yang punya total.
      expect(phases.first, BackfillPhase.fetching);
      expect(phases.last, BackfillPhase.importing);
      expect(phases, orderedEquals([
        BackfillPhase.fetching,
        BackfillPhase.fetching,
        BackfillPhase.importing,
        BackfillPhase.importing,
        BackfillPhase.importing,
        BackfillPhase.importing,
      ]));
    });

    test('tahap pengambilan tidak mengarang total', () async {
      final apiClient = clientServing([spreadSamples()]);
      addTearDown(apiClient.close);

      final fetching = <BackfillProgress>[];
      await backfillFilling(apiClient).run(
        Uri.parse('http://server:5000/api/data'),
        now: DateTime(2026, 9, 29, 13),
        onProgress: (progress) {
          if (progress.phase == BackfillPhase.fetching) {
            fetching.add(progress);
          }
        },
      );

      // Jumlah halaman tidak diketahui sampai server berhenti mengirim halaman
      // penuh, jadi menampilkan "x dari y" pada tahap ini berarti mengarang y.
      expect(fetching, isNotEmpty);
      expect(fetching.every((progress) => progress.total == null), isTrue);
      expect(fetching.every((progress) => progress.fraction == null), isTrue);
    });

    test('tahap impor memakai total sebenarnya dan berakhir di 100 persen',
        () async {
      final apiClient = clientServing([spreadSamples()]);
      addTearDown(apiClient.close);

      final importing = <BackfillProgress>[];
      await backfillFilling(apiClient).run(
        Uri.parse('http://server:5000/api/data'),
        now: DateTime(2026, 9, 29, 13),
        onProgress: (progress) {
          if (progress.phase == BackfillPhase.importing) {
            importing.add(progress);
          }
        },
      );

      expect(importing, isNotEmpty);
      expect(importing.every((p) => p.total == 120), isTrue);
      expect(importing.first.samples, 0);
      expect(importing.last.samples, 120);
      expect(importing.last.fraction, 1.0);
      // Monoton naik: kalau tidak, bar progres bisa mundur di tengah jalan.
      for (var i = 1; i < importing.length; i++) {
        expect(importing[i].samples, greaterThan(importing[i - 1].samples));
      }
    });

    test('baris yang tidak terbaca tidak ikut dihitung sebagai progres',
        () async {
      // Sampel dengan timestamp rusak dan angka yang tidak valid dilewati saat
      // parsing, sebelum total dihitung. Kalau ikut dihitung, bar akan bergerak
      // lalu berhenti sebelum 100 persen dan terlihat macet.
      final apiClient = clientServing([
        [
          serverRow(id: 3, createdAt: '2026-09-29T08:00:00'),
          serverRow(id: 2, createdAt: 'bukan tanggal'),
          {
            ...serverRow(id: 1, createdAt: '2026-09-29T07:00:00'),
            'power': 'tidak angka',
          },
        ],
      ]);
      addTearDown(apiClient.close);

      final importing = <BackfillProgress>[];
      await backfillFilling(apiClient).run(
        Uri.parse('http://server:5000/api/data'),
        now: DateTime(2026, 9, 29, 13),
        onProgress: (progress) {
          if (progress.phase == BackfillPhase.importing) {
            importing.add(progress);
          }
        },
      );

      expect(importing, isNotEmpty);
      expect(importing.every((p) => p.total == 1), isTrue);
      expect(importing.last.samples, 1);
      expect(importing.last.fraction, 1.0);
    });

    test('server kosong tidak dilaporkan gagal', () async {
      final apiClient = clientServing([[]]);
      addTearDown(apiClient.close);

      final phases = <BackfillPhase>[];
      final result = await backfillFilling(apiClient).run(
        Uri.parse('http://server:5000/api/data'),
        now: DateTime(2026, 9, 29, 13),
        onProgress: (progress) => phases.add(progress.phase),
      );

      expect(result.samples, 0);
      expect(phases, [BackfillPhase.fetching]);
    });
  });
}
