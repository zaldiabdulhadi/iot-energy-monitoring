import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show Rect;

import '../data/local/app_database.dart';
import '../models/energy_hourly.dart';
import '../models/energy_period_summary.dart';
import 'energy_export_target.dart';
import 'energy_history_service.dart';

/// Hasil satu kali ekspor CSV.
class EnergyCsvExport {
  const EnergyCsvExport({
    required this.period,
    required this.fileName,
    required this.location,
    required this.rowCount,
    required this.from,
    required this.to,
  });

  final HistoryPeriod period;
  final String fileName;

  /// Lokasi di perangkat, misalnya `Download/SmartEnergy/data-bulan.csv`.
  final String location;

  /// Jumlah jam yang ikut ditulis, bukan jumlah baris tabel.
  final int rowCount;
  final DateTime from;
  final DateTime to;
}

/// Gagal mengekspor karena memang tidak ada yang bisa ditulis.
class EnergyExportException implements Exception {
  const EnergyExportException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Menyusun CSV satu baris per jam, lalu mengirimnya ke perangkat.
///
/// Baris diambil apa adanya dari `hourly_history`, jadi angka di berkas
/// persis sama dengan yang dipakai ringkasan di layar Analisis.
class EnergyCsvExporter {
  const EnergyCsvExporter({
    required this.database,
    required this.history,
    this.target = const DeviceEnergyExportTarget(),
  });

  final EnergyDatabase database;
  final EnergyHistoryService history;
  final EnergyExportTarget target;

  /// Menulis riwayat [period] ke Downloads lalu membuka lembar bagikan.
  ///
  /// [origin] diteruskan ke lembar bagikan sebagai titik jangkar tombol. Data
  /// simulasi ikut ditulis dengan kolom `is_demo` bernilai 1 supaya tidak
  /// pernah tercampur diam-diam dengan pengukuran sungguhan.
  Future<EnergyCsvExport> export(
    HistoryPeriod period, {
    DateTime? now,
    Rect? origin,
  }) async {
    final deviceKey = await database.currentDeviceId();
    if (deviceKey == null) {
      throw const EnergyExportException(
        'Belum ada perangkat terdaftar, jadi tidak ada data yang bisa diunduh.',
      );
    }

    final window = history.windowFor(period, now ?? DateTime.now());
    final rows = await database.historyBetween(
      deviceKey,
      window.from,
      window.to,
    );
    final usable = rows.where((row) => !row.isEmpty).toList();
    if (usable.isEmpty) {
      throw const EnergyExportException(
        'Belum ada data tercatat pada periode ini. Data muncul setelah satu '
        'jam penuh terekam.',
      );
    }

    final fileName = _fileName(period, window.to);
    final bytes = Uint8List.fromList(utf8.encode(buildHourlyCsv(usable)));
    final location = await target.saveToDownloads(fileName, bytes);
    await target.share(
      fileName,
      bytes,
      subject: 'Rekap energi smart_energy',
      text: 'Rekam ${period.label.toLowerCase()} ${usable.length} jam, '
          'disimpan di $location',
      origin: origin,
    );

    return EnergyCsvExport(
      period: period,
      fileName: fileName,
      location: location,
      rowCount: usable.length,
      from: window.from,
      to: window.to,
    );
  }

  String _fileName(HistoryPeriod period, DateTime to) {
    String two(int value) => value.toString().padLeft(2, '0');
    final stamp =
        '${to.year}${two(to.month)}${two(to.day)}-${two(to.hour)}${two(to.minute)}';
    return 'smart-energy_${period.name}_$stamp.csv';
  }
}

/// Isi berkas CSV: satu baris per jam dengan seluruh kolom yang direkam.
///
/// Pemisah kolom memakai titik koma dan desimal memakai koma, jadi isinya
/// langsung tampil benar saat CSV dibuka di Excel versi Indonesia. Desimal
/// dibulatkan ke tiga angka supaya noise pembulatan floating point tidak
/// memenuhi kolom.
String buildHourlyCsv(List<EnergyHourly> rows) {
  final buffer = StringBuffer(_csvHeader)..writeln();
  for (final row in rows) {
    buffer.writeln(
      <Object?>[
        row.hourStart.toIso8601String(),
        _number(row.energyKwh),
        _number(row.avgPowerW),
        _number(row.powerMin),
        _number(row.powerMax),
        _number(row.avgVoltage),
        _number(row.voltageMin),
        _number(row.voltageMax),
        _number(row.avgCurrent),
        _number(row.currentMax),
        _number(row.avgFrequency),
        _number(row.frequencyMin),
        _number(row.frequencyMax),
        _number(row.avgPowerFactor),
        _number(row.powerFactorMin),
        row.sampleCount,
        _number(row.observedSeconds, decimals: 0),
        row.estimatedIntervals,
        _number(row.coveragePct, decimals: 1),
        row.quality.wireName,
        row.isDemo ? 1 : 0,
      ].map(_cell).join(';'),
    );
  }
  return buffer.toString();
}

/// Nama kolom memakai bahasa Indonesia tanpa spasi supaya aman dipakai sebagai
/// nama kolom di Excel, Python, atau SQL.
const _csvHeader =
    'waktu;kwh;daya_rata_w;daya_min_w;daya_max_w;'
    'tegangan_rata_v;tegangan_min_v;tegangan_max_v;'
    'arus_rata_a;arus_maks_a;'
    'frekuensi_rata_hz;frekuensi_min_hz;frekuensi_max_hz;'
    'pf_rata;pf_min;jumlah_sampel;durasi_teramati_detik;interval_estimasi;'
    'cakupan_persen;mutu_data;is_demo';

/// Satu sel CSV: nilai kosong dibiarkan kosong, sisanya hanya diberi kutip
/// kalau benar-benar mengandung pemisah, kutip, atau baris baru.
String _cell(Object? value) {
  if (value == null) return '';
  final text = value.toString();
  if (!text.contains(';') && !text.contains('"') && !text.contains('\n')) {
    return text;
  }
  return '"${text.replaceAll('"', '""')}"';
}

String _number(double? value, {int decimals = 3}) {
  if (value == null) return '';
  return value.toStringAsFixed(decimals);
}
