import 'package:flutter/foundation.dart';
import 'package:restaurante_app/core/config/supabase_config.dart';
import 'package:restaurante_app/core/utils/date_utils.dart';
import 'package:restaurante_app/features/reservas/domain/holiday_entity.dart';
import 'package:restaurante_app/features/reservas/domain/reservation_entity.dart';
import 'package:restaurante_app/features/reservas/domain/reservation_repository.dart';

class SupabaseReservationRepository implements ReservationRepository {
  // Almacén en memoria para respaldo y funcionamiento sin conexión / demo
  final List<Reservation> _inMemoryReservations = [
    Reservation(
      id: 'res-demo-today-1',
      userId: 'demo-user-123',
      userName: 'Juan Pérez (Empleado)',
      dishName: 'Silpancho Cochabambino',
      date: DateTime.now(),
      type: 'diaria',
      status: 'confirmada',
      notes: 'Sin locoto en la sarza',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    Reservation(
      id: 'res-demo-today-2',
      userId: 'demo-emp-2',
      userName: 'María Quispe (Empleado)',
      dishName: 'Pique Macho Especial',
      date: DateTime.now(),
      type: 'diaria',
      status: 'confirmada',
      notes: 'Bien caliente por favor',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Reservation(
      id: 'res-demo-today-3',
      userId: 'demo-emp-3',
      userName: 'Carlos Mamani (Empleado)',
      dishName: 'Sopa de Maní Tradicional',
      date: DateTime.now(),
      type: 'diaria',
      status: 'entregada',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    Reservation(
      id: 'res-demo-1',
      userId: 'demo-user-123',
      userName: 'Juan Pérez (Empleado)',
      dishName: 'Silpancho Cochabambino',
      date: DateTime.now().add(const Duration(days: 1)),
      type: 'diaria',
      status: 'confirmada',
      notes: 'Sin locoto en la sarza',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Reservation(
      id: 'res-demo-2',
      userId: 'demo-user-123',
      userName: 'Juan Pérez (Empleado)',
      dishName: 'Sopa de Maní Tradicional',
      date: DateTime.now().add(const Duration(days: 2)),
      type: 'diaria',
      status: 'confirmada',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    Reservation(
      id: 'res-demo-3',
      userId: 'demo-user-123',
      userName: 'Juan Pérez (Empleado)',
      dishName: 'Pique Macho Especial',
      date: DateTime.now().subtract(const Duration(days: 2)),
      type: 'diaria',
      status: 'entregada',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  /// Limpia las reservas de prueba en memoria.
  void clearTestReservations() {
    _inMemoryReservations.removeWhere(
      (r) =>
          r.userId.startsWith('demo-') ||
          r.userName.toLowerCase().contains('empleado') ||
          r.userName.toLowerCase().contains('juan'),
    );
  }

  @override
  Future<List<Reservation>> getUserReservations(String userId) async {
    final client = SupabaseConfig.client;
    if (client == null) {
      return _inMemoryReservations
          .where(
            (r) =>
                r.userId == userId ||
                userId == 'demo-user-123' ||
                userId.isEmpty,
          )
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    }
    if (!_isUuid(userId)) {
      return _inMemoryReservations
          .where(
            (r) =>
                r.userId == userId ||
                userId == 'demo-user-123' ||
                userId.isEmpty,
          )
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    }

    try {
      final response = await client
          .from('reservations')
          .select('*, dishes(name)')
          .eq('user_id', userId)
          .order('reservation_date', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        if (map['dishes'] != null && map['dishes']['name'] != null) {
          map['dish_name'] = map['dishes']['name'];
        }
        if (map['dish_name'] != null &&
            !map['dish_name'].toString().contains('Almuerzo Completo') &&
            map['plato_principal'] != null) {
          map['dish_name'] =
              'Almuerzo Completo (${map['plato_principal']} + ${map['sopa_nombre'] ?? "Sopa de Maní Tradicional"})';
        }
        return Reservation.fromJson(map);
      }).toList();
    } catch (e1) {
      try {
        final response = await client
            .from('reservas')
            .select()
            .eq('empleado_id', userId)
            .order('fecha', ascending: false);
        final List<dynamic> data = response as List<dynamic>;
        return data
            .map(
              (item) =>
                  Reservation.fromJson(Map<String, dynamic>.from(item as Map)),
            )
            .toList();
      } catch (e2) {
        debugPrint(
          '⚠️ Error al consultar reservas del usuario en Supabase ($e1, $e2). Retornando memoria.',
        );
        return _inMemoryReservations
            .where((r) => r.userId == userId || userId == 'demo-user-123')
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
      }
    }
  }

  @override
  Future<List<Reservation>> getAllReservationsForDate(DateTime date) async {
    final client = SupabaseConfig.client;
    final dateStr =
        "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    if (client == null) {
      return _inMemoryReservations
          .where((r) => AppDateUtils.isSameDay(r.date, date))
          .toList();
    }

    Future<List<Reservation>> withMonthlyPlanOrders(
      List<Reservation> reservations,
    ) async {
      try {
        final monthlyResponse = await client
            .from('vista_usuarios')
            .select()
            .eq('rol', 'Empleado')
            .eq('activo', true);

        final existingUserIds = reservations.map((r) => r.userId).toSet();
        final monthlyOrders = (monthlyResponse as List<dynamic>)
            .map((row) => Map<String, dynamic>.from(row as Map))
            .where((user) => !existingUserIds.contains((user['id_usuario'] ?? user['id']).toString()))
            .map(
              (user) {
                final uid = (user['id_usuario'] ?? user['id'] ?? '').toString();
                final name = user['nombre_completo']?.toString() ??
                    '${user['nombre'] ?? user['nombres'] ?? ''} ${user['apellidos'] ?? ''}'
                        .trim();
                return Reservation(
                  id: 'monthly-$uid-$dateStr',
                  userId: uid,
                  userName: name,
                  beneficiaryName: name,
                  dishName: 'Almuerzo Completo del Día',
                  date: date,
                  type: 'pension',
                  status: 'confirmada',
                  price: 15.0,
                  notes: 'Plan Mensual',
                  createdAt: date,
                );
              },
            )
            .toList();

        return [...reservations, ...monthlyOrders];
      } catch (e) {
        debugPrint('ℹ️ No se pudieron cargar empleados con Plan Mensual: $e');
        return reservations;
      }
    }

    // 1. Intentar consultar 'reservations' con joins de platos y perfiles
    try {
      final response = await client
          .from('reservations')
          .select('*, dishes(name), profiles(full_name)')
          .eq('reservation_date', dateStr);

      final List<dynamic> data = response as List<dynamic>;
      final reservations = data.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        if (map['dishes'] != null && map['dishes']['name'] != null) {
          map['dish_name'] = map['dishes']['name'];
        }
        if (map['profiles'] != null && map['profiles']['full_name'] != null) {
          map['user_name'] = map['profiles']['full_name'];
        }
        return Reservation.fromJson(map);
      }).toList();
      return await withMonthlyPlanOrders(reservations);
    } catch (e1) {
      debugPrint(
        'ℹ️ Fallback 1: No se pudo consultar reservations con relaciones ($e1). Probando sin relaciones.',
      );

      // 2. Intentar consultar 'reservations' sin relaciones
      try {
        final response = await client
            .from('reservations')
            .select()
            .eq('reservation_date', dateStr);
        final List<dynamic> data = response as List<dynamic>;
        final reservations = data
            .map(
              (item) =>
                  Reservation.fromJson(Map<String, dynamic>.from(item as Map)),
            )
            .toList();
        return await withMonthlyPlanOrders(reservations);
      } catch (e2) {
        debugPrint(
          'ℹ️ Fallback 2: No se pudo consultar tabla reservations ($e2). Probando tabla reservas.',
        );

        // 3. Intentar consultar tabla 'reservas' (esquema DDL principal)
        try {
          final response = await client
              .from('reservas')
              .select()
              .eq('fecha', dateStr);
          final List<dynamic> data = response as List<dynamic>;
          final reservations = data
              .map(
                (item) => Reservation.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList();
          return await withMonthlyPlanOrders(reservations);
        } catch (e3) {
          debugPrint(
            '⚠️ Error al consultar reservas en Supabase ($e3). Retornando datos en memoria.',
          );
          return _inMemoryReservations
              .where((r) => AppDateUtils.isSameDay(r.date, date))
              .toList();
        }
      }
    }
  }

  @override
  Future<void> createReservation(Reservation reservation) async {
    // Almacenar en memoria primero para reactividad inmediata
    final existingIdx = _inMemoryReservations.indexWhere(
      (r) => r.id == reservation.id,
    );
    if (existingIdx != -1) {
      _inMemoryReservations[existingIdx] = reservation;
    } else {
      _inMemoryReservations.add(reservation);
    }

    final client = SupabaseConfig.client;
    if (client == null) {
      return;
    }

    final dateStr =
        "${reservation.date.year.toString().padLeft(4, '0')}-${reservation.date.month.toString().padLeft(2, '0')}-${reservation.date.day.toString().padLeft(2, '0')}";

    // Nombre estructurado según categoría del menú
    final comboDishName = reservation.dishName.isNotEmpty
        ? reservation.dishName
        : (reservation.isAlmuerzoCompleto
              ? 'Almuerzo Completo (${reservation.entradaNombre ?? "Ensalada Fresca del Día"} + ${reservation.sopaNombre ?? "Sopa del día"} + ${reservation.platoPrincipal ?? "Segundo"})'
              : (reservation.platoPrincipal ?? 'Plato del Día'));

    try {
      // 1. Intento primario con columnas dedicadas para Almuerzo Completo en Supabase
      final payload = {
        'id': reservation.id,
        'user_id': reservation.userId,
        if (_isUuid(reservation.dishId)) 'dish_id': reservation.dishId,
        'dish_name': comboDishName,
        'entrada_nombre': reservation.entradaNombre,
        'ensalada_nombre': reservation.entradaNombre,
        'plato_principal': reservation.platoPrincipal ?? reservation.dishName,
        'sopa_nombre': reservation.sopaNombre,
        'es_almuerzo_completo': reservation.isAlmuerzoCompleto,
        'menu_category': reservation.menuCategory.wireValue,
        'categoria_menu': reservation.menuCategory.label,
        'reservation_date': dateStr,
        'type': reservation.type,
        'status': reservation.status,
        if (reservation.familiarId != null)
          'familiar_id': reservation.familiarId,
        'beneficiary_name': reservation.displayName,
        'price': reservation.price,
        if (reservation.notes != null) 'notes': reservation.notes,
      };

      await client.from('reservations').insert(payload);
    } catch (e1) {
      // 2. Fallback de compatibilidad: Por si aún no se corrió la migración de nuevas columnas
      try {
        final payloadFallback = {
          'id': reservation.id,
          'user_id': reservation.userId,
          if (_isUuid(reservation.dishId)) 'dish_id': reservation.dishId,
          'reservation_date': dateStr,
          'type': reservation.type,
          'status': reservation.status,
          if (reservation.familiarId != null)
            'familiar_id': reservation.familiarId,
          'beneficiary_name': reservation.displayName,
          'price': reservation.price,
          'notes': [
            if (reservation.notes != null && reservation.notes!.isNotEmpty)
              reservation.notes,
            'Categoría: ${reservation.menuCategory.label}',
            'Combo: $comboDishName',
          ].join(' | '),
        };
        await client.from('reservations').insert(payloadFallback);
      } catch (e2) {
        // 3. Inserción en tabla real de Supabase 'reserva'
        try {
          final payloadReservaReal = {
            if (_isUuid(reservation.userId)) 'id_usuario': reservation.userId,
            'fecha': reservation.date.toUtc().toIso8601String(),
            'costo_aplicado': reservation.price,
            'estado': reservation.status.toUpperCase(),
            'es_pension': reservation.price <= 15.0,
            'origen': reservation.familiarId != null ? 'FAMILIAR' : 'EMPLEADO',
          };
          await client.from('reserva').insert(payloadReservaReal);
        } catch (e3) {
          debugPrint(
            '⚠️ Error al guardar reserva en Supabase ($e1, $e2, $e3). Guardada en memoria.',
          );
        }
      }
    }
  }

  bool _isUuid(String? value) {
    if (value == null) return false;
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    ).hasMatch(value);
  }

  @override
  Future<void> cancelReservation(String reservationId) async {
    final index = _inMemoryReservations.indexWhere(
      (r) => r.id == reservationId,
    );
    if (index != -1) {
      _inMemoryReservations[index] = _inMemoryReservations[index].copyWith(
        status: 'cancelada',
      );
    }

    final client = SupabaseConfig.client;
    if (client == null) return;

    try {
      await client
          .from('reservations')
          .update({'status': 'cancelada'})
          .eq('id', reservationId);
    } catch (e1) {
      try {
        await client
            .from('reservas')
            .update({'estado': 'CANCELADA'})
            .eq('id', reservationId);
      } catch (e2) {
        debugPrint('⚠️ Error al cancelar reserva en Supabase: $e1, $e2');
      }
    }
  }

  @override
  Future<void> updateReservationStatus(
    String reservationId,
    String status,
  ) async {
    final index = _inMemoryReservations.indexWhere(
      (r) => r.id == reservationId,
    );
    if (index != -1) {
      _inMemoryReservations[index] = _inMemoryReservations[index].copyWith(
        status: status,
      );
    }

    final client = SupabaseConfig.client;
    if (client == null) return;

    try {
      await client
          .from('reservations')
          .update({'status': status})
          .eq('id', reservationId);
    } catch (e1) {
      try {
        await client
            .from('reservas')
            .update({'estado': status.toUpperCase()})
            .eq('id', reservationId);
      } catch (e2) {
        debugPrint(
          '⚠️ Error al actualizar estado de reserva en Supabase: $e1, $e2',
        );
      }
    }
  }

  @override
  Future<List<Holiday>> getHolidays() async {
    final client = SupabaseConfig.client;
    if (client == null) {
      return Holiday.defaultHolidays;
    }

    try {
      final List<Holiday> list = [];

      // 1. Consultar excepcion_calendario (HU6)
      try {
        final exRes = await client.from('excepcion_calendario').select();
        if (exRes.isNotEmpty) {
          for (final row in exRes) {
            final fStr = row['fecha']?.toString();
            if (fStr != null && fStr.isNotEmpty) {
              final dt = DateTime.tryParse(fStr);
              if (dt != null) {
                list.add(
                  Holiday(
                    id: row['id_excepcion']?.toString() ?? 'ex-${list.length}',
                    date: dt,
                    name: row['motivo']?.toString() ?? 'Excepción de calendario',
                    description: 'Día no habilitado en calendario (HU6)',
                  ),
                );
              }
            }
          }
        }
      } catch (eEx) {
        debugPrint('ℹ️ No se pudo cargar excepcion_calendario: $eEx');
      }

      // 2. Consultar tabla holidays si existiera
      try {
        final response = await client.from('holidays').select();
        final List<dynamic> data = response as List<dynamic>;
        if (data.isNotEmpty) {
          list.addAll(
            data.map((item) => Holiday.fromJson(item as Map<String, dynamic>)),
          );
        }
      } catch (_) {}

      // Si no hay datos, incluir los feriados por defecto
      if (list.isEmpty) {
        return Holiday.defaultHolidays;
      }
      return list;
    } catch (e) {
      debugPrint('⚠️ Error al obtener feriados desde Supabase: $e');
      return Holiday.defaultHolidays;
    }
  }
}
