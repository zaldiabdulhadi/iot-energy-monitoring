import 'package:supabase_flutter/supabase_flutter.dart';

/// Konfigurasi backend Supabase, dibaca dari `--dart-define` saat build.
///
/// ```
/// flutter run \
///   --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///   --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxx \
///   --dart-define=SUPABASE_SYNC_SECRET=rahasia-anda
/// ```
///
/// Kalau salah satu nilai di atas kosong, [isConfigured] bernilai false dan
/// aplikasi berjalan sepenuhnya lokal: pencatatan energi tetap jalan, hanya
/// sinkronisasi ke cloud yang dinonaktifkan.
class SupabaseConfig {
  const SupabaseConfig._();

  static const String url = String.fromEnvironment('SUPABASE_URL');

  static const String publishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  /// Dibandingkan oleh policy RLS `sync_secret_all` di backend.
  static const String syncSecret =
      String.fromEnvironment('SUPABASE_SYNC_SECRET');

  /// Header yang wajib ada agar policy RLS mengizinkan akses.
  static const String syncSecretHeader = 'x-sync-secret';

  /// Ketiga nilai wajib ada, bukan hanya URL dan publishable key.
  ///
  /// [syncSecret] ikut diperiksa karena policy RLS menolak setiap request yang
  /// tidak membawa header `x-sync-secret`. Kalau secret dikosongkan, sinkronisasi
  /// akan gagal dengan 403 di setiap percobaan tanpa memberi petunjuk penyebab,
  /// jadi lebih baik aplikasi melaporkannya sebagai "belum dikonfigurasi".
  static bool get isConfigured =>
      url.isNotEmpty && publishableKey.isNotEmpty && syncSecret.isNotEmpty;

  /// Membuat client Supabase baru.
  ///
  /// Sengaja memakai konstruktor [SupabaseClient] langsung, bukan singleton
  /// global `Supabase.initialize`, supaya client bisa di-inject ke dalam
  /// `EnergyRemoteDataSource` dan diganti dengan `MockClient` saat pengujian.
  static SupabaseClient? createClient() {
    if (!isConfigured) return null;
    return SupabaseClient(
      url,
      publishableKey,
      headers: const {syncSecretHeader: syncSecret},
    );
  }
}
