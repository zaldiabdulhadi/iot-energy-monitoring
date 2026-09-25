import 'package:flutter/material.dart';

import 'app.dart';
import 'data/local/app_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = EnergyDatabase();
  runApp(SmartEnergyApp(database: database));
}
