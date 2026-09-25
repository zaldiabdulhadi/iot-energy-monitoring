import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/energy_device.dart';
import '../providers/energy_data_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/status_pill.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  final _formatter = NumberFormat.decimalPattern('id');

  String _query = '';
  String _filter = 'Semua';

  static const _filters = ['Semua', 'Aktif', 'Hemat energi'];

  List _visible(EnergyDataProvider provider) {
    return provider.devices.where((d) {
      final matchesQuery = _query.isEmpty ||
          d.name.toLowerCase().contains(_query.toLowerCase()) ||
          d.room.toLowerCase().contains(_query.toLowerCase());
      final matchesFilter = switch (_filter) {
        'Aktif' => d.isOn,
        'Hemat energi' => d.smartLabel != null,
        _ => true,
      };
      return matchesQuery && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EnergyDataProvider>();
    final textTheme = Theme.of(context).textTheme;
    final devices = provider.devices;
    final connected = devices.where((d) => d.isOn).length;
    final saving = devices.where((d) => d.smartLabel != null).length;
    final visible = _visible(provider);

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Perangkat',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${devices.length} perangkat terhubung',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              if (provider.demoMode) ...[
                const StatusPill(label: 'Demo', tone: PillTone.info),
                const SizedBox(width: 8),
              ],
              TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pemindaian jaringan IoT dimulai…'),
                    ),
                  );
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Tambah'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryDark,
                  backgroundColor: AppColors.primaryLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(
              hintText: 'Cari perangkat atau ruangan…',
              prefixIcon: Icon(Icons.search_rounded, size: 20),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _summaryTile(
                  icon: Icons.electric_bolt_rounded,
                  color: AppColors.success,
                  label: 'Terhubung',
                  value: '$connected aktif',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summaryTile(
                  icon: Icons.auto_awesome_rounded,
                  color: AppColors.cyanAccent,
                  label: 'Hemat energi',
                  value: '$saving perangkat',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final f = _filters[index];
                final selected = f == _filter;
                return ChoiceChip(
                  label: Text(f),
                  selected: selected,
                  onSelected: (_) => setState(() => _filter = f),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Column(
                children: [
                  const Icon(
                    Icons.devices_other_rounded,
                    size: 44,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tidak ada perangkat yang cocok',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            ...visible.map((d) => _DeviceCard(
                  device: d,
                  formatter: _formatter,
                  onToggle: (v) => provider.setDeviceOn(d.id, v),
                )),
        ],
      ),
    );
  }

  Widget _summaryTile({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({
    required this.device,
    required this.formatter,
    required this.onToggle,
  });

  final EnergyDevice device;
  final NumberFormat formatter;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final isSolar = device.powerDrawKw < 0;
    final pct = (device.powerDrawKw.abs() / 2.0).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: device.iconBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              device.icon,
              size: 23,
              color: isSolar ? AppColors.warning : AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        device.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (device.smartLabel != null) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.cyanAccent,
                        size: 14,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  device.room,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    StatusPill(
                      label: isSolar
                          ? 'Menghasilkan'
                          : device.isOn
                              ? 'Aktif'
                              : 'Mati',
                      tone: device.isOn
                          ? (isSolar ? PillTone.info : PillTone.success)
                          : PillTone.neutral,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isSolar
                          ? '+${formatter.format(device.powerDrawKw.abs())} kW'
                          : '${formatter.format(device.powerDrawKw)} kW',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (device.trend != 0 && device.isOn) ...[
                      const SizedBox(width: 8),
                      _trendBadge(device.trend),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 4,
                    color: isSolar
                        ? AppColors.warning
                        : device.isOn
                            ? AppColors.primaryDark
                            : AppColors.border,
                    backgroundColor: AppColors.primaryLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Switch(
            value: device.isOn,
            onChanged: onToggle,
          ),
        ],
      ),
    );
  }

  Widget _trendBadge(double trend) {
    final up = trend > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: (up ? AppColors.warning : AppColors.success).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: 13,
            color: up ? AppColors.warning : AppColors.success,
          ),
          const SizedBox(width: 2),
          Text(
            '${trend.abs().toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: up ? AppColors.warning : AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}