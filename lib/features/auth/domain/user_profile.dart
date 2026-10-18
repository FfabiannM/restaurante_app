class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String role; // 'empleado', 'admin', 'cocina'
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

  bool get isEmpleado => role.toLowerCase() == 'empleado';
  bool get isAdmin =>
      role.toLowerCase() == 'admin' || role.toLowerCase() == 'institucion';
  bool get isCocina =>
      role.toLowerCase() == 'cocina' || role.toLowerCase() == 'encargado';

  // Compatibilidad hacia atrás
  bool get isEncargado => isCocina;
  bool get isInstitucion => isAdmin;

  String get roleDisplay {
    if (isCocina) {
      return 'Empleado de Cocina';
    } else if (isAdmin) {
      return 'Administrador Institucional';
    } else {
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
    // Si viene de public.usuarios (db.md): tiene nombres, apellidos y rol
    String name = json['full_name'] ?? json['fullName'] ?? '';
    if (name.isEmpty && (json['nombres'] != null || json['apellidos'] != null)) {
      name = '${json['nombres'] ?? ''} ${json['apellidos'] ?? ''}'.trim();
    }
    if (name.isEmpty) {
      name = 'Usuario';
    }

    final rawRole = (json['rol'] ?? json['role'] ?? 'empleado')
        .toString()
        .toLowerCase();
    final normalizedRole = rawRole.contains('admin') || rawRole.contains('institucion')
        ? 'admin'
        : rawRole.contains('cocina') || rawRole.contains('encargado')
            ? 'cocina'
            : 'empleado';

    return UserProfile(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      fullName: name,
      role: normalizedRole,
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
      'rol': role.toUpperCase(),
      'department': department,
      'is_pensioner': isPensioner,
      'monthly_expense': monthlyExpense,
    };
  }
}
