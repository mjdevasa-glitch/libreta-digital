import 'registro_diario.dart';

class DiaClase {
  final DateTime fecha;
  String tema;

  final Map<String, RegistroDiario> registros;

  DiaClase({
    required this.fecha,
    this.tema = '',
    Map<String, RegistroDiario>? registros,
  }) : registros = registros ?? {};
}