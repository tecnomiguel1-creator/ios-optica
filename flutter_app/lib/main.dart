import 'package:flutter/material.dart';
import 'app.dart';
import 'core/sync/supabase_sync_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseSyncBootstrap.initialize();
  runApp(const OnlyEyesApp());
}
