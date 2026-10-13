class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String role; // 'empleado', 'encargado', 'institucion'
  final String department;
  final bool isPensioner;
  final double monthlyExpense;

  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.role = 'empleado',
    this.department = 'Administración Central',
    this.isPensioner = true,
    this.monthlyExpense = 280.0,
  });

  bool get isEmpleado => role == 'empleado';
  bool get isEncargado => role == 'encargado';
  bool get isInstitucion => role == 'institucion';

  String get roleDisplay {
    switch (role) {
      case 'encargado':
        return 'Encargado de Restaurante / Cocina';
      case 'institucion':
        return 'Administrador Institucional';
      case 'empleado':
      default:
        return 'Empleado Institucional';
    }
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? role,
    String? department,
    bool? isPensioner,
    double? monthlyExpense,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      department: department ?? this.department,
      isPensioner: isPensioner ?? this.isPensioner,
      monthlyExpense: monthlyExpense ?? this.monthlyExpense,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? json['fullName'] ?? 'Usuario',
      role: json['role'] ?? 'empleado',
      department: json['department'] ?? 'Administración Central',
      isPensioner: json['is_pensioner'] == true || json['isPensioner'] == true,
      monthlyExpense: (json['monthly_expense'] as num?)?.toDouble() ?? 280.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role,
      'department': department,
      'is_pensioner': isPensioner,
      'monthly_expense': monthlyExpense,
    };
  }
}
