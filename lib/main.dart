import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurante_app/core/config/supabase_config.dart';
import 'package:restaurante_app/core/layout/admin_shell.dart';
import 'package:restaurante_app/core/layout/kitchen_shell.dart';
import 'package:restaurante_app/core/layout/main_layout.dart';
import 'package:restaurante_app/core/theme/app_theme.dart';
import 'package:restaurante_app/features/auth/presentation/login_screen.dart';
import 'package:restaurante_app/features/auth/presentation/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización tolerante a fallos de Supabase
  await SupabaseConfig.initialize();

  runApp(const ProviderScope(child: RestauranteApp()));
}

class RestauranteApp extends ConsumerWidget {
  const RestauranteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);

    Widget homeScreen;
    if (user == null) {
      homeScreen = const LoginScreen();
    } else if (user.isAdmin) {
      homeScreen = const AdminShell();
    } else if (user.isCocina) {
      homeScreen = const KitchenShell();
    } else {
      homeScreen = const MainLayout();
    }

    return MaterialApp(
      title: 'Restaurante App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: homeScreen,
    );
  }
}
