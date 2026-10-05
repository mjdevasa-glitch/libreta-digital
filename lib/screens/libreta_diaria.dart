import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


import '../models/alumno.dart';
import '../models/grupo.dart';
import '../models/registro_diario.dart';
import '../models/dia_clase.dart';

class LibretaDiaria extends StatefulWidget {
  final Grupo grupo;

  const LibretaDiaria({
    super.key,
    required this.grupo,
  });

  @override
  State<LibretaDiaria> createState() => _LibretaDiariaState();
}

class _LibretaDiariaState extends State<LibretaDiaria> {
  // ------------------------------------------------------------
  // ALUMNOS DE PRUEBA
  // Más adelante llegarán desde GestorAlumnos.
  // ------------------------------------------------------------

  List<Alumno> get alumnos => widget.grupo.alumnos;

  // ------------------------------------------------------------
  // REGISTROS DIARIOS
  // Cada alumno tiene su propio registro.
  // ------------------------------------------------------------

  Map<String, RegistroDiario> get registros => diaActual?.registros ?? {};

  final List<DiaClase> dias = [];

  DiaClase? diaActual;

  // Campo del tema.
  final TextEditingController temaController =
      TextEditingController(text: 'Fracciones: suma y resta');

  @override
void initState() {
  super.initState();

  cargarDatos();
}

    void seleccionarDia(DiaClase dia) {
      setState(() {
        diaActual = dia;
        temaController.text = dia.tema;
      });
    }

        Future<void> guardarDatos() async {
      final prefs = await SharedPreferences.getInstance();

      final datos = dias.map((dia) {
        return {
          'fecha': dia.fecha.toIso8601String(),
          'tema': dia.tema,
          'registros': dia.registros.map((documento, registro) {
            return MapEntry(
              documento,
              {
                'actitud': registro.actitud,
                'trabajo': registro.trabajo,
                'observaciones': registro.observaciones,
                'tema': registro.tema,
              },
            );
          }),
        };       
      }).toList();

      await prefs.setString(
        'dias_${widget.grupo.nombre}',
        jsonEncode(datos),
      );
    }
Future<void> cargarDatos() async {
  final prefs = await SharedPreferences.getInstance();

  final texto = prefs.getString(
    'dias_${widget.grupo.nombre}',
  );

if (texto == null) {
  final fecha = DateTime(2026, 9, 30);

  final primerDia = DiaClase(
    fecha: fecha,
    tema: 'Fracciones: suma y resta',
  );

  for (final alumno in alumnos) {
    primerDia.registros[alumno.documento] = RegistroDiario(
      alumnoDocumento: alumno.documento,
      fecha: fecha,
      tema: primerDia.tema,
    );
  }

  dias.add(primerDia);
  diaActual = primerDia;
  temaController.text = primerDia.tema;

  setState(() {});
  return;
}

  final datos = jsonDecode(texto) as List;

  dias.clear();

  for (final dato in datos) {
    final fecha = DateTime.parse(dato['fecha'] as String);

    final dia = DiaClase(
      fecha: fecha,
      tema: dato['tema'] as String,
    );

    final registrosGuardados =
        dato['registros'] as Map<String, dynamic>;

    for (final alumno in alumnos) {
      final registroGuardado =
          registrosGuardados[alumno.documento];

      if (registroGuardado != null) {
        dia.registros[alumno.documento] = RegistroDiario(
          alumnoDocumento: alumno.documento,
          fecha: fecha,
          tema: registroGuardado['tema'] as String,
          actitud: registroGuardado['actitud'] as int,
          trabajo: registroGuardado['trabajo'] as bool,
          observaciones:
              registroGuardado['observaciones'] as String,
        );
      } else {
        dia.registros[alumno.documento] = RegistroDiario(
          alumnoDocumento: alumno.documento,
          fecha: fecha,
          tema: dia.tema,
        );
      }
    }

    dias.add(dia);
  }

  if (dias.isNotEmpty) {
    diaActual = dias.last;
    temaController.text = diaActual!.tema;
  }

  setState(() {});
}

    Future<void> crearNuevoDia() async {
      final fecha = await showDatePicker(
        context: context,
        initialDate: diaActual?.fecha ?? DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime(2035),
      );

      if (fecha == null) {
        return;
      }

      final yaExiste = dias.any(
        (dia) =>
            dia.fecha.year == fecha.year &&
            dia.fecha.month == fecha.month &&
            dia.fecha.day == fecha.day,
      );

      if (yaExiste) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ese día ya existe en la libreta.'),
          ),
        );

        return;
      }

      final nuevoDia = DiaClase(
        fecha: fecha,
        tema: '',
      );

      for (final alumno in alumnos) {
        nuevoDia.registros[alumno.documento] = RegistroDiario(
          alumnoDocumento: alumno.documento,
          fecha: fecha,
          tema: '',
        );
      }

      setState(() {
        dias.add(nuevoDia);
        diaActual = nuevoDia;
        temaController.text = '';
      });
      await guardarDatos();
    }

  @override
  void dispose() {
    temaController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // ACTITUD
  // 0 = sin color
  // 1 = naranja
  // 2 = rosa
  // 3 = rojo
  // 4º toque = vuelve a 0
  // ------------------------------------------------------------

  void cambiarActitud(Alumno alumno) {
    final registro = registros[alumno.documento]!;

    setState(() {
      registro.actitud = (registro.actitud + 1) % 4;
    });

    guardarDatos();

  }

  // ------------------------------------------------------------
  // TRABAJO
  // ------------------------------------------------------------

  void cambiarTrabajo(Alumno alumno) {
    final registro = registros[alumno.documento]!;

    setState(() {
      registro.trabajo = !registro.trabajo;
    });

    guardarDatos();
  }

  // ------------------------------------------------------------
  // COLOR DE ACTITUD
  // ------------------------------------------------------------

  Color? colorActitud(Alumno alumno) {
    final registro = registros[alumno.documento]!;

    switch (registro.actitud) {
      case 1:
        return Colors.orange;

      case 2:
        return Colors.pink.shade300;

      case 3:
        return Colors.red;

      default:
        return null;
    }
  }

  // ------------------------------------------------------------
  // CELDA DE LA TABLA
  // ------------------------------------------------------------

  Widget celda({
    required Widget child,
    double width = 180,
  }) {
    return Container(
      width: width,
      height: 62,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: child,
    );
  }

  // ------------------------------------------------------------
  // INTERFAZ
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'LIBRETA DIARIA',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [

            // --------------------------------------------------
            // CABECERA
            // --------------------------------------------------

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),

              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(10),
              ),

              child: Row(
                children: [

                  const Icon(Icons.calendar_today),

                  const SizedBox(width: 10),



DropdownButton<DiaClase>(
  value: diaActual,
  items: dias.map((dia) {
    return DropdownMenuItem<DiaClase>(
      value: dia,
      child: Text(
        '${dia.fecha.day.toString().padLeft(2, '0')}/'
        '${dia.fecha.month.toString().padLeft(2, '0')}/'
        '${dia.fecha.year}',
      ),
    );
  }).toList(),
  onChanged: (dia) {
    if (dia != null) {
      seleccionarDia(dia);
    }
  },
),



                  const SizedBox(width: 30),

                  const Text(
                    'Tema:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: TextField(
                      controller: temaController,

                      decoration: const InputDecoration(
                        hintText: 'Escribe el tema de hoy',
                        border: InputBorder.none,
                      ),

                      onChanged: (valor) {
                        diaActual?.tema = valor;

                        for (final registro in registros.values) {
                          registro.tema = valor;
                        }
                        guardarDatos();
                      },
                    ),
                  ),
                  const SizedBox(width: 20),

                  FilledButton.icon(
                    onPressed: crearNuevoDia,
                    icon: const Icon(Icons.add),
                    label: const Text('Nuevo día'),
                  ),

                ],
              ),
            ),

            const SizedBox(height: 16),

            // --------------------------------------------------
            // TABLA
            // --------------------------------------------------

            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,

                child: SizedBox(
                  width: 900,

                  child: Column(
                    children: [

                      // CABECERA DE LA TABLA
                      Row(
                        children: [

                          celda(
                            width: 280,
                            child: const Text(
                              'ALUMNO',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          celda(
                            width: 130,
                            child: const Text(
                              'ACTITUD',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          celda(
                            width: 130,
                            child: const Text(
                              'TRABAJO',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          celda(
                            width: 360,
                            child: const Text(
                              'OBSERVACIONES',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // LISTA DE ALUMNOS
                      Expanded(
                        child: ListView.builder(
                          itemCount: alumnos.length,

                          itemBuilder: (context, index) {
                            final alumno = alumnos[index];
                            final registro =
                                registros[alumno.documento]!;

                            return Row(
                              children: [

                                // ------------------------------
                                // ALUMNO
                                // ------------------------------

                                celda(
                                  width: 280,

                                  child: Align(
                                    alignment: Alignment.centerLeft,

                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(left: 12),

child: Row(
  children: [
    if (alumno.foto != null)
      Padding(
        padding: const EdgeInsets.only(right: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.memory(
            base64Decode(alumno.foto!),
            width: 40,
            height: 50,
            fit: BoxFit.cover,
          ),
        ),
      ),
    Expanded(
      child: Text(
        alumno.nombre,
        style: const TextStyle(
          fontSize: 16,
        ),
      ),
    ),
  ],
),
                                    ),
                                  ),
                                ),

                                // ------------------------------
                                // ACTITUD
                                // ------------------------------

                                celda(
                                  width: 130,

                                  child: GestureDetector(
                                    onTap: () {
                                      cambiarActitud(alumno);
                                    },

                                    child: Container(
                                      width: 32,
                                      height: 32,

                                      decoration: BoxDecoration(
                                        color: colorActitud(alumno),

                                        border: Border.all(
                                          color:
                                              Colors.grey.shade500,
                                        ),

                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),

                                // ------------------------------
                                // TRABAJO
                                // ------------------------------

                                celda(
                                  width: 130,

                                  child: GestureDetector(
                                    onTap: () {
                                      cambiarTrabajo(alumno);
                                    },

                                    child: Container(
                                      width: 32,
                                      height: 32,

                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color:
                                              Colors.grey.shade600,
                                          width: 2,
                                        ),

                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),

                                      child: registro.trabajo
                                          ? const Icon(
                                              Icons.check,
                                              size: 25,
                                            )
                                          : null,
                                    ),
                                  ),
                                ),

                                // ------------------------------
                                // OBSERVACIONES
                                // ------------------------------

                                Container(
                                  width: 360,
                                  height: 62,

                                  padding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),

                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color:
                                          Colors.grey.shade300,
                                    ),
                                  ),

                                  child: TextField(
                                    maxLines: 2,

                                    decoration:
                                        const InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'Escribir...',
                                    ),

                                    controller:
                                        TextEditingController(
                                      text:
                                          registro.observaciones,
                                    ),

                                    onChanged: (texto) {
                                      registro.observaciones =
                                          texto;
                                      guardarDatos();
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}