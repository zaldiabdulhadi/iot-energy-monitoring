-- Menambahkan penanda asal-usul data ke `energy_hourly`.
--
-- Aplikasi berjalan tanpa ESP terpasang, jadi mode demo merekam agregat per jam
-- seperti pengukuran sungguhan. Tanpa kolom ini, data karangan di server tidak
-- bisa dibedakan dari hasil pengukuran. Default `false` menjaga seluruh baris
-- lama tetap dibaca sebagai pengukuran, yang memang benar: sebelum kolom ini
-- ada, semua data berasal dari ESP.
alter table public.energy_hourly
  add column if not exists is_demo boolean not null default false;

comment on column public.energy_hourly.is_demo is
  'true bila agregat per jam ini mengandung data simulasi, bukan pengukuran ESP';

-- Index parsial untuk pembacaan panel yang hanya mau melihat pengukuran nyata.
-- Baris demo sengaja tidak ikut terindeks karena jumlahnya bisa besar dan
-- tidak pernah dipakai untuk angka resmi.
create index if not exists energy_hourly_measured_idx
  on public.energy_hourly (hour_start desc)
  where not is_demo;
