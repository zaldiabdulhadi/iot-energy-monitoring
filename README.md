# IoT Smart Energy Monitoring

Aplikasi Flutter untuk memantau konsumsi listrik dari mikrokontroler ESP (PZEM-004T)
melalui API HTTP, menyimpannya secara lokal, lalu menyinkronkannya ke Supabase.

## Arsitektur

```
ESP ──HTTP GET──► EnergyApiClient ──► EnergyDataProvider
                                          │
                                          ▼
                                    EnergyRecorder
                                          │ rollup 60 menit
                                          ▼
                            minute_aggregates
                                          │
                              ┌───────────┴───────────┐
                              ▼                       ▼
                      hourly_queue              hourly_history
                      (antrean unggah)          (riwayat lokal)
                              │ sync_state=pending
                              ▼
                                              EnergySyncService
                                                              │ upsert batch
                                                              ▼
                                            Supabase / PostgREST
```

`hourly_queue` dan `hourly_history` menerima data yang sama saat jam ditutup, tapi
berumur berbeda: antrean bisa dipangkas setelah 30 hari (`pruneSynced`) karena
salinannya sudah ada di server, sedangkan `hourly_history` tidak pernah dihapus
dan menjadi sumber angka untuk layar Analisis. Karena itu `pruneSynced` tidak
menyentuh tabel riwayat.

Aplikasi bersifat **offline-first**: SQLite lokal (Drift) adalah sumber kebenaran
saat perangkat tidak terhubung, dan Supabase hanya menerima salinan agregat per
jam. Menutup aplikasi tidak kehilangan data pengukuran.

## Struktur data

| Tabel lokal (Drift) | Tabel Supabase | Isi |
|---|---|---|
| `local_devices` | `devices` | Profil meter, endpoint, tarif, faktor CO2 |
| `minute_aggregates` | *(tidak diunggah)* | Agregat per menit, dibuang setelah di-rollup |
| `hourly_queue` | `energy_hourly` | Agregat per jam + status sinkronisasi |
| `hourly_history` | `energy_hourly` | Salinan agregat per jam, tanpa umur, untuk analisis |

Kolom *sync bookkeeping* (`sync_state`, `attempts`, `last_error`, `synced_at`)
hanya ada di sisi lokal karena merupakan urusan device, bukan server. Di sisi
server ada `created_at`/`updated_at` yang dikelola trigger.

Backward compatibility upsert dijamin oleh `uuid` devices yang dibuat client
sebagai primary key, dan primary key komposit `(device_id, hour_start)` untuk
`energy_hourly`.

## Layar

Tiga tab, tanpa tab "Perangkat": JSON ESP tidak memuat identitas perangkat,
sehingga watt per perangkat hanya bisa berupa karangan.

- **Dashboard** — enam metrik yang benar-benar dikirim ESP
  (`voltage`, `current`, `power`, `energy`, `frequency`, `pf`), konsumsi 24 jam
  terakhir, kualitas daya, rekomendasi, dan grafik daya lima menit terakhir.
- **Analisis** — riwayat nyata per jam untuk jendela 24 jam, 7 hari, 30 hari,
  dan 12 bulan terakhir; grafik konsumsi, grafik tiap parameter, tabel
  rentang, dan rekomendasi yang dihitung dari angka itu.
- **Profil** — sumber data yang sedang aktif, ringkasan konsumsi, status
  sinkronisasi, dan konfigurasi API ESP.

Semua angka berasal dari pengukuran. Kalau rentang periode belum punya cukup
baris, layar menampilkan keadaan kosong beserta penjelasannya, bukan angka
perkiraan. Biaya dan jejak karbon memakai tarif serta faktor CO2 dari
`local_devices`, dan nilai tarifnya ikut ditampilkan agar asumsinya terlihat.

### Layar pembuka

Setiap kali aplikasi dibuka, `_IntroGate` di `lib/app.dart` menampilkan logo
`AppSplashLogo` selama 1,5 detik, lalu menampilkan tiga halaman instruksi yang
dapat digeser dengan jari atau lewat tombol "Lewati"/"Lanjut". Isinya
menjelaskan enam metrik yang dibaca ESP, cara membaca riwayat di tab Analisis,
dan cara menghubungkan ESP serta menyinkronkannya ke Supabase. Label metrik di
halaman pertama diambil dari `EnergyMetric.values`, bukan ditulis ulang.

Layar pembuka tidak memakai penyimpanan preferensi, jadi isinya selalu sama dan
tidak ada yang bisa "sudah pernah dilihat". Provider dibuat di atas
`MaterialApp`, sehingga pencatatan metrik berjalan selama layar pembuka tampil
dan tidak ada rekaman yang hilang selama transisi.

### Mode demo

Mode demo menyintesis enam metrik untuk menggerakkan metrik live di Dashboard,
tanpa meter terhubung. Badge "Demo" dan "Mode simulasi" selalu terlihat selama
mode ini aktif.

Simulasi **tetap direkam**, dengan satu syarat: setiap barisnya ditandai
`is_demo`. Jadi riwayat dan analisis punya isi tanpa ESP terpasang, tanpa
perlu ada cara untuk mencampur angka karangan dengan pengukuran.

Aturannya:

- Sumber data di setiap tabel lokal (`minute_aggregates`, `hourly_queue`,
  `hourly_history`) punya kolom `is_demo`.
- Satu menit yang pernah menerima sampel simulasi ditandai simulasi, dan
  penandanya tidak pernah turun kembali meski sampel ESP menyusul di menit yang
  sama. Kunci utama menit hanya `(device_key, minute_start)`, jadi keduanya tidak
  bisa hidup berdampingan; menandai menit tercemar adalah pilihan yang tidak
  membiarkan data karangan lolos sebagai pengukuran.
- Satu menit simulasi sudah menandai seluruh jamnya, karena jam tidak bisa
  menyimpan asal-usul per menitnya di sisi server.
- `EnergySyncService` **menyaring jam simulasi sebelum unggah**. Barisnya tetap
  menggantung di antrean, tidak dihapus, dan badge antrean tidak menghitungnya
  supaya "Menunggu N jam" tidak menggantung selamanya tanpa alasan. Kalau label
  sinkronisasi hanya melihat jam simulasi, ia menulis "Hanya data simulasi".
- Mengunggah data simulasi adalah opt-in lewat
  `EnergySyncService(includeDemo: true)`, dan baris yang dikirim tetap membawa
  `is_demo` ke server. Default-nya `false`.

Cuplikan kodenya:

```dart
// src/simulasi, src/ESP
recorder.record(reading, isDemo: true);
recorder.record(reading, isDemo: false);
```

[`DemoHistory`](../lib/services/demo_history.dart) tetap dipakai sebagai
fallback untuk rentang yang benar-benar kosong, dan baris tiruannya juga
ditandai `isDemo` supaya UI menampilkan sufiks `*`, label sumbu amber, serta
catatan bahwa angkanya bukan pengukuran.

## Menjalankan

```bash
flutter pub get
dart run build_runner build
flutter run
```

Tanpa sinkronisasi cloud, aplikasi tetap berjalan penuh dan menyimpan data
sepenuhnya lokal.

## Menyaktifkan sinkronisasi Supabase

Sinkronisasi dimatikan secara bawaan. Tanpa `--dart-define`, aplikasi tetap
berjalan penuh dan menyimpan data sepenuhnya lokal, dan baris "Sinkronisasi
data" di layar Profil menampilkan "Sinkronisasi nonaktif".

> **Rahasia tidak pernah masuk git.** `SUPABASE_SYNC_SECRET` tertanam di dalam
> binary aplikasi, jadi sekali masuk riwayat git ia bocor permanen. Karena itu
> migrasi di repo ini sengaja **tidak** memuat nilai rahasia apa pun, dan seluruh
> berkas berisi rahasia diabaikan `.gitignore`.

### 1. Terapkan skema

Buka **SQL Editor** di dashboard Supabase, lalu jalankan isi berkas migrasi di
`supabase/migrations` **berurutan**:

1. `20260925000001_init.sql` — tabel, trigger, dan RLS aktif, tanpa policy.
2. `20260928000002_add_is_demo.sql` — kolom `energy_hourly.is_demo` beserta index
   parsialnya. Lewati berkas ini kalau Anda tidak pernah menjalankan aplikasi
   versi yang menandai data simulasi.

Migrasi tidak membuat policy — lihat langkah 2.

Alternatif memakai CLI (butuh Node 20+ dan `supabase login`):

```bash
npm install -D supabase
npx supabase link --project-ref <PROJECT-REF>
npx supabase db push
```

### 2. Pasang policy RLS

Salin templat, lalu isi rahasianya:

```bash
cp supabase/setup/enable_rls_policies.sql.example \
   supabase/setup/enable_rls_policies.sql
# ganti semua GANTI_DENGAN_SECRET_ANDA dengan nilai acak, misalnya:
#   openssl rand -hex 24
```

Jalankan `supabase/setup/enable_rls_policies.sql` di SQL Editor. Berkas itu
sudah idempoten (`drop policy if exists` sebelum `create`), jadi aman dijalankan
ulang setiap kali Anda ingin mengganti rahasia.

Terakhir, paksa PostgREST membaca ulang skema. Tanpa ini, query pertama setelah
DDL masih bisa menjawab 404 palsu karena PostgREST menyimpan cache skema:

```sql
NOTIFY pgrst, 'reload schema';
```

Query verifikasi di akhir berkas itu harus mengembalikan 4 baris policy: dua
untuk role `anon` dan dua untuk `authenticated` di masing-masing tabel. Kalau
hasilnya kosong, policy belum terpasang dan setiap request akan ditolak.

> **Catatan keamanan.** Aplikasi ini memakai mode single-user tanpa
> Supabase Auth. Role `anon` bersifat publik, sehingga policy RLS mewajibkan
> header `x-sync-secret` agar tidak terbuka bebas. Ini **bukan keamanan
> sungguhan** — nilainya ada di dalam binary aplikasi dan bisa dibongkar. Yang
> sebenarnya dilakukan adalah menaikkan hambatan dari "punya publishable key"
> menjadi "punya publishable key dan binary aplikasi".
>
> Policy untuk role `authenticated` sengaja memakai secret yang sama dengan
> policy `anon`, dan itu **bukan** isolasi per pengguna: siapa pun yang punya
> secret tersebut mendapat akses yang sama. Untuk mengisolasi data antar
> pengguna, gantikan dengan Supabase Auth beserta policy berbasis `auth.uid()`.

### 3. Isi kredensial build

```bash
cp .env.local.example .env.local
```

Isi ketiga nilai di dalamnya. `SUPABASE_URL` dan `SUPABASE_PUBLISHABLE_KEY`
diambil dari **Project Settings → Data API**; `SUPABASE_SYNC_SECRET` **harus
sama persis** dengan yang Anda pakai di langkah 2.

### 4. Jalankan

```bash
flutter run --dart-define-from-file=.env.local
```

Ketiganya wajib diisi. Tanpa `SUPABASE_SYNC_SECRET`, policy RLS menolak setiap
permintaan dengan 403 tanpa memberi petunjuk penyebab, jadi aplikasi
memperlakukan konfigurasi itu sebagai belum diatur dan menampilkan
"Sinkronisasi nonaktif". Untuk build rilis, triplet yang sama diteruskan ke
`flutter build` lewat flag yang sama.

### 5. Verifikasi

Layar Profil harus berubah dari "Sinkronisasi nonaktif" menjadi "Tersinkron",
dan angka "Menunggu N jam" turun ke `0`.

Bisa juga dicek langsung dari luar aplikasi:

```bash
curl -s -o /dev/null -w '%{http_code}\n' \
  -H "apikey: $SUPABASE_PUBLISHABLE_KEY" \
  "https://<PROJECT-REF>.supabase.co/rest/v1/energy_hourly?select=hour_start&limit=1"
# 401 atau 403 = RLS aktif, tabel tertutup
# 200 dengan []      = RLS aktif dan request Anda diterima
```

Counterpart-nya di perangkat bisa ditarik untuk dibandingkan:

```bash
adb exec-out run-as com.smartenergy.smart_energy \
  cat app_flutter/smart_energy.sqlite > /tmp/smart_energy.sqlite
sqlite3 /tmp/smart_energy.sqlite \
  "select sync_state, count(*) from hourly_queue group by 1;"
```

Jumlah baris `synced` di sana harus sama dengan `count(*)` dari
`energy_hourly` di cloud.


## Perilaku sinkronisasi

- Otomatis setiap 5 menit, saat aplikasi kembali aktif, dan lewat tombol manual
  di layar Profil.
- Jam yang sudah `synced` tidak diunggah ulang; mengunggah ulang jam yang sama
  memperbarui nilainya karena `upsert` memakai
  `Prefer: resolution=merge-duplicates`.
- Baris yang gagal diunggah dijadwalkan ulang dengan backoff eksponensial
  60s → 120s → 240s, dibatasi 2 jam, lewat kolom `next_attempt_at`.
- Baris `synced` yang lebih tua dari 30 hari dihapus dari antrean lokal
  (`pruneSynced`). Data historis tetap ada di Supabase.
- Data historis yang sudah ada di SQLite lokal ikut terunggah pada sinkronisasi
  pertama, karena seluruhnya berstatus `pending`.

## Pengujian

```bash
flutter analyze
flutter test
```

`SupabaseClient` diinjeksi ke `EnergyRemoteDataSource` sebagai konstruktor,
bukan lewat singleton global, sehingga seluruh jalur jaringan diuji dengan
`MockClient` tanpa koneksi nyata. Perlu menyertakan `request` pada respons tiruan
karena PostgREST membacanya untuk menentukan metode HTTP.

Cakupan test:

- `test/energy_metric_test.dart` — satuan metrik, klasifikasi batas, dan
  konversi watt ke kW.
- `test/energy_history_service_test.dart` — rentang periode, pembagian bucket
  per jam/hari/bulan kalender, kelengkapan data, dan perbandingan periode.
- `test/layout_test.dart` — ketiga tab pada lebar 320, 400, dan 600 dp tanpa
  overflow, plus gutter, jumlah kolom, dan label bilah navigasi.
- `test/onboarding_test.dart` — transisi logo ke halaman instruksi, tombol
  "Lewati"/"Lanjut"/"Mulai", daftar metrik di halaman pertama, dan halaman
  instruksi tanpa overflow pada lebar 320, 400, dan 600 dp. Test ini memakai
  `showIntroOnLaunch` yang bernilai `true`; test lain mengaturnya menjadi
  `false` supaya bisa langsung berinteraksi dengan tab.
- `test/energy_recorder_test.dart`, `test/energy_sync_service_test.dart`,
  `test/energy_data_provider_test.dart`, `test/energy_api_client_test.dart` —
  pencatatan, sinkronisasi, polling, dan parsing API.
