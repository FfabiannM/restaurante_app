class Familiar {
  final String id;
  final String empleadoId;
  final String ci;
  final String nombres;
  final String apellidos;
  final String parentesco; // 'Hijo', 'Hija', 'Cónyuge', 'Padre', 'Madre', 'Hermano/a', etc.
  final bool activo;
  final DateTime? creadoEn;

  const Familiar({
    required this.id,
    required this.empleadoId,
    required this.ci,
    required this.nombres,
    required this.apellidos,
    required this.parentesco,
    this.activo = true,
    this.creadoEn,
  });

  String get fullName => '$nombres $apellidos'.trim();

  String get displayName => '$fullName ($parentesco)';

  factory Familiar.fromJson(Map<String, dynamic> json) {
    return Familiar(
      id: json['id']?.toString() ?? '',
      empleadoId: json['empleado_id']?.toString() ?? '',
      ci: json['ci']?.toString() ?? '',
      nombres: json['nombres']?.toString() ?? '',
      apellidos: json['apellidos']?.toString() ?? '',
      parentesco: json['parentesco']?.toString() ?? 'Familiar',
      activo: json['activo'] == true || json['activo'] == 1,
      creadoEn: json['creado_en'] != null
          ? DateTime.tryParse(json['creado_en'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'empleado_id': empleadoId,
      'ci': ci,
      'nombres': nombres,
      'apellidos': apellidos,
      'parentesco': parentesco,
      'activo': activo,
      if (creadoEn != null) 'creado_en': creadoEn!.toIso8601String(),
    };
  }

  Familiar copyWith({
    String? id,
    String? empleadoId,
    String? ci,
    String? nombres,
    String? apellidos,
    String? parentesco,
    bool? activo,
    DateTime? creadoEn,
  }) {
    return Familiar(
      id: id ?? this.id,
      empleadoId: empleadoId ?? this.empleadoId,
      ci: ci ?? this.ci,
      nombres: nombres ?? this.nombres,
      apellidos: apellidos ?? this.apellidos,
      parentesco: parentesco ?? this.parentesco,
      activo: activo ?? this.activo,
      creadoEn: creadoEn ?? this.creadoEn,
    );
  }
}
