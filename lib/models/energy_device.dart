import 'package:flutter/material.dart';

/// A connected IoT device in the smart home energy grid.
class EnergyDevice {
  const EnergyDevice({
    required this.id,
    required this.name,
    required this.room,
    required this.icon,
    required this.iconBackground,
    required this.powerDrawKw,
    required this.isOn,
    required this.trend,
    this.smartLabel,
  });

  final String id;
  final String name;
  final String room;
  final IconData icon;
  final Color iconBackground;
  final double powerDrawKw;
  final bool isOn;

  /// Hour-over-hour change in percent, e.g. -12.5 means 12.5% decrease.
  final double trend;
  final String? smartLabel;

  EnergyDevice copyWith({bool? isOn, double? powerDrawKw}) {
    return EnergyDevice(
      id: id,
      name: name,
      room: room,
      icon: icon,
      iconBackground: iconBackground,
      powerDrawKw: powerDrawKw ?? this.powerDrawKw,
      isOn: isOn ?? this.isOn,
      trend: trend,
      smartLabel: smartLabel,
    );
  }

  static List<EnergyDevice> get seedData => [
        EnergyDevice(
          id: 'dev_01',
          name: 'Smart LED Panel',
          room: 'Ruang Keluarga',
          icon: Icons.lightbulb_outline_rounded,
          iconBackground: const Color(0xFFE8F6EB),
          powerDrawKw: 0.042,
          isOn: true,
          trend: -8.2,
          smartLabel: 'Efisiensi 92%',
        ),
        EnergyDevice(
          id: 'dev_02',
          name: 'AC Inverter 1 PK',
          room: 'Kamar Tidur',
          icon: Icons.ac_unit_rounded,
          iconBackground: const Color(0xFFE3F4F4),
          powerDrawKw: 0.86,
          isOn: true,
          trend: 12.4,
          smartLabel: 'Mode Eco aktif',
        ),
        EnergyDevice(
          id: 'dev_03',
          name: 'Refrigerator',
          room: 'Dapur',
          icon: Icons.kitchen_rounded,
          iconBackground: const Color(0xFFE9F0FB),
          powerDrawKw: 0.18,
          isOn: true,
          trend: -3.1,
        ),
        EnergyDevice(
          id: 'dev_04',
          name: 'Water Heater',
          room: 'Kamar Mandi',
          icon: Icons.hot_tub_rounded,
          iconBackground: const Color(0xFFFBEEE3),
          powerDrawKw: 0.0,
          isOn: false,
          trend: 0.0,
        ),
        EnergyDevice(
          id: 'dev_05',
          name: 'EV Charger 7.4kW',
          room: 'Garasi',
          icon: Icons.ev_station_rounded,
          iconBackground: const Color(0xFFE3F4F4),
          powerDrawKw: 0.42,
          isOn: true,
          trend: 5.6,
          smartLabel: 'Home Solar sync',
        ),
        EnergyDevice(
          id: 'dev_06',
          name: 'Solar Panel 5kWp',
          room: 'Atap',
          icon: Icons.solar_power_rounded,
          iconBackground: const Color(0xFFF5EEDD),
          powerDrawKw: -1.86,
          isOn: true,
          trend: -4.3,
          smartLabel: 'Menghasilkan energi',
        ),
      ];
}