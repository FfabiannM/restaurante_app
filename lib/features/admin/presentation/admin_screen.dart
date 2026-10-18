import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurante_app/features/admin/domain/admin_employee_entity.dart';
import 'package:restaurante_app/features/admin/presentation/institucion_screen.dart';
import 'package:restaurante_app/features/admin/presentation/providers/admin_providers.dart';
import 'package:restaurante_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:restaurante_app/features/familiares/domain/familiar_entity.dart';
import 'package:restaurante_app/features/familiares/domain/family_policy.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminEmployeesProvider);
    final currentFilter = ref.watch(membershipFilterProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Panel Administrador',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            Text(
              'Gestión de personal, familiares y membresías',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Actualizar lista',
            onPressed: () =>
                ref.read(adminEmployeesProvider.notifier).loadEmployees(),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white),
            tooltip: 'Limpiar Datos de Prueba',
            onPressed: () => _confirmClearTestData(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Cerrar Sesión',
            onPressed: () => ref.read(authProvider.notifier).signOut(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(
              icon: Icon(Icons.badge_outlined),
              text: 'Empleados & Familiares',
            ),
            Tab(icon: Icon(Icons.card_membership_outlined), text: 'Membresías'),
            Tab(icon: Icon(Icons.analytics_outlined), text: 'Auditoría'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEmployeesTab(state),
          _buildMembershipsTab(state, currentFilter),
          const InstitucionScreen(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => _openEmployeeFormModal(context),
              icon: const Icon(Icons.person_add),
              label: const Text('Registrar Empleado'),
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  // ===========================================================================
  // TAB 1: GESTIÓN DE EMPLEADOS Y FAMILIARES
  // ===========================================================================
  Widget _buildEmployeesTab(AdminEmployeesState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    final employees = state.employees.where((e) {
      final q = _searchQuery.toLowerCase();
      return e.fullName.toLowerCase().contains(q) ||
          e.ci.contains(q) ||
          e.departamento.toLowerCase().contains(q);
    }).toList();

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(adminEmployeesProvider.notifier).loadEmployees(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Resumen de estadísticas
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetricItem(
                    'Empleados',
                    '${state.totalEmployees}',
                    Icons.people,
                    Colors.blue,
                  ),
                  _buildMetricItem(
                    'Familiares',
                    '${state.totalFamilyCount}',
                    Icons.family_restroom,
                    Colors.teal,
                  ),
                  _buildMetricItem(
                    'Plan Mensual',
                    '${state.monthlyPlanCount}',
                    Icons.star,
                    Colors.amber.shade800,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Buscador
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: const InputDecoration(
                  hintText: 'Buscar por nombre, CI o departamento...',
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 12),

            if (employees.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'No se encontraron empleados registrados.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: employees.length,
                itemBuilder: (context, index) {
                  final emp = employees[index];
                  return _buildEmployeeCard(emp);
                },
              ),
            const SizedBox(height: 70), // Espacio para FAB
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(AdminEmployee emp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.15),
          child: Text(
            emp.nombres.isNotEmpty ? emp.nombres[0].toUpperCase() : 'E',
            style: const TextStyle(
              color: Color(0xFF2563EB),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          emp.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CI: ${emp.ci} • ${emp.departamento}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: emp.hasMonthlyPlan
                        ? Colors.green.withValues(alpha: 0.15)
                        : Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    emp.hasMonthlyPlan
                        ? 'Plan Mensual (Bs. 15)'
                        : 'Diario (Bs. 18)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: emp.hasMonthlyPlan
                          ? Colors.green.shade800
                          : Colors.orange.shade900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${emp.familiares.length}/3 familiares',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(
                Icons.edit_outlined,
                size: 20,
                color: Colors.blue,
              ),
              tooltip: 'Editar empleado',
              onPressed: () => _openEmployeeFormModal(context, employee: emp),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                size: 20,
                color: Colors.red,
              ),
              tooltip: 'Eliminar empleado',
              onPressed: () => _confirmDeleteEmployee(context, emp),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Familiares Vinculados (Máx. 3)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (emp.familiares.length <
                        FamilyPolicy.maxFamilyMembersPerEmployee)
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Agregar Familiar'),
                        onPressed: () => _openAddFamiliarModal(context, emp.id),
                      )
                    else
                      const Text(
                        'Cupo máximo lleno',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                  ],
                ),
                if (emp.familiares.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'No tiene familiares registrados.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  )
                else
                  ...emp.familiares.map((fam) {
                    return Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 14,
                            backgroundColor: Color(0xFFDBEAFE),
                            child: Icon(
                              Icons.person,
                              size: 16,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fam.fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                  ),
                                ),
                                Text(
                                  'Parentesco: ${fam.parentesco} • CI: ${fam.ci}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Colors.redAccent,
                            ),
                            tooltip: 'Eliminar familiar',
                            onPressed: () =>
                                _confirmDeleteFamiliar(context, emp.id, fam),
                          ),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  // ===========================================================================
  // TAB 2: CONTROL DE MEMBRESÍAS
  // ===========================================================================
  Widget _buildMembershipsTab(
    AdminEmployeesState state,
    MembershipFilter currentFilter,
  ) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    final filtered = ref.watch(filteredAdminEmployeesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Banner de Tarifas del Sistema
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.sell_outlined, color: Color(0xFF2563EB)),
                    SizedBox(width: 8),
                    Text(
                      'Tarifas Fijas del Comedor Institucional',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Column(
                          children: [
                            Text(
                              'Bs. 15.00',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              'Plan Mensual',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Suscripción activa',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Column(
                          children: [
                            Text(
                              'Bs. 18.00',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange,
                              ),
                            ),
                            Text(
                              'Sin Plan / Diario',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Comensal particular',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Filtro Rápido de Membresías
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.filter_list, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                const Text(
                  'Filtrar:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: Text('Todos (${state.totalEmployees})'),
                          selected: currentFilter == MembershipFilter.todos,
                          onSelected: (val) {
                            if (val) {
                              ref
                                      .read(membershipFilterProvider.notifier)
                                      .state =
                                  MembershipFilter.todos;
                            }
                          },
                        ),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          label: Text(
                            'Plan Mensual [15 Bs] (${state.monthlyPlanCount})',
                          ),
                          selected: currentFilter == MembershipFilter.mensual,
                          selectedColor: Colors.green.shade100,
                          onSelected: (val) {
                            if (val) {
                              ref
                                      .read(membershipFilterProvider.notifier)
                                      .state =
                                  MembershipFilter.mensual;
                            }
                          },
                        ),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          label: Text(
                            'Sin Plan [18 Bs] (${state.dailyPlanCount})',
                          ),
                          selected: currentFilter == MembershipFilter.diario,
                          selectedColor: Colors.orange.shade100,
                          onSelected: (val) {
                            if (val) {
                              ref
                                      .read(membershipFilterProvider.notifier)
                                      .state =
                                  MembershipFilter.diario;
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Lista de Comensales con switch de membresía
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final emp = filtered[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: emp.hasMonthlyPlan
                        ? Colors.green.shade200
                        : Colors.orange.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: emp.hasMonthlyPlan
                          ? Colors.green.withValues(alpha: 0.15)
                          : Colors.orange.withValues(alpha: 0.15),
                      child: Icon(
                        emp.hasMonthlyPlan ? Icons.star : Icons.person_outline,
                        color: emp.hasMonthlyPlan
                            ? Colors.green
                            : Colors.orange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            emp.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                            ),
                          ),
                          Text(
                            'CI: ${emp.ci} • ${emp.departamento}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            'Tarifa aplicable: Bs. ${emp.tariffPrice.toStringAsFixed(2)} por plato',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: emp.hasMonthlyPlan
                                  ? Colors.green.shade800
                                  : Colors.deepOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Switch(
                          value: emp.hasMonthlyPlan,
                          activeThumbColor: Colors.green,
                          onChanged: (val) {
                            ref
                                .read(adminEmployeesProvider.notifier)
                                .toggleMonthlyPlan(emp.id, val);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  val
                                      ? '${emp.fullName} suscrito a Plan Mensual (Tarifa: 15 Bs).'
                                      : '${emp.fullName} en modalidad diaria (Tarifa: 18 Bs).',
                                ),
                                backgroundColor: val
                                    ? Colors.green
                                    : Colors.orange.shade800,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                        Text(
                          emp.hasMonthlyPlan ? 'Plan 15 Bs' : 'Diario 18 Bs',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: emp.hasMonthlyPlan
                                ? Colors.green
                                : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // MODALES & CONFIRMACIONES
  // ===========================================================================

  Widget _buildMetricItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          radius: 18,
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  void _openEmployeeFormModal(BuildContext context, {AdminEmployee? employee}) {
    final isEditing = employee != null;
    final ciController = TextEditingController(text: employee?.ci ?? '');
    final nombresController = TextEditingController(
      text: employee?.nombres ?? '',
    );
    final apellidosController = TextEditingController(
      text: employee?.apellidos ?? '',
    );
    final emailController = TextEditingController(text: employee?.email ?? '');
    final telefonoController = TextEditingController(
      text: employee?.telefono ?? '',
    );
    final deptController = TextEditingController(
      text: employee?.departamento ?? 'Finanzas y Contabilidad',
    );
    bool hasMonthlyPlan = employee?.hasMonthlyPlan ?? true;

    // Familiares iniciales para nuevo empleado
    final List<Map<String, String>> initialFamiliares = [];
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
              top: 20,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing
                            ? 'Editar Empleado'
                            : 'Registrar Nuevo Empleado',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(modalCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nombresController,
                    decoration: const InputDecoration(
                      labelText: 'Nombres',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: apellidosController,
                    decoration: const InputDecoration(
                      labelText: 'Apellidos',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: ciController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Cédula de Identidad (CI)',
                            prefixIcon: Icon(Icons.credit_card),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: telefonoController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Teléfono',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo Institucional',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: deptController,
                    decoration: const InputDecoration(
                      labelText: 'Departamento / Área',
                      prefixIcon: Icon(Icons.business_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Membresía inicial
                  Material(
                    color: Colors.transparent,
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Activar Plan Mensual (Tarifa Bs. 15)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        'Desmarcar para modalidad diaria particular (Bs. 18)',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: hasMonthlyPlan,
                      activeThumbColor: Colors.green,
                      onChanged: (val) {
                        setModalState(() => hasMonthlyPlan = val);
                      },
                    ),
                  ),

                  // Si es nuevo registro, opción para asociar familiares
                  if (!isEditing) ...[
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Asociar Familiares Iniciales (Opcional, máx. 3)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (initialFamiliares.length < 3)
                          TextButton.icon(
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Agregar'),
                            onPressed: () {
                              setModalState(() {
                                initialFamiliares.add({
                                  'nombres': '',
                                  'apellidos': apellidosController.text,
                                  'ci': '',
                                  'parentesco': 'Hijo/a',
                                });
                              });
                            },
                          ),
                      ],
                    ),
                    ...initialFamiliares.asMap().entries.map((entry) {
                      final i = entry.key;
                      final fam = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      labelText: 'Nombre Familiar #${i + 1}',
                                      isDense: true,
                                    ),
                                    onChanged: (v) => fam['nombres'] = v,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    decoration: InputDecoration(
                                      labelText: 'CI Familiar #${i + 1}',
                                      isDense: true,
                                    ),
                                    onChanged: (v) => fam['ci'] = v,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    setModalState(() {
                                      initialFamiliares.removeAt(i);
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final nombres = nombresController.text.trim();
                              final apellidos = apellidosController.text.trim();
                              final ci = ciController.text.trim();
                              final telefono = telefonoController.text.trim();
                              final email = emailController.text.trim();
                              final dept = deptController.text.trim();

                              // 1. Validación estricta: No permitir guardar si hay campos vacíos
                              if (nombres.isEmpty ||
                                  apellidos.isEmpty ||
                                  ci.isEmpty ||
                                  telefono.isEmpty ||
                                  email.isEmpty ||
                                  dept.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'No se permite guardar al empleado con campos vacíos. Completa todos los campos obligatorios.',
                                    ),
                                    backgroundColor: Colors.red,
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                                return;
                              }

                              // 2. Validación estricta de campos numéricos (solo números)
                              final numericRegex = RegExp(r'^[0-9]+$');
                              if (!numericRegex.hasMatch(ci)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'El campo Cédula de Identidad (CI) solo permite números.',
                                    ),
                                    backgroundColor: Colors.red,
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                                return;
                              }

                              if (!numericRegex.hasMatch(telefono)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'El campo Teléfono solo permite números.',
                                    ),
                                    backgroundColor: Colors.red,
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                                return;
                              }

                              // 3. Validación de correo institucional
                              final emailRegex = RegExp(
                                r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                              );
                              if (!emailRegex.hasMatch(email)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Por favor ingresa un correo electrónico institucional válido.',
                                    ),
                                    backgroundColor: Colors.red,
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                                return;
                              }

                              // 4. Validación de familiares asociados
                              for (int i = 0; i < initialFamiliares.length; i++) {
                                final fam = initialFamiliares[i];
                                final famNombre = (fam['nombres'] ?? '').trim();
                                final famCi = (fam['ci'] ?? '').trim();
                                if (famNombre.isEmpty || famCi.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'El familiar #${i + 1} tiene campos vacíos. Completa nombre y CI.',
                                      ),
                                      backgroundColor: Colors.red,
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                  return;
                                }
                                if (!numericRegex.hasMatch(famCi)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'El CI del familiar #${i + 1} solo permite números.',
                                      ),
                                      backgroundColor: Colors.red,
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                  return;
                                }
                              }

                              // Procesar guardado en Supabase
                              final messenger = ScaffoldMessenger.of(context);
                              final navigator = Navigator.of(modalCtx);
                              setModalState(() => isSubmitting = true);
                              try {
                                bool ok;
                                if (isEditing) {
                                  ok = await ref
                                      .read(adminEmployeesProvider.notifier)
                                      .updateEmployee(
                                        employee.copyWith(
                                          nombres: nombres,
                                          apellidos: apellidos,
                                          ci: ci,
                                          email: email,
                                          telefono: telefono,
                                          departamento: dept,
                                          hasMonthlyPlan: hasMonthlyPlan,
                                        ),
                                      );
                                } else {
                                  ok = await ref
                                      .read(adminEmployeesProvider.notifier)
                                      .createEmployee(
                                        ci: ci,
                                        nombres: nombres,
                                        apellidos: apellidos,
                                        email: email,
                                        telefono: telefono,
                                        departamento: dept,
                                        hasMonthlyPlan: hasMonthlyPlan,
                                        initialFamiliares: initialFamiliares,
                                      );
                                }

                                if (modalCtx.mounted) {
                                  setModalState(() => isSubmitting = false);
                                }

                                if (ok) {
                                  navigator.pop();
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isEditing
                                            ? 'Empleado actualizado con éxito en Supabase.'
                                            : 'Empleado registrado con éxito en Supabase.',
                                      ),
                                      backgroundColor: Colors.green,
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                } else {
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Error al guardar el empleado en la base de datos Supabase.',
                                      ),
                                      backgroundColor: Colors.red,
                                      duration: Duration(seconds: 3),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (modalCtx.mounted) {
                                  setModalState(() => isSubmitting = false);
                                }
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Error al guardar el empleado en Supabase: $e',
                                    ),
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              isEditing
                                  ? 'Guardar Cambios'
                                  : 'Registrar y Asociar Familiares',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openAddFamiliarModal(BuildContext context, String employeeId) {
    final nombresController = TextEditingController();
    final apellidosController = TextEditingController();
    final ciController = TextEditingController();
    String parentesco = 'Hijo/a';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Asociar Familiar a Cuenta'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombresController,
                  decoration: const InputDecoration(labelText: 'Nombres'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: apellidosController,
                  decoration: const InputDecoration(labelText: 'Apellidos'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: ciController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Cédula de Identidad (CI)',
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: parentesco,
                  decoration: const InputDecoration(labelText: 'Parentesco'),
                  items: const [
                    DropdownMenuItem(value: 'Hijo/a', child: Text('Hijo/a')),
                    DropdownMenuItem(value: 'Cónyuge', child: Text('Cónyuge')),
                    DropdownMenuItem(value: 'Padre', child: Text('Padre')),
                    DropdownMenuItem(value: 'Madre', child: Text('Madre')),
                    DropdownMenuItem(
                      value: 'Hermano/a',
                      child: Text('Hermano/a'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => parentesco = val);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final nombres = nombresController.text.trim();
                final apellidos = apellidosController.text.trim();
                final ci = ciController.text.trim();

                if (nombres.isEmpty || apellidos.isEmpty || ci.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'No se permite asociar un familiar con campos vacíos. Completa Nombres, Apellidos y CI.',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (!RegExp(r'^[0-9]+$').hasMatch(ci)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'El CI del familiar solo permite números.',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.pop(ctx);
                final ok = await ref
                    .read(adminEmployeesProvider.notifier)
                    .addFamiliarToEmployee(
                      employeeId: employeeId,
                      ci: ci,
                      nombres: nombres,
                      apellidos: apellidos,
                      parentesco: parentesco,
                    );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ok
                            ? 'Familiar vinculado exitosamente en Supabase.'
                            : 'No se pudo agregar: Límite máximo de 3 familiares alcanzado.',
                      ),
                      backgroundColor: ok ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Guardar Familiar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteEmployee(
    BuildContext context,
    AdminEmployee emp,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Confirmar Eliminación'),
          ],
        ),
        content: Text(
          '¿Estás seguro de eliminar al empleado "${emp.fullName}" (CI: ${emp.ci}) y a sus familiares asociados del sistema?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sí, Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final ok = await ref
          .read(adminEmployeesProvider.notifier)
          .deleteEmployee(emp.id);
      if (context.mounted && ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Empleado ${emp.fullName} eliminado.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteFamiliar(
    BuildContext context,
    String employeeId,
    Familiar fam,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Familiar'),
        content: Text(
          '¿Deseas desvincular a "${fam.fullName}" (${fam.parentesco}) de los servicios del restaurante?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sí, Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await ref
          .read(adminEmployeesProvider.notifier)
          .deleteFamiliarFromEmployee(employeeId, fam.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Familiar ${fam.fullName} desvinculado con éxito.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _confirmClearTestData(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Limpiar Datos de Prueba'),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que deseas eliminar permanentemente todos los registros y cuentas de prueba correspondientes a "empleado", "administrador" y "cocina" en Supabase?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sí, Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final ok = await ref.read(adminEmployeesProvider.notifier).clearTestData();
      if (context.mounted) {
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Datos de prueba eliminados con éxito de Supabase.'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al limpiar datos de prueba.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
