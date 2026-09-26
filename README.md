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
                            minute_aggregates ──delete──► hourly_queue
                                                              │ sync_state=pending
                                                              ▼
                                              EnergySyncService
                                                              │ upsert batch
                                                              ▼
                                            Supabase / PostgREST
```

Aplikasi bersifat **offline-first**: SQLite lokal (Drift) adalah sumber kebenaran
saat perangkat tidak terhubung, dan Supabase hanya menerima salinan agregat per
jam. Menutup aplikasi tidak kehilangan data pengukuran.

## Struktur data

| Tabel lokal (Drift) | Tabel Supabase | Isi |
|---|---|---|
| `local_devices` | `devices` | Profil perangkat, endpoint, tarif, faktor CO2 |
| `minute_aggregates` | *(tidak diunggah)* | Agregat per menit, dibuang setelah di-rollup |
| `hourly_queue` | `energy_hourly` | Agregat per jam + status sinkronisasi |

Kolom *sync bookkeeping* (`sync_state`, `attempts`, `last_error`, `synced_at`)
hanya ada di sisi lokal karena merupakan urusan device, bukan server. Di sisi
server ada `created_at`/`updated_at` yang dikelola trigger.

Backward compatibility upsert dijamin oleh `uuid` devices yang dibuat client
sebagai primary key, dan primary key komposit `(device_id, hour_start)` untuk
`energy_hourly`.

## Menjalankan

```bash
flutter pub get
dart run build_runner build
flutter run
```

Tanpa sinkronisasi cloud, aplikasi tetap berjalan penuh dan menyimpan data
sepenuhnya lokal.

## Menyaktifkan sinkronisasi Supabase

### 1. Terapkan skema

```bash
supabase db push
```

Alternatif tanpa CLI: tempel `supabase/migrations/20260925000001_init.sql` ke
SQL Editor di dashboard Supabase.

### 2. Ganti nilai policy RLS

Di file migrasi, ganti `'GANTI_DENGAN_SYNC_SECRET_ANDA'` dengan string rahasia
pilihan Anda, lalu terapkan ulang. Nilai yang sama harus dipakai di langkah 3.

> **Catatan keamanan.** Aplikasi ini memakai mode single-user tanpa
> Supabase Auth. Role `anon` bersifat publik, sehingga policy RLS mewajibkan
> header `x-sync-secret` agar tidak terbuka bebas. Ini **bukan keamanan
> sungguhan** — nilainya ada di dalam binary aplikasi dan bisa dibongkar. Yang
> sebenarnya dilakukan adalah menaikkan hambatan dari "punya publishable key"
> menjadi "punya publishable key dan binary aplikasi". Untuk mengisolasi data
> antar pengguna, gantikan dengan Supabase Auth beserta policy berbasis
> `auth.uid()`.

### 3. Jalankan dengan `--dart-define`

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxx \
  --dart-define=SUPABASE_SYNC_SECRET=rahasia-anda
```

Nilai diambil dari `String.fromEnvironment`, jadi tidak ada secrets yang ikut
ter-commit. Ketiganya wajib diisi: tanpa `SUPABASE_SYNC_SECRET`, policy RLS akan
menolak setiap permintaan, jadi aplikasi memperlakukan konfigurasi itu sebagai
belum diatur dan baris "Sinkronisasi data" di layar Profil menampilkan
"Sinkronisasi nonaktif".

Untuk build rilis, triplet yang sama diteruskan ke `flutter build`.

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
