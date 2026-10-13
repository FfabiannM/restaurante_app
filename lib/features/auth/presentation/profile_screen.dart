import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurante_app/core/config/supabase_config.dart';
import 'package:restaurante_app/features/admin/presentation/encargado_screen.dart';
import 'package:restaurante_app/features/admin/presentation/institucion_screen.dart';
import 'package:restaurante_app/features/auth/data/supabase_auth_repository.dart';
import 'package:restaurante_app/features/auth/domain/user_profile.dart';
import 'package:restaurante_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:restaurante_app/features/pension/presentation/pension_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _isSignUp = false;
  String _selectedRole = 'empleado';
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Perfil & Autenticación',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: user == null ? _buildAuthForm() : _buildUserProfile(user),
    );
  }

  Widget _buildAuthForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Tarjeta de Formulario
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isSignUp ? 'Crear Cuenta' : 'Iniciar Sesión',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _isSignUp = !_isSignUp),
                      child: Text(
                        _isSignUp ? 'Tengo cuenta' : 'Registrarse',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_isSignUp) ...[
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre Completo',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Rol en la Institución',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'empleado',
                        child: Text('Empleado'),
                      ),
                      DropdownMenuItem(
                        value: 'encargado',
                        child: Text('Encargado de Restaurante'),
                      ),
                      DropdownMenuItem(
                        value: 'institucion',
                        child: Text('Administrador Institucional'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedRole = val);
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo Institucional',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitAuth,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _isSignUp
                                ? 'Completar Registro'
                                : 'Ingresar al Sistema',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Acceso Rápido Modo Demostración
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.touch_app_outlined, color: Color(0xFF2563EB)),
                    SizedBox(width: 8),
                    Text(
                      'Acceso Rápido de Prueba (Demo)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Prueba la experiencia de cada rol con un solo clic:',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                _buildDemoButton(
                  '1. Entrar como Empleado',
                  'Juan Pérez (Reservas y pensión)',
                  Icons.person,
                  Colors.blue,
                  SupabaseAuthRepository.demoEmpleado,
                ),
                const SizedBox(height: 8),
                _buildDemoButton(
                  '2. Entrar como Encargado',
                  'Chef Carlos (Cocina y despacho)',
                  Icons.restaurant_menu,
                  Colors.orange,
                  SupabaseAuthRepository.demoEncargado,
                ),
                const SizedBox(height: 8),
                _buildDemoButton(
                  '3. Entrar como Institución',
                  'Lic. Mariana Gómez (Métricas)',
                  Icons.business,
                  Colors.purple,
                  SupabaseAuthRepository.demoInstitucion,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    UserProfile demoUser,
  ) {
    return InkWell(
      onTap: () {
        ref.read(authProvider.notifier).setDemoUser(demoUser);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sesión iniciada como ${demoUser.roleDisplay}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.2),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfile(UserProfile user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Tarjeta Principal de Perfil
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 38,
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  child: Text(
                    user.fullName.isNotEmpty
                        ? user.fullName.substring(0, 1).toUpperCase()
                        : 'U',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user.fullName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user.email,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: user.isEncargado
                        ? Colors.orange.withValues(alpha: 0.15)
                        : user.isInstitucion
                            ? Colors.purple.withValues(alpha: 0.15)
                            : Colors.blue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    user.roleDisplay,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: user.isEncargado
                          ? Colors.orange.shade800
                          : user.isInstitucion
                              ? Colors.purple.shade800
                              : Colors.blue.shade800,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildUserStat(
                      'Departamento',
                      user.department,
                      Icons.business_center,
                    ),
                    _buildUserStat(
                      'Consumo Mes',
                      'Bs. ${user.monthlyExpense.toStringAsFixed(0)}',
                      Icons.receipt,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Módulos Especializados según el Rol
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gestión y Servicios',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // Suscripción a Pensión
                _buildActionTile(
                  title: 'Modalidad Mensual (Pensión)',
                  subtitle: 'Almuerzos fijos de lunes a viernes con descuento',
                  icon: Icons.calendar_month,
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PensionScreen(),
                      ),
                    );
                  },
                ),

                const Divider(),

                // Panel Encargado de Cocina
                _buildActionTile(
                  title: 'Panel de Cocina & Despacho',
                  subtitle: user.isEncargado
                      ? 'Administra la entrega de platos de hoy'
                      : 'Ver vista previa del encargado de cocina',
                  icon: Icons.soup_kitchen,
                  color: Colors.orange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EncargadoScreen(),
                      ),
                    );
                  },
                ),

                const Divider(),

                // Panel Institucional
                _buildActionTile(
                  title: 'Métricas Institucionales',
                  subtitle: user.isInstitucion
                      ? 'Reportes de subsidio y nómina'
                      : 'Ver métricas de la institución',
                  icon: Icons.bar_chart,
                  color: Colors.purple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InstitucionScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Cambiador rápido de rol demo
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Simular otro rol:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => ref
                            .read(authProvider.notifier)
                            .setDemoUser(SupabaseAuthRepository.demoEmpleado),
                        child: const Text('Empleado', style: TextStyle(fontSize: 11)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => ref
                            .read(authProvider.notifier)
                            .setDemoUser(SupabaseAuthRepository.demoEncargado),
                        child: const Text('Cocina', style: TextStyle(fontSize: 11)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => ref
                            .read(authProvider.notifier)
                            .setDemoUser(SupabaseAuthRepository.demoInstitucion),
                        child: const Text('Admin', style: TextStyle(fontSize: 11)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Conexión Supabase:',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      SupabaseConfig.isInitialized
                          ? 'En Línea (Cloud)'
                          : 'Modo Local / Demo Activo',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: SupabaseConfig.isInitialized
                            ? Colors.green
                            : Colors.orange.shade800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Botón Cerrar Sesión
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ref.read(authProvider.notifier).signOut();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar Sesión'),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildUserStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Future<void> _submitAuth() async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor llena todos los campos.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    bool ok;
    if (_isSignUp) {
      final name = _nameController.text.trim().isEmpty
          ? 'Empleado'
          : _nameController.text.trim();
      ok = await ref.read(authProvider.notifier).signUp(
            email: email,
            password: pass,
            fullName: name,
            role: _selectedRole,
          );
    } else {
      ok = await ref.read(authProvider.notifier).signIn(email, pass);
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al autenticar. Verifica tus credenciales.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
