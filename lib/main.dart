import 'package:flutter/material.dart';

import 'app.dart';
import 'config/supabase_config.dart';
import 'data/local/app_database.dart';
import 'data/remote/energy_remote_data_source.dart';
import 'services/energy_sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = EnergyDatabase();

  // Client null kalau SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY tidak diisi.
  // Aplikasi tetap berjalan penuh secara lokal dalam kasus itu.
  final supabaseClient = SupabaseConfig.createClient();

  runApp(
    SmartEnergyApp(
      database: database,
      syncService: EnergySyncService(
        database: database,
        remote: supabaseClient == null
            ? null
            : EnergyRemoteDataSource(supabaseClient),
      ),
    ),
  );
}
