class Reservation {
  final String id;
  final String userId;
  final String userName;
  final String? dishId;
  final String dishName;
  final DateTime date;
  final String type; // 'diaria' o 'pension'
  final String status; // 'confirmada', 'cancelada', 'entregada'
  final String? notes;
  final DateTime createdAt;

  const Reservation({
    required this.id,
    required this.userId,
    this.userName = 'Usuario',
    this.dishId,
    this.dishName = 'Almuerzo Completo del Día',
    required this.date,
    this.type = 'diaria',
    this.status = 'confirmada',
    this.notes,
    required this.createdAt,
  });

  bool get isConfirmed => status == 'confirmada';
  bool get isCancelled => status == 'cancelada';
  bool get isDelivered => status == 'entregada';

  Reservation copyWith({
    String? id,
    String? userId,
    String? userName,
    String? dishId,
    String? dishName,
    DateTime? date,
    String? type,
    String? status,
    String? notes,
    DateTime? createdAt,
  }) {
    return Reservation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      dishId: dishId ?? this.dishId,
      dishName: dishName ?? this.dishName,
      date: date ?? this.date,
      type: type ?? this.type,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? 'Usuario',
      dishId: json['dish_id']?.toString(),
      dishName: json['dish_name']?.toString() ?? 'Almuerzo Completo',
      date: json['reservation_date'] != null
          ? DateTime.parse(json['reservation_date'] as String)
          : DateTime.now(),
      type: json['type'] ?? 'diaria',
      status: json['status'] ?? 'confirmada',
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'dish_id': dishId,
      'reservation_date':
          "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
      'type': type,
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
