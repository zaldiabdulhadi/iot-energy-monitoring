import 'package:flutter/foundation.dart';

/// Sinyal bahwa riwayat yang sudah dibaca Somewhere berubah karena aksi
/// pengguna, bukan karena ada rekaman baru.
///
/// Ini ada karena ada **dua** instance [EnergyHistoryProvider] yang hidup
/// bersamaan: satu di atas aplikasi untuk Dashboard dan Profil, satu lagi di
/// dalam tab Analisis. `context.read` dari Profil hanya bisa menemukan yang di
/// atas aplikasi, jadi memuat ulang provider itu tidak pernah menyentuh angka
/// yang sedang tampil di tab Analisis.
///
/// Berdiri sendiri, bukan turunan dari [EnergyDataProvider], karena provider
/// itu memanggil `notifyListeners()` setiap lima detik saat polling. Kalau tab
/// Analisis berlangganan ke sana, layarnya dibangun ulang terus-menerus tanpa
/// ada yang berubah.
class HistoryInvalidator extends ChangeNotifier {
  /// Memberi tahu semua pembaca riwayat bahwa angka yang mereka pegang sudah
  /// usang dan harus dimuat ulang.
  void invalidate() => notifyListeners();
}
