class Reservation {
  final String id;
  final String userId;
  final String userName;
  final String? familiarId; // ID del familiar en Supabase (public.familiares)
  final String? beneficiaryName; // Nombre del beneficiario (Empleado o Familiar)
  final String? dishId;
  final String dishName;
  final DateTime date;
  final String type; // 'diaria' o 'pension'
  final String status; // 'confirmada', 'cancelada', 'entregada'
  final double price; // 15.0 para Plan Mensual, 18.0 para Particular
  final String? notes;
  final DateTime createdAt;

  const Reservation({
    required this.id,
    required this.userId,
    this.userName = 'Usuario',
    this.familiarId,
    this.beneficiaryName,
    this.dishId,
    this.dishName = 'Almuerzo Completo del Día',
    required this.date,
    this.type = 'diaria',
    this.status = 'confirmada',
    this.price = 18.0,
    this.notes,
    required this.createdAt,
  });

  bool get isConfirmed => status == 'confirmada';
  bool get isCancelled => status == 'cancelada';
  bool get isDelivered => status == 'entregada';
  bool get isForFamiliar => familiarId != null;

  String get displayName => beneficiaryName ?? userName;

  Reservation copyWith({
    String? id,
    String? userId,
    String? userName,
    String? familiarId,
    String? beneficiaryName,
    String? dishId,
    String? dishName,
    DateTime? date,
    String? type,
    String? status,
    double? price,
    String? notes,
    DateTime? createdAt,
  }) {
    return Reservation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      familiarId: familiarId ?? this.familiarId,
      beneficiaryName: beneficiaryName ?? this.beneficiaryName,
      dishId: dishId ?? this.dishId,
      dishName: dishName ?? this.dishName,
      date: date ?? this.date,
      type: type ?? this.type,
      status: status ?? this.status,
      price: price ?? this.price,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id']?.toString() ?? '',
      userId: (json['empleado_id'] ?? json['user_id'])?.toString() ?? '',
      userName: json['user_name']?.toString() ?? 'Usuario',
      familiarId: json['familiar_id']?.toString(),
      beneficiaryName: json['beneficiary_name']?.toString(),
      dishId: json['dish_id']?.toString(),
      dishName: json['dish_name']?.toString() ?? 'Almuerzo Completo',
      date: json['reservation_date'] != null
          ? DateTime.parse(json['reservation_date'] as String)
          : json['fecha'] != null
              ? DateTime.parse(json['fecha'] as String)
              : DateTime.now(),
      type: json['tipo'] ?? json['type'] ?? 'diaria',
      status: (json['estado'] ?? json['status'])?.toString().toLowerCase() ?? 'confirmada',
      price: (json['precio'] as num?)?.toDouble() ??
          (json['price'] as num?)?.toDouble() ??
          18.0,
      notes: json['notes'] as String? ?? json['notas'] as String?,
      createdAt: json['creado_en'] != null
          ? DateTime.parse(json['creado_en'] as String)
          : json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    final dateStr =
        "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    return {
      'id': id,
      'user_id': userId,
      'empleado_id': userId,
      if (familiarId != null) 'familiar_id': familiarId,
      'beneficiary_name': beneficiaryName ?? userName,
      'dish_id': dishId,
      'dish_name': dishName,
      'reservation_date': dateStr,
      'fecha': dateStr,
      'type': type,
      'status': status,
      'precio': price,
      'price': price,
      'notes': notes,
      'notas': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
