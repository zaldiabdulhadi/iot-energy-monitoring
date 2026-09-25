import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/energy_data_provider.dart';
import '../services/energy_api_client.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/status_pill.dart';

class EspApiSettingsScreen extends StatefulWidget {
  const EspApiSettingsScreen({super.key});

  @override
  State<EspApiSettingsScreen> createState() => _EspApiSettingsScreenState();
}

class _EspApiSettingsScreenState extends State<EspApiSettingsScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  final TextEditingController _endpointController = TextEditingController(
    text: EnergyApiClient.defaultEndpoint.toString(),
  );
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _clock?.cancel();
    _endpointController.dispose();
    super.dispose();
  }

  String _elapsed(DateTime since) {
    final difference = DateTime.now().difference(since);
    final hours = difference.inHours;
    final minutes = difference.inMinutes.remainder(60);
    final seconds = difference.inSeconds.remainder(60);
    if (hours > 0) return '${hours}j ${minutes}m ${seconds}d';
    if (minutes > 0) return '${minutes}m ${seconds}d';
    return '${seconds}d';
  }

  Future<void> _handleConnect(EnergyDataProvider provider) async {
    final connectionActive = provider.connected || !provider.demoMode;
    if (connectionActive) {
      await provider.disconnect();
      return;
    }

    final endpoint = Uri.tryParse(_endpointController.text.trim());
    if (endpoint == null ||
        (endpoint.scheme != 'http' && endpoint.scheme != 'https') ||
        endpoint.host.isEmpty) {
      _showError('Masukkan URL API ESP yang valid.');
      return;
    }

    await provider.connect(endpoint: endpoint);
    if (mounted && provider.error != null) {
      _showError(provider.error!);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.critical,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EnergyDataProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Koneksi API ESP'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _buildStatusCard(provider),
          const SizedBox(height: 20),
          _buildLatestReading(provider),
          const SizedBox(height: 20),
          _buildConfigForm(provider),
          const SizedBox(height: 20),
          _buildApiCard(),
        ],
      ),
    );
  }

  Widget _buildStatusCard(EnergyDataProvider provider) {
    final connectionActive = provider.connected || !provider.demoMode;
    final hasError = connectionActive && provider.error != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8F6EB), Color(0xFFF8FAF9)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: provider.connecting
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                : provider.connected
                ? AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) => Transform.scale(
                      scale: 1 + _pulseController.value * 0.09,
                      child: child,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: AppColors.success,
                        size: 32,
                      ),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: hasError
                          ? AppColors.critical.withValues(alpha: 0.16)
                          : AppColors.warning.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      hasError
                          ? Icons.cloud_off_rounded
                          : Icons.sensors_off_rounded,
                      color: hasError ? AppColors.critical : AppColors.warning,
                      size: 32,
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      provider.connected
                          ? 'Data API aktif'
                          : provider.connecting
                          ? 'Mengambil data…'
                          : hasError
                          ? 'Koneksi terputus'
                          : 'Mode demo aktif',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepGreen,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (provider.connected)
                      const StatusPill(label: 'Live', tone: PillTone.success),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  provider.error ??
                      (connectionActive
                          ? provider.endpoint.toString()
                          : 'Hubungkan perangkat ke hotspot ESP.'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: provider.error == null
                        ? AppColors.textSecondary
                        : AppColors.critical,
                  ),
                ),
                if (provider.connectedSince != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Terhubung ${_elapsed(provider.connectedSince!)}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ] else if (provider.lastUpdated != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Terakhir diperbarui ${_elapsed(provider.lastUpdated!)} lalu',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLatestReading(EnergyDataProvider provider) {
    final readings = [
      (
        label: 'Tegangan',
        value: _format(provider.voltage, 1),
        unit: 'V',
        icon: Icons.bolt_rounded,
      ),
      (
        label: 'Arus',
        value: _format(provider.current, 2),
        unit: 'A',
        icon: Icons.waves_rounded,
      ),
      (
        label: 'Daya',
        value: _format(provider.currentKw, 2),
        unit: 'kW',
        icon: Icons.electric_meter_rounded,
      ),
      (
        label: 'Energi',
        value: _format(provider.energyToday, 1),
        unit: 'kWh',
        icon: Icons.energy_savings_leaf_rounded,
      ),
      (
        label: 'Frekuensi',
        value: _format(provider.frequency, 2),
        unit: 'Hz',
        icon: Icons.speed_rounded,
      ),
      (
        label: 'Faktor daya',
        value: _format(provider.powerFactor, 2),
        unit: 'PF',
        icon: Icons.tune_rounded,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 8),
          child: Text(
            'Data terakhir diterima',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.25,
          children: [
            for (final reading in readings)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Icon(
                          reading.icon,
                          size: 15,
                          color: AppColors.primaryDark,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            reading.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(
                        text: reading.value,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        children: [
                          TextSpan(
                            text: ' ${reading.unit}',
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildConfigForm(EnergyDataProvider provider) {
    final connectionActive = provider.connected || !provider.demoMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 8),
          child: Text(
            'Konfigurasi API',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: AppTheme.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Endpoint API',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _endpointController,
                enabled: !connectionActive && !provider.connecting,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: const InputDecoration(
                  hintText: 'http://192.168.4.1/api/air-quality',
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.sync_rounded,
                      size: 18,
                      color: AppColors.primaryDark,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pembaruan otomatis setiap 5 detik',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: provider.connecting
                      ? null
                      : () => _handleConnect(provider),
                  icon: Icon(
                    connectionActive
                        ? Icons.power_settings_new_rounded
                        : Icons.cloud_download_rounded,
                    size: 18,
                  ),
                  label: Text(
                    provider.connecting
                        ? 'Mengambil data…'
                        : connectionActive
                        ? 'Putuskan Koneksi'
                        : 'Ambil Data',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildApiCard() {
    const fields = [
      ('voltage', 'Volt'),
      ('current', 'Ampere'),
      ('power', 'Watt'),
      ('energy', 'kWh'),
      ('frequency', 'Hz'),
      ('pf', '0..1'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 8),
          child: Text(
            'Format data ESP',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'API mengembalikan objek JSON numerik dengan field berikut:',
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              for (final field in fields) ...[
                _fieldRow(field.$1, field.$2),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _fieldRow(String field, String unit) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            field,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.deepGreen,
              fontFamily: 'monospace',
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          unit,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  String _format(double value, int decimals) =>
      value.toStringAsFixed(decimals).replaceAll('.', ',');
}
