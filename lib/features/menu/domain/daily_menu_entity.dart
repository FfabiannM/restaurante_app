import 'package:restaurante_app/features/menu/domain/menu_entity.dart';

/// Representa el Almuerzo Completo diario que incluye:
/// 1. Entrada
/// 2. Sopa
/// 3. Segundo (Plato Fuerte)
class AlmuerzoCompleto {
  final Dish entrada;
  final Dish sopa;
  final Dish segundo;
  final double precio;

  const AlmuerzoCompleto({
    required this.entrada,
    required this.sopa,
    required this.segundo,
    this.precio = 18.0,
  });

  String get summary => '${entrada.name} + ${sopa.name} + ${segundo.name}';
}

/// Representa la oferta del menú para una fecha determinada:
/// - Almuerzo completo (entrada, sopa, segundo)
/// - 1 Plato vegetariano por día
/// - 1 Plato especial por día
/// - Postre: Disponible ÚNICAMENTE los días Jueves.
class DailyMenu {
  final DateTime date;
  final AlmuerzoCompleto almuerzoCompleto;
  final Dish platoVegetariano;
  final Dish platoEspecial;
  final Dish? postre; // Solo presente si date.weekday == DateTime.thursday

  const DailyMenu({
    required this.date,
    required this.almuerzoCompleto,
    required this.platoVegetariano,
    required this.platoEspecial,
    this.postre,
  });

  /// Regla de negocio: El postre se sirve única y exclusivamente los jueves.
  bool get hasDessert => date.weekday == DateTime.thursday && postre != null;

  /// Retorna la lista de todos los platos disponibles hoy
  List<Dish> get allDishes {
    final list = [
      almuerzoCompleto.entrada,
      almuerzoCompleto.sopa,
      almuerzoCompleto.segundo,
      platoVegetariano,
      platoEspecial,
    ];
    if (hasDessert && postre != null) {
      list.add(postre!);
    }
    return list;
  }
}
