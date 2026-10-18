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
            .map((item) =>
                Reservation.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      } catch (e2) {
        debugPrint(
            '⚠️ Error al consultar reservas del usuario en Supabase ($e1, $e2). Retornando memoria.');
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

    // 1. Intentar consultar 'reservations' con joins de platos y perfiles
    try {
      final response = await client
          .from('reservations')
          .select('*, dishes(name), profiles(full_name)')
          .eq('reservation_date', dateStr);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        if (map['dishes'] != null && map['dishes']['name'] != null) {
          map['dish_name'] = map['dishes']['name'];
        }
        if (map['profiles'] != null && map['profiles']['full_name'] != null) {
          map['user_name'] = map['profiles']['full_name'];
        }
        return Reservation.fromJson(map);
      }).toList();
    } catch (e1) {
      debugPrint(
          'ℹ️ Fallback 1: No se pudo consultar reservations con relaciones ($e1). Probando sin relaciones.');

      // 2. Intentar consultar 'reservations' sin relaciones
      try {
        final response = await client
            .from('reservations')
            .select()
            .eq('reservation_date', dateStr);
        final List<dynamic> data = response as List<dynamic>;
        return data
            .map((item) =>
                Reservation.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      } catch (e2) {
        debugPrint(
            'ℹ️ Fallback 2: No se pudo consultar tabla reservations ($e2). Probando tabla reservas.');

        // 3. Intentar consultar tabla 'reservas' (esquema DDL principal)
        try {
          final response =
              await client.from('reservas').select().eq('fecha', dateStr);
          final List<dynamic> data = response as List<dynamic>;
          return data
              .map((item) =>
                  Reservation.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList();
        } catch (e3) {
          debugPrint(
              '⚠️ Error al consultar reservas en Supabase ($e3). Retornando datos en memoria.');
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
    final existingIdx =
        _inMemoryReservations.indexWhere((r) => r.id == reservation.id);
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

    try {
      final payload = {
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
        if (reservation.notes != null) 'notes': reservation.notes,
      };

      await client.from('reservations').insert(payload);
    } catch (e1) {
      // Intentar en tabla 'reservas' si falla 'reservations'
      try {
        final payloadReservas = {
          'empleado_id': reservation.userId,
          if (reservation.familiarId != null &&
              int.tryParse(reservation.familiarId!) != null)
            'familiar_id': int.tryParse(reservation.familiarId!),
          'fecha': dateStr,
          'estado': reservation.status.toUpperCase(),
          'tipo_tarifa':
              reservation.price <= 15 ? 'PLAN_MENSUAL' : 'PARTICULAR',
          'precio': reservation.price,
          'notas': reservation.notes,
        };
        await client.from('reservas').insert(payloadReservas);
      } catch (e2) {
        debugPrint(
            '⚠️ Error al guardar reserva en Supabase ($e1, $e2). Guardada en memoria.');
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
        debugPrint('⚠️ Error al actualizar estado de reserva en Supabase: $e1, $e2');
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
      final response = await client.from('holidays').select();
      final List<dynamic> data = response as List<dynamic>;
      if (data.isEmpty) {
        return Holiday.defaultHolidays;
      }
      return data
          .map((item) => Holiday.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('⚠️ Error al obtener feriados desde Supabase: $e');
      return Holiday.defaultHolidays;
    }
  }
}
