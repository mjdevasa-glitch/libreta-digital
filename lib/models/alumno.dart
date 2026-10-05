class Alumno {
  final String nombre;
  final String grupo;
  final String documento;
  final String? foto;

  Alumno({
    required this.nombre,
    required this.grupo,
    required this.documento,
    this.foto,
  });
}