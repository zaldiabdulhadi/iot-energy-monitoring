-- Skema backend cloud untuk aplikasi IoT Smart Energy.
--
-- Cerminan 1:1 dari tabel Drift lokal (`local_devices` dan `hourly_queue`),
-- kecuali kolom *sync bookkeeping* (sync_state, attempts, last_error, synced_at)
-- yang sengaja tidak ikut karena itu urusan lokal device saja.
--
-- Satuan: energi kWh, tegangan Volt, arus Ampere, daya Watt, frekuensi Hz,
-- faktor daya 0..1.

create table public.devices (
  id                  uuid primary key,
  name                text        not null default 'ESP Smart Energy',
  endpoint            text,
  timezone            text        not null default 'Asia/Jakarta',
  tariff_per_kwh      double precision not null default 1650,
  grid_co2_kg_per_kwh double precision not null default 0.42,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

create table public.energy_hourly (
  device_id           uuid        not null references public.devices (id) on delete cascade,
  hour_start          timestamptz not null,
  energy_kwh          double precision not null default 0,
  power_sum           double precision not null default 0,
  power_min           double precision,
  power_max           double precision,
  voltage_sum         double precision not null default 0,
  voltage_min         double precision,
  voltage_max         double precision,
  current_sum         double precision not null default 0,
  current_max         double precision,
  frequency_sum       double precision not null default 0,
  frequency_min       double precision,
  frequency_max       double precision,
  power_factor_sum    double precision not null default 0,
  power_factor_min    double precision,
  sample_count        integer     not null default 0,
  observed_seconds    double precision not null default 0,
  estimated_intervals integer     not null default 0,
  coverage_pct        double precision not null default 0,
  data_quality        text        not null default 'partial',
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  primary key (device_id, hour_start),
  constraint energy_hourly_quality_chk
    check (data_quality in ('complete', 'partial', 'estimated'))
);

-- Primary key (device_id, hour_start) sudah melayani query per-perangkat.
-- Indeks ini khusus untuk "N jam terakhir lintas perangkat".
create index energy_hourly_hour_desc_idx
  on public.energy_hourly (hour_start desc);

create or replace function public.set_updated_at() returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger devices_set_updated_at
  before update on public.devices
  for each row execute function public.set_updated_at();

create trigger energy_hourly_set_updated_at
  before update on public.energy_hourly
  for each row execute function public.set_updated_at();

-- Row level security.
--
-- Single-user tanpa Supabase Auth: role `anon` adalah role publik, jadi tanpa
-- policy tambahan siapa pun yang memegang publishable key bisa membaca dan
-- menulis seluruh tabel. Supaya tetap tanpa login tetapi tidak terbuka lebar,
-- policy di sini mewajibkan header `x-sync-secret`.
--
-- CATATAN KEAMANAN: ini bukan keamanan sungguhan. Nilainya ada di dalam binary
-- aplikasi dan bisa dibongkar. Yang dilakukan fungsi ini adalah memindahkan
-- hambatan dari "punya publishable key" menjadi "punya publishable key DAN
-- binary aplikasi". Untuk mengisolasi data per pengguna, ganti dengan Supabase
-- Auth dan policy berbasis auth.uid().

-- Helper agar policy tidak mengulang cast langsung dan tidak bisa salah ketik
-- nama header. Argumen kedua current_setting() wajib true supaya tidak error
-- ketika header tidak ada sama sekali. Fungsi ini harus dibuat sebelum policy
-- karena PostgreSQL memvalidasi ekspresi policy saat pembuatan.
create or replace function public.read_sync_secret() returns text
language sql
stable
security invoker
set search_path = ''
as $$
  select coalesce(
    nullif(
      (nullif(current_setting('request.headers', true), '')::jsonb ->> 'x-sync-secret'),
      ''
    ),
    ''
  );
$$;

alter table public.devices enable row level security;
alter table public.energy_hourly enable row level security;

create policy "sync_secret_all" on public.devices
  for all to anon
  using (public.read_sync_secret() = 'GANTI_DENGAN_SYNC_SECRET_ANDA')
  with check (public.read_sync_secret() = 'GANTI_DENGAN_SYNC_SECRET_ANDA');

create policy "sync_secret_all" on public.energy_hourly
  for all to anon
  using (public.read_sync_secret() = 'GANTI_DENGAN_SYNC_SECRET_ANDA')
  with check (public.read_sync_secret() = 'GANTI_DENGAN_SYNC_SECRET_ANDA');

-- Proyek Supabase sudah memasang default privileges untuk schema public, tapi
-- granting eksplisit agar migrasi ini tidak bergantung pada itu.
grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on table public.devices to anon, authenticated;
grant select, insert, update, delete on table public.energy_hourly to anon, authenticated;
grant execute on function public.read_sync_secret() to anon, authenticated;
