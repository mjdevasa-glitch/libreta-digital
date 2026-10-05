import 'alumno.dart';

class Grupo {
  String nombre;
  final List<Alumno> alumnos;
  bool seleccionado;
  bool esMixto;

  Grupo({
    required this.nombre,
    this.alumnos = const [],
    this.seleccionado = true,
    this.esMixto = false,
  });
}