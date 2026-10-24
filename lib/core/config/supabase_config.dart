import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String dishImagesBucket = 'platos';

  /// URL del proyecto Supabase.
  /// Puede ser configurada mediante variables de entorno (--dart-define=SUPABASE_URL=...)
  /// o editando esta constante con tu URL de Supabase.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://qnieqczrdyxyhpepjduj.supabase.co',
  );

  /// Clave anónima pública de Supabase (anon public key).
  /// Puede configurarse mediante --dart-define=SUPABASE_ANON_KEY=...
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_s7ww56WzXyW76KlH-cqvfQ_SgdpLsX7',
  );

  static bool _isInitialized = false;

  /// Retorna si Supabase está activo y conectado.
  static bool get isInitialized => _isInitialized;

  /// Retorna el cliente Supabase si está disponible.
  static SupabaseClient? get client {
    if (_isInitialized) {
      try {
        return Supabase.instance.client;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Convierte una ruta guardada en la tabla `platos` en una URL pública del
  /// bucket de imágenes. Las rutas locales se dejan para el fallback de demo.
  static String? publicDishImageUrl(String? rawPath) {
    final path = rawPath?.trim() ?? '';
    if (path.isEmpty) return null;

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    if (path.startsWith('assets/')) return null;

    final normalizedPath = path
        .replaceFirst(RegExp(r'^/+'), '')
        .replaceFirst(RegExp('^$dishImagesBucket/'), '');
    final supabaseClient = client;
    if (supabaseClient == null || normalizedPath.isEmpty) return null;

    return supabaseClient.storage
        .from(dishImagesBucket)
        .getPublicUrl(normalizedPath);
  }

  /// Inicializa Supabase de manera tolerante a fallos.
  /// Si la URL no es válida o no hay conexión, la app inicia en modo demostración/híbrido.
  static Future<void> initialize() async {
    try {
      if (supabaseUrl.isNotEmpty &&
          supabaseUrl.startsWith('https://') &&
          !supabaseUrl.contains('demo-restaurante')) {
        await Supabase.initialize(
          url: supabaseUrl,
          publishableKey: supabaseAnonKey,
          authOptions: const FlutterAuthClientOptions(
            authFlowType: AuthFlowType.pkce,
          ),
        );
        _isInitialized = true;
        debugPrint('✅ Supabase inicializado correctamente.');
      } else {
        debugPrint(
          'ℹ️ Supabase no configurado con credenciales reales. Iniciando en modo local/demo.',
        );
        _isInitialized = false;
      }
    } catch (e) {
      debugPrint('⚠️ Error al inicializar Supabase ($e). Modo local activo.');
      _isInitialized = false;
    }
  }

  /// Comprueba el estado de la conexión a Supabase y retorna un diagnóstico legible.
  static Future<Map<String, dynamic>> checkConnectionHealth() async {
    final client = SupabaseConfig.client;
    if (!_isInitialized || client == null) {
      return {
        'connected': false,
        'message': 'Supabase no inicializado o modo local activo',
        'url': supabaseUrl,
      };
    }
    try {
      final res = await client.from('platos').select('id').limit(1);
      return {
        'connected': true,
        'message': 'Conexión exitosa a Supabase y tablas accesibles',
        'url': supabaseUrl,
        'data': res,
      };
    } catch (e) {
      return {
        'connected': true,
        'message':
            'Cliente conectado con éxito al endpoint (RLS o permisos requeridos): $e',
        'url': supabaseUrl,
      };
    }
  }
}
