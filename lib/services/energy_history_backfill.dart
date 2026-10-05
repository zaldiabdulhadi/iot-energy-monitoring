import '../data/local/app_database.dart';
import '../models/energy_reading.dart';
import '../utils/bucket_time.dart';
import 'energy_api_client.dart';
import 'energy_recorder.dart';

/// Tahap mana importer sedang berada.
enum BackfillPhase {
  /// Menarik halaman mentah dari server. Jumlah akhirnya belum diketahui,
  /// jadi yang bisa ditampilkan cuma halaman ke berapa.
  fetching,

  /// Menulis sampel yang sudah ditarik ke tabel per menit lalu per jam.
  /// Di tahap ini jumlah akhirnya sudah diketahui.
  importing,
}

/// Kemajuan satu kali impor riwayat.
class BackfillProgress {
  const BackfillProgress({required this.phase, this.samples = 0, this.total});

  final BackfillPhase phase;

  /// Pada [BackfillPhase.fetching] ini jumlah baris yang sudah terkumpul,
  /// pada [BackfillPhase.importing] jumlah sampel yang sudah ditulis.
  final int samples;

  /// Total akhir, hanya terisi pada [BackfillPhase.importing].
  final int? total;

  /// Persentase yang bisa dipakai langsung oleh indikator kemajuan.
  ///
  /// Null saat total belum diketahui, jadi widget harus menampilkan
  /// indeterminate bar dan bukan mengisi angka nol yang terlihat selesai.
  double? get fraction => total == null || total! <= 0
      ? null
      : (samples / total!).clamp(0.0, 1.0);
}

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
  ///
  /// [onProgress] dipanggil sepanjang proses supaya layar bisa menampilkan
  /// kemajuan. Enam ribu sampai sebelas ribu sampel diproses satu per satu
  /// lewat [EnergyRecorder], jadi tanpa laporan ini prosesnya terlihat macet.
  Future<BackfillResult> run(
    Uri endpoint, {
    DateTime? now,
    void Function(BackfillProgress progress)? onProgress,
  }) async {
    final timestamp = now ?? DateTime.now();
    final cutoff = floorToHour(timestamp);

    onProgress?.call(const BackfillProgress(phase: BackfillPhase.fetching));
    final rows = await apiClient.fetchAllHistory(
      endpoint,
      onPage: (page, collected) => onProgress?.call(
        BackfillProgress(phase: BackfillPhase.fetching, samples: collected),
      ),
    );
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

    onProgress?.call(
      BackfillProgress(
        phase: BackfillPhase.importing,
        samples: 0,
        total: samples.length,
      ),
    );
    for (var index = 0; index < samples.length; index++) {
      final sample = samples[index];
      await recorder.record(
        sample.reading,
        now: sample.at,
        isDemo: false,
      );
      // Dilaporkan tiap sampel ke-50, bukan tiap sampel. Memanggil
      // `notifyListeners` sebelas ribu kali akan membuat seluruh UI ikut
      // rebuild, sementara langkah 50 membuat bilah tetap bergerak jelas.
      if (index % 50 == 49 || index == samples.length - 1) {
        onProgress?.call(
          BackfillProgress(
            phase: BackfillPhase.importing,
            samples: index + 1,
            total: samples.length,
          ),
        );
      }
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
