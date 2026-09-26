import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/local/app_database.dart';
import '../../models/energy_hourly.dart';

/// Kegagalan saat berkomunikasi dengan backend Supabase.
class EnergyRemoteException implements Exception {
  const EnergyRemoteException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Akses baca/tulis ke tabel `devices` dan `energy_hourly` di Postgres.
///
/// Sengaja menerima sebuah [SupabaseClient] melalui konstruktor supaya bisa
/// diganti dengan client yang memakai `MockClient` saat pengujian.
class EnergyRemoteDataSource {
  const EnergyRemoteDataSource(this._client);

  final SupabaseClient _client;

  /// Kunci konflik untuk tabel `energy_hourly`, sesuai primary key-nya.
  static const String hourlyConflictTarget = 'device_id,hour_start';

  /// Mendaftarkan atau memperbarui profil perangkat.
  ///
  /// Harus dijalankan sebelum mengunggah `energy_hourly` karena ada foreign
  /// key dari `energy_hourly.device_id` ke `devices.id`.
  Future<void> upsertDevice(LocalDeviceRow device) async {
    await _run(() async {
      await _client.from('devices').upsert(
        <String, dynamic>{
          'id': device.localId,
          'name': device.name,
          'endpoint': device.endpoint,
          'timezone': device.timezone,
          'tariff_per_kwh': device.tariffPerKwh,
          'grid_co2_kg_per_kwh': device.gridCo2KgPerKwh,
        },
        // `defaultToNull: false` mengirim `Prefer: missing=default` supaya
        // created_at dan updated_at memakai DEFAULT now() saat INSERT. Tanpa itu
        // PostgREST mengirim NULL eksplisit dan melanggar kolom NOT NULL.
        onConflict: 'id',
        defaultToNull: false,
      );
    }, 'menyimpan profil perangkat');
  }

  /// Mengunggah sekumpulan agregat per jam dalam satu permintaan.
  ///
  /// `ignoreDuplicates: false` membuat PostgREST memakai
  /// `Prefer: resolution=merge-duplicates`, jadi mengunggah ulang jam yang
  /// sama memperbarui nilainya alih-alih membuat baris ganda.
  Future<void> upsertHourly(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    await _run(() async {
      await _client.from('energy_hourly').upsert(
        rows,
        onConflict: hourlyConflictTarget,
        defaultToNull: false,
      );
    }, 'mengunggah data energi');
  }

  /// Membaca agregat per jam dalam rentang setengah terbuka `[from, to)`.
  Future<List<EnergyHourly>> fetchHourlyRange({
    required String deviceId,
    required DateTime from,
    required DateTime to,
  }) async {
    final rows = await _run(() async {
      final result = await _client
          .from('energy_hourly')
          .select()
          .eq('device_id', deviceId)
          .gte('hour_start', from.toUtc().toIso8601String())
          .lt('hour_start', to.toUtc().toIso8601String())
          .order('hour_start', ascending: true);
      return (result as List).cast<Map<String, dynamic>>();
    }, 'mengambil riwayat energi');
    return rows.map(EnergyHourly.fromJson).toList();
  }

  /// Membungkus error jaringan dan PostgREST menjadi pesan yang bisa ditampilkan
  /// pengguna, sekaligus tetap meneruskan [EnergyRemoteException] apa adanya.
  Future<T> _run<T>(Future<T> Function() action, String context) async {
    try {
      return await action();
    } on EnergyRemoteException {
      rethrow;
    } on PostgrestException catch (error) {
      throw EnergyRemoteException('Gagal $context: ${error.message}');
    } catch (error) {
      throw EnergyRemoteException('Gagal $context: $error');
    }
  }
}
