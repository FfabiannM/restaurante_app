import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurante_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:restaurante_app/features/menu/data/supabase_menu_repository.dart';
import 'package:restaurante_app/features/menu/domain/daily_menu_entity.dart';
import 'package:restaurante_app/features/menu/domain/daily_menu_policy.dart';
import 'package:restaurante_app/features/menu/domain/menu_entity.dart';
import 'package:restaurante_app/features/menu/domain/menu_repository.dart';
import 'package:restaurante_app/supabase/menu_service.dart';

class MenuScreen extends ConsumerStatefulWidget {
  final void Function(Dish dish)? onSelectDishForReservation;

  const MenuScreen({super.key, this.onSelectDishForReservation});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  final MenuRepository _repository = SupabaseMenuRepository();

  DateTime _selectedDate = DateTime.now();
  List<DateTime> _weekDays = [];
  Set<String> _excepcionesFechas = {};
  Map<String, String> _excepcionesMotivos = {};

  bool _isExcepcionDay = false;
  String? _motivoExcepcion;
  bool _isMenuDisponible = false;

  List<Dish> _dishes = [];
  DailyMenu? _dailyMenu;
  bool _isLoading = true;
  String _selectedCategory = 'Todos';
  String _searchQuery = '';

  List<String> _categories(bool isThursday) => [
        'Todos',
        'Almuerzo Completo',
        'Segundo',
        'Sopa',
        'Especial',
        'Vegetariano',
        if (isThursday) 'Postre',
      ];

  @override
  void initState() {
    super.initState();
    _initWeekAndLoad();
  }

  /// Inicializa la semana laboral (Lunes a Viernes) y carga los menús del día
  Future<void> _initWeekAndLoad() async {
    final now = DateTime.now();
    _weekDays = MenuService.getDiasSemana(referenceDate: now);

    // Por defecto seleccionar el día actual (o el primer día hábil si es fin de semana)
    final normalizedNow = DateTime(now.year, now.month, now.day);
    if (now.weekday >= 1 && now.weekday <= 5) {
      _selectedDate = normalizedNow;
    } else if (_weekDays.isNotEmpty) {
      _selectedDate = _weekDays.first;
    } else {
      _selectedDate = normalizedNow;
    }

    await _loadWeekExceptions();
    await _loadMenuForDate(_selectedDate);
  }

  /// Carga las excepciones de calendario para la semana actual (HU6)
  Future<void> _loadWeekExceptions() async {
    final rango = MenuService.getRangoSemana(referenceDate: _selectedDate);
    final exceptions = await MenuService.getExcepcionesCalendario(
      fechaInicio: MenuService.formatDate(rango.inicioSemana),
      fechaFin: MenuService.formatDate(rango.finSemana),
    );

    if (mounted) {
      setState(() {
        _excepcionesFechas = exceptions
            .map((e) => e['fecha']?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toSet();
        _excepcionesMotivos = {
          for (final e in exceptions)
            if (e['fecha'] != null)
              e['fecha'].toString():
                  e['motivo']?.toString() ?? 'Día de no atención',
        };
      });
    }
  }

  /// Carga el menú para una fecha específica desde `vista_menu_con_platos`
  /// filtrando estrictamente contra `excepcion_calendario` (HU5 y HU6).
  Future<void> _loadMenuForDate(DateTime date) async {
    setState(() {
      _isLoading = true;
      _selectedDate = date;
    });

    final dateStr = MenuService.formatDate(date);

    // 1. Verificar si la fecha está en excepcion_calendario (HU6)
    if (_excepcionesFechas.contains(dateStr)) {
      final motivo =
          _excepcionesMotivos[dateStr] ?? 'Feriado / Suspensión de servicio';
      if (mounted) {
        setState(() {
          _isExcepcionDay = true;
          _motivoExcepcion = motivo;
          _isMenuDisponible = false;
          _dishes = const [];
          _dailyMenu = null;
          _isLoading = false;
        });
      }
      return;
    }

    // 2. Consultar menú desde vista_menu_con_platos a través de MenuService
    final menuResult = await MenuService.getMenuPorFecha(date);
    if (menuResult.isExcepcion) {
      if (mounted) {
        setState(() {
          _isExcepcionDay = true;
          _motivoExcepcion =
              menuResult.motivoExcepcion ?? 'Día de no atención';
          _isMenuDisponible = false;
          _dishes = const [];
          _dailyMenu = null;
          _isLoading = false;
        });
      }
      return;
    }

    // 3. Obtener estructura de menú y platos
    final structure = await _repository.getDailyMenuStructure(date);
    final dishes = menuResult.platos.isNotEmpty
        ? menuResult.platos
        : structure.allDishes.toSet().toList();

    if (_selectedCategory == 'Postre' && !DailyMenuPolicy.isDessertDay(date)) {
      _selectedCategory = 'Todos';
    }

    if (mounted) {
      setState(() {
        _isExcepcionDay = false;
        _motivoExcepcion = null;
        _isMenuDisponible = menuResult.isDisponible || dishes.isNotEmpty;
        _dailyMenu = structure;
        _dishes = dishes;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite(Dish dish) async {
    final updatedFavorites = !dish.isFavorite;
    setState(() {
      final index = _dishes.indexWhere((d) => d.id == dish.id);
      if (index != -1) {
        _dishes[index] = dish.copyWith(isFavorite: updatedFavorites);
      }
    });

    await _repository.toggleFavorite(dish.id);
  }

  List<Dish> get _filteredDishes {
    return _dishes.where((dish) {
      final matchesCategory = _matchesCategory(dish);
      final matchesSearch = _matchesSearch(dish);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  bool _matchesCategory(Dish dish) {
    if (_selectedCategory == 'Todos') {
      return true;
    }
    if (_selectedCategory == 'Almuerzo Completo') {
      return dish.category == 'Sopa' ||
          dish.category == 'Segundo' ||
          dish.category == 'Entrada';
    }
    return dish.category.toLowerCase().contains(
          _selectedCategory.toLowerCase(),
        );
  }

  List<Dish> get _selectedDishes {
    if (_selectedCategory == 'Especial' && _dailyMenu != null) {
      final especialDishes = _dishes
          .where((d) => d.category.toLowerCase().contains('especial'))
          .where(_matchesSearch)
          .toList();
      if (especialDishes.isNotEmpty) return especialDishes;
      return [_dailyMenu!.platoEspecial].where(_matchesSearch).toList();
    }
    if (_selectedCategory == 'Vegetariano' && _dailyMenu != null) {
      final vegDishes = _dishes
          .where((d) => d.category.toLowerCase().contains('veg'))
          .where(_matchesSearch)
          .toList();
      if (vegDishes.isNotEmpty) return vegDishes;
      return [_dailyMenu!.platoVegetariano].where(_matchesSearch).toList();
    }
    return _filteredDishes;
  }

  bool _matchesSearch(Dish dish) {
    final query = _searchQuery.toLowerCase();
    return dish.name.toLowerCase().contains(query) ||
        dish.description.toLowerCase().contains(query);
  }

  @override
  Widget build(BuildContext context) {
    final isThursday = DailyMenuPolicy.isDessertDay(_selectedDate);
    final categories = _categories(isThursday);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Menú del Día',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.white,
              ),
            ),
            Text(
              'Restaurante Institucional',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Actualizar menú',
            onPressed: () async {
              await _loadWeekExceptions();
              await _loadMenuForDate(_selectedDate);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Cerrar Sesión',
            onPressed: _confirmSignOut,
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Selector semanal Lunes a Viernes (Fórmula solicitada)
          _buildWeekDaySelector(),

          // 2. Contenido según estado: Excepción (HU6), No disponible (HU5) o Menú
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : _isExcepcionDay
                    ? _buildExcepcionBanner()
                    : !_isMenuDisponible
                        ? _buildMenuNoDisponibleBanner()
                        : _buildMenuContent(categories, isThursday),
          ),
        ],
      ),
    );
  }

  /// Selector de días de la semana laboral (Lunes a Viernes)
  Widget _buildWeekDaySelector() {
    final dayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie'];
    final todayStr = MenuService.formatDate(DateTime.now());
    final selectedStr = MenuService.formatDate(_selectedDate);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _weekDays.asMap().entries.map((entry) {
          final index = entry.key;
          final dayDate = entry.value;
          final dateStr = MenuService.formatDate(dayDate);
          final isSelected = dateStr == selectedStr;
          final isToday = dateStr == todayStr;
          final isExcepcion = _excepcionesFechas.contains(dateStr);

          return InkWell(
            onTap: () => _loadMenuForDate(dayDate),
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : (isToday
                        ? Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.12)
                        : Colors.transparent),
                borderRadius: BorderRadius.circular(14),
                border: isToday && !isSelected
                    ? Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.5,
                      )
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dayNames[index % dayNames.length],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : (isExcepcion
                                  ? Colors.red.shade700
                                  : const Color(0xFF64748B)),
                        ),
                      ),
                      if (isExcepcion) ...[
                        const SizedBox(width: 3),
                        Icon(
                          Icons.block,
                          size: 11,
                          color: isSelected ? Colors.white : Colors.red,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dayDate.day.toString().padLeft(2, '0'),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : (isExcepcion
                              ? Colors.red.shade700
                              : const Color(0xFF1E293B)),
                    ),
                  ),
                  if (isToday)
                    Text(
                      'Hoy',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white70
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Banner cuando el día tiene excepción de calendario (HU6)
  Widget _buildExcepcionBanner() {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.orange.shade200, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.event_busy_rounded,
                  size: 48,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Día no habilitado para atención',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _motivoExcepcion ?? 'Feriado / Suspensión de servicio',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'El restaurante institucional no prestará servicio de almuerzos en esta fecha en cumplimiento de las excepciones de calendario (HU6).',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Banner cuando el menú aún no ha sido cargado por el encargado (HU5)
  Widget _buildMenuNoDisponibleBanner() {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.restaurant_outlined,
                  size: 48,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Menú no disponible',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'El menú para esta fecha aún no ha sido cargado o publicado por el encargado del restaurante (HU5).',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Contenido principal del menú disponible
  Widget _buildMenuContent(List<String> categories, bool isThursday) {
    final showCombos = _selectedCategory == 'Almuerzo Completo' &&
        _dailyMenu != null &&
        _dailyMenu!.opcionesAlmuerzo.isNotEmpty;
    final itemsCount =
        showCombos ? _dailyMenu!.opcionesAlmuerzo.length : _selectedDishes.length;
    final hasBanner = _dailyMenu != null;

    return Column(
      children: [
        // Barra de búsqueda rápida
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 2.0,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: const InputDecoration(
                hintText: 'Buscar platos, ingredientes...',
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),

        // Filtro por categorías
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          child: Row(
            children: categories.map((cat) {
              final isSelected = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  label: Text(
                    cat,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: Theme.of(context).colorScheme.primary,
                  backgroundColor: Colors.white.withValues(alpha: 0.85),
                  checkmarkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = cat;
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),

        // Lista de platos o combos con banner integrado
        Expanded(
          child: (itemsCount == 0 && !hasBanner)
              ? Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.restaurant_outlined,
                          size: 48,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No se encontraron platos para este filtro.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => _loadMenuForDate(_selectedDate),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: itemsCount + (hasBanner ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (hasBanner && index == 0) {
                        return _buildDailyMenuBanner(isThursday);
                      }
                      final itemIdx = hasBanner ? index - 1 : index;
                      if (itemsCount == 0) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(top: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'No se encontraron platos para este filtro.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                        );
                      }
                      if (showCombos) {
                        return _buildCompleteLunchCard(
                          _dailyMenu!.opcionesAlmuerzo[itemIdx],
                          itemIdx,
                        );
                      }
                      return _buildDishCard(_selectedDishes[itemIdx]);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildDailyMenuBanner(bool isThursday) {
    if (_dailyMenu == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.restaurant_menu,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Menú Diario',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isThursday
                        ? Colors.purple.withValues(alpha: 0.15)
                        : Colors.grey.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isThursday
                        ? '🍰 Jueves: Postre'
                        : '🍰 Postres solo jueves',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isThursday
                          ? Colors.purple
                          : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._dailyMenu!.opcionesAlmuerzo.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      '• Almuerzo Completo ${entry.key + 1}: Entrada (${entry.value.entrada.name}) + Sopa (${entry.value.sopa.name}) + Segundo (${entry.value.segundo.name})',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                ),
            const SizedBox(height: 2),
            Text(
              '• Opción Vegetariana: ${_dailyMenu!.platoVegetariano.name}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '• Plato Especial: ${_dailyMenu!.platoEspecial.name}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompleteLunchCard(AlmuerzoCompleto combo, int index) {
    final components = [
      ('Entrada / ensalada', combo.entrada),
      ('Sopa del día', combo.sopa),
      ('Segundo', combo.segundo),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.restaurant_menu,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Almuerzo Completo ${index + 1}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              Text(
                'Bs. ${combo.precio.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...components.map(
            (component) =>
                _buildComboComponent(label: component.$1, dish: component.$2),
          ),
          if (widget.onSelectDishForReservation != null) ...[
            const Divider(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () =>
                    widget.onSelectDishForReservation!(combo.segundo),
                icon: const Icon(Icons.calendar_today, size: 16),
                label: const Text('Reservar este almuerzo'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildComboComponent({required String label, required Dish dish}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          _buildDishImage(
            dish.imageUrl,
            width: 58,
            height: 58,
            borderRadius: 10,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dish.name.isNotEmpty ? dish.name : 'Plato del día',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDishCard(Dish dish) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen redondeada con control de nulos y carga
                _buildDishImage(
                  dish.imageUrl,
                  width: 90,
                  height: 90,
                  borderRadius: 18,
                ),
                const SizedBox(width: 14),

                // Detalles del plato
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              dish.name.isNotEmpty
                                  ? dish.name
                                  : 'Plato del día',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              dish.isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color:
                                  dish.isFavorite ? Colors.red : Colors.grey,
                              size: 22,
                            ),
                            onPressed: () => _toggleFavorite(dish),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dish.description.isNotEmpty
                            ? dish.description
                            : 'Plato registrado en el restaurante.',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12.5,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Etiquetas (categoría, calorías, precio)
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              dish.category,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${dish.calories} kcal',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Bs. ${dish.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (widget.onSelectDishForReservation != null)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.15),
                  ),
                ),
              ),
              child: InkWell(
                onTap: () => widget.onSelectDishForReservation!(dish),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Reservar este plato',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Construye de manera resiliente la imagen del plato soportando URLs remotas (Supabase Storage),
  /// assets locales y placeholders ante fallas o nulos.
  Widget _buildDishImage(
    String? rawUrl, {
    double width = 90,
    double height = 90,
    double borderRadius = 18,
  }) {
    final url = rawUrl?.trim() ?? '';
    if (url.isEmpty) {
      return _buildImagePlaceholder(
        width: width,
        height: height,
        borderRadius: borderRadius,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: url.startsWith('http://') || url.startsWith('https://')
            ? Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey.shade100,
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) =>
                    _buildImagePlaceholder(
                  width: width,
                  height: height,
                  borderRadius: borderRadius,
                ),
              )
            : Image.asset(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildImagePlaceholder(
                  width: width,
                  height: height,
                  borderRadius: borderRadius,
                ),
              ),
      ),
    );
  }

  Widget _buildImagePlaceholder({
    double width = 90,
    double height = 90,
    double borderRadius = 18,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: const Icon(Icons.restaurant, color: Colors.grey, size: 28),
    );
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
