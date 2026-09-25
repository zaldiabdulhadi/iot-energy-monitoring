import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/energy_topics.dart';
import '../providers/energy_data_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/status_pill.dart';

class MqttSettingsScreen extends StatefulWidget {
  const MqttSettingsScreen({super.key});

  @override
  State<MqttSettingsScreen> createState() => _MqttSettingsScreenState();
}

class _MqttSettingsScreenState extends State<MqttSettingsScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  Timer? _clock;
  bool _obscurePassword = true;

  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _portController = TextEditingController(text: '8883');
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _clock?.cancel();
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _elapsed(DateTime since) {
    final diff = DateTime.now().difference(since);
    final h = diff.inHours;
    final m = diff.inMinutes.remainder(60);
    final s = diff.inSeconds.remainder(60);
    if (h > 0) return '${h}j ${m}m ${s}d';
    if (m > 0) return '${m}m ${s}d';
    return '${s}d';
  }

  Future<void> _handleConnect() async {
    final provider = context.read<EnergyDataProvider>();

    if (provider.connected) {
      await provider.disconnect();
      return;
    }

    final host = _hostController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 8883;
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (host.isEmpty || username.isEmpty || password.isEmpty) {
      _showError('Host, Username, dan Password wajib diisi.');
      return;
    }

    await provider.connect(
      host: host,
      port: port,
      username: username,
      password: password,
    );

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
        title: const Text('Koneksi MQTT'),
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
          _buildTopicsCard(),
        ],
      ),
    );
  }

  Widget _buildStatusCard(EnergyDataProvider provider) {
    final connected = provider.connected;
    final connecting = provider.connecting;

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
            child: connecting
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                : connected
                    ? AnimatedBuilder(
                        animation: _pulseCtrl,
                        builder: (context, child) => Transform.scale(
                          scale: 1.0 + (_pulseCtrl.value * 0.09),
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
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.sensors_off_rounded,
                          color: AppColors.warning,
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
                      connected
                          ? 'Terkoneksi'
                          : connecting
                              ? 'Menghubungkan…'
                              : 'Belum terhubung',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepGreen,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (connected)
                      const StatusPill(label: 'Live', tone: PillTone.success),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  connected
                      ? provider.connectedHost ?? ''
                      : provider.demoMode
                          ? 'Mode Demo aktif — simulasi berjalan.'
                          : 'Mode Demo menunggu…',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (connected && provider.connectedSince != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Terhubung ${_elapsed(provider.connectedSince!)}',
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
      (label: 'Tegangan', value: _fmt(provider.voltage, 1), unit: 'V', icon: Icons.bolt_rounded),
      (label: 'Arus', value: _fmt(provider.current, 2), unit: 'A', icon: Icons.waves_rounded),
      (label: 'Daya', value: _fmt(provider.currentKw, 2), unit: 'kW', icon: Icons.electric_meter_rounded),
      (label: 'Energi', value: _fmt(provider.energyToday, 1), unit: 'kWh', icon: Icons.energy_savings_leaf_rounded),
      (label: 'Frekuensi', value: _fmt(provider.frequency, 2), unit: 'Hz', icon: Icons.speed_rounded),
      (label: 'Faktor daya', value: _fmt(provider.powerFactor, 2), unit: 'PF', icon: Icons.tune_rounded),
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
            for (final r in readings)
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
                        Icon(r.icon, size: 15, color: AppColors.primaryDark),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            r.label,
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
                        text: r.value,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        children: [
                          TextSpan(
                            text: ' ${r.unit}',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 8),
          child: Text(
            'Konfigurasi broker',
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
              Text(
                'Host',
                style: _labelStyle(),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _hostController,
                enabled: !provider.connected,
                decoration: const InputDecoration(
                  hintText: 'mis. broker.hivemq.cloud',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Port',
                style: _labelStyle(),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _portController,
                enabled: !provider.connected,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: '8883 / 8084'),
              ),
              const SizedBox(height: 16),
              Text(
                'Username',
                style: _labelStyle(),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _usernameController,
                enabled: !provider.connected,
                decoration: const InputDecoration(hintText: 'username broker'),
              ),
              const SizedBox(height: 16),
              Text(
                'Password',
                style: _labelStyle(),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                enabled: !provider.connected,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'password broker',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed:
                      provider.connecting ? null : _handleConnect,
                  icon: Icon(
                    provider.connected
                        ? Icons.power_settings_new_rounded
                        : Icons.bolt_rounded,
                    size: 18,
                  ),
                  label: Text(
                    provider.connecting
                        ? 'Menghubungkan…'
                        : provider.connected
                            ? 'Putuskan Koneksi'
                            : 'Connect',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  TextStyle _labelStyle() => const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      );

  Widget _buildTopicsCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 8),
          child: Text(
            'Topic yang wajib cocok di firmware ESP',
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
                'Sesuaikan topik publikasi PZEM-004T di firmware ESP32 '
                'dengan daftar di lib/config/energy_topics.dart. '
                'Nilai dikirim sebagai teks (double), dipisah per topic.',
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              for (final t in [
                [EnergyTopics.power, 'Watt'],
                [EnergyTopics.voltage, 'Volt'],
                [EnergyTopics.current, 'Ampere'],
                [EnergyTopics.energy, 'kWh'],
                [EnergyTopics.frequency, 'Hz'],
                [EnergyTopics.powerFactor, '0..1'],
                [EnergyTopics.solarPower, 'Watt (opsional)'],
              ]) ...[
                _topicRow(t[0], t[1]),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _topicRow(String topic, String unit) {
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
            topic,
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
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  String _fmt(double value, int decimals) =>
      value.toStringAsFixed(decimals).replaceAll('.', ',');
}