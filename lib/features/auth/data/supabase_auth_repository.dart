import 'package:flutter/foundation.dart';
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

  static final UserProfile demoEncargado = UserProfile(
    id: 'demo-chef-456',
    email: 'carlos.chef@restaurante.com',
    fullName: 'Chef Carlos Mendoza',
    role: 'encargado',
    department: 'Cocina & Restaurante',
    isPensioner: false,
    monthlyExpense: 0.0,
  );

  static final UserProfile demoInstitucion = UserProfile(
    id: 'demo-admin-789',
    email: 'admin.rrhh@institucion.gob.bo',
    fullName: 'Lic. Mariana Gómez',
    role: 'institucion',
    department: 'Dirección de Recursos Humanos',
    isPensioner: false,
    monthlyExpense: 0.0,
  );

  Future<UserProfile?> getCurrentUser() async {
    final client = SupabaseConfig.client;
    if (client == null) {
      return _localSession ?? demoEmpleado;
    }

    try {
      final user = client.auth.currentUser;
      if (user == null) {
        return _localSession;
      }

      final profileData = await client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profileData != null) {
        return UserProfile.fromJson(profileData);
      }

      return UserProfile(
        id: user.id,
        email: user.email ?? '',
        fullName: user.userMetadata?['full_name'] ?? 'Usuario',
        role: user.userMetadata?['role'] ?? 'empleado',
      );
    } catch (e) {
      debugPrint('⚠️ Error obteniendo usuario actual de Supabase: $e');
      return _localSession ?? demoEmpleado;
    }
  }

  Future<UserProfile> signInWithEmailPassword(
      String email, String password) async {
    final client = SupabaseConfig.client;
    if (client == null) {
      // Modo demo / offline: login simulado
      final profile = UserProfile(
        id: 'usr-${email.hashCode}',
        email: email,
        fullName: email.split('@').first.toUpperCase(),
        role: email.contains('chef') || email.contains('encargado')
            ? 'encargado'
            : email.contains('admin')
                ? 'institucion'
                : 'empleado',
      );
      _localSession = profile;
      return profile;
    }

    final authRes = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = authRes.user;
    if (user == null) {
      throw Exception('Credenciales incorrectas');
    }

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

    final fallbackProf = UserProfile(
      id: user.id,
      email: user.email ?? email,
      fullName: user.userMetadata?['full_name'] ?? 'Usuario',
      role: user.userMetadata?['role'] ?? 'empleado',
    );
    _localSession = fallbackProf;
    return fallbackProf;
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

    // Insertar perfil en la tabla 'profiles'
    final profile = UserProfile(
      id: user.id,
      email: email,
      fullName: fullName,
      role: role,
    );

    try {
      await client.from('profiles').upsert(profile.toJson());
    } catch (e) {
      debugPrint('⚠️ Error guardando perfil en Supabase: $e');
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

  void switchDemoUser(UserProfile demoUser) {
    _localSession = demoUser;
  }
}
