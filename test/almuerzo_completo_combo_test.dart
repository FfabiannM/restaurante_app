import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurante_app/features/auth/data/supabase_auth_repository.dart';
import 'package:restaurante_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:restaurante_app/features/menu/domain/bolivian_dish_entity.dart';
import 'package:restaurante_app/features/menu/presentation/providers/weekly_menu_provider.dart';
import 'package:restaurante_app/features/reservas/data/supabase_reservation_repository.dart';
import 'package:restaurante_app/features/reservas/domain/reservation_entity.dart';
import 'package:restaurante_app/features/reservas/presentation/employee_screen.dart';

class _StaticAuthNotifier extends AuthNotifier {
  final dynamic _user;
  _StaticAuthNotifier(this._user);

  @override
  build() => _user;
}

class _StaticWeekNotifier extends SelectedWeekNotifier {
  final DateTime _week;
  _StaticWeekNotifier(this._week);

  @override
  DateTime build() => _week;
}

void main() {
  group('1. Entidad y Lógica de Almuerzo Completo (Combo Plato + Sopa)', () {
    test(
      'Reservation model soporta combo Almuerzo Completo (plato principal + sopa)',
      () {
        final now = DateTime.now();
        final res = Reservation(
          id: 'test-combo-1',
          userId: 'usr-123',
          userName: 'Empleado Test',
          dishName:
              'Almuerzo Completo (Silpancho Cochabambino + Sopa de Maní Tradicional)',
          platoPrincipal: 'Silpancho Cochabambino',
          sopaNombre: 'Sopa de Maní Tradicional',
          isAlmuerzoCompleto: true,
          date: now,
          price: 15.0,
          createdAt: now,
        );

        expect(res.platoPrincipal, equals('Silpancho Cochabambino'));
        expect(res.sopaNombre, equals('Sopa de Maní Tradicional'));
        expect(res.isAlmuerzoCompleto, isTrue);
        expect(res.dishName, contains('Almuerzo Completo'));

        final json = res.toJson();
        expect(json['plato_principal'], equals('Silpancho Cochabambino'));
        expect(json['sopa_nombre'], equals('Sopa de Maní Tradicional'));
        expect(json['es_almuerzo_completo'], isTrue);

        final fromJson = Reservation.fromJson(json);
        expect(fromJson.platoPrincipal, equals('Silpancho Cochabambino'));
        expect(fromJson.sopaNombre, equals('Sopa de Maní Tradicional'));
        expect(fromJson.isAlmuerzoCompleto, isTrue);
        expect(fromJson.dishName, contains('Almuerzo Completo'));
      },
    );

    test(
      'SupabaseReservationRepository almacena combo de Almuerzo Completo',
      () async {
        final repo = SupabaseReservationRepository();
        final now = DateTime.now();

        final res = Reservation(
          id: 'res-combo-test-2',
          userId: 'demo-user-123',
          userName: 'Juan Pérez (Empleado)',
          dishName: 'Almuerzo Completo (Pique Macho Especial + Chairo Paceño)',
          platoPrincipal: 'Pique Macho Especial',
          sopaNombre: 'Chairo Paceño',
          isAlmuerzoCompleto: true,
          date: now,
          price: 18.0,
          createdAt: now,
        );

        await repo.createReservation(res);

        final userReservations = await repo.getUserReservations(
          'demo-user-123',
        );
        final saved = userReservations.firstWhere(
          (r) => r.id == 'res-combo-test-2',
        );

        expect(saved.platoPrincipal, equals('Pique Macho Especial'));
        expect(saved.sopaNombre, equals('Chairo Paceño'));
        expect(saved.isAlmuerzoCompleto, isTrue);
        expect(
          saved.dishName,
          equals('Almuerzo Completo (Pique Macho Especial + Chairo Paceño)'),
        );
      },
    );
  });

  group('2. Interfaz de EmployeeScreen con Almuerzo Completo y Sopa Boliviana', () {
    testWidgets(
      'EmployeeScreen muestra selector de sopa boliviana y banner de Almuerzo Completo',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final today = DateTime.now();
        final monday = today.subtract(Duration(days: today.weekday - 1));

        final testMenu = [
          MenuSemanalItem(
            id: 1,
            fecha: today,
            diaSemana: 'Hoy',
            platoCatalogoId: 1,
            platoNombre: 'Silpancho Cochabambino',
            platoDescripcion: 'Carne apanada tierna con arroz y papas',
            platoRegion: 'Cochabamba',
            tipoPlato: 'Segundo',
            estado: 'publicado',
            imagenUrl: 'assets/images/01_silpancho.jpg',
          ),
        ];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith(
                () => _StaticAuthNotifier(SupabaseAuthRepository.demoEmpleado),
              ),
              publishedWeeklyMenuProvider.overrideWith((ref) async => testMenu),
              selectedWeekProvider.overrideWith(
                () => _StaticWeekNotifier(monday),
              ),
            ],
            child: const MaterialApp(home: EmployeeScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Verificar que se renderizan los tres componentes del combo
        expect(find.text('Sopa del día incluida:'), findsOneWidget);
        expect(find.text('1. Entrada / Ensalada:'), findsOneWidget);

        // Verificar que el combo Almuerzo Completo se muestra
        expect(
          find.text('🍱 Almuerzo Completo (Combo del Día)'),
          findsOneWidget,
        );
        expect(
          find.text('Silpancho Cochabambino + Sopa de Maní Tradicional'),
          findsWidgets,
        );

        // Verificar que en el desglose de costo se indica el combo Almuerzo Completo
        expect(
          find.textContaining(
            'Almuerzo Completo: Ensalada (Ensalada Fresca del Día) + Sopa del día (Sopa de Maní Tradicional)',
          ),
          findsOneWidget,
        );

        // Seleccionar otra sopa boliviana (ej. Chairo Paceño)
        final soupDropdownFinder = find.byKey(
          ValueKey('soup_selector_${today.year}_${today.month}_${today.day}'),
        );
        expect(soupDropdownFinder, findsOneWidget);
        await tester.tap(soupDropdownFinder);
        await tester.pumpAndSettle();

        final chairoOption = find.text('Chairo Paceño').last;
        await tester.tap(chairoOption);
        await tester.pumpAndSettle();

        // Verificar actualización del combo
        expect(
          find.text('Silpancho Cochabambino + Chairo Paceño'),
          findsWidgets,
        );
      },
    );
  });
}
