-- Skema backend cloud untuk aplikasi WattSerra.
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
-- Tabel diaktifkan RLS di sini, tapi policy-nya sengaja TIDAK dibuat di file
-- ini. Alasannya: satu-satunya pembatas yang dipakai aplikasi adalah nilai
-- `SUPABASE_SYNC_SECRET`, dan nilai itu tidak boleh masuk ke riwayat git.
-- Migrasi tetap bisa di-commit, tapi tidak pernah memuat rahasia.
--
-- Policy dibuat oleh berkas terpisah, `supabase/setup/enable_rls_policies.sql`,
-- yang di-gitignore. Salin dari `.example`, isi rahasianya, lalu jalankan
-- satu kali per proyek lewat SQL Editor.
--
-- CATATAN KEAMANAN: ini bukan keamanan sungguhan. Nilai `SUPABASE_SYNC_SECRET`
-- ada di dalam binary aplikasi dan bisa dibongkar. Yang dilakukan fungsi ini
-- adalah memindahkan hambatan dari "punya publishable key" menjadi "punya
-- publishable key DAN binary aplikasi". Untuk mengisolasi data per pengguna,
-- ganti dengan Supabase Auth dan policy berbasis auth.uid().

alter table public.devices enable row level security;
alter table public.energy_hourly enable row level security;

-- Proyek Supabase sudah memasang default privileges untuk schema public, tapi
-- granting eksplisit agar migrasi ini tidak bergantung pada itu.
--
-- Perhatikan bahwa `authenticated` punya grant tapi tidak punya policy sampai
-- `enable_rls_policies.sql` dijalankan. Selama itu belum dijalankan, setiap
-- request sebagai `authenticated` akan ditolak RLS dengan 403. Itu disengaja:
-- policy-nya belum diisi, jadi lebih baik menolak daripada membuka akses.
grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on table public.devices to anon, authenticated;
grant select, insert, update, delete on table public.energy_hourly to anon, authenticated;
