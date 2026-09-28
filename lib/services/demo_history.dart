import '../models/energy_hourly.dart';
import '../utils/bucket_time.dart';

/// Pembuat riwayat sementara untuk tampilan layar Analisis.
///
/// **SEMENTARA.** Fungsi ini ada supaya tampilan Analisis bisa dilihat dan
/// dinilai sebelum ESP sempat merekam apa pun. Angkanya bukan pengukuran dan
/// tidak pernah boleh diperlakukan sebagai hasil pengukuran. Yang menjaga hal
/// itu:
/// - `EnergyHistoryService` hanya memakainya kalau rentang waktu yang diminta
///   benar-benar kosong, dan hanya kalau pemanggil mengizinkan secara eksplisit.
/// - Ringkasan yang dihasilkannya ditandai `isDemo`, dan UI menampilkan
///   penanda selama tanda itu menyala.
/// - Pemanggil di luar layar Analisis memakai instance tanpa izin tersebut, jadi
///   Dashboard dan Profil tetap menampilkan apa adanya.
///
/// Menghapus sementara ini cukup dengan menghapus file ini, turunkan parameter
/// `synthetic` di [EnergyHistoryService.report], dan providers yang mengizinkan
/// data contoh.
class DemoHistory {
  const DemoHistory();

  /// Kunci perangkat palsu untuk baris yang tidak pernah menyentuh database.
  static const String deviceKey = 'demo';

  /// Jumlah sampel per jam, satu per menit.
  static const int _samplesPerHour = 60;

  /// Beban dasar tiap jam dalam kilowatt, index 0 adalah pukul 00.00.
  ///
  /// Pola pemakaian listrik rumah tangga: paling rendah tengah malam, naik di
  /// pagi hari untuk kompor dan pemanas air, lalu puncak lagi di sore dan malam
  /// saat lampu serta pendingin ruang menyala. Totalnya sekitar 9 kWh per hari,
  /// masuk akal untuk rumah tangga yang memakai AC.
  static const List<double> _hourlyLoadKw = [
    0.12, 0.11, 0.10, 0.10, 0.11, 0.16, // 00-05
    0.32, 0.68, 0.55, 0.30, 0.27, 0.28, // 06-11
    0.40, 0.30, 0.27, 0.28, 0.30, 0.42, // 12-17
    0.65, 0.85, 0.88, 0.78, 0.52, 0.26, // 18-23
  ];

  /// Beban akhir pekan sedikit lebih tinggi karena rumah lebih sering dihuni.
  static const double _weekendFactor = 1.08;

  /// Panjang baris untuk rentang setengah terbuka `[from, to)`.
  List<EnergyHourly> rows({required DateTime from, required DateTime to}) {
    final result = <EnergyHourly>[];
    var hour = floorToHour(from);
    while (hour.isBefore(to)) {
      result.add(_hourAt(hour));
      hour = hour.add(const Duration(hours: 1));
    }
    return result;
  }

  EnergyHourly _hourAt(DateTime hourStart) {
    var powerSum = 0.0;
    var powerMin = double.infinity;
    var powerMax = 0.0;
    var voltageSum = 0.0;
    var voltageMin = double.infinity;
    var voltageMax = 0.0;
    var currentSum = 0.0;
    var currentMax = 0.0;
    var frequencySum = 0.0;
    var frequencyMin = double.infinity;
    var frequencyMax = 0.0;
    var powerFactorSum = 0.0;
    var powerFactorMin = double.infinity;
    var energyKwh = 0.0;

    // Benih per jam memakai jam absolut supaya nilai sebuah jam tidak berubah
    // kalau jendela waktu yang dihitung berbeda, dan tidak bergeser tiap render.
    final hourSeed = hourStart.millisecondsSinceEpoch ~/ 3600000;

    for (var minute = 0; minute < _samplesPerHour; minute++) {
      final seed = hourSeed * _samplesPerHour + minute;

      final watts = _wattsAt(hourStart, seed);
      final voltage = 228 + 4 * (_unit(seed + 7) - 0.5);
      // Dijaga di atas 0,90 supaya tabel parameter tidak menandai data contoh
      // sebagai penyimpangan, yang membuat tampilan yang sedang dinilai menyesatkan.
      final powerFactor = 0.90 + 0.08 * _unit(seed + 13);
      final frequency = 49.95 + 0.08 * (_unit(seed + 29) - 0.5);
      // Arus diturunkan dari daya, tegangan, dan faktor daya supaya keenamnya
      // konsisten secara fisika seperti bacaan meter yang sebenarnya.
      final current = watts / (voltage * powerFactor);

      powerSum += watts;
      powerMin = powerMin < watts ? powerMin : watts;
      powerMax = powerMax > watts ? powerMax : watts;

      voltageSum += voltage;
      voltageMin = voltageMin < voltage ? voltageMin : voltage;
      voltageMax = voltageMax > voltage ? voltageMax : voltage;

      currentSum += current;
      currentMax = currentMax > current ? currentMax : current;

      frequencySum += frequency;
      frequencyMin = frequencyMin < frequency ? frequencyMin : frequency;
      frequencyMax = frequencyMax > frequency ? frequencyMax : frequency;

      powerFactorSum += powerFactor;
      powerFactorMin = powerFactorMin < powerFactor ? powerFactorMin : powerFactor;

      // Satu sampel mewakili satu menit.
      energyKwh += watts / 1000 / 60;
    }

    return EnergyHourly(
      deviceKey: deviceKey,
      hourStart: hourStart,
      energyKwh: energyKwh,
      powerSum: powerSum,
      powerMin: powerMin,
      powerMax: powerMax,
      voltageSum: voltageSum,
      voltageMin: voltageMin,
      voltageMax: voltageMax,
      currentSum: currentSum,
      currentMax: currentMax,
      frequencySum: frequencySum,
      frequencyMin: frequencyMin,
      frequencyMax: frequencyMax,
      powerFactorSum: powerFactorSum,
      powerFactorMin: powerFactorMin,
      sampleCount: _samplesPerHour,
      observedSeconds: 3600,
      estimatedIntervals: 0,
      coveragePct: 100,
      quality: EnergyDataQuality.complete,
    );
  }

  /// Daya satu sampel dalam watt.
  double _wattsAt(DateTime hourStart, int seed) {
    final base = _hourlyLoadKw[hourStart.hour];
    final weekend = hourStart.weekday >= DateTime.saturday
        ? _weekendFactor
        : 1.0;
    // Pergantian harian supaya pola konsumsi tidak terlihat persis berulang.
    final daySeed = hourStart.millisecondsSinceEpoch ~/ 86400000;
    final daily = 1 + (_unit(daySeed) - 0.5) * 0.18;
    // Derbyau 0,85 sampai 1,15, cukup untuk membuat grafik tidak lurus.
    final jitter = 0.85 + 0.30 * _unit(seed);
    return base * 1000 * weekend * daily * jitter;
  }

  /// Bilangan pecahan 0 sampai 1 yang deterministik untuk [seed] mana pun.
  ///
  /// Pakai bilangan bulat, bukan `sin`, supaya hasilnya persis sama di semua
  /// platform dan bisa diuji tanpa toleransi.
  static double _unit(int seed) {
    var x = (seed ^ 0x5bf03635) & 0x7fffffff;
    x = (x * 1103515245 + 12345) & 0x7fffffff;
    x = (x ^ (x >> 13)) & 0x7fffffff;
    return (x % 10000) / 10000.0;
  }
}
