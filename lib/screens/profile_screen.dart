import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/energy_data_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/status_pill.dart';
import 'esp_api_settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static final _f = NumberFormat.decimalPattern('id');

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
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
          _buildBillingCard(),
          const SizedBox(height: 20),
          _settingsGroup(
            title: 'Umum',
            children: [
              _SettingTile(
                icon: Icons.notifications_none_rounded,
                label: 'Notifikasi',
                subtitle: 'Alarm beban, tagihan & tips hemat',
                trailing: Switch(value: true, onChanged: (_) {}),
              ),
              _SettingTile(
                icon: Icons.wifi_tethering_rounded,
                label: 'Mode Hemat Daya',
                subtitle: 'Optimasi otomatis perangkat aktif',
                trailing: Switch(value: false, onChanged: (_) {}),
              ),
              _SettingTile(
                icon: Icons.language_rounded,
                label: 'Bahasa',
                subtitle: 'Bahasa Indonesia',
                trailing: _chevron(),
              ),
              _SettingTile(
                icon: Icons.straighten_rounded,
                label: 'Satuan energi',
                subtitle: 'kWh · Rupiah',
                trailing: _chevron(),
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
              _SettingTile(
                icon: Icons.cloud_sync_outlined,
                label: 'Sinkronisasi data',
                subtitle: 'Ambil data API setiap 5 detik',
                trailing: const StatusPill(
                  label: 'Aktif',
                  tone: PillTone.success,
                  icon: Icons.sync_rounded,
                ),
              ),
              _SettingTile(
                icon: Icons.help_outline_rounded,
                label: 'Pusat bantuan',
                trailing: _chevron(),
              ),
              _SettingTile(
                icon: Icons.info_outline_rounded,
                label: 'Tentang Smart Energy',
                subtitle: 'v1.0.0',
                trailing: _chevron(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {},
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.textPrimary,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

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
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: Text(
                  'A',
                  style: textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alex Nugraha',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepGreen,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.home_rounded,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Rumah Asri Residence · Blok C12',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const StatusPill(
                label: 'Premium',
                tone: PillTone.info,
                icon: Icons.workspace_premium_rounded,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _profileStat(value: '8,6', unit: 'kWh', label: 'Rata-rata harian'),
              _profileStat(value: 'Rp 486k', unit: '/bulan', label: 'Estimasi tagihan'),
              _profileStat(value: '6', unit: 'unit', label: 'Perangkat'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _profileStat({
    required String value,
    required String unit,
    required String label,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text.rich(
            TextSpan(
              text: value,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.deepGreen,
              ),
              children: [
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: AppColors.primaryDark,
              size: 23,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tagihan ${_f.format(416)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      Icons.event_available_rounded,
                      size: 13,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Jatuh tempo 10 Okt · sudah dibayar',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textMuted,
          ),
        ],
      ),
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

  Widget _chevron() => const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textMuted,
      );
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.label,
    required this.trailing,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget trailing;

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
          trailing,
        ],
      ),
    );
  }
}