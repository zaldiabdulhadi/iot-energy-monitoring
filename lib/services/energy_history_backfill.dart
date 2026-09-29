import '../data/local/app_database.dart';
import '../models/energy_reading.dart';
import '../utils/bucket_time.dart';
import 'energy_api_client.dart';
import 'energy_recorder.dart';

/// Menarik riwayat yang sudah terkumpul di server collector ke database lokal.
///
/// Server Flask menyimpan sampel mentah tiap beberapa detik, sementara tab
/// Analisis hanya membaca `hourly_history` di perangkat. Tanpa jembatan ini
/// semua baris yang sudah tercatat di server tidak akan pernah muncul di
/// analisis, karena aplikasi hanya mengambil satu baris terbaru per polling.
///
/// Impor didorong lewat [EnergyRecorder] dan bukan lewat agregasi sendiri:
/// `computeIntervalEnergy` sudah tahu cara menurunkan energi interval dari
/// register kumulatif, dan `rollupMinutes` sudah tahu cara menyusun baris per
/// jam. Meniru keduanya di tempat lain pasti cepat melenceng dari aslinya.
class EnergyHistoryBackfill {
  EnergyHistoryBackfill({
    required this.database,
    required this.apiClient,
    this.pollInterval = const Duration(seconds: 5),
  });

  final EnergyDatabase database;
  final EnergyApiClient apiClient;
  final Duration pollInterval;

  /// Mengimpor seluruh riwayat yang bisa dibaca dari [endpoint].
  ///
  /// Hanya jam yang sudah lewat yang disentuh. Jam berjalan masih ditulis
  /// oleh recorder live, dan menimpanya dengan hasil impor akan membuat angka
  /// yang sedang tampil meloncat turun.
  Future<BackfillResult> run(Uri endpoint, {DateTime? now}) async {
    final timestamp = now ?? DateTime.now();
    final cutoff = floorToHour(timestamp);
    final rows = await apiClient.fetchAllHistory(endpoint);
    if (rows.isEmpty) return const BackfillResult(samples: 0, hours: 0);

    final samples = _parse(rows, cutoff);
    if (samples.isEmpty) return const BackfillResult(samples: 0, hours: 0);

    // Recorder terpisah, bukan milik polling live. Buffer per menit dan sampel
    // sebelumnya di dalam sini tidak boleh bercampur dengan rekaman yang
    // sedang berjalan, kalau tidak energi interval live akan dihitung
    // terhadap sampel lama.
    final recorder = EnergyRecorder(
      database: database,
      pollInterval: pollInterval,
    );

    for (final sample in samples) {
      await recorder.record(
        sample.reading,
        now: sample.at,
        isDemo: false,
      );
    }
    await recorder.flush();
    await recorder.closeCompletedHours(now: timestamp);

    // Jumlah jam dihitung dari sampel yang diimpor, bukan dari nilai balik
    // `closeCompletedHours`. Recorder itu menutup jam lama di tengah stream
    // setiap kali menit berganti, jadi panggilan terakhir hanya menghitung sisa
    // dan akan melaporkan angka yang jauh lebih kecil dari kenyataan.
    final hours = samples.map((sample) => floorToHour(sample.at)).toSet().length;

    return BackfillResult(samples: samples.length, hours: hours);
  }

  /// Mengubah baris mentah server menjadi sampel yang bisa direkam.
  ///
  /// Server mengurutkan `id DESC`, sedangkan energi interval hanya bisa dihitung
  /// dari pasangan sampel yang berurutan waktu, jadi hasilnya dibalik dulu.
  List<_Sample> _parse(List<Map<String, dynamic>> rows, DateTime cutoff) {
    final samples = <_Sample>[];
    for (final row in rows) {
      final at = _readTime(row['created_at']);
      if (at == null || !at.isBefore(cutoff)) continue;
      try {
        samples.add(_Sample(EnergyReading.fromJson(row), at));
      } on FormatException {
        // Baris dengan angka rusak dilewati, bukan menggagalkan seluruh impor.
        continue;
      }
    }
    samples.sort((a, b) => a.at.compareTo(b.at));
    return samples;
  }

  /// `created_at` ditulis `datetime.now().isoformat()` jadi tanpa offset.
  ///
  /// String seperti itu dibaca sebagai waktu lokal perangkat, yang benar selama
  /// server dan perangkat berada di zona waktu yang sama.
  static DateTime? _readTime(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}

class _Sample {
  const _Sample(this.reading, this.at);

  final EnergyReading reading;
  final DateTime at;
}

/// Ringkasan satu importation, untuk ditampilkan di log atau di UI.
class BackfillResult {
  const BackfillResult({required this.samples, required this.hours});

  final int samples;
  final int hours;

  bool get isEmpty => samples == 0;
}
