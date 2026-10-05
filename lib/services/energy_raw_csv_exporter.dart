import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'energy_api_client.dart';
import 'energy_csv_exporter.dart' show EnergyExportException;
import 'energy_export_target.dart';

/// Hasil satu kali ekspor sampel mentah.
class EnergyRawCsvExport {
  const EnergyRawCsvExport({
    required this.fileName,
    required this.location,
    required this.rowCount,
    required this.from,
    required this.to,
  });

  final String fileName;

  /// Lokasi di perangkat, misalnya `Download/WattSerra/pzem-20260929-1502.csv`.
  final String location;

  /// Jumlah sampel yang ikut ditulis, sama dengan jumlah baris di server.
  final int rowCount;
  final DateTime from;
  final DateTime to;
}

/// Mengunduh sampel mentah dari server collector lalu menulisnya sebagai CSV
/// dengan format yang sama persis dengan `server/export_csv.py`.
///
/// Berbeda dari [EnergyCsvExporter] yang membaca `hourly_history` di perangkat,
/// ekspor ini menarik langsung dari server lewat `EnergyApiClient.fetchAllHistory`
/// sehingga isinya identik dengan `server/data.db` pada saat diunduh. Konsekuensi:
/// server harus terjangkau saat tombol ditekan, dan berkas hanya berisi data
/// yang sudah sampai di server.
class EnergyRawCsvExporter {
  const EnergyRawCsvExporter({
    required this.apiClient,
    this.target = const DeviceEnergyExportTarget(),
  });

  final EnergyApiClient apiClient;
  final EnergyExportTarget target;

  /// Menulis seluruh sampel [endpoint] ke Downloads lalu membuka lembar bagikan.
  Future<EnergyRawCsvExport> export(
    Uri endpoint, {
    DateTime? now,
    Rect? origin,
  }) async {
    final rows = await apiClient.fetchAllHistory(endpoint);
    if (rows.isEmpty) {
      throw const EnergyExportException(
        'Server belum punya data sampel untuk diunduh.',
      );
    }

    // Server mengembalikan `id` menurun; CSV pakai `id` naik supaya sampel
    // paling lama ada di atas, sama seperti `server/export_csv.py`.
    final sorted = rows.toList()
      ..sort((a, b) => _rowId(a).compareTo(_rowId(b)));

    final timestamp = now ?? DateTime.now();
    final bytes = Uint8List.fromList(utf8.encode(buildRawCsv(sorted)));
    final fileName = _fileName(timestamp);
    final location = await target.saveToDownloads(fileName, bytes);
    await target.share(
      fileName,
      bytes,
      subject: 'Sampel mentah WattSerra',
      text: 'Unduh ${sorted.length} sampel, disimpan di $location',
      origin: origin,
    );

    return EnergyRawCsvExport(
      fileName: fileName,
      location: location,
      rowCount: sorted.length,
      from: _rowTime(sorted.first),
      to: _rowTime(sorted.last),
    );
  }

  String _fileName(DateTime to) {
    String two(int value) => value.toString().padLeft(2, '0');
    return 'pzem-${to.year}${two(to.month)}${two(to.day)}-'
        '${two(to.hour)}${two(to.minute)}.csv';
  }
}

/// Isi berkas CSV sampel mentah, satu baris per pengukuran server.
///
/// Format ini adalah acuan tunggal yang dipakai juga oleh
/// `server/export_csv.py`, jadi output keduanya harus sama baris demi baris:
/// pemisah kolom `;`, desimal koma, UTF-8 dengan BOM supaya langsung benar
/// saat dibuka di Excel versi Indonesia, dan nilai NULL sebagai sel kosong.
/// Desimal mengikuti `app.py`: tegangan 1 angka, arus 3, daya 1, energi 3,
/// frekuensi 1, pf 2.
String buildRawCsv(List<Map<String, dynamic>> rows) {
  final buffer = StringBuffer('\uFEFF$_rawHeader')..writeln();
  for (final row in rows) {
    buffer.writeln(
      <Object>[
        _rowId(row),
        row['created_at'] ?? '',
        _decimal(row['voltage'], 1),
        _decimal(row['current'], 3),
        _decimal(row['power'], 1),
        _decimal(row['energy'], 3),
        _decimal(row['frequency'], 1),
        _decimal(row['pf'], 2),
      ].map(_cell).join(';'),
    );
  }
  return buffer.toString();
}

/// Nama kolom bahasa Indonesia tanpa spasi supaya aman dipakai sebagai nama
/// kolom di Excel, Python, atau SQL.
const _rawHeader =
    'id;waktu;tegangan_v;arus_a;daya_w;energi_kwh;frekuensi_hz;pf';

int _rowId(Map<String, dynamic> row) =>
    (row['id'] as num?)?.toInt() ?? 0;

/// `created_at` ditulis `datetime.now().isoformat()` jadi tanpa offset; dibaca
/// sebagai waktu lokal server.
DateTime _rowTime(Object? value) {
  final text = value?.toString() ?? '';
  return DateTime.tryParse(text) ?? DateTime.fromMillisecondsSinceEpoch(0);
}

/// Satu angka dengan desimal koma; NULL dan nilai rusak jadi sel kosong.
String _decimal(Object? value, int decimals) {
  final number = value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '');
  if (number == null || !number.isFinite) return '';
  return number.toStringAsFixed(decimals).replaceAll('.', ',');
}

/// Satu sel CSV seperti `server/export_csv.py`: nilai kosong dibiarkan kosong,
/// sisanya hanya diberi kutip kalau benar-benar mengandung pemisah, kutip,
/// atau baris baru.
String _cell(Object? value) {
  if (value == null) return '';
  final text = value.toString();
  if (!text.contains(';') && !text.contains('"') && !text.contains('\n')) {
    return text;
  }
  return '"${text.replaceAll('"', '""')}"';
}