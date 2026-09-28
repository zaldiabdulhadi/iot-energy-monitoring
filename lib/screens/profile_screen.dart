import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/energy_data_provider.dart';
import '../providers/energy_history_provider.dart';
import '../providers/sync_status_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/layout.dart';
import '../widgets/metric_tile.dart';
import '../widgets/status_pill.dart';
import 'esp_api_settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final gutters = Gutters.of(context);

    return ListView(
      padding: gutters.all,
      children: [
        Text(
          'Profil',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 18),
        _buildProfileCard(textTheme),
        const SizedBox(height: 20),
        _buildUsageCard(),
        const SizedBox(height: 20),
        // Tidak ada penyimpanan preferensi di aplikasi ini, jadi baris di sini
        // hanya menampilkan nilai yang benar-benar berlaku. Menampilkan sakelar
        // atau tanda panah untuk sesuatu yang tidak bisa dibuka akan menyesatkan.
        _settingsGroup(
          title: 'Umum',
          children: [
            _SettingTile(
              icon: Icons.language_rounded,
              label: 'Bahasa',
              subtitle: 'Bahasa Indonesia',
            ),
            _SettingTile(
              icon: Icons.straighten_rounded,
              label: 'Satuan energi',
              subtitle: 'kWh',
            ),
          ],
        ),
          const SizedBox(height: 20),
          _settingsGroup(
            title: 'Koneksi & Info',
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const EspApiSettingsScreen(),
                  ),
                ),
                child: Consumer<EnergyDataProvider>(
                  builder: (context, provider, _) => _SettingTile(
                    icon: Icons.hub_outlined,
                    label: 'Koneksi API ESP',
                    subtitle: provider.connected
                        ? provider.connectedEndpoint.toString()
                        : provider.demoMode
                            ? 'Mode demo · hubungkan ke hotspot ESP'
                            : provider.error ?? 'Koneksi API terputus',
                    trailing: provider.connecting
                        ? const StatusPill(
                            label: 'Menghubungkan',
                            tone: PillTone.info,
                          )
                        : provider.connected
                            ? const StatusPill(
                                label: 'Live',
                                tone: PillTone.success,
                                icon: Icons.check_rounded,
                              )
                            : provider.demoMode
                                ? const StatusPill(
                                    label: 'Demo',
                                    tone: PillTone.warning,
                                  )
                                : const StatusPill(
                                    label: 'Error',
                                    tone: PillTone.critical,
                                  ),
                  ),
                ),
              ),
              _SyncTile(),
              _SettingTile(
                icon: Icons.info_outline_rounded,
                label: 'Tentang Smart Energy',
                subtitle: 'v1.0.0 · aplikasi pemantau listrik ESP',
              ),
            ],
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  /// Kartu identitas aplikasi.
  ///
  /// Tidak ada login di aplikasi ini, jadi nama dan alamat penghuni tidak
  /// ditampilkan: mengarang identitas hanya membuat pengguna mengira datanya
  /// milik-premises tertentu. Yang ditampilkan adalah sumber data yang
  /// sebenarnya sedang dipakai.
  Widget _buildProfileCard(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8F6EB), Color(0xFFDDF3E3)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.bolt_rounded,
                  size: 30,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart Energy',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepGreen,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pemantau listrik ESP',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const _SourcePill(),
            ],
          ),
        ],
      ),
    );
  }

  /// Ringkasan konsumsi dari riwayat yang benar-benar terekam.
  Widget _buildUsageCard() {
    return Consumer<EnergyHistoryProvider>(
      builder: (context, history, _) {
        final summary = history.summary;

        if (summary == null || history.isEmpty) {
          return const AppCard(
            child: Row(
              children: [
                Icon(Icons.hourglass_empty_rounded,
                    size: 20, color: AppColors.textMuted),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Belum ada riwayat. Konsumsi harian dan mingguan muncul '
                    'setelah jam-jam pertama terekam.',
                    style: TextStyle(
                        fontSize: 11.5, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          );
        }

        final days = summary.period.span.inDays;
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                days > 1
                    ? 'Konsumsi ${summary.period.label.toLowerCase()}'
                    : 'Konsumsi hari ini',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 10),
              AdaptiveNumber(
                value: formatValue(summary.totalKwh, 2),
                suffix: 'kWh',
                fontSize: 28,
                color: AppColors.deepGreen,
              ),
              const SizedBox(height: 12),
              MetricGrid(
                tiles: [
                  SummaryTile(
                    label: 'Rata-rata daya',
                    value: formatValue(summary.averagePowerKw, 2),
                    suffix: 'kW',
                    icon: Icons.electric_meter_rounded,
                    caption: 'seluruh periode',
                  ),
                  SummaryTile(
                    label: 'Data terekam',
                    value: '${summary.observedHours}',
                    suffix: 'jam',
                    icon: Icons.schedule_rounded,
                    caption: 'dari ${summary.expectedHours} jam',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _settingsGroup({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: AppTheme.softShadow,
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  const Divider(
                    indent: 62,
                    color: AppColors.border,
                  ),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }

}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;

  /// Widget di kanan baris. Kosong untuk baris yang informatif saja dan tidak
  /// bisa diketuk.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 18, color: AppColors.primaryDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Trailing dibuat fleksibel supaya di layar sempit pill statusnya
          // yang dipotong elipsis, bukan membuat baris meluber melewati tepi.
          if (trailing != null) Flexible(child: trailing!),
        ],
      ),
    );
  }
}

/// Menampilkan sumber data yang sedang aktif, jadi pengguna selalu tahu angka
/// di layar berasal dari meter sungguhan atau dari simulasi.
class _SourcePill extends StatelessWidget {
  const _SourcePill();

  @override
  Widget build(BuildContext context) {
    return Consumer<EnergyDataProvider>(
      builder: (context, provider, _) {
        if (provider.connecting) {
          return const StatusPill(
            label: 'Menghubungkan',
            tone: PillTone.info,
          );
        }
        if (provider.connected) {
          return const StatusPill(
            label: 'Live',
            tone: PillTone.success,
            icon: Icons.check_rounded,
          );
        }
        if (provider.demoMode) {
          return const StatusPill(
            label: 'Demo',
            tone: PillTone.warning,
          );
        }
        return const StatusPill(label: 'Error', tone: PillTone.critical);
      },
    );
  }
}

/// Baris "Sinkronisasi data" yang menampilkan kondisi antrean unggahan yang
/// sebenarnya: berapa jam yang belum terkirim, kapan sinkronisasi terakhir
/// berhasil, dan pesan error bila ada.
class _SyncTile extends StatelessWidget {
  const _SyncTile();

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncStatusProvider>(
      builder: (context, sync, _) {
        final lastSynced = sync.lastSyncedAt;
        final localizations = MaterialLocalizations.of(context);

        final String subtitle;
        if (!sync.isEnabled) {
          // Ketiganya wajib, karena policy RLS menolak request tanpa
          // x-sync-secret. Menyebutkan hanya SUPABASE_URL akan membuat pengguna
          // mengisi dua define lalu tetap gagal sinkronisasi.
          subtitle = 'Isi SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, dan '
              'SUPABASE_SYNC_SECRET saat build untuk mengaktifkan';
        } else if (sync.error != null) {
          subtitle = sync.error!;
        } else if (lastSynced != null) {
          subtitle = 'Terakhir sinkron '
              '${localizations.formatMediumDate(lastSynced)} '
              '${localizations.formatTimeOfDay(
            TimeOfDay.fromDateTime(lastSynced),
            alwaysUse24HourFormat: true,
          )}';
        } else {
          subtitle = 'Belum ada data yang tersinkron';
        }

        return _SettingTile(
          icon: Icons.cloud_sync_outlined,
          label: 'Sinkronisasi data',
          subtitle: subtitle,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pill dibuat fleksibel supaya tombol sinkronkan selalu punya
              // ruang. Tanpa ini, label status yang panjang membuat seluruh
              // baris meluber di layar sempit.
              Flexible(
                child: StatusPill(
                  label: sync.statusLabel,
                  tone: _toneOf(sync),
                  icon: sync.isSyncing ? Icons.sync_rounded : null,
                ),
              ),
              if (sync.isEnabled) ...[
                const SizedBox(width: 4),
                IconButton(
                  onPressed: sync.isSyncing ? null : sync.syncNow,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  tooltip: 'Sinkronkan sekarang',
                  color: AppColors.textMuted,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  static PillTone _toneOf(SyncStatusProvider sync) {
    if (!sync.isEnabled) return PillTone.neutral;
    if (sync.isSyncing) return PillTone.info;
    if (sync.error != null) return PillTone.critical;
    if (sync.hasPending) return PillTone.warning;
    return PillTone.success;
  }
}