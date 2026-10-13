import 'package:restaurante_app/features/menu/domain/menu_entity.dart';

abstract class MenuRepository {
  Future<List<Dish>> getDailyMenu();
  Future<void> toggleFavorite(String dishId);
  Future<void> addDish(Dish dish);
}
