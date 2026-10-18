class PlatoCatalogo {
  final int id;
  final String nombre;
  final String descripcion;
  final String categoria;
  final String region;
  final double precio;
  final String imagenUrl;
  final bool activo;

  const PlatoCatalogo({
    required this.id,
    required this.nombre,
    required this.descripcion,
    this.categoria = 'Segundo',
    this.region = 'Bolivia',
    this.precio = 18.0,
    this.imagenUrl = 'assets/silpancho.png',
    this.activo = true,
  });

  factory PlatoCatalogo.fromJson(Map<String, dynamic> json) {
    return PlatoCatalogo(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      nombre: json['nombre']?.toString() ?? '',
      descripcion: json['descripcion']?.toString() ?? '',
      categoria: json['categoria']?.toString() ?? 'Segundo',
      region: json['region']?.toString() ?? 'Bolivia',
      precio: (json['precio'] as num?)?.toDouble() ?? 18.0,
      imagenUrl: json['imagen_url']?.toString() ?? 'assets/silpancho.png',
      activo: json['activo'] == true || json['activo'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'categoria': categoria,
      'region': region,
      'precio': precio,
      'imagen_url': imagenUrl,
      'activo': activo,
    };
  }

  PlatoCatalogo copyWith({
    int? id,
    String? nombre,
    String? descripcion,
    String? categoria,
    String? region,
    double? precio,
    String? imagenUrl,
    bool? activo,
  }) {
    return PlatoCatalogo(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      categoria: categoria ?? this.categoria,
      region: region ?? this.region,
      precio: precio ?? this.precio,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      activo: activo ?? this.activo,
    );
  }
}

class MenuSemanalItem {
  final int id;
  final DateTime fecha;
  final String diaSemana;
  final int platoCatalogoId;
  final String platoNombre;
  final String platoDescripcion;
  final String platoRegion;
  final String tipoPlato;
  final String estado; // 'borrador', 'publicado'

  const MenuSemanalItem({
    required this.id,
    required this.fecha,
    required this.diaSemana,
    required this.platoCatalogoId,
    required this.platoNombre,
    this.platoDescripcion = '',
    this.platoRegion = 'Bolivia',
    this.tipoPlato = 'Segundo',
    this.estado = 'borrador',
  });

  bool get isPublicado => estado.toLowerCase() == 'publicado';
  bool get isBorrador => estado.toLowerCase() == 'borrador';

  factory MenuSemanalItem.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    if (json['fecha'] is DateTime) {
      parsedDate = json['fecha'] as DateTime;
    } else if (json['fecha'] != null) {
      parsedDate = DateTime.tryParse(json['fecha'].toString()) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    String platoNom = json['plato_nombre']?.toString() ?? '';
    String platoDesc = json['plato_descripcion']?.toString() ?? '';
    String platoReg = json['plato_region']?.toString() ?? 'Bolivia';

    if (json['platos_catalogo'] is Map) {
      final pMap = json['platos_catalogo'] as Map;
      if (platoNom.isEmpty) platoNom = pMap['nombre']?.toString() ?? '';
      if (platoDesc.isEmpty) platoDesc = pMap['descripcion']?.toString() ?? '';
      if (platoReg == 'Bolivia') platoReg = pMap['region']?.toString() ?? 'Bolivia';
    }

    return MenuSemanalItem(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      fecha: parsedDate,
      diaSemana: json['dia_semana']?.toString() ?? 'Lunes',
      platoCatalogoId: json['plato_catalogo_id'] is int
          ? json['plato_catalogo_id'] as int
          : int.tryParse(json['plato_catalogo_id']?.toString() ?? '0') ?? 0,
      platoNombre: platoNom.isNotEmpty ? platoNom : 'Plato Boliviano',
      platoDescripcion: platoDesc,
      platoRegion: platoReg,
      tipoPlato: json['tipo_plato']?.toString() ?? 'Segundo',
      estado: json['estado']?.toString() ?? 'borrador',
    );
  }

  Map<String, dynamic> toJson() {
    final dateStr =
        "${fecha.year.toString().padLeft(4, '0')}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";
    return {
      'id': id,
      'fecha': dateStr,
      'dia_semana': diaSemana,
      'plato_catalogo_id': platoCatalogoId,
      'plato_nombre': platoNombre,
      'tipo_plato': tipoPlato,
      'estado': estado,
    };
  }

  MenuSemanalItem copyWith({
    int? id,
    DateTime? fecha,
    String? diaSemana,
    int? platoCatalogoId,
    String? platoNombre,
    String? platoDescripcion,
    String? platoRegion,
    String? tipoPlato,
    String? estado,
  }) {
    return MenuSemanalItem(
      id: id ?? this.id,
      fecha: fecha ?? this.fecha,
      diaSemana: diaSemana ?? this.diaSemana,
      platoCatalogoId: platoCatalogoId ?? this.platoCatalogoId,
      platoNombre: platoNombre ?? this.platoNombre,
      platoDescripcion: platoDescripcion ?? this.platoDescripcion,
      platoRegion: platoRegion ?? this.platoRegion,
      tipoPlato: tipoPlato ?? this.tipoPlato,
      estado: estado ?? this.estado,
    );
  }
}
