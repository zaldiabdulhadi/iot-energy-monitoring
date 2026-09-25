import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/local/app_database.dart';
import 'providers/energy_data_provider.dart';
import 'screens/home_shell.dart';
import 'services/energy_recorder.dart';
import 'theme/app_theme.dart';

class SmartEnergyApp extends StatelessWidget {
  const SmartEnergyApp({super.key, required this.database});

  final EnergyDatabase database;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<EnergyDatabase>.value(value: database),
        ChangeNotifierProvider(
          create: (_) => EnergyDataProvider(
            recorder: EnergyRecorder(
              database: database,
              pollInterval: const Duration(seconds: 5),
            ),
          )..startDemo(),
        ),
      ],
      child: MaterialApp(
        title: 'Smart Energy',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const HomeShell(),
      ),
    );
  }
}
