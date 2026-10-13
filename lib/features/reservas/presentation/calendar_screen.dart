import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:restaurante_app/core/utils/date_utils.dart';
import 'package:restaurante_app/features/menu/data/supabase_menu_repository.dart';
import 'package:restaurante_app/features/menu/domain/menu_entity.dart';
import 'package:restaurante_app/features/reservas/domain/holiday_entity.dart';
import 'package:restaurante_app/features/reservas/domain/reservation_entity.dart';
import 'package:restaurante_app/features/reservas/presentation/providers/reservation_providers.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  Dish? _selectedDish;
  final TextEditingController _notesController = TextEditingController();
  List<Dish> _availableDishes = [];
  bool _isLoadingDishes = true;

  @override
  void initState() {
    super.initState();
    _loadDishes();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadDishes() async {
    final dishes = await SupabaseMenuRepository().getDailyMenu();
    if (mounted) {
      setState(() {
        _availableDishes = dishes;
        if (dishes.isNotEmpty) {
          _selectedDish = dishes.first;
        }
        _isLoadingDishes = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final policy = ref.watch(reservationPolicyProvider);
    final holidaysAsync = ref.watch(holidaysProvider);
    final holidays = holidaysAsync.value ?? Holiday.defaultHolidays;

    final userReservations = ref.watch(userReservationsProvider);

    // Ver si el usuario ya tiene reserva en la fecha seleccionada
    final existingReservation = userReservations
        .cast<Reservation?>()
        .firstWhere(
          (r) =>
              r != null &&
              AppDateUtils.isSameDay(r.date, selectedDate) &&
              r.isConfirmed,
          orElse: () => null,
        );

    final isHoliday = holidays.any(
      (h) => AppDateUtils.isSameDay(h.date, selectedDate),
    );
    final holidayObj = isHoliday
        ? holidays.firstWhere(
            (h) => AppDateUtils.isSameDay(h.date, selectedDate),
          )
        : null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reservar Almuerzo',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.white,
              ),
            ),
            Text(
              'Selecciona un día hábil en el calendario',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            // Contenedor blanco translúcido para el calendario
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: TableCalendar(
                firstDay: DateTime.now().subtract(const Duration(days: 30)),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: _focusedDay,
                currentDay: DateTime.now(),
                selectedDayPredicate: (day) =>
                    AppDateUtils.isSameDay(selectedDate, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                  ref.read(selectedDateProvider.notifier).state = selectedDay;
                },
                calendarFormat: CalendarFormat.month,
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                  leftChevronIcon: Icon(
                    Icons.chevron_left,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  weekendTextStyle: const TextStyle(color: Colors.redAccent),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    final hasRes = userReservations.any(
                      (r) =>
                          AppDateUtils.isSameDay(r.date, date) && r.isConfirmed,
                    );
                    final isHol = holidays.any(
                      (h) => AppDateUtils.isSameDay(h.date, date),
                    );

                    if (hasRes || isHol) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (hasRes)
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.green,
                              ),
                            ),
                          if (isHol)
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.amber,
                              ),
                            ),
                        ],
                      );
                    }
                    return null;
                  },
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Leyenda rápida
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(Colors.green, 'Tienes Reserva'),
                  const SizedBox(width: 16),
                  _buildLegendItem(Colors.amber, 'Feriado'),
                  const SizedBox(width: 16),
                  _buildLegendItem(
                    Theme.of(context).colorScheme.primary,
                    'Seleccionado',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Tarjeta de estado de política para la fecha seleccionada
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isHoliday
                      ? Colors.amber.shade400
                      : policy.canReserve
                      ? Colors.green.shade300
                      : Colors.red.shade200,
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isHoliday
                            ? Icons.celebration
                            : policy.canReserve
                            ? Icons.check_circle
                            : Icons.info_outline,
                        color: isHoliday
                            ? Colors.amber.shade800
                            : policy.canReserve
                            ? Colors.green
                            : Colors.red,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppDateUtils.formatFullDate(selectedDate),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (existingReservation != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.bookmark_added,
                            color: Colors.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Ya reservaste: "${existingReservation.dishName}"',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Text(
                    isHoliday
                        ? 'Feriado: ${holidayObj?.name ?? 'Feriado Oficial'}. Restaurante no atiende.'
                        : policy.canReserve
                        ? 'Día habilitado para reserva de almuerzo institucional.'
                        : policy.reserveReason,
                    style: TextStyle(
                      fontSize: 13,
                      color: isHoliday
                          ? Colors.amber.shade900
                          : policy.canReserve
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Opciones de reserva si está habilitado y no tiene reserva previa
            if (policy.canReserve && existingReservation == null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Elige tu opción de plato:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_isLoadingDishes)
                      const Center(child: CircularProgressIndicator())
                    else
                      DropdownButtonFormField<Dish>(
                        initialValue: _selectedDish,
                        isExpanded: true,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        items: _availableDishes.map((dish) {
                          return DropdownMenuItem<Dish>(
                            value: dish,
                            child: Text(
                              '${dish.name} (Bs. ${dish.price.toStringAsFixed(0)})',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }).toList(),
                        onChanged: (dish) {
                          setState(() {
                            _selectedDish = dish;
                          });
                        },
                      ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        hintText:
                            'Observaciones (ej. Sin ensalada, para llevar)',
                        prefixIcon: const Icon(Icons.note_alt_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Botón de acción principal
            if (existingReservation != null)
              // Botón de Cancelación respetando política de las 8:59 AM
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: policy.canCancel
                      ? () =>
                            _handleCancellation(context, existingReservation.id)
                      : () => _showPolicyError(context, policy.cancelReason),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: policy.canCancel ? Colors.red : Colors.grey,
                      width: 1.5,
                    ),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: Icon(
                    Icons.cancel_outlined,
                    color: policy.canCancel ? Colors.red : Colors.grey,
                  ),
                  label: Text(
                    'Cancelar esta Reserva',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: policy.canCancel ? Colors.red : Colors.grey,
                    ),
                  ),
                ),
              )
            else
              // Botón de Reserva respetando política de las 9:00 AM
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: policy.canReserve
                      ? () => _handleReservation(context, selectedDate)
                      : () => _showPolicyError(
                          context,
                          isHoliday
                              ? 'No se puede reservar en días feriados'
                              : policy.reserveReason,
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: policy.canReserve
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade400,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(
                    policy.canReserve
                        ? 'Confirmar Reserva (${selectedDate.day}/${selectedDate.month})'
                        : 'Reserva no disponible',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Future<void> _handleReservation(
    BuildContext context,
    DateTime selectedDate,
  ) async {
    final dishName = _selectedDish?.name ?? 'Almuerzo Completo del Día';
    final dishId = _selectedDish?.id;
    final notes = _notesController.text.trim();

    final success = await ref
        .read(userReservationsProvider.notifier)
        .createReservation(
          date: selectedDate,
          dishId: dishId,
          dishName: dishName,
          notes: notes.isNotEmpty ? notes : null,
        );

    if (!context.mounted) return;

    if (success) {
      _notesController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '¡Reserva confirmada para ${AppDateUtils.formatShortDate(selectedDate)}!',
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      _showPolicyError(context, 'No se pudo registrar la reserva.');
    }
  }

  Future<void> _handleCancellation(
    BuildContext context,
    String reservationId,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar cancelación'),
        content: const Text(
          '¿Estás seguro de que deseas cancelar tu reserva para este día?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Volver'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sí, Cancelar'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    final success = await ref
        .read(userReservationsProvider.notifier)
        .cancelReservation(reservationId);

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tu reserva ha sido cancelada exitosamente.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showPolicyError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
