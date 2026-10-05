package com.smartenergy.smart_energy

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            downloadsChannel,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveToDownloads" -> {
                    val fileName = call.argument<String>("fileName")
                    val bytes = call.argument<ByteArray>("bytes")
                    if (fileName == null || bytes == null) {
                        result.error(
                            "invalid_arguments",
                            "fileName dan bytes wajib diisi",
                            null,
                        )
                    } else {
                        try {
                            result.success(saveToDownloads(fileName, bytes))
                        } catch (error: Exception) {
                            result.error("save_failed", error.message, null)
                        }
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    /**
     * Menulis berkas ke folder Downloads milik pengguna.
     *
     * Android 10 ke atas memakai MediaStore, jadi tidak butuh izin penyimpanan
     * apa pun. Android 9 ke bawah belum punya MediaStore.Downloads dan menulis
     * ke folder publik membutuhkan izin runtime, jadi fallenya ke folder
     * eksternal aplikasi yang selalu boleh dipakai tanpa izin.
     */
    private fun saveToDownloads(fileName: String, bytes: ByteArray): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val resolver = contentResolver
            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                put(MediaStore.Downloads.MIME_TYPE, "text/csv")
                put(
                    MediaStore.Downloads.RELATIVE_PATH,
                    "${Environment.DIRECTORY_DOWNLOADS}/WattSerra",
                )
                // Pending mencegah berkas setengah jadi muncul di Downloads.
                put(MediaStore.Downloads.IS_PENDING, 1)
            }

            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                ?: throw IllegalStateException("MediaStore menolak menyimpan berkas")
            resolver.openOutputStream(uri)?.use { it.write(bytes) }
                ?: throw IllegalStateException("Gagal menulis berkas")
            values.clear()
            values.put(MediaStore.Downloads.IS_PENDING, 0)
            resolver.update(uri, values, null, null)

            return "Download/WattSerra/$fileName"
        }

        val directory = getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS) ?: filesDir
        val file = File(directory, fileName)
        file.writeBytes(bytes)
        return file.absolutePath
    }

    private companion object {
        const val downloadsChannel = "com.smartenergy.smart_energy/downloads"
    }
}
