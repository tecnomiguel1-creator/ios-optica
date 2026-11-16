import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/mobile_sync_config.dart';

/// Inicializa el canal remoto solo cuando se configuró al compilar.
///
/// Las ventas, pagos, caja e inventario siguen pasando por FastAPI, para
/// conservar las validaciones e idempotencia que se usan en Windows.
class SupabaseSyncBootstrap {
  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static Future<void> initialize() async {
    if (!MobileSyncConfig.isConfigured || _initialized) return;

    await Supabase.initialize(
      url: MobileSyncConfig.supabaseUrl,
      publishableKey: MobileSyncConfig.supabasePublishableKey,
    );
    _initialized = true;
  }
}
