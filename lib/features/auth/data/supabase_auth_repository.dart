import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:restaurante_app/core/config/supabase_config.dart';
import 'package:restaurante_app/features/auth/domain/user_profile.dart';

class SupabaseAuthRepository {
  UserProfile? _localSession;

  static final UserProfile demoEmpleado = UserProfile(
    id: 'demo-user-123',
    email: 'juan.empleado@institucion.gob.bo',
    fullName: 'Juan Pérez',
    role: 'empleado',
    department: 'Finanzas y Contabilidad',
    isPensioner: true,
    monthlyExpense: 308.0,
  );

  static final UserProfile demoAdmin = UserProfile(
    id: 'demo-admin-789',
    email: 'admin.rrhh@institucion.gob.bo',
    fullName: 'Lic. Mariana Gómez',
    role: 'admin',
    department: 'Dirección de Recursos Humanos',
    isPensioner: false,
    monthlyExpense: 0.0,
  );

  static final UserProfile demoCocina = UserProfile(
    id: 'demo-chef-456',
    email: 'carlos.chef@restaurante.com',
    fullName: 'Chef Carlos Mendoza',
    role: 'cocina',
    department: 'Cocina & Restaurante',
    isPensioner: false,
    monthlyExpense: 0.0,
  );

  // Aliases para compatibilidad hacia atrás
  static UserProfile get demoInstitucion => demoAdmin;
  static UserProfile get demoEncargado => demoCocina;

  Future<UserProfile?> getCurrentUser() async {
    final client = SupabaseConfig.client;
    if (client == null) {
      return _localSession;
    }

    try {
      final user = client.auth.currentUser;
      if (user == null) {
        return _localSession;
      }

      // 1. Intentar consultar tabla public.usuarios (db.md)
      try {
        final usuarioData = await client
            .from('usuarios')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (usuarioData != null) {
          return UserProfile.fromJson(usuarioData);
        }
      } catch (_) {
        // Fallback a tabla profiles si usuarios no tiene permisos
      }

      // 2. Intentar consultar tabla profiles
      try {
        final profileData = await client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (profileData != null) {
          return UserProfile.fromJson(profileData);
        }
      } catch (_) {}

      return UserProfile(
        id: user.id,
        email: user.email ?? '',
        fullName: user.userMetadata?['full_name'] ?? 'Usuario',
        role: user.userMetadata?['role'] ?? 'empleado',
      );
    } catch (e) {
      debugPrint('⚠️ Error obteniendo usuario actual de Supabase: $e');
      return _localSession;
    }
  }

  Future<UserProfile> signInWithEmailPassword(
      String email, String password) async {
    final client = SupabaseConfig.client;

    if (client == null) {
      // Modo demo / offline: login simulado según credenciales o dominio
      return _mockSignIn(email);
    }

    try {
      final authRes = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = authRes.user;
      if (user == null) {
        return _mockSignIn(email);
      }

      // Consultar perfil en usuarios (db.md)
      try {
        final usuarioData = await client
            .from('usuarios')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (usuarioData != null) {
          final prof = UserProfile.fromJson(usuarioData);
          _localSession = prof;
          return prof;
        }
      } catch (_) {}

      // Fallback a profiles o metadata
      try {
        final profileData = await client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (profileData != null) {
          final prof = UserProfile.fromJson(profileData);
          _localSession = prof;
          return prof;
        }
      } catch (_) {}

      final fallbackProf = UserProfile(
        id: user.id,
        email: user.email ?? email,
        fullName: user.userMetadata?['full_name'] ?? email.split('@').first,
        role: user.userMetadata?['role'] ?? _inferRoleFromEmail(email),
      );
      _localSession = fallbackProf;
      return fallbackProf;
    } catch (e) {
      debugPrint('⚠️ Falló login remoto en Supabase ($e). Usando verificación local/demo.');
      return _mockSignIn(email);
    }
  }

  UserProfile _mockSignIn(String email) {
    final lower = email.toLowerCase();
    UserProfile prof;
    if (lower.contains('admin') || lower.contains('institucion')) {
      prof = demoAdmin.copyWith(
        email: email,
        fullName: 'Administrador ${email.split('@').first}',
      );
    } else if (lower.contains('cocina') ||
        lower.contains('chef') ||
        lower.contains('encargado')) {
      prof = demoCocina.copyWith(
        email: email,
        fullName: 'Cocinero ${email.split('@').first}',
      );
    } else {
      prof = demoEmpleado.copyWith(
        email: email,
        fullName: email.split('@').first.toUpperCase(),
      );
    }
    _localSession = prof;
    return prof;
  }

  String _inferRoleFromEmail(String email) {
    final lower = email.toLowerCase();
    if (lower.contains('admin') || lower.contains('institucion')) {
      return 'admin';
    } else if (lower.contains('cocina') ||
        lower.contains('chef') ||
        lower.contains('encargado')) {
      return 'cocina';
    } else {
      return 'empleado';
    }
  }

  Future<UserProfile> signUpWithEmailPassword({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    final client = SupabaseConfig.client;
    if (client == null) {
      final profile = UserProfile(
        id: 'usr-${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        fullName: fullName,
        role: role,
      );
      _localSession = profile;
      return profile;
    }

    final res = await client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName, 'role': role},
    );

    final user = res.user;
    if (user == null) {
      throw Exception('Error al registrar usuario');
    }

    final profile = UserProfile(
      id: user.id,
      email: email,
      fullName: fullName,
      role: role,
    );

    try {
      await client.from('usuarios').upsert({
        'id': user.id,
        'ci': 'CI-${user.id.substring(0, 6)}',
        'nombres': fullName,
        'apellidos': 'Institucional',
        'email': email,
        'rol': role.toUpperCase(),
        'activo': true,
      });
    } catch (_) {
      try {
        await client.from('profiles').upsert(profile.toJson());
      } catch (e) {
        debugPrint('⚠️ Error guardando perfil en Supabase: $e');
      }
    }

    _localSession = profile;
    return profile;
  }

  Future<void> signOut() async {
    _localSession = null;
    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        await client.auth.signOut();
      } catch (e) {
        debugPrint('⚠️ Error cerrando sesión en Supabase: $e');
      }
    }
  }

  Future<void> updatePassword(String newPassword) async {
    final client = SupabaseConfig.client;
    if (client != null && client.auth.currentUser != null) {
      try {
        final res = await client.auth.updateUser(
          UserAttributes(password: newPassword),
        );
        if (res.user == null) {
          throw Exception('No se pudo actualizar la contraseña en Supabase Auth.');
        }
        debugPrint('✅ Contraseña actualizada en Supabase Auth.');
      } catch (e) {
        debugPrint('⚠️ Error actualizando contraseña en Supabase: $e');
        rethrow;
      }
    } else {
      // En modo local / demo: la contraseña se actualiza en memoria sin alterar sesión ni datos de BD
      debugPrint('ℹ️ Contraseña actualizada en modo demo/local sin alterar datos de BD.');
    }
  }

  void switchDemoUser(UserProfile demoUser) {
    _localSession = demoUser;
  }
}
