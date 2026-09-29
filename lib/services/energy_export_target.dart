import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Ke mana berkas hasil ekspor dikirim.
///
/// Dipisah dari [_EnergyCsvExporter] supaya penyusunan CSV bisa diuji tanpa
/// menyentuh Android: pengujian memakai [_FakeExportTarget], sementara
/// aplikasi memakai [DeviceEnergyExportTarget].
abstract class EnergyExportTarget {
  /// Menyalin [bytes] ke folder Downloads dan mengembalikan lokasi yang
  /// layak ditampilkan ke pengguna.
  Future<String> saveToDownloads(String fileName, Uint8List bytes);

  /// Membuka lembar bagikan dengan isi [bytes].
  ///
  /// [origin] adalah titik jangkar tombol yang ditekan, dipakai supaya lembar
  /// bagikan tidak mengambang di tengah layar di iPad.
  Future<void> share(
    String fileName,
    Uint8List bytes, {
    String? subject,
    String? text,
    Rect? origin,
  });
}

/// Implementasi sungguhan: simpan lewat kanal Android, lalu bagikan file.
class DeviceEnergyExportTarget implements EnergyExportTarget {
  const DeviceEnergyExportTarget();

  /// Dijaga agar sama persis dengan kanal yang didaftarkan di `MainActivity`.
  static const channelName = 'com.smartenergy.smart_energy/downloads';
  static const MethodChannel _channel = MethodChannel(channelName);

  @override
  Future<String> saveToDownloads(String fileName, Uint8List bytes) async {
    final location = await _channel.invokeMethod<String>(
      'saveToDownloads',
      <String, Object?>{'fileName': fileName, 'bytes': bytes},
    );
    return location ?? fileName;
  }

  @override
  Future<void> share(
    String fileName,
    Uint8List bytes, {
    String? subject,
    String? text,
    Rect? origin,
  }) async {
    // Berkas sementara dipakai untuk dikirim lewat lembar bagikan, karena yang
    // tersimpan di Downloads berupa content URI yang tak bisa dibaca sebagai
    // file biasa.
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[XFile(file.path, name: fileName)],
        fileNameOverrides: <String>[fileName],
        subject: subject,
        text: text,
        sharePositionOrigin: origin,
      ),
    );
  }
}
