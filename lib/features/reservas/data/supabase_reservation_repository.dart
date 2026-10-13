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

  @override
  Future<List<Reservation>> getUserReservations(String userId) async {
    final client = SupabaseConfig.client;
    if (client == null) {
      return _inMemoryReservations
          .where((r) => r.userId == userId || userId == 'demo-user-123' || userId.isEmpty)
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
      if (data.isEmpty) {
        return _inMemoryReservations
            .where((r) => r.userId == userId || userId == 'demo-user-123')
            .toList();
      }

      return data.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        if (map['dishes'] != null && map['dishes']['name'] != null) {
          map['dish_name'] = map['dishes']['name'];
        }
        return Reservation.fromJson(map);
      }).toList();
    } catch (e) {
      debugPrint('⚠️ Error al consultar reservas en Supabase: $e');
      return _inMemoryReservations
          .where((r) => r.userId == userId || userId == 'demo-user-123' || userId.isEmpty)
          .toList();
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
    } catch (e) {
      debugPrint('⚠️ Error al consultar reservas por fecha en Supabase: $e');
      return _inMemoryReservations
          .where((r) => AppDateUtils.isSameDay(r.date, date))
          .toList();
    }
  }

  @override
  Future<void> createReservation(Reservation reservation) async {
    final client = SupabaseConfig.client;
    // Siempre mantenemos el almacenamiento local sincronizado
    _inMemoryReservations.add(reservation);

    if (client == null) {
      return;
    }

    try {
      await client.from('reservations').insert(reservation.toJson());
    } catch (e) {
      debugPrint('⚠️ Error al guardar reserva en Supabase ($e). Guardada en memoria.');
    }
  }

  @override
  Future<void> cancelReservation(String reservationId) async {
    final index = _inMemoryReservations.indexWhere((r) => r.id == reservationId);
    if (index != -1) {
      _inMemoryReservations[index] =
          _inMemoryReservations[index].copyWith(status: 'cancelada');
    }

    final client = SupabaseConfig.client;
    if (client == null) return;

    try {
      await client
          .from('reservations')
          .update({'status': 'cancelada'})
          .eq('id', reservationId);
    } catch (e) {
      debugPrint('⚠️ Error al cancelar reserva en Supabase: $e');
    }
  }

  @override
  Future<void> updateReservationStatus(
      String reservationId, String status) async {
    final index = _inMemoryReservations.indexWhere((r) => r.id == reservationId);
    if (index != -1) {
      _inMemoryReservations[index] =
          _inMemoryReservations[index].copyWith(status: status);
    }

    final client = SupabaseConfig.client;
    if (client == null) return;

    try {
      await client
          .from('reservations')
          .update({'status': status})
          .eq('id', reservationId);
    } catch (e) {
      debugPrint('⚠️ Error al actualizar estado de reserva en Supabase: $e');
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
