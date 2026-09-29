import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_energy/services/energy_api_client.dart';
import 'package:smart_energy/services/energy_csv_exporter.dart';
import 'package:smart_energy/services/energy_export_target.dart';
import 'package:smart_energy/services/energy_raw_csv_exporter.dart';

/// Catat semua yang diminta ke exporter tanpa menyentuh Android.
class _FakeTarget implements EnergyExportTarget {
  final List<String> savedNames = <String>[];
  final List<String> sharedNames = <String>[];
  final List<String> sharedSubjects = <String>[];
  Uint8List? lastBytes;

  @override
  Future<String> saveToDownloads(String fileName, Uint8List bytes) async {
    savedNames.add(fileName);
    lastBytes = bytes;
    return 'Download/SmartEnergy/$fileName';
  }

  @override
  Future<void> share(
    String fileName,
    Uint8List bytes, {
    String? subject,
    String? text,
    Rect? origin,
  }) async {
    sharedNames.add(fileName);
    sharedSubjects.add(subject ?? '');
  }
}

/// Satu baris mentah seperti yang ditulis `server/app.py`.
Map<String, dynamic> serverRow({
  required int id,
  String? createdAt,
  double? voltage,
  double? current,
  double? power,
  double? energy,
  double? frequency,
  double? pf,
}) =>
    {
      'id': id,
      'created_at': createdAt ?? '2026-09-29T15:02:33',
      'voltage': voltage,
      'current': current,
      'power': power,
      'energy': energy,
      'frequency': frequency,
      'pf': pf,
    };

void main() {
  group('isi csv', () {
    test('satu baris per sampel dengan format identik server/export_csv.py', () {
      final csv = buildRawCsv([
        serverRow(
          id: 2450,
          voltage: 214.8,
          current: 0.275,
          power: 34.2,
          energy: 0.202,
          frequency: 50.0,
          pf: 0.58,
        ),
      ]);

      expect(csv.codeUnitAt(0), 0xFEFF, reason: 'UTF-8 BOM');
      final lines = csv.trimRight().split('\n');
      expect(lines, hasLength(2));
      expect(
        lines.first.replaceFirst('\uFEFF', ''),
        'id;waktu;tegangan_v;arus_a;daya_w;energi_kwh;frekuensi_hz;pf',
      );

      // Pemisah titik koma dan desimal koma: langsung benar di Excel Indonesia.
      final cells = lines.last.split(';');
      expect(cells, <String>[
        '2450',
        '2026-09-29T15:02:33',
        '214,8',
        '0,275',
        '34,2',
        '0,202',
        '50,0',
        '0,58',
      ]);
    });

    test('nilai NULL jadi sel kosong, bukan nol', () {
      final csv = buildRawCsv([
        serverRow(
          id: 1,
          voltage: 211.0,
          current: 0.3,
          // power, energy, frequency, pf sengaja NULL (baris lama/rusak).
        ),
      ]);

      final cells = csv.trimRight().split('\n').last.split(';');
      expect(cells, <String>[
        '1',
        '2026-09-29T15:02:33',
        '211,0',
        '0,300',
        '',
        '',
        '',
        '',
      ]);
    });

    test('id dan waktu ditulis apa adanya, tidak diubah format', () {
      final csv = buildRawCsv([
        serverRow(id: 90, createdAt: '2026-09-28T20:06:31'),
      ]);

      final cells = csv.trimRight().split('\n').last.split(';');
      expect(cells[0], '90');
      // `created_at` dikeluarkan mentah seperti server menyimpannya, bukan
      // lewat `DateTime.toIso8601String` yang bisa menambah detik pecahan.
      expect(cells[1], '2026-09-28T20:06:31');
    });
  });

  group('ekspor sampel mentah', () {
    final now = DateTime(2026, 3, 15, 12, 30);

    Uri uri(String key) => Uri.parse('http://server:5000/api/data?api_key=$key');

    EnergyRawCsvExporter exporterServing(
      _FakeTarget target,
      List<List<Map<String, dynamic>>> pages,
    ) {
      var call = 0;
      final apiClient = EnergyApiClient(
        client: MockClient((request) async {
          final page = call < pages.length ? pages[call] : <Map<String, dynamic>>[];
          call += 1;
          return http.Response(jsonEncode(page), 200);
        }),
      );
      addTearDown(apiClient.close);
      return EnergyRawCsvExporter(apiClient: apiClient, target: target);
    }

    test('menyimpan sampel ke Downloads lalu membagikannya, urut id naik',
        () async {
      final target = _FakeTarget();
      // Server mengembalikan `id` menurun; berkas harus `id` naik.
      final exporter = exporterServing(target, [
        [serverRow(id: 3), serverRow(id: 2), serverRow(id: 1)],
      ]);

      final result = await exporter.export(uri('kunci'), now: now);

      expect(result.rowCount, 3);
      expect(result.fileName, 'pzem-20260315-1230.csv');
      expect(result.location, contains('pzem-20260315-1230.csv'));
      expect(target.savedNames, <String>[result.fileName]);
      expect(target.sharedNames, <String>[result.fileName]);
      expect(target.sharedSubjects.single, isNotEmpty);

      final lines = utf8.decode(target.lastBytes!).trimRight().split('\n');
      expect(lines, hasLength(4), reason: 'header + tiga sampel');
      expect(lines[1].split(';').first, '1');
      expect(lines[2].split(';').first, '2');
      expect(lines.last.split(';').first, '3');
    });

    test('server kosong ditolak sebelum menulis berkas', () async {
      final target = _FakeTarget();
      final exporter = exporterServing(target, [[]]);

      await expectLater(
        exporter.export(uri('kunci'), now: now),
        throwsA(
          isA<EnergyExportException>().having(
            (error) => error.message,
            'message',
            contains('belum punya data'),
          ),
        ),
      );
      expect(target.savedNames, isEmpty);
    });
  });
}