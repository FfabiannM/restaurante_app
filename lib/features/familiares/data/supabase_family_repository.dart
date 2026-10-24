import 'package:flutter/foundation.dart';
import 'package:restaurante_app/core/config/supabase_config.dart';
import 'package:restaurante_app/features/familiares/domain/familiar_entity.dart';
import 'package:restaurante_app/features/familiares/domain/family_policy.dart';
import 'package:restaurante_app/features/familiares/domain/family_repository.dart';

class SupabaseFamilyRepository implements FamilyRepository {
  /// Datos de familiares precargados para pruebas y modo offline.
  /// Cada empleado puede tener hasta 3 familiares registrados.
  static final Map<String, List<Familiar>> _mockFamilyStore = {
    'demo-user-123': [
      const Familiar(
        id: 'fam-1',
        empleadoId: 'demo-user-123',
        ci: '8492011',
        nombres: 'Sofía',
        apellidos: 'Pérez',
        parentesco: 'Hija',
        activo: true,
      ),
      const Familiar(
        id: 'fam-2',
        empleadoId: 'demo-user-123',
        ci: '8492012',
        nombres: 'Mateo',
        apellidos: 'Pérez',
        parentesco: 'Hijo',
        activo: true,
      ),
      const Familiar(
        id: 'fam-3',
        empleadoId: 'demo-user-123',
        ci: '5938210',
        nombres: 'Carmen',
        apellidos: 'López',
        parentesco: 'Cónyuge',
        activo: true,
      ),
    ],
  };

  /// Limpia los familiares de prueba en memoria.
  static void clearMockFamilyStore([String? empleadoId]) {
    if (empleadoId != null) {
      _mockFamilyStore[empleadoId] = [];
    } else {
      _mockFamilyStore.clear();
      _mockFamilyStore['demo-user-123'] = [];
      _mockFamilyStore['demo-emp-002'] = [];
      _mockFamilyStore['demo-emp-003'] = [];
      _mockFamilyStore['demo-emp-004'] = [];
    }
  }

  /// Restablece los familiares de prueba iniciales para pruebas.
  static void resetMockFamilyStore() {
    _mockFamilyStore.clear();
    _mockFamilyStore['demo-user-123'] = [
      const Familiar(
        id: 'fam-1',
        empleadoId: 'demo-user-123',
        ci: '8492011',
        nombres: 'Sofía',
        apellidos: 'Pérez',
        parentesco: 'Hija',
        activo: true,
      ),
      const Familiar(
        id: 'fam-2',
        empleadoId: 'demo-user-123',
        ci: '8492012',
        nombres: 'Mateo',
        apellidos: 'Pérez',
        parentesco: 'Hijo',
        activo: true,
      ),
      const Familiar(
        id: 'fam-3',
        empleadoId: 'demo-user-123',
        ci: '5938210',
        nombres: 'Carmen',
        apellidos: 'López',
        parentesco: 'Cónyuge',
        activo: true,
      ),
    ];
  }

  @override
  Future<List<Familiar>> getFamilyMembers(String empleadoId) async {
    final client = SupabaseConfig.client;

    if (client == null) {
      return _getMockFamily(empleadoId);
    }

    try {
      final response = await client
          .from('familiares')
          .select()
          .eq('empleado_id', empleadoId)
          .eq('activo', true)
          .limit(FamilyPolicy.maxFamilyMembersPerEmployee);

      final List<dynamic> data = response as List<dynamic>;
      if (data.isEmpty) {
        return [];
      }

      final list = data
          .map((item) => Familiar.fromJson(item as Map<String, dynamic>))
          .toList();

      return FamilyPolicy.enforceLimit(list);
    } catch (e) {
      debugPrint(
        '⚠️ Error consultando familiares en Supabase ($e). Usando datos precargados.',
      );
      return _getMockFamily(empleadoId);
    }
  }

  @override
  Future<bool> canUseRestaurantService(
    String empleadoId,
    String familiarId,
  ) async {
    final members = await getFamilyMembers(empleadoId);
    return FamilyPolicy.isFamilyMemberAuthorized(
      familiarId: familiarId,
      employeeFamilyMembers: members,
    );
  }

  List<Familiar> _getMockFamily(String empleadoId) {
    if (_mockFamilyStore.containsKey(empleadoId)) {
      return FamilyPolicy.enforceLimit(_mockFamilyStore[empleadoId]!);
    }
    return [];
  }
}
