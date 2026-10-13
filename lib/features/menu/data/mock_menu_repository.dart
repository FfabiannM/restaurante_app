import 'package:restaurante_app/features/menu/domain/menu_entity.dart';
import 'package:restaurante_app/features/menu/domain/menu_repository.dart';

class MockMenuRepository implements MenuRepository {
  final List<Dish> _dishes = [
    const Dish(
      id: '1',
      name: 'Silpancho Cochabambino',
      description:
          'Carne apanada sobre cama de arroz blanco y papas doradas con huevo estrellado y sarza fresca.',
      imageUrl: 'https://images.unsplash.com/photo-1544025162-d76694265947?w=500',
      price: 18.00,
      category: 'Plato Fuerte',
      calories: 780,
      isFavorite: true,
      isAvailable: true,
    ),
    const Dish(
      id: '2',
      name: 'Sopa de Maní Tradicional',
      description:
          'Sopa espesa y aromática a base de maní licuado, verduras selectas, carne tierna y fideos tostados.',
      imageUrl: 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=500',
      price: 12.00,
      category: 'Sopa',
      calories: 520,
      isFavorite: true,
      isAvailable: true,
    ),
    const Dish(
      id: '3',
      name: 'Pique Macho Especial',
      description:
          'Trozos de lomo de res saltados con salchichas, papas fritas crocantes, huevo duro, tomate y locoto.',
      imageUrl: 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=500',
      price: 22.00,
      category: 'Plato Fuerte',
      calories: 890,
      isFavorite: false,
      isAvailable: true,
    ),
    const Dish(
      id: '4',
      name: 'Plato Saludable Vegetariano',
      description:
          'Quinua real perlada con verduras salteadas al wok, palta fresca y champiñones grillados.',
      imageUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=500',
      price: 16.00,
      category: 'Vegetariano',
      calories: 460,
      isFavorite: false,
      isAvailable: true,
    ),
    const Dish(
      id: '5',
      name: 'Postre: Budín de Pan Casero',
      description:
          'Tradicional budín horneado bañado en caramelo dorado con pasas de uva y un toque de canela.',
      imageUrl: 'https://images.unsplash.com/photo-1551024709-8f23befc6f87?w=500',
      price: 7.00,
      category: 'Postre',
      calories: 320,
      isFavorite: false,
      isAvailable: true,
    ),
  ];

  @override
  Future<List<Dish>> getDailyMenu() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_dishes);
  }

  @override
  Future<void> toggleFavorite(String dishId) async {
    final index = _dishes.indexWhere((d) => d.id == dishId);
    if (index != -1) {
      final current = _dishes[index];
      _dishes[index] = current.copyWith(isFavorite: !current.isFavorite);
    }
  }

  @override
  Future<void> addDish(Dish dish) async {
    _dishes.add(dish);
  }
}
