import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/energy_data_provider.dart';
import 'screens/home_shell.dart';
import 'theme/app_theme.dart';

class SmartEnergyApp extends StatelessWidget {
  const SmartEnergyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EnergyDataProvider()..startDemo(),
      child: MaterialApp(
        title: 'Smart Energy',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const HomeShell(),
      ),
    );
  }
}