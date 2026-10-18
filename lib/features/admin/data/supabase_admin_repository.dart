import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:restaurante_app/core/config/supabase_config.dart';
import 'package:restaurante_app/features/admin/domain/admin_employee_entity.dart';
import 'package:restaurante_app/features/familiares/data/supabase_family_repository.dart';
import 'package:restaurante_app/features/familiares/domain/familiar_entity.dart';
import 'package:restaurante_app/features/familiares/domain/family_policy.dart';

class SupabaseAdminRepository {
  // Almacén en memoria de empleados y sus familiares asociados para demo y modo local
  final List<AdminEmployee> _employees = [
    AdminEmployee(
      id: 'demo-user-123',
      ci: '4839201',
      nombres: 'Juan',
      apellidos: 'Pérez Mendoza',
      email: 'juan.empleado@institucion.gob.bo',
      telefono: '70612345',
      departamento: 'Finanzas y Contabilidad',
      rol: 'EMPLEADO',
      hasMonthlyPlan: true,
      creadoEn: DateTime.now().subtract(const Duration(days: 90)),
      familiares: const [
        Familiar(
          id: 'fam-1',
          empleadoId: 'demo-user-123',
          ci: '8492011',
          nombres: 'Sofía',
          apellidos: 'Pérez',
          parentesco: 'Hija',
          activo: true,
        ),
        Familiar(
          id: 'fam-2',
          empleadoId: 'demo-user-123',
          ci: '8492012',
          nombres: 'Mateo',
          apellidos: 'Pérez',
          parentesco: 'Hijo',
          activo: true,
        ),
        Familiar(
          id: 'fam-3',
          empleadoId: 'demo-user-123',
          ci: '5938210',
          nombres: 'Carmen',
          apellidos: 'López',
          parentesco: 'Cónyuge',
          activo: true,
        ),
      ],
    ),
    AdminEmployee(
      id: 'demo-emp-002',
      ci: '6192843',
      nombres: 'Roberto',
      apellidos: 'Flores Vargas',
      email: 'roberto.flores@institucion.gob.bo',
      telefono: '71598234',
      departamento: 'Tecnología e Informática',
      rol: 'EMPLEADO',
      hasMonthlyPlan: false, // Tarifa particular 18 Bs
      creadoEn: DateTime.now().subtract(const Duration(days: 60)),
      familiares: const [
        Familiar(
          id: 'fam-4',
          empleadoId: 'demo-emp-002',
          ci: '9128374',
          nombres: 'Elena',
          apellidos: 'Flores',
          parentesco: 'Hija',
          activo: true,
        ),
      ],
    ),
    AdminEmployee(
      id: 'demo-emp-003',
      ci: '5201948',
      nombres: 'Claudia',
      apellidos: 'Gutiérrez Rojas',
      email: 'claudia.gutierrez@institucion.gob.bo',
      telefono: '72034918',
      departamento: 'Recursos Humanos',
      rol: 'EMPLEADO',
      hasMonthlyPlan: true, // Plan Mensual 15 Bs
      creadoEn: DateTime.now().subtract(const Duration(days: 45)),
      familiares: const [
        Familiar(
          id: 'fam-5',
          empleadoId: 'demo-emp-003',
          ci: '7391028',
          nombres: 'David',
          apellidos: 'Montaño',
          parentesco: 'Cónyuge',
          activo: true,
        ),
        Familiar(
          id: 'fam-6',
          empleadoId: 'demo-emp-003',
          ci: '8392019',
          nombres: 'Camila',
          apellidos: 'Montaño',
          parentesco: 'Hija',
          activo: true,
        ),
      ],
    ),
    AdminEmployee(
      id: 'demo-emp-004',
      ci: '3928104',
      nombres: 'Gonzalo',
      apellidos: 'Mamani Quispe',
      email: 'gonzalo.mamani@institucion.gob.bo',
      telefono: '76829104',
      departamento: 'Dirección Ejecutiva',
      rol: 'EMPLEADO',
      hasMonthlyPlan: false, // Tarifa particular 18 Bs
      creadoEn: DateTime.now().subtract(const Duration(days: 30)),
      familiares: const [],
    ),
  ];

  /// Obtiene la lista completa de empleados con sus familiares
  Future<List<AdminEmployee>> getEmployees() async {
    final client = SupabaseConfig.client;
    if (client == null) {
      return List.unmodifiable(_employees);
    }

    try {
      final res = await client
          .from('usuarios')
          .select('*, familiares(*)')
          .eq('activo', true)
          .order('creado_en', ascending: false);

      final List<dynamic> data = res as List<dynamic>;
      if (data.isEmpty) {
        return List.unmodifiable(_employees);
      }

      return data.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        final rawFamilires = map['familiares'] as List<dynamic>? ?? [];
        final familiares = rawFamilires
            .map((f) => Familiar.fromJson(Map<String, dynamic>.from(f as Map)))
            .toList();
        return AdminEmployee.fromJson(map, familiares: familiares);
      }).toList();
    } catch (e) {
      debugPrint(
        '⚠️ Error obteniendo empleados de Supabase ($e). Usando memoria.',
      );
      return List.unmodifiable(_employees);
    }
  }

  /// Registra un nuevo empleado junto a sus familiares iniciales
  Future<AdminEmployee> createEmployee({
    required String ci,
    required String nombres,
    required String apellidos,
    required String email,
    required String telefono,
    required String departamento,
    required bool hasMonthlyPlan,
    List<Map<String, String>> initialFamiliares = const [],
  }) async {
    final newId = const Uuid().v4();
    final List<Familiar> addedFamiliares = [];

    // Limitar familiares iniciales al máximo legal de 3
    final limitedList = initialFamiliares.take(
      FamilyPolicy.maxFamilyMembersPerEmployee,
    );
    int famIndex = 1;
    for (final famData in limitedList) {
      if ((famData['nombres'] ?? '').trim().isNotEmpty) {
        addedFamiliares.add(
          Familiar(
            id: 'fam-$newId-${famIndex++}',
            empleadoId: newId,
            ci: famData['ci'] ?? '',
            nombres: famData['nombres'] ?? '',
            apellidos: famData['apellidos'] ?? apellidos,
            parentesco: famData['parentesco'] ?? 'Familiar',
            activo: true,
          ),
        );
      }
    }

    final newEmployee = AdminEmployee(
      id: newId,
      ci: ci,
      nombres: nombres,
      apellidos: apellidos,
      email: email,
      telefono: telefono,
      departamento: departamento,
      rol: 'EMPLEADO',
      hasMonthlyPlan: hasMonthlyPlan,
      activo: true,
      creadoEn: DateTime.now(),
      familiares: addedFamiliares,
    );

    _employees.insert(0, newEmployee);

    final client = SupabaseConfig.client;
    if (client != null && SupabaseConfig.isInitialized) {
      try {
        await client.from('usuarios').insert({
          'id': newId,
          'ci': ci,
          'nombres': nombres,
          'apellidos': apellidos,
          'email': email,
          'telefono': telefono,
          'rol': 'EMPLEADO',
          'activo': true,
        });

        for (final fam in addedFamiliares) {
          await client.from('familiares').insert({
            'empleado_id': newId,
            'ci': fam.ci,
            'nombres': fam.nombres,
            'apellidos': fam.apellidos,
            'parentesco': fam.parentesco,
            'activo': true,
          });
        }
      } catch (e) {
        debugPrint(
          '⚠️ Error registrando empleado en Supabase ($e).',
        );
        rethrow;
      }
    }

    return newEmployee;
  }

  /// Actualiza los datos de un empleado
  Future<void> updateEmployee(AdminEmployee updated) async {
    final index = _employees.indexWhere((e) => e.id == updated.id);
    if (index != -1) {
      _employees[index] = updated;
    }

    final client = SupabaseConfig.client;
    if (client != null && SupabaseConfig.isInitialized) {
      try {
        await client
            .from('usuarios')
            .update({
              'ci': updated.ci,
              'nombres': updated.nombres,
              'apellidos': updated.apellidos,
              'email': updated.email,
              'telefono': updated.telefono,
            })
            .eq('id', updated.id);
      } catch (e) {
        debugPrint('⚠️ Error actualizando empleado en Supabase: $e');
        rethrow;
      }
    }
  }

  /// Borra los datos y registros de prueba correspondientes a
  /// 'empleado', 'administrador' y 'cocina' tanto en memoria como en Supabase.
  Future<Map<String, dynamic>> clearTestData() async {
    // 1. Limpieza en memoria local
    _employees.removeWhere(
      (e) =>
          e.id.startsWith('demo-') ||
          e.email.toLowerCase().contains('empleado') ||
          e.email.toLowerCase().contains('admin') ||
          e.email.toLowerCase().contains('chef') ||
          e.email.toLowerCase().contains('cocina'),
    );

    // Limpieza de familiares en memoria
    SupabaseFamilyRepository.clearMockFamilyStore();

    // 2. Si Supabase está conectado, borrar registros de prueba de BD
    final client = SupabaseConfig.client;
    if (client != null && SupabaseConfig.isInitialized) {
      try {
        await client.rpc('limpiar_datos_prueba');
      } catch (e) {
        debugPrint('ℹ️ RPC limpiar_datos_prueba no disponible, borrado directo en tablas: $e');
        final testIds = [
          'demo-user-123',
          'demo-admin-789',
          'demo-chef-456',
          'demo-emp-002',
          'demo-emp-003',
          'demo-emp-004',
        ];
        final testEmails = [
          'juan.empleado@institucion.gob.bo',
          'roberto.flores@institucion.gob.bo',
          'claudia.gutierrez@institucion.gob.bo',
          'gonzalo.mamani@institucion.gob.bo',
          'admin.rrhh@institucion.gob.bo',
          'admin@institucion.gob.bo',
          'carlos.chef@restaurante.com',
          'chef@restaurante.com',
          'maria.empleado@test.com',
          'admin.rrhh@test.com',
          'cocina.turno@test.com',
        ];

        for (final uid in testIds) {
          try { await client.from('reservas').delete().eq('empleado_id', uid); } catch (_) {}
          try { await client.from('reservations').delete().eq('user_id', uid); } catch (_) {}
          try { await client.from('familiares').delete().eq('empleado_id', uid); } catch (_) {}
          try { await client.from('suscripciones').delete().eq('empleado_id', uid); } catch (_) {}
          try { await client.from('monthly_subscriptions').delete().eq('user_id', uid); } catch (_) {}
          try { await client.from('menu_semanal').delete().eq('creado_por', uid); } catch (_) {}
          try { await client.from('usuarios').delete().eq('id', uid); } catch (_) {}
          try { await client.from('profiles').delete().eq('id', uid); } catch (_) {}
        }

        for (final email in testEmails) {
          try { await client.from('usuarios').delete().eq('email', email); } catch (_) {}
          try { await client.from('profiles').delete().eq('email', email); } catch (_) {}
        }
      }
    }

    return {
      'success': true,
      'message': 'Registros de prueba de empleado, administrador y cocina borrados con éxito.',
    };
  }

  /// Elimina un empleado
  Future<void> deleteEmployee(String employeeId) async {
    _employees.removeWhere((e) => e.id == employeeId);

    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        // En cascada o borrado lógico
        await client
            .from('usuarios')
            .update({'activo': false})
            .eq('id', employeeId);
      } catch (e) {
        debugPrint('⚠️ Error al eliminar empleado en Supabase: $e');
      }
    }
  }

  /// Agrega un familiar a un empleado respetando el límite de 3
  Future<bool> addFamiliar(String employeeId, Familiar familiar) async {
    final empIndex = _employees.indexWhere((e) => e.id == employeeId);
    if (empIndex == -1) return false;

    final currentEmp = _employees[empIndex];
    if (currentEmp.familiares.length >=
        FamilyPolicy.maxFamilyMembersPerEmployee) {
      return false; // Cupo máximo alcanzado
    }

    final updatedFamiliares = [...currentEmp.familiares, familiar];
    _employees[empIndex] = currentEmp.copyWith(familiares: updatedFamiliares);

    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        await client.from('familiares').insert({
          'empleado_id': employeeId,
          'ci': familiar.ci,
          'nombres': familiar.nombres,
          'apellidos': familiar.apellidos,
          'parentesco': familiar.parentesco,
          'activo': true,
        });
      } catch (e) {
        debugPrint('⚠️ Error insertando familiar en Supabase: $e');
      }
    }

    return true;
  }

  /// Elimina un familiar asociado
  Future<void> deleteFamiliar(String employeeId, String familiarId) async {
    final empIndex = _employees.indexWhere((e) => e.id == employeeId);
    if (empIndex != -1) {
      final currentEmp = _employees[empIndex];
      final updatedFamiliares = currentEmp.familiares
          .where((f) => f.id != familiarId)
          .toList();
      _employees[empIndex] = currentEmp.copyWith(familiares: updatedFamiliares);
    }

    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        await client.from('familiares').delete().eq('id', familiarId);
      } catch (e) {
        debugPrint('⚠️ Error eliminando familiar en Supabase: $e');
      }
    }
  }

  /// Alterna o activa el plan mensual (tarifa Bs. 15 vs Bs. 18)
  Future<void> toggleMonthlyPlan(String employeeId, bool hasPlan) async {
    final empIndex = _employees.indexWhere((e) => e.id == employeeId);
    if (empIndex != -1) {
      _employees[empIndex] = _employees[empIndex].copyWith(
        hasMonthlyPlan: hasPlan,
      );
    }

    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        if (hasPlan) {
          final currentMonth = DateTime(
            DateTime.now().year,
            DateTime.now().month,
            1,
          );
          final monthStr =
              "${currentMonth.year}-${currentMonth.month.toString().padLeft(2, '0')}-01";
          await client.from('suscripciones').upsert({
            'empleado_id': employeeId,
            'mes': monthStr,
            'modalidad': 'MENSUAL',
            'activo': true,
          });
        } else {
          await client
              .from('suscripciones')
              .update({'activo': false})
              .eq('empleado_id', employeeId);
        }
      } catch (e) {
        debugPrint('⚠️ Error actualizando plan mensual en Supabase: $e');
      }
    }
  }
}
