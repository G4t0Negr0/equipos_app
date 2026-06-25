class Equipo {
  final String nombre;
  final String codigo;
  final String? marca;
  final String? numeroSerie;
  final String? rangoCapacidad;
  final String? fechaCalibracion;
  final String? fechaProximaCalibracion;
  final String? calibradoPor;
  final String? responsable;
  final String? estado;

  Equipo({
    required this.nombre,
    required this.codigo,
    this.marca,
    this.numeroSerie,
    this.rangoCapacidad,
    this.fechaCalibracion,
    this.fechaProximaCalibracion,
    this.calibradoPor,
    this.responsable,
    this.estado,
  });

  factory Equipo.fromJson(Map<String, dynamic> json) {
    return Equipo(
      nombre: json['nombre'] ?? '',
      codigo: json['codigo'] ?? '',
      marca: json['marca'],
      numeroSerie: json['numero_serie'],
      rangoCapacidad: json['rango_capacidad'],
      fechaCalibracion: json['fecha_calibracion'],
      fechaProximaCalibracion: json['fecha_proxima_calibracion'],
      calibradoPor: json['calibrado_por'],
      responsable: json['responsable'],
      estado: json['estado'],
    );
  }
}