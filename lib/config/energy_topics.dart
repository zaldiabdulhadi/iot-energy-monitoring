/// Kontrak topic MQTT yang dipublikasikan ESP32 via modul PZEM-004T.
///
/// Saat firmware ESP sudah siap, samakan prefix/basename topic di sini
/// dengan yang dikirim broker — layar lain otomatis mengikuti tanpa edit.
class EnergyTopics {
  EnergyTopics._();

  static const String base = 'smart_energy/pzem';

  /// Daya nyata dalam Watt (double, contoh: "1246.8").
  static const String power = '$base/power';

  /// Tegangan RMS dalam Volt (double, contoh: "220.4").
  static const String voltage = '$base/voltage';

  /// Arus RMS dalam Ampere (double, contoh: "5.63").
  static const String current = '$base/current';

  /// Energi terakumulasi dalam kWh (double, contoh: "168.5").
  static const String energy = '$base/energy';

  /// Frekuensi jaringan dalam Hz (double, contoh: "50.02").
  static const String frequency = '$base/frequency';

  /// Faktor daya 0..1 (double, contoh: "0.94").
  static const String powerFactor = '$base/power_factor';

  /// Output solar dalam Watt. Opsional; dihilangkan jika tidak dipakai.
  static const String solarPower = 'smart_energy/solar_power';

  static const List<String> all = [
    power,
    voltage,
    current,
    energy,
    frequency,
    powerFactor,
    solarPower,
  ];
}