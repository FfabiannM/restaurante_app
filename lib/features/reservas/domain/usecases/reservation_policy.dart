import 'package:restaurante_app/features/reservas/domain/holiday_entity.dart';

class PolicyCheckResult {
  final bool isAllowed;
  final String message;

  const PolicyCheckResult({
    required this.isAllowed,
    required this.message,
  });

  static const PolicyCheckResult allowed = PolicyCheckResult(
    isAllowed: true,
    message: 'Operación permitida',
  );
}

class ReservationPolicy {
  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  bool _isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  /// Verifica si una fecha seleccionada puede ser reservada según las políticas de la institución.
  PolicyCheckResult checkCanReserve(
    DateTime selectedDate,
    DateTime currentTime, {
    List<Holiday> holidays = const [],
  }) {
    final today = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day,
    );
    final target = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    // Regla 1: No se puede reservar en días pasados
    if (target.isBefore(today)) {
      return const PolicyCheckResult(
        isAllowed: false,
        message: 'No es posible realizar reservas para fechas pasadas.',
      );
    }

    // Regla 2: Fin de semana (sábado y domingo sin servicio)
    if (_isWeekend(target)) {
      return const PolicyCheckResult(
        isAllowed: false,
        message: 'El restaurante no brinda servicio los fines de semana.',
      );
    }

    // Regla 3: Control de Feriados
    for (final holiday in holidays) {
      if (_isSameDay(holiday.date, target)) {
        return PolicyCheckResult(
          isAllowed: false,
          message: 'Día no hábil por feriado institucional: ${holiday.name}.',
        );
      }
    }

    // Regla 4: Bloqueo Horario para reservas del mismo día
    // Si es hoy, el límite estricto son las 9:00 AM (9:01 ya no es permitido)
    if (_isSameDay(target, today)) {
      if (currentTime.hour > 9 || (currentTime.hour == 9 && currentTime.minute > 0)) {
        return const PolicyCheckResult(
          isAllowed: false,
          message:
              'Las reservas para el almuerzo de hoy cerraron a las 9:00 AM.',
        );
      }
    }

    // Regla 5: Días futuros hábiles permitidos
    return PolicyCheckResult.allowed;
  }

  /// Verifica si una reserva existente puede cancelarse.
  PolicyCheckResult checkCanCancel(
    DateTime selectedDate,
    DateTime currentTime,
  ) {
    final today = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day,
    );
    final target = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    // Regla 1: No se puede cancelar en fechas pasadas
    if (target.isBefore(today)) {
      return const PolicyCheckResult(
        isAllowed: false,
        message: 'No es posible cancelar una reserva de días pasados.',
      );
    }

    // Regla 2: Bloqueo Horario para cancelaciones del mismo día
    // Permitir cancelación solo antes de las 8:59 AM (a partir de las 9:00 AM ya no)
    if (_isSameDay(target, today)) {
      if (currentTime.hour >= 9) {
        return const PolicyCheckResult(
          isAllowed: false,
          message:
              'El plazo de cancelación para hoy venció a las 8:59 AM (compras en curso).',
        );
      }
    }

    return PolicyCheckResult.allowed;
  }

  // Métodos simplificados booleanos para conveniencia
  bool canReserve(
    DateTime selectedDate,
    DateTime currentTime, {
    List<Holiday> holidays = const [],
  }) {
    return checkCanReserve(selectedDate, currentTime, holidays: holidays)
        .isAllowed;
  }

  bool canCancel(DateTime selectedDate, DateTime currentTime) {
    return checkCanCancel(selectedDate, currentTime).isAllowed;
  }
}
