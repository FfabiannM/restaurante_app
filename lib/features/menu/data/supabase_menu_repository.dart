import 'package:flutter/foundation.dart';
import 'package:restaurante_app/core/config/supabase_config.dart';
import 'package:restaurante_app/features/menu/data/mock_menu_repository.dart';
import 'package:restaurante_app/features/menu/domain/menu_entity.dart';
import 'package:restaurante_app/features/menu/domain/menu_repository.dart';

class SupabaseMenuRepository implements MenuRepository {
  final MockMenuRepository _mockFallback = MockMenuRepository();

  @override
  Future<List<Dish>> getDailyMenu() async {
    final client = SupabaseConfig.client;
    if (client == null) {
      return _mockFallback.getDailyMenu();
    }

    try {
      final response = await client
          .from('dishes')
          .select()
          .order('name', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      if (data.isEmpty) {
        // Si la tabla existe pero está vacía, entregamos platos de fallback
        return _mockFallback.getDailyMenu();
      }
      return data.map((item) => Dish.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('⚠️ Error al consultar menú desde Supabase: $e. Usando datos de respaldo.');
      return _mockFallback.getDailyMenu();
    }
  }

  @override
  Future<void> toggleFavorite(String dishId) async {
    final client = SupabaseConfig.client;
    if (client == null) {
      return _mockFallback.toggleFavorite(dishId);
    }

    try {
      // Obtenemos el plato actual
      final current = await client
          .from('dishes')
          .select('is_favorite')
          .eq('id', dishId)
          .maybeSingle();

      if (current != null) {
        final currentFav = current['is_favorite'] == true;
        await client
            .from('dishes')
            .update({'is_favorite': !currentFav})
            .eq('id', dishId);
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
      await client.from('dishes').insert(dish.toJson());
    } catch (e) {
      debugPrint('⚠️ Error al agregar plato a Supabase: $e');
      await _mockFallback.addDish(dish);
    }
  }
}
