import 'package:flutter/foundation.dart';
import 'package:restaurante_app/core/config/supabase_config.dart';
import 'package:restaurante_app/features/menu/data/mock_menu_repository.dart';
import 'package:restaurante_app/features/menu/domain/daily_menu_entity.dart';
import 'package:restaurante_app/features/menu/domain/daily_menu_policy.dart';
import 'package:restaurante_app/features/menu/domain/menu_entity.dart';
import 'package:restaurante_app/features/menu/domain/menu_repository.dart';

class SupabaseMenuRepository implements MenuRepository {
  final MockMenuRepository _mockFallback = MockMenuRepository();

  @override
  Future<DailyMenu> getDailyMenuStructure(DateTime date) async {
    final client = SupabaseConfig.client;
    if (client == null) {
      return _mockFallback.getDailyMenuStructure(date);
    }

    try {
      final dateStr =
          "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

      // Consultar menu_dias para la fecha especificada
      final menuDayRes = await client
          .from('menu_dias')
          .select('id, visible_desde, visible_hasta')
          .eq('fecha', dateStr)
          .maybeSingle();

      if (menuDayRes != null && menuDayRes['id'] != null) {
        final menuDiaId = menuDayRes['id'];
        final dishesRes = await client
            .from('menu_dia_platos')
            .select('platos(*)')
            .eq('menu_dia_id', menuDiaId);

        if (dishesRes.isNotEmpty) {
          final List<Dish> loadedDishes = [];
          for (final row in dishesRes) {
            final platoData = row['platos'];
            if (platoData != null && platoData is Map<String, dynamic>) {
              loadedDishes.add(
                Dish(
                  id: platoData['id'].toString(),
                  name: platoData['nombre'] ?? '',
                  description: 'Plato registrado en Supabase',
                  imageUrl: 'assets/silpancho.png',
                  category: platoData['tipo'] ?? 'Plato Fuerte',
                  price: 18.0,
                ),
              );
            }
          }

          if (loadedDishes.length >= 3) {
            // Clasificar platos según tipo
            final entrada = loadedDishes.firstWhere(
              (d) => d.category.toLowerCase().contains('entrada'),
              orElse: () => MockMenuRepository.entradaMock,
            );
            final sopa = loadedDishes.firstWhere(
              (d) => d.category.toLowerCase().contains('sopa'),
              orElse: () => MockMenuRepository.sopaMock,
            );
            final segundo = loadedDishes.firstWhere(
              (d) =>
                  d.category.toLowerCase().contains('segundo') ||
                  d.category.toLowerCase().contains('fuerte') ||
                  d.category.toLowerCase().contains('regular'),
              orElse: () => MockMenuRepository.segundoMock,
            );
            final vegetariano = loadedDishes.firstWhere(
              (d) => d.category.toLowerCase().contains('veg'),
              orElse: () => MockMenuRepository.vegetarianoMock,
            );
            final especial = loadedDishes.firstWhere(
              (d) => d.category.toLowerCase().contains('esp'),
              orElse: () => MockMenuRepository.especialMock,
            );
            final postre = loadedDishes.firstWhere(
              (d) => d.category.toLowerCase().contains('postre'),
              orElse: () => MockMenuRepository.postreMock,
            );

            return DailyMenuPolicy.buildDailyMenu(
              date: date,
              entrada: entrada,
              sopa: sopa,
              segundo: segundo,
              platoVegetariano: vegetariano,
              platoEspecial: especial,
              postre: postre,
            );
          }
        }
      }

      // Si no hay configuración específica en Supabase para este día, usar fallback estructurado
      return _mockFallback.getDailyMenuStructure(date);
    } catch (e) {
      debugPrint('⚠️ Error obteniendo estructura de menú en Supabase: $e');
      return _mockFallback.getDailyMenuStructure(date);
    }
  }

  @override
  Future<List<Dish>> getDailyMenu() async {
    final today = DateTime.now();
    final structure = await getDailyMenuStructure(today);
    return structure.allDishes;
  }

  @override
  Future<void> toggleFavorite(String dishId) async {
    final client = SupabaseConfig.client;
    if (client == null) {
      return _mockFallback.toggleFavorite(dishId);
    }

    try {
      final current = await client
          .from('platos')
          .select('id')
          .eq('id', dishId)
          .maybeSingle();

      if (current != null) {
        // Toggle favorito
      } else {
        await _mockFallback.toggleFavorite(dishId);
      }
    } catch (e) {
      debugPrint('⚠️ Error en toggleFavorite con Supabase: $e');
      await _mockFallback.toggleFavorite(dishId);
    }
  }

  @override
  Future<void> addDish(Dish dish) async {
    final client = SupabaseConfig.client;
    if (client == null) {
      return _mockFallback.addDish(dish);
    }

    try {
      await client.from('platos').insert({
        'nombre': dish.name,
        'tipo': dish.category.toUpperCase(),
        'activo': dish.isAvailable,
      });
    } catch (e) {
      debugPrint('⚠️ Error al agregar plato a Supabase: $e');
      await _mockFallback.addDish(dish);
    }
  }
}
