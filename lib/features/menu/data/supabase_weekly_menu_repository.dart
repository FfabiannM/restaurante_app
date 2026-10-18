import 'package:flutter/foundation.dart';
import 'package:restaurante_app/core/config/supabase_config.dart';
import 'package:restaurante_app/core/utils/date_utils.dart';
import 'package:restaurante_app/features/menu/domain/bolivian_dish_entity.dart';

class SupabaseWeeklyMenuRepository {
  // Catálogo base de platos típicos de la gastronomía boliviana
  static final List<PlatoCatalogo> defaultCatalogo = [
    const PlatoCatalogo(
      id: 1,
      nombre: 'Silpancho Cochabambino',
      descripcion:
          'Carne apanada tierna sobre cama de arroz y papas doradas, con huevo frito y sarza criolla',
      categoria: 'Segundo',
      region: 'Cochabamba',
      precio: 18.0,
      imagenUrl: 'assets/silpancho.png',
    ),
    const PlatoCatalogo(
      id: 2,
      nombre: 'Pique Macho Especial',
      descripcion:
          'Trozos de lomo de res, salchichas, papas fritas, huevo duro, cebolla, tomate y locoto',
      categoria: 'Segundo',
      region: 'Cochabamba',
      precio: 18.0,
      imagenUrl: 'assets/silpancho.png',
    ),
    const PlatoCatalogo(
      id: 3,
      nombre: 'Majadito Cruceño',
      descripcion:
          'Arroz tostado con charque de res desmenuzado, plátano frito maduro y huevo criollo',
      categoria: 'Segundo',
      region: 'Santa Cruz',
      precio: 18.0,
      imagenUrl: 'assets/silpancho.png',
    ),
    const PlatoCatalogo(
      id: 4,
      nombre: 'Sopa de Maní Tradicional',
      descripcion:
          'Sopa cremosa tradicional a base de maní molido, costilla de res, arvejas y papas al hilo',
      categoria: 'Sopa',
      region: 'Nacional',
      precio: 18.0,
      imagenUrl: 'assets/silpancho.png',
    ),
    const PlatoCatalogo(
      id: 5,
      nombre: 'Falso Conejo',
      descripcion:
          'Carne apanada en ají amarillo con arvejas jugosas, servido con arroz graneado y fideo',
      categoria: 'Segundo',
      region: 'La Paz',
      precio: 18.0,
      imagenUrl: 'assets/silpancho.png',
    ),
    const PlatoCatalogo(
      id: 6,
      nombre: 'Saice Tarijeño',
      descripcion:
          'Guiso tradicional de carne picada, ají colorado, arvejas, cebolla picada y chuchusmuti',
      categoria: 'Segundo',
      region: 'Tarija',
      precio: 18.0,
      imagenUrl: 'assets/silpancho.png',
    ),
    const PlatoCatalogo(
      id: 7,
      nombre: 'Chairo Paceño',
      descripcion:
          'Sopa andina espesa con chuño picado, chalona, carne de res, trigo pelado y hierbabuena',
      categoria: 'Sopa',
      region: 'La Paz',
      precio: 18.0,
      imagenUrl: 'assets/silpancho.png',
    ),
    const PlatoCatalogo(
      id: 8,
      nombre: 'Picante Mixto',
      descripcion:
          'Combinación de pollo al ají amarillo y lengua de res en ají rojo con chuño phuti',
      categoria: 'Segundo',
      region: 'Cochabamba / Chuquisaca',
      precio: 18.0,
      imagenUrl: 'assets/silpancho.png',
    ),
    const PlatoCatalogo(
      id: 9,
      nombre: 'Mondongo Chuquisaqueño',
      descripcion:
          'Carne de cerdo dorada en ají colorado acompañada de mote amarillo cocido y papas',
      categoria: 'Segundo',
      region: 'Chuquisaca',
      precio: 18.0,
      imagenUrl: 'assets/silpancho.png',
    ),
    const PlatoCatalogo(
      id: 10,
      nombre: 'Trucha del Titicaca al Limón',
      descripcion:
          'Filete fresco de trucha a la plancha con limón, arroz blanco y papas a la francesa',
      categoria: 'Segundo',
      region: 'La Paz',
      precio: 18.0,
      imagenUrl: 'assets/silpancho.png',
    ),
    const PlatoCatalogo(
      id: 11,
      nombre: 'Pastel de Fideo Criollo',
      descripcion:
          'Pastel horneado de fideos con abundante queso chaqueño boliviano y huevo batido',
      categoria: 'Segundo',
      region: 'Nacional',
      precio: 18.0,
      imagenUrl: 'assets/silpancho.png',
    ),
    const PlatoCatalogo(
      id: 12,
      nombre: 'Ají de Papalisa',
      descripcion:
          'Guiso tradicional de papalisa en trozos con carne picada, ají colorado y cebollín',
      categoria: 'Segundo',
      region: 'Potosí / Cochabamba',
      precio: 18.0,
      imagenUrl: 'assets/silpancho.png',
    ),
  ];

  // Almacén en memoria de menú semanal para respaldo y modo local
  final List<MenuSemanalItem> _inMemoryMenuSemanal = [];

  SupabaseWeeklyMenuRepository() {
    _initDefaultWeeklyMenu();
  }

  void _initDefaultWeeklyMenu() {
    final now = DateTime.now();
    // Encontrar el lunes de la semana actual
    final monday = now.subtract(Duration(days: now.weekday - 1));

    final defaultAssignments = [
      {'day': 0, 'dishId': 1, 'name': 'Lunes'}, // Silpancho
      {'day': 1, 'dishId': 4, 'name': 'Martes'}, // Sopa de Maní
      {'day': 2, 'dishId': 3, 'name': 'Miércoles'}, // Majadito
      {'day': 3, 'dishId': 2, 'name': 'Jueves'}, // Pique Macho
      {'day': 4, 'dishId': 5, 'name': 'Viernes'}, // Falso Conejo
    ];

    int autoId = 100;
    for (final assign in defaultAssignments) {
      final date = monday.add(Duration(days: assign['day'] as int));
      final dish = defaultCatalogo.firstWhere(
        (d) => d.id == assign['dishId'],
        orElse: () => defaultCatalogo.first,
      );

      _inMemoryMenuSemanal.add(
        MenuSemanalItem(
          id: autoId++,
          fecha: date,
          diaSemana: assign['name'] as String,
          platoCatalogoId: dish.id,
          platoNombre: dish.nombre,
          platoDescripcion: dish.descripcion,
          platoRegion: dish.region,
          tipoPlato: dish.categoria,
          estado: 'publicado',
        ),
      );
    }
  }

  /// Obtiene la lista completa de platos preestablecidos de la gastronomía boliviana
  Future<List<PlatoCatalogo>> getCatalogoPlatos() async {
    final client = SupabaseConfig.client;
    if (client == null) {
      return defaultCatalogo;
    }

    try {
      final response = await client
          .from('platos_catalogo')
          .select()
          .eq('activo', true)
          .order('id', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      if (data.isEmpty) {
        return defaultCatalogo;
      }
      return data
          .map((item) => PlatoCatalogo.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('⚠️ Error obteniendo catálogo boliviano de Supabase ($e). Usando catálogo base.');
      return defaultCatalogo;
    }
  }

  /// Obtiene los platos configurados para la semana indicada
  Future<List<MenuSemanalItem>> getMenuSemanal(DateTime startOfWeek) async {
    final client = SupabaseConfig.client;
    final monday = startOfWeek.subtract(Duration(days: startOfWeek.weekday - 1));
    final friday = monday.add(const Duration(days: 4));

    final mondayStr =
        "${monday.year.toString().padLeft(4, '0')}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}";
    final fridayStr =
        "${friday.year.toString().padLeft(4, '0')}-${friday.month.toString().padLeft(2, '0')}-${friday.day.toString().padLeft(2, '0')}";

    if (client == null) {
      return _inMemoryMenuSemanal.where((item) {
        final d = DateTime(item.fecha.year, item.fecha.month, item.fecha.day);
        final start = DateTime(monday.year, monday.month, monday.day);
        final end = DateTime(friday.year, friday.month, friday.day);
        return (d.isAfter(start.subtract(const Duration(days: 1))) &&
            d.isBefore(end.add(const Duration(days: 1))));
      }).toList();
    }

    try {
      final response = await client
          .from('menu_semanal')
          .select('*, platos_catalogo(*)')
          .gte('fecha', mondayStr)
          .lte('fecha', fridayStr)
          .order('fecha', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      if (data.isEmpty) {
        return _inMemoryMenuSemanal;
      }
      return data
          .map((item) => MenuSemanalItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('⚠️ Error al consultar menú semanal en Supabase ($e). Retornando memoria.');
      return _inMemoryMenuSemanal;
    }
  }

  /// Obtiene el menú de la semana que ya ha sido publicado y está visible para empleados
  Future<List<MenuSemanalItem>> getMenuPublicado(DateTime date) async {
    final list = await getMenuSemanal(date);
    return list.where((item) => item.isPublicado).toList();
  }

  /// Agrega o quita un plato del menú de un día específico
  Future<void> togglePlatoEnMenu({
    required DateTime fecha,
    required String diaSemana,
    required PlatoCatalogo plato,
    required bool agregar,
  }) async {
    final client = SupabaseConfig.client;
    final dateStr =
        "${fecha.year.toString().padLeft(4, '0')}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";

    if (agregar) {
      // Agregar plato al día
      final exists = _inMemoryMenuSemanal.any(
        (m) =>
            AppDateUtils.isSameDay(m.fecha, fecha) &&
            m.platoCatalogoId == plato.id,
      );
      if (!exists) {
        final newItem = MenuSemanalItem(
          id: DateTime.now().millisecondsSinceEpoch % 1000000,
          fecha: fecha,
          diaSemana: diaSemana,
          platoCatalogoId: plato.id,
          platoNombre: plato.nombre,
          platoDescripcion: plato.descripcion,
          platoRegion: plato.region,
          tipoPlato: plato.categoria,
          estado: 'borrador',
        );
        _inMemoryMenuSemanal.add(newItem);

        if (client != null) {
          try {
            await client.from('menu_semanal').insert({
              'fecha': dateStr,
              'dia_semana': diaSemana,
              'plato_catalogo_id': plato.id,
              'tipo_plato': plato.categoria,
              'estado': 'borrador',
            });
          } catch (e) {
            debugPrint('⚠️ Error al insertar plato en menú semanal Supabase: $e');
          }
        }
      }
    } else {
      // Quitar plato del día
      _inMemoryMenuSemanal.removeWhere(
        (m) =>
            AppDateUtils.isSameDay(m.fecha, fecha) &&
            m.platoCatalogoId == plato.id,
      );

      if (client != null) {
        try {
          await client
              .from('menu_semanal')
              .delete()
              .eq('fecha', dateStr)
              .eq('plato_catalogo_id', plato.id);
        } catch (e) {
          debugPrint('⚠️ Error al eliminar plato de menú semanal Supabase: $e');
        }
      }
    }
  }

  /// Publica el menú semanal (cambia el estado de borrador a 'publicado')
  Future<bool> publicarMenuSemanal({
    required DateTime startOfWeek,
  }) async {
    final monday = startOfWeek.subtract(Duration(days: startOfWeek.weekday - 1));
    final friday = monday.add(const Duration(days: 4));

    final mondayStr =
        "${monday.year.toString().padLeft(4, '0')}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}";
    final fridayStr =
        "${friday.year.toString().padLeft(4, '0')}-${friday.month.toString().padLeft(2, '0')}-${friday.day.toString().padLeft(2, '0')}";

    // Actualizar estado en memoria
    for (int i = 0; i < _inMemoryMenuSemanal.length; i++) {
      final item = _inMemoryMenuSemanal[i];
      final d = DateTime(item.fecha.year, item.fecha.month, item.fecha.day);
      final start = DateTime(monday.year, monday.month, monday.day);
      final end = DateTime(friday.year, friday.month, friday.day);

      if (!d.isBefore(start) && !d.isAfter(end)) {
        _inMemoryMenuSemanal[i] = item.copyWith(estado: 'publicado');
      }
    }

    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        await client
            .from('menu_semanal')
            .update({
              'estado': 'publicado',
              'actualizado_en': DateTime.now().toIso8601String(),
            })
            .gte('fecha', mondayStr)
            .lte('fecha', fridayStr);
        return true;
      } catch (e) {
        debugPrint('⚠️ Error actualizando estado a publicado en Supabase: $e');
        return true;
      }
    }
    return true;
  }
}
