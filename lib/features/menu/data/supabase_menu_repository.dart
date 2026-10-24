import 'package:flutter/foundation.dart';
import 'package:restaurante_app/core/config/supabase_config.dart';
import 'package:restaurante_app/features/menu/data/mock_menu_repository.dart';
import 'package:restaurante_app/features/menu/domain/daily_menu_entity.dart';
import 'package:restaurante_app/features/menu/domain/daily_menu_policy.dart';
import 'package:restaurante_app/features/menu/domain/menu_entity.dart';
import 'package:restaurante_app/features/menu/domain/menu_repository.dart';
import 'package:restaurante_app/features/menu/data/dish_image_resolver.dart';
import 'package:restaurante_app/features/menu/data/dish_category_resolver.dart';

class SupabaseMenuRepository implements MenuRepository {
  final MockMenuRepository _mockFallback = MockMenuRepository();

  bool _isDishActive(Map<String, dynamic> dish) {
    final value = dish['activo'] ?? dish['is_available'];
    return value != false &&
        value != 0 &&
        value?.toString().toLowerCase() != 'false';
  }

  List<AlmuerzoCompleto> _buildAlmuerzoOptions(List<Dish> dishes) {
    final entradas = dishes
        .where((d) => d.category.toLowerCase().contains('entrada'))
        .toList();
    final sopas = dishes
        .where((d) => d.category.toLowerCase().contains('sopa'))
        .toList();
    final segundos = dishes
        .where(
          (d) =>
              d.category.toLowerCase().contains('segundo') ||
              d.category.toLowerCase().contains('fuerte') ||
              d.category.toLowerCase().contains('regular'),
        )
        .toList();

    if (entradas.isEmpty || sopas.isEmpty || segundos.isEmpty) {
      return const [];
    }

    final count = [
      entradas.length,
      sopas.length,
      segundos.length,
    ].reduce((a, b) => a < b ? a : b).clamp(1, 3).toInt();
    return List.generate(
      count,
      (index) => AlmuerzoCompleto(
        entrada: entradas[index % entradas.length],
        sopa: sopas[index % sopas.length],
        segundo: segundos[index % segundos.length],
      ),
    );
  }

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
            if (platoData is Map<String, dynamic> && _isDishActive(platoData)) {
              final imgPath = platoData['imagen_path']?.toString();
              final resolvedImageUrl = (imgPath != null && imgPath.isNotEmpty)
                  ? (imgPath.startsWith('assets/')
                        ? imgPath
                        : 'assets/images/$imgPath')
                  : 'assets/images/01_silpancho.jpg';

              loadedDishes.add(
                Dish(
                  id: platoData['id'].toString(),
                  name: platoData['nombre'] ?? '',
                  description: 'Plato registrado en Supabase',
                  imageUrl: resolvedImageUrl,
                  category: resolveDishCategory(
                    type: platoData['tipo']?.toString(),
                    name: platoData['nombre']?.toString(),
                  ),
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
              almuerzosCompletos: _buildAlmuerzoOptions(loadedDishes),
            );
          }
        }
      }

      // Si no hay configuración en menu_dias para este día, consultar tabla platos directamente en Supabase
      try {
        final platosRes = await client.from('platos').select();
        final List<dynamic> platosList = (platosRes as List<dynamic>)
            .where((row) => _isDishActive(row as Map<String, dynamic>))
            .toList();
        if (platosList.isNotEmpty) {
          final List<Dish> dbDishes = [];
          for (final row in platosList) {
            final platoData = row as Map<String, dynamic>;
            final rawImg =
                platoData['imagen_path'] ??
                platoData['imagen_url'] ??
                platoData['image_url'];
            final platoNom = platoData['nombre']?.toString() ?? 'Plato';
            final platoId = platoData['id'] is int
                ? platoData['id'] as int
                : int.tryParse(platoData['id']?.toString() ?? '0') ?? 0;

            final resolvedImageUrl = resolveDatabaseDishImage(
              rawImg?.toString(),
              dishName: platoNom,
              dishId: platoId,
            );

            dbDishes.add(
              Dish(
                id: platoId.toString(),
                name: platoNom,
                description:
                    platoData['descripcion']?.toString() ??
                    'Plato registrado en Supabase',
                imageUrl: resolvedImageUrl,
                category: resolveDishCategory(
                  type:
                      platoData['tipo']?.toString() ??
                      platoData['categoria']?.toString(),
                  name: platoNom,
                ),
                price: (platoData['precio'] as num?)?.toDouble() ?? 18.0,
              ),
            );
          }

          if (dbDishes.isNotEmpty) {
            return DailyMenuPolicy.buildDailyMenu(
              date: date,
              entrada: dbDishes.firstWhere(
                (d) => d.category.toLowerCase().contains('entrada'),
                orElse: () => dbDishes.first,
              ),
              sopa: dbDishes.firstWhere(
                (d) => d.category.toLowerCase().contains('sopa'),
                orElse: () => dbDishes.first,
              ),
              segundo: dbDishes.firstWhere(
                (d) =>
                    d.category.toLowerCase().contains('segundo') ||
                    d.category.toLowerCase().contains('fuerte'),
                orElse: () => dbDishes.first,
              ),
              platoVegetariano: dbDishes.firstWhere(
                (d) => d.category.toLowerCase().contains('veg'),
                orElse: () => dbDishes.first,
              ),
              platoEspecial: dbDishes.firstWhere(
                (d) => d.category.toLowerCase().contains('esp'),
                orElse: () => dbDishes.first,
              ),
              postre: dbDishes.firstWhere(
                (d) => d.category.toLowerCase().contains('postre'),
                orElse: () => dbDishes.first,
              ),
              almuerzosCompletos: _buildAlmuerzoOptions(dbDishes),
            );
          }
        }
      } catch (ePlatos) {
        debugPrint('ℹ️ Fallback platos en SupabaseMenuRepository ($ePlatos).');
      }

      // Fallback estructurado en memoria si Supabase no tiene datos
      return _mockFallback.getDailyMenuStructure(date);
    } catch (e) {
      debugPrint('⚠️ Error obteniendo estructura de menú en Supabase: $e');
      return _mockFallback.getDailyMenuStructure(date);
    }
  }

  @override
  Future<List<Dish>> getDailyMenu() async {
    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        final platosRes = await client.from('platos').select();
        final List<dynamic> platosList = (platosRes as List<dynamic>).where((
          row,
        ) {
          return _isDishActive(row as Map<String, dynamic>);
        }).toList();
        if (platosList.isNotEmpty) {
          return platosList.map((row) {
            final platoData = row as Map<String, dynamic>;
            final rawImg =
                platoData['imagen_path'] ??
                platoData['imagen_url'] ??
                platoData['image_url'];
            final platoNom = platoData['nombre']?.toString() ?? 'Plato';
            final platoId = platoData['id'] is int
                ? platoData['id'] as int
                : int.tryParse(platoData['id']?.toString() ?? '0') ?? 0;

            return Dish(
              id: platoId.toString(),
              name: platoNom,
              description:
                  platoData['descripcion']?.toString() ??
                  'Plato registrado en Supabase',
              imageUrl: resolveDatabaseDishImage(
                rawImg?.toString(),
                dishName: platoNom,
                dishId: platoId,
              ),
              category: resolveDishCategory(
                type:
                    platoData['tipo']?.toString() ??
                    platoData['categoria']?.toString(),
                name: platoNom,
              ),
              price: (platoData['precio'] as num?)?.toDouble() ?? 18.0,
            );
          }).toList();
        }
      } catch (_) {}
    }

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
