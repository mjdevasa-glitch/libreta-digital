class RegistroDiario {
  final String alumnoDocumento;
  final DateTime fecha;
  String tema;

  int actitud;
  bool trabajo;
  String observaciones;

  RegistroDiario({
    required this.alumnoDocumento,
    required this.fecha,
    required this.tema,
    this.actitud = 0,
    this.trabajo = false,
    this.observaciones = '',
  });
}