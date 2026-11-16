/// Configuración pública de la sincronización móvil.
///
/// La clave publicable de Supabase se pasa al compilar mediante
/// `--dart-define`; nunca se incluye una clave de servicio en el teléfono.
/// FastAPI mantiene la validación comercial, Caja e inventario.
class MobileSyncConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static bool get isConfigured =>
      supabaseUrl.startsWith('https://') && supabasePublishableKey.isNotEmpty;

  /// Dirección de respaldo para trabajar por Wi-Fi dentro de la óptica cuando
  /// no hay Internet. Se suministra al compilar o se ajusta desde Ajustes.
  static const localBackendUrl = String.fromEnvironment('LOCAL_BACKEND_URL');
}
