class MonthlyPensionSubscription {
  final String id;
  final String userId;
  final int year;
  final int month;
  final int totalDays;
  final double pricePerDay;
  final double totalPrice;
  final String status; // 	'Pensionado', 'Regular'
  final DateTime createdAt;

  const MonthlyPensionSubscription({
    required this.id,
    required this.userId,
    required this.year,
    required this.month,
    required this.totalDays,
    this.pricePerDay = 15.0,
    required this.totalPrice,
    this.status = 'Pensionado',
    required this.createdAt,
  });

  bool get isActive => status == 'Pensionado';

  /// Regla de negocio: Bloquea cambio o cancelación una vez el mes ha iniciado.
  /// Si el año y mes seleccionado ya inició (o pasó), no se puede cancelar ni suscribir.
  bool canModifyOrCancel(DateTime currentTime) {
    final firstDayOfMonth = DateTime(year, month, 1);
    final today = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day,
    );
    return today.isBefore(firstDayOfMonth);
  }

  factory MonthlyPensionSubscription.fromJson(Map<String, dynamic> json) {
    return MonthlyPensionSubscription(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      year: (json['year'] as num).toInt(),
      month: (json['month'] as num).toInt(),
      totalDays: (json['total_days'] as num).toInt(),
      pricePerDay: (json['price_per_day'] as num?)?.toDouble() ?? 15.0,
      totalPrice: (json['total_price'] as num).toDouble(),
      status: json['status'] ?? 'activa',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'year': year,
      'month': month,
      'total_days': totalDays,
      'total_price': totalPrice,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
