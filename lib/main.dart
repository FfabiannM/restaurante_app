import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurante_app/core/config/supabase_config.dart';
import 'package:restaurante_app/core/layout/main_layout.dart';
import 'package:restaurante_app/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización tolerante a fallos de Supabase
  await SupabaseConfig.initialize();

  runApp(
    const ProviderScope(
      child: RestauranteApp(),
    ),
  );
}

class RestauranteApp extends StatelessWidget {
  const RestauranteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Restaurante App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainLayout(),
    );
  }
}
