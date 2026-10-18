import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurante_app/core/utils/date_utils.dart';
import 'package:restaurante_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:restaurante_app/features/familiares/domain/familiar_entity.dart';
import 'package:restaurante_app/features/familiares/presentation/providers/family_providers.dart';
import 'package:restaurante_app/features/menu/domain/bolivian_dish_entity.dart';
import 'package:restaurante_app/features/menu/presentation/providers/weekly_menu_provider.dart';
import 'package:restaurante_app/features/reservas/presentation/providers/reservation_providers.dart';

class EmployeeScreen extends ConsumerStatefulWidget {
  const EmployeeScreen({super.key});

  @override
  ConsumerState<EmployeeScreen> createState() => _EmployeeScreenState();
}

class _EmployeeScreenState extends ConsumerState<EmployeeScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedDishName;
  final TextEditingController _notesController = TextEditingController();

  // Modo de reserva:
  // true = "Reserva Conjunta (Empleado + Familiares)"
  // false = "Reserva Individual / Por Comensal"
  bool _isJointReservation = true;

  // Selección en modo conjunto
  bool _includeEmployee = true;
  final Set<String> _selectedFamiliarIds = {};

  // Selección en modo individual (null = para el empleado)
  Familiar? _individualFamiliar;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Iniciar con el siguiente día hábil si hoy es fin de semana
    if (AppDateUtils.isWeekend(_selectedDate)) {
      _selectedDate = _selectedDate.add(
        Duration(days: _selectedDate.weekday == DateTime.saturday ? 2 : 1),
      );
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider);
    final familyAsync = ref.watch(employeeFamilyMembersProvider);
    final publishedMenuAsync = ref.watch(publishedWeeklyMenuProvider);
    final weekStart = ref.watch(selectedWeekProvider);

    final familyMembers = familyAsync.value ?? [];

    // Determinar tarifa aplicable:
    // 15 Bs si cuenta con Plan Mensual (isPensioner / hasMonthlyPlan)
    // 18 Bs si es particular / sin plan registrado
    final hasMonthlyPlan = currentUser?.isPensioner ?? false;
    final double tariffPrice = hasMonthlyPlan ? 15.0 : 18.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reservas de Comedor',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            Text(
              'Menú semanal boliviano y tarifas institucionales',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Cerrar Sesión',
            onPressed: _confirmSignOut,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner de Membresía y Tarifa Fija del Usuario
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: hasMonthlyPlan
                        ? Colors.green.withValues(alpha: 0.15)
                        : Colors.orange.withValues(alpha: 0.15),
                    child: Icon(
                      hasMonthlyPlan
                          ? Icons.stars_rounded
                          : Icons.account_circle_outlined,
                      color: hasMonthlyPlan ? Colors.green : Colors.orange,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hola, ${currentUser?.fullName ?? 'Empleado'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          hasMonthlyPlan
                              ? '⭐ Cuenta con Plan Mensual Activo'
                              : 'Modalidad Diaria / Particular',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: hasMonthlyPlan
                                ? Colors.green.shade800
                                : Colors.orange.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: hasMonthlyPlan
                          ? Colors.green.withValues(alpha: 0.12)
                          : Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Bs. ${tariffPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: hasMonthlyPlan
                                ? Colors.green.shade800
                                : Colors.deepOrange,
                          ),
                        ),
                        const Text(
                          'por plato',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // SECCIÓN 1: MENÚ PUBLICADO DE LA SEMANA
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.restaurant_menu,
                              color: Color(0xFF2563EB),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Menú Publicado de la Semana',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${AppDateUtils.formatShortDate(weekStart)} - ${AppDateUtils.formatShortDate(weekStart.add(const Duration(days: 4)))}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Días de la semana (Lunes a Viernes)
                  publishedMenuAsync.when(
                    data: (menuItems) {
                      final publishedDays = [
                        {'name': 'Lunes', 'offset': 0},
                        {'name': 'Martes', 'offset': 1},
                        {'name': 'Miércoles', 'offset': 2},
                        {'name': 'Jueves', 'offset': 3},
                        {'name': 'Viernes', 'offset': 4},
                      ];

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: publishedDays.map((dayMap) {
                            final offset = dayMap['offset'] as int;
                            final date = weekStart.add(Duration(days: offset));
                            final isDaySelected = AppDateUtils.isSameDay(
                              _selectedDate,
                              date,
                            );

                            final dishesToday = menuItems.where((i) {
                              return i.fecha.year == date.year &&
                                  i.fecha.month == date.month &&
                                  i.fecha.day == date.day;
                            }).toList();

                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedDate = date;
                                    if (dishesToday.isNotEmpty) {
                                      _selectedDishName =
                                          dishesToday.first.platoNombre;
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  width: 140,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDaySelected
                                        ? const Color(0xFF2563EB)
                                        : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDaySelected
                                          ? const Color(0xFF2563EB)
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        dayMap['name'] as String,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: isDaySelected
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        '${date.day}/${date.month}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDaySelected
                                              ? Colors.white70
                                              : Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      if (dishesToday.isEmpty)
                                        Text(
                                          'Menú en preparación',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontStyle: FontStyle.italic,
                                            color: isDaySelected
                                                ? Colors.white70
                                                : Colors.grey,
                                          ),
                                        )
                                      else
                                        ...dishesToday.take(2).map((dish) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 2.0,
                                            ),
                                            child: Text(
                                              '• ${dish.platoNombre}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: isDaySelected
                                                    ? Colors.white
                                                    : const Color(0xFF1E293B),
                                              ),
                                            ),
                                          );
                                        }),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (e, stack) => Text('Error al cargar menú: $e'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // SECCIÓN 2: FORMULARIO DE RESERVA (FLEXIBLE: EMPLEADO + FAMILIARES O INDIVIDUAL)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Configurar Reserva',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          AppDateUtils.formatDate(_selectedDate),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Selector de Plato del día
                  const Text(
                    'Plato Seleccionado:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  _buildDishSelector(publishedMenuAsync),

                  const SizedBox(height: 16),

                  // Alternar Modo: Reserva Conjunta vs Individual
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          avatar: const Icon(Icons.group, size: 16),
                          label: const Text('Reserva Conjunta'),
                          selected: _isJointReservation,
                          selectedColor: const Color(
                            0xFF2563EB,
                          ).withValues(alpha: 0.15),
                          onSelected: (val) {
                            if (val) setState(() => _isJointReservation = true);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          avatar: const Icon(Icons.person, size: 16),
                          label: const Text('Reserva Individual'),
                          selected: !_isJointReservation,
                          selectedColor: const Color(
                            0xFF2563EB,
                          ).withValues(alpha: 0.15),
                          onSelected: (val) {
                            if (val) {
                              setState(() => _isJointReservation = false);
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // MODO A: RESERVA CONJUNTA (Marcar empleado + familiares en una sola acción)
                  if (_isJointReservation) ...[
                    const Text(
                      'Marcar comensales para esta fecha:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Puedes incluir al empleado y a uno o más familiares con un clic:',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),

                    // Opción: Empleado
                    Material(
                      color: Colors.transparent,
                      child: CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Empleado: ${currentUser?.fullName ?? 'Usuario'}',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          hasMonthlyPlan
                              ? 'Tarifa Plan Mensual: Bs. 15.00'
                              : 'Tarifa Particular: Bs. 18.00',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: hasMonthlyPlan
                                ? Colors.green
                                : Colors.deepOrange,
                          ),
                        ),
                        value: _includeEmployee,
                        activeColor: const Color(0xFF2563EB),
                        onChanged: (val) {
                          setState(() => _includeEmployee = val ?? false);
                        },
                      ),
                    ),

                    // Opciones: Familiares
                    if (familyMembers.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          'No tienes familiares registrados. Puedes solicitar su vinculación con el Administrador.',
                          style: TextStyle(fontSize: 11.5, color: Colors.grey),
                        ),
                      )
                    else
                      ...familyMembers.map((fam) {
                        final isChecked = _selectedFamiliarIds.contains(fam.id);
                        return Material(
                          color: Colors.transparent,
                          child: CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Familiar: ${fam.displayName}',
                              style: const TextStyle(fontSize: 13),
                            ),
                            subtitle: Text(
                              'CI: ${fam.ci} • Tarifa: Bs. ${tariffPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            value: isChecked,
                            activeColor: const Color(0xFF2563EB),
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedFamiliarIds.add(fam.id);
                                } else {
                                  _selectedFamiliarIds.remove(fam.id);
                                }
                              });
                            },
                          ),
                        );
                      }),
                  ] else ...[
                    // MODO B: RESERVA INDIVIDUAL POR COMENSAL
                    const Text(
                      'Seleccionar comensal para la reserva individual:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<Familiar?>(
                      initialValue: _individualFamiliar,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        prefixIcon: const Icon(Icons.badge_outlined),
                      ),
                      items: [
                        DropdownMenuItem<Familiar?>(
                          value: null,
                          child: Text(
                            'Para mí (Empleado: ${currentUser?.fullName ?? 'Usuario'})',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ...familyMembers.map((f) {
                          return DropdownMenuItem<Familiar?>(
                            value: f,
                            child: Text(
                              'Familiar: ${f.displayName}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          );
                        }),
                      ],
                      onChanged: (f) {
                        setState(() => _individualFamiliar = f);
                      },
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Campo Notas / Observaciones
                  TextField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      hintText:
                          'Notas especiales (ej. Para llevar, sin locoto, vegetariano)',
                      prefixIcon: const Icon(Icons.edit_note),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // CÁLCULO Y DESGLOSE DE COSTO EN TIEMPO REAL ANTES DE CONFIRMAR
                  _buildCostSummary(tariffPrice, familyMembers),

                  const SizedBox(height: 16),

                  // Botón Confirmar Reserva
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting
                          ? null
                          : () => _handleConfirmReservation(
                              context,
                              tariffPrice,
                              familyMembers,
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: Text(
                        _isSubmitting
                            ? 'Registrando reserva...'
                            : 'Confirmar Reserva (${AppDateUtils.formatShortDate(_selectedDate)})',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // WIDGETS AUXILIARES
  // ===========================================================================

  Widget _buildDishSelector(
    AsyncValue<List<MenuSemanalItem>> publishedMenuAsync,
  ) {
    return publishedMenuAsync.when(
      data: (items) {
        final dishesToday = items.where((i) {
          return i.fecha.year == _selectedDate.year &&
              i.fecha.month == _selectedDate.month &&
              i.fecha.day == _selectedDate.day;
        }).toList();

        final options = dishesToday.isNotEmpty
            ? dishesToday.map((d) => d.platoNombre).toSet().toList()
            : [
                'Silpancho Cochabambino',
                'Pique Macho Especial',
                'Majadito Cruceño',
                'Sopa de Maní Tradicional',
                'Almuerzo Completo del Día',
              ];

        if (_selectedDishName == null || !options.contains(_selectedDishName)) {
          _selectedDishName = options.first;
        }

        return DropdownButtonFormField<String>(
          initialValue: _selectedDishName,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            prefixIcon: const Icon(Icons.soup_kitchen_outlined),
          ),
          items: options.map((dishName) {
            return DropdownMenuItem<String>(
              value: dishName,
              child: Text(
                dishName,
                style: const TextStyle(fontSize: 13.5),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedDishName = val);
          },
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (e, stack) => const Text('Error al cargar platos'),
    );
  }

  Widget _buildCostSummary(double tariffPrice, List<Familiar> familyMembers) {
    int count = 0;
    if (_isJointReservation) {
      if (_includeEmployee) count++;
      count += _selectedFamiliarIds.length;
    } else {
      count = 1;
    }

    final double totalCost = count * tariffPrice;
    final isPlanMensual = tariffPrice == 15.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isPlanMensual
            ? Colors.green.withValues(alpha: 0.08)
            : Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPlanMensual
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Desglose y Costo Total:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isPlanMensual ? Colors.green : Colors.deepOrange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isPlanMensual ? 'Tarifa Plan Mensual' : 'Tarifa Particular',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Cantidad de raciones: $count comensal(es)',
                  style: const TextStyle(fontSize: 12.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$count × Bs. ${tariffPrice.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 12.5, color: Colors.grey),
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Total a Cobrar:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Bs. ${totalCost.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isPlanMensual
                      ? Colors.green.shade800
                      : Colors.deepOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleConfirmReservation(
    BuildContext context,
    double tariffPrice,
    List<Familiar> familyMembers,
  ) async {
    final currentUser = ref.read(authProvider);
    final userId = currentUser?.id ?? 'demo-user-123';
    final userName = currentUser?.fullName ?? 'Empleado';
    final dish = _selectedDishName ?? 'Silpancho Cochabambino';
    final notes = _notesController.text.trim();

    // Validar selección
    if (_isJointReservation &&
        !_includeEmployee &&
        _selectedFamiliarIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor marca al menos un comensal para reservar.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (_isJointReservation) {
        final Map<String, String> famNames = {
          for (final f in familyMembers) f.id: f.displayName,
        };

        final createdCount = await ref
            .read(userReservationsProvider.notifier)
            .createJointReservations(
              date: _selectedDate,
              dishName: dish,
              reserveForEmployee: _includeEmployee,
              selectedFamiliarIds: _selectedFamiliarIds.toList(),
              familiarNames: famNames,
              pricePerPerson: tariffPrice,
              notes: notes.isNotEmpty ? notes : null,
              userName: userName,
              userId: userId,
            );

        if (context.mounted) {
          final total = createdCount * tariffPrice;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '¡Reserva conjunta confirmada ($createdCount comensales)! Total: Bs. ${total.toStringAsFixed(2)}',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _notesController.clear();
        }
      } else {
        // Reserva individual
        final isForFam = _individualFamiliar != null;
        final beneficiary = isForFam
            ? _individualFamiliar!.displayName
            : userName;

        final success = await ref
            .read(userReservationsProvider.notifier)
            .createReservation(
              date: _selectedDate,
              dishName: dish,
              familiarId: _individualFamiliar?.id,
              beneficiaryName: beneficiary,
              price: tariffPrice,
              notes: notes.isNotEmpty ? notes : null,
              userName: userName,
              userId: userId,
            );

        if (context.mounted && success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '¡Reserva confirmada para $beneficiary! (Tarifa: Bs. ${tariffPrice.toStringAsFixed(2)})',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _notesController.clear();
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar reserva: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _confirmSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text('Cerrar Sesión'),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que deseas cerrar sesión y salir del sistema de forma segura?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      await ref.read(authProvider.notifier).signOut();
      messenger?.showSnackBar(
        const SnackBar(
          content: Text('Sesión cerrada de forma segura.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
