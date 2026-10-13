import 'package:flutter/foundation.dart';
import 'package:restaurante_app/core/config/supabase_config.dart';
import 'package:restaurante_app/core/utils/date_utils.dart';
import 'package:restaurante_app/features/pension/domain/pension_entity.dart';
import 'package:restaurante_app/features/reservas/domain/holiday_entity.dart';

class SupabasePensionRepository {
  // Suscripción demo local para pruebas
  final List<MonthlyPensionSubscription> _inMemorySubscriptions = [
    MonthlyPensionSubscription(
      id: 'sub-oct-2026',
      userId: 'demo-user-123',
      year: 2026,
      month: 10,
      totalDays: 22,
      pricePerDay: 14.0, // Descuento pensionado
      totalPrice: 308.0,
      status: 'activa',
      createdAt: DateTime(2026, 9, 25),
    ),
  ];

  Future<MonthlyPensionSubscription?> getSubscription(
    String userId,
    int year,
    int month,
  ) async {
    final client = SupabaseConfig.client;
    if (client == null) {
      return _inMemorySubscriptions
          .cast<MonthlyPensionSubscription?>()
          .firstWhere(
            (s) =>
                s != null &&
                (s.userId == userId || userId == 'demo-user-123') &&
                s.year == year &&
                s.month == month &&
                s.status == 'activa',
            orElse: () => null,
          );
    }

    try {
      final response = await client
          .from('monthly_subscriptions')
          .select()
          .eq('user_id', userId)
          .eq('year', year)
          .eq('month', month)
          .eq('status', 'activa')
          .maybeSingle();

      if (response != null) {
        return MonthlyPensionSubscription.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('⚠️ Error al consultar pensión en Supabase: $e');
      return _inMemorySubscriptions
          .cast<MonthlyPensionSubscription?>()
          .firstWhere(
            (s) =>
                s != null &&
                s.userId == userId &&
                s.year == year &&
                s.month == month &&
                s.status == 'activa',
            orElse: () => null,
          );
    }
  }

  Future<bool> subscribeMonthly({
    required String userId,
    required int year,
    required int month,
    List<Holiday> holidays = const [],
    double pricePerDay = 14.0,
  }) async {
    final holidayDates = holidays.map((h) => h.date).toList();
    final businessDays = AppDateUtils.countBusinessDays(
      year,
      month,
      holidays: holidayDates,
    );
    final totalPrice = businessDays * pricePerDay;

    final newSub = MonthlyPensionSubscription(
      id: 'sub-$year-$month-${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      year: year,
      month: month,
      totalDays: businessDays,
      pricePerDay: pricePerDay,
      totalPrice: totalPrice,
      status: 'activa',
      createdAt: DateTime.now(),
    );

    _inMemorySubscriptions.add(newSub);

    final client = SupabaseConfig.client;
    if (client == null) return true;

    try {
      await client.from('monthly_subscriptions').insert(newSub.toJson());
      return true;
    } catch (e) {
      debugPrint('⚠️ Error al registrar pensión en Supabase: $e');
      return true; // Conservado en memoria local
    }
  }

  Future<bool> cancelMonthlySubscription(
    String subscriptionId,
    int year,
    int month,
    DateTime currentTime,
  ) async {
    // Validación de regla de negocio
    final firstDayOfMonth = DateTime(year, month, 1);
    final today = DateTime(currentTime.year, currentTime.month, currentTime.day);
    if (!today.isBefore(firstDayOfMonth)) {
      debugPrint('⛔ No se puede cancelar: el mes ya inició.');
      return false;
    }

    final index =
        _inMemorySubscriptions.indexWhere((s) => s.id == subscriptionId);
    if (index != -1) {
      final cur = _inMemorySubscriptions[index];
      _inMemorySubscriptions[index] = MonthlyPensionSubscription(
        id: cur.id,
        userId: cur.userId,
        year: cur.year,
        month: cur.month,
        totalDays: cur.totalDays,
        pricePerDay: cur.pricePerDay,
        totalPrice: cur.totalPrice,
        status: 'cancelada',
        createdAt: cur.createdAt,
      );
    }

    final client = SupabaseConfig.client;
    if (client == null) return true;

    try {
      await client
          .from('monthly_subscriptions')
          .update({'status': 'cancelada'})
          .eq('id', subscriptionId);
      return true;
    } catch (e) {
      debugPrint('⚠️ Error al cancelar pensión en Supabase: $e');
      return true;
    }
  }
}
