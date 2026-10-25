import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurante_app/core/utils/date_utils.dart';
import 'package:restaurante_app/features/pension/data/supabase_pension_repository.dart';
import 'package:restaurante_app/features/pension/domain/pension_entity.dart';
import 'package:restaurante_app/features/reservas/domain/holiday_entity.dart';
import 'package:restaurante_app/features/reservas/presentation/providers/reservation_providers.dart';

class PensionScreen extends ConsumerStatefulWidget {
  const PensionScreen({super.key});

  @override
  ConsumerState<PensionScreen> createState() => _PensionScreenState();
}

class _PensionScreenState extends ConsumerState<PensionScreen> {
  final SupabasePensionRepository _pensionRepo = SupabasePensionRepository();
  final String _userId = 'demo-user-123';

  MonthlyPensionSubscription? _currentMonthSub;
  MonthlyPensionSubscription? _nextMonthSub;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    setState(() => _isLoading = true);
    final now = DateTime.now();
    final curSub = await _pensionRepo.getSubscription(
      _userId,
      now.year,
      now.month,
    );

    final nextMonthDate = DateTime(now.year, now.month + 1, 1);
    final nxtSub = await _pensionRepo.getSubscription(
      _userId,
      nextMonthDate.year,
      nextMonthDate.month,
    );

    if (mounted) {
      setState(() {
        _currentMonthSub = curSub;
        _nextMonthSub = nxtSub;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(currentTimeProvider);
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    final holidaysAsync = ref.watch(holidaysProvider);
    final holidays = holidaysAsync.value ?? Holiday.defaultHolidays;

    final nextMonthWorkDays = AppDateUtils.countBusinessDays(
      nextMonth.year,
      nextMonth.month,
      holidays: holidays.map((h) => h.date).toList(),
    );
    final nextMonthTotal = nextMonthWorkDays * 14.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Pensión Mensual',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tarjeta Informativa de Beneficios
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.stars, color: Colors.amber, size: 28),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Modalidad Pensionado',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Asegura tus almuerzos institucionales de lunes a viernes con un mejor precio para usted y su familia.',
                          style: TextStyle(color: Colors.white, fontSize: 13.5),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildBenefitBadge('Bs. 15 / día', 'Descuento'),
                            const SizedBox(width: 12),
                            // _buildBenefitBadge(
                            //   'Garantizado',
                            //   '',
                            // ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Estado Mes Actual
                  _buildMonthStatusCard(
                    title:
                        'Mes Actual: ${AppDateUtils.getMonthName(now.month)} ${now.year}',
                    isCurrentMonth: true,
                    subscription: _currentMonthSub,
                    workDays: _currentMonthSub?.totalDays ?? 22,
                    totalPrice: _currentMonthSub?.totalPrice ?? (22 * 14.0),
                    onAction: null, // Bloqueado por regla de negocio
                  ),

                  const SizedBox(height: 16),

                  // Estado Próximo Mes
                  _buildMonthStatusCard(
                    title:
                        'Próximo Mes: ${AppDateUtils.getMonthName(nextMonth.month)} ${nextMonth.year}',
                    isCurrentMonth: false,
                    subscription: _nextMonthSub,
                    workDays: nextMonthWorkDays,
                    totalPrice: nextMonthTotal,
                    onAction: () => _handleNextMonthSubscription(
                      nextMonth.year,
                      nextMonth.month,
                      holidays,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Explicación de Políticas Institucionales
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.policy_outlined,
                              color: Color(0xFF2563EB),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Reglas y Políticas de Pensión',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildPolicyBullet(
                          'Inicio de Mes:',
                          'Una vez iniciado el mes, la suscripción se bloquea y no es posible cancelarla ni modificarla.',
                        ),
                        _buildPolicyBullet(
                          'Días Incluidos:',
                          'Cubre todos los días laborables de lunes a viernes, descontando feriados institucionales.',
                        ),
                        _buildPolicyBullet(
                          'Descuento:',
                          'El cobro se procesa vía nómina institucional o tesorería de la entidad.',
                        ),
                        _buildPolicyBullet(
                          'Días Mínimos:',
                          'Una vez pensionado usted o sus familiares deben consumir un mínimo de 10 almuerzos en el mes, usted puede elegir qué días.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildBenefitBadge(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthStatusCard({
    required String title,
    required bool isCurrentMonth,
    required MonthlyPensionSubscription? subscription,
    required int workDays,
    required double totalPrice,
    required VoidCallback? onAction,
  }) {
    final hasActiveSub = subscription != null && subscription.isActive;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
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
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1E293B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: hasActiveSub
                      ? Colors.green.withValues(alpha: 0.15)
                      : Colors.grey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  hasActiveSub ? 'Suscrito' : 'No suscrito',
                  style: TextStyle(
                    color: hasActiveSub
                        ? Colors.green.shade800
                        : Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Días laborales calculados:',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              ),
              Text(
                '$workDays días hábiles',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monto mensual total:',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              ),
              Text(
                'Bs. ${totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (isCurrentMonth)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_clock, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mes en curso: Cambios bloqueados por política institucional.',
                      style: TextStyle(
                        color: Colors.deepOrange,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasActiveSub
                      ? Colors.red.shade600
                      : const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                ),
                icon: Icon(
                  hasActiveSub ? Icons.cancel_outlined : Icons.check_circle,
                ),
                label: Text(
                  hasActiveSub
                      ? 'Cancelar Suscripción del Próximo Mes'
                      : 'Suscribirse al Próximo Mes',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPolicyBullet(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12.5, color: Colors.black87),
                children: [
                  TextSpan(
                    text: '$title ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: desc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleNextMonthSubscription(
    int year,
    int month,
    List<Holiday> holidays,
  ) async {
    final hasActiveSub = _nextMonthSub != null && _nextMonthSub!.isActive;

    if (hasActiveSub) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cancelar Pensión'),
          content: Text(
            '¿Deseas cancelar la pensión de ${AppDateUtils.getMonthName(month)} $year?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Sí, Cancelar'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await _pensionRepo.cancelMonthlySubscription(
          _nextMonthSub!.id,
          year,
          month,
          DateTime.now(),
        );
        _loadSubscriptions();
      }
    } else {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirmar Suscripción'),
          content: Text(
            '¿Deseas activar tu pensión para todo el mes de ${AppDateUtils.getMonthName(month)} $year?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Volver'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await _pensionRepo.subscribeMonthly(
          userId: _userId,
          year: year,
          month: month,
          holidays: holidays,
        );
        _loadSubscriptions();
      }
    }
  }
}
