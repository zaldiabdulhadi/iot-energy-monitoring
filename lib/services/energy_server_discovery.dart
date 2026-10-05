import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Collector yang ditemukan di jaringan lokal.
class DiscoveredCollector {
  const DiscoveredCollector({
    required this.endpoint,
    required this.rows,
    this.lastSeen,
  });

  /// Alamat siap pakai untuk polling dan impor riwayat.
  final Uri endpoint;

  /// Nilai `rows` dari `/health`, dipakai sebagai penanda bahwa host ini
  /// memang collector dan bukan layanan lain.
  final int rows;

  /// Waktu sampel terakhir yang tercatat di server tersebut.
  ///
  /// Nullable karena `data.db` masih boleh kosong. Null **tidak** boleh
  /// dianggap paling segar: dua collector yang sama-sama masih kosong tidak
  /// bisa dibedakan, jadi yang sudah punya data harus menang.
  final DateTime? lastSeen;

  /// Mengurutkan collector mana yang paling layak dipakai.
  ///
  /// Yang punya data lebih baru datang lebih dulu, dan yang tanpa `lastSeen`
  /// ditempatkan paling akhir.
  static int compareFreshness(DiscoveredCollector a, DiscoveredCollector b) {
    final left = a.lastSeen;
    final right = b.lastSeen;
    if (left != null && right != null) {
      final byTime = right.compareTo(left);
      if (byTime != 0) return byTime;
    } else if (left == null && right != null) {
      return 1;
    } else if (left != null && right == null) {
      return -1;
    }
    // `lastSeen` sama, atau sama-sama kosong karena `data.db` belum terisi.
    // `List.sort` tidak menjamin kestabilan, jadi alamat ikut dibandingkan supaya
    // collector yang dipilih tidak berganti-ganti pada data yang sama.
    return a.endpoint.host.compareTo(b.endpoint.host);
  }
}

/// Mencari collector `server/app.py` di jaringan WiFi yang sedang dipakai.
///
/// Masalah yang dipecahkan: alamat IP server dari DHCP berubah sewaktu-waktu,
/// sedangkan pengguna tidak akan mengetik ulang URL setiap kali berganti.
/// Aplikasi menyapu seluruh blok /24 miliknya sendiri dan memeriksa setiap
/// host yang menjawab di [port], lalu menyimpan alamat yang ketemu sebagai
/// endpoint. Jadi penyapuan hanya perlu berhasil sekali.
///
/// Yang diperiksa bukan "ada yang menjawab di port 5000", melainkan `/health`
/// yang membawa penanda `service`. Tanpa itu, backend atau layanan lain di
/// port yang sama akan tertukar dengan collector ini dan aplikasi akan
/// membaca JSON yang salah bentuk tanpa pernah mengeluh.
///
/// Batasan yang disengaja:
/// - Hanya IPv4 privat. Di seluler atau di jaringan publik tidak ada yang bisa
///   menjawab, jadi penyapuan dilewati seluruhnyaalih-alih menembak 254 host.
/// - Ada [overallBudget]. Jaringan yang membuang semua packet akan menggantung
///   penuh; setelah anggaran habis, penyapuan menyerah dan dianggap "tidak
///   ketemu" supaya pemanggil bisa jatuh ke jalur lain.
class EnergyServerDiscovery {
  EnergyServerDiscovery({
    http.Client? client,
    this.port = 5000,
    this.probeTimeout = const Duration(milliseconds: 350),
    this.batchSize = 32,
    this.overallBudget = const Duration(seconds: 6),
    Future<List<String>> Function()? candidates,
  })  : _client = client ?? http.Client(),
        _candidates = candidates ?? _hostsFromInterfaces;

  final http.Client _client;
  final Future<List<String>> Function() _candidates;

  final int port;

  /// Batas waktu per probe.
  ///
  /// Harus jauh lebih pendek dari [overallBudget], kalau tidak kelompok pertama
  /// saja sudah menghabiskan seluruh anggaran.
  final Duration probeTimeout;

  /// Berapa host yang diperiksa bersamaan.
  ///
  /// 32 membuat penyapuan selesai sekitar 3 detik di LAN biasa, sambil tetap
  /// menahan jumlah socket yang masuk akal untuk perangkat seluler.
  final int batchSize;

  final Duration overallBudget;

  /// Penanda yang harus dikembalikan `/health` milik collector.
  ///
  /// Harus sama persis dengan `SERVICE_NAME` di `server/app.py`.
  static const String serviceName = 'wattserra-collector';

  /// Path penanda di server.
  static const String healthPath = '/health';

  /// Path data di server, dipakai untuk menyusun endpoint hasil penemuan.
  static const String dataPath = '/api/data';

  /// Menemukan collector di jaringan, atau null kalau tidak ada.
  ///
  /// Host yang menjawab lebih dari satu bukan kondisi error: yang paling baru
  /// punya data yang dipilih, karena mesin yang sedang dipakai biasanya juga
  /// yang benar-benar ditembak ESP32.
  Future<DiscoveredCollector?> discover() async {
    final hosts = await _candidates();
    if (hosts.isEmpty) return null;

    final deadline = DateTime.now().add(overallBudget);
    final found = <DiscoveredCollector>[];

    for (final batch in _batched(hosts, batchSize)) {
      // Diperiksa sebelum probe berikutnya dimulai: anggaran habis di tengah
      // kelompok tetap menyisakan kelompok terakhir terlewati.
      if (DateTime.now().isAfter(deadline)) break;
      final results = await Future.wait(batch.map(_probe));
      for (final collector in results) {
        if (collector != null) found.add(collector);
      }
    }

    if (found.isEmpty) return null;
    found.sort(DiscoveredCollector.compareFreshness);
    return found.first;
  }

  /// Memeriksa satu host. Tidak pernah melempar.
  ///
  /// Host mati, timeout, atau jawabannya milik layanan lain semuanya berarti
  /// "bukan collector" dan tidak boleh menggagalkan penyapuan yang lain.
  Future<DiscoveredCollector?> _probe(String host) async {
    final uri = Uri.parse('http://$host:$port$healthPath');
    try {
      final response = await _client.get(uri).timeout(probeTimeout);
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return null;
      // Dicocokkan dari hasil parse, bukan dari pencarian teks di respons
      // mentah. Pencarian teks cuma penghematan biaya parse untuk 253 host
      // yang bukan collector.
      if (decoded['service'] != serviceName) return null;

      final lastSeen = decoded['last_seen'];
      return DiscoveredCollector(
        endpoint: Uri.parse('http://$host:$port$dataPath'),
        rows: _readInt(decoded['rows']),
        lastSeen: lastSeen is String ? DateTime.tryParse(lastSeen) : null,
      );
    } on TimeoutException {
      return null;
    } on http.ClientException {
      return null;
    } on FormatException {
      return null;
    } on SocketException {
      return null;
    }
  }

  /// Membagi daftar host menjadi kelompok berukuran [size].
  ///
  /// Dipisah dari [discover] supaya jumlah probe yang berjalan bersamaan selalu
  /// terbatas, bukan 254 socket sekaligus.
  static Iterable<List<String>> _batched(List<String> items, int size) sync* {
    final step = size <= 0 ? items.length : size;
    for (var start = 0; start < items.length; start += step) {
      final end = start + step;
      yield items.sublist(start, end > items.length ? items.length : end);
    }
  }

  static int _readInt(Object? value) => value is num ? value.toInt() : 0;

  /// Host yang layak disapu: seluruh blok /24 privat milik antarmuka yang
  /// sedang aktif, dikecualikan alamat perangkat sendiri.
  ///
  /// Dipisah dari [discover] dan bisa diganti lewat constructor supaya tes
  /// bisa menjalankan penyapuan penuh tanpa jaringan sungguhan.
  static Future<List<String>> _hostsFromInterfaces() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
      includeLinkLocal: false,
    );
    final hosts = <String>{};
    for (final interface in interfaces) {
      for (final address in interface.addresses) {
        final parts = address.address.split('.');
        if (parts.length != 4) continue;
        if (!_isPrivate(parts)) continue;

        final prefix = parts.take(3).join('.');
        final own = parts[3];
        for (var host = 1; host <= 254; host++) {
          final name = host.toString();
          if (name == own) continue;
          hosts.add('$prefix.$name');
        }
      }
    }
    return hosts.toList();
  }

  /// Hanya blok privat yang layak disapu.
  ///
  /// `172.16` sampai `172.31` adalah satu blok /12, bukan dua, jadi batas atas
  /// diperiksa inklusif. Tanpa itu, HP di seluler dengan alamat `172.32.x.x`
  /// akan salah dianggap sedang di jaringan lokal dan menembak 254 host sia.
  static bool _isPrivate(List<String> parts) {
    final first = int.tryParse(parts[0]) ?? -1;
    final second = int.tryParse(parts[1]) ?? -1;
    if (first == 10) return true;
    if (first == 192 && second == 168) return true;
    return first == 172 && second >= 16 && second <= 31;
  }

  void close() => _client.close();
}