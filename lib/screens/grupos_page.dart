import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf_manipulator/pdf_manipulator.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as syncfusion;


import '../models/alumno.dart';
import '../models/grupo.dart';
import 'libreta_diaria.dart';
import 'configuracion_grupos.dart';

class GruposPage extends StatefulWidget {
const  GruposPage({super.key});

  @override
  State<GruposPage> createState() => _GruposPageState();
}

class _GruposPageState extends State<GruposPage> {

@override
void initState() {
  super.initState();

  _cargarGrupos();
  _cargarGruposImportados();
}

List<Grupo> grupos = [];

Future<void> _cargarGrupos() async {
  final prefs = await SharedPreferences.getInstance();
  final nombresPersonalizados =
      prefs.getStringList('grupos_personalizados');
      if (nombresPersonalizados != null) {
  for (final nombre in nombresPersonalizados) {
    if (!grupos.any((grupo) => grupo.nombre == nombre)) {
      grupos.add(
        Grupo(nombre: nombre),
      );
    }
  }
}
  final nombresSeleccionados =
      prefs.getStringList('grupos_seleccionados');
  debugPrint ('CARGADO: $nombresSeleccionados');
  if (nombresSeleccionados == null) {
    return;
  }

  for (final grupo in grupos) {
    grupo.seleccionado =
        nombresSeleccionados.contains(grupo.nombre);
  }

  if (mounted) {
    setState(() {});
  }
}

Future<void> _guardarGruposPersonalizados() async {
  final prefs = await SharedPreferences.getInstance();

  final nombres = grupos
      .where((grupo) => grupo.alumnos.isEmpty)
      .map((grupo) => grupo.nombre)
      .toList();

  await prefs.setStringList(
    'grupos_personalizados',
    nombres,
  );
}

Future<void> _guardarGrupos() async {
  final prefs = await SharedPreferences.getInstance();

  final nombresSeleccionados = grupos
      .where((grupo) => grupo.seleccionado)
      .map((grupo) => grupo.nombre)
      .toList();

  await prefs.setStringList(
    'grupos_seleccionados',
    nombresSeleccionados,
  );
  debugPrint('GUARDADO: $nombresSeleccionados');
}

Future<void> _guardarGruposImportados() async {
  final prefs = await SharedPreferences.getInstance();

  final gruposImportados = grupos
      .where((grupo) => grupo.alumnos.isNotEmpty)
      .map((grupo) {
        return {
          'nombre': grupo.nombre,
          'seleccionado': grupo.seleccionado,
          'esMixto': grupo.esMixto,
          'alumnos': grupo.alumnos.map((alumno) {
            return {
              'nombre': alumno.nombre,
              'grupo': alumno.grupo,
              'documento': alumno.documento,
              'foto': alumno.foto,
            };
          }).toList(),
        };
      }).toList();

  await prefs.setString(
    'grupos_importados',
    jsonEncode(gruposImportados),
  );
}

Future<void> _crearCopiaSeguridad() async {
  final prefs = await SharedPreferences.getInstance();

  final datos = <String, dynamic>{};

  for (final clave in prefs.getKeys()) {
    datos[clave] = prefs.get(clave);
  }

  final copia = jsonEncode(datos);

  await FilePicker.saveFile(
    dialogTitle: 'Guardar copia de seguridad',
    fileName: 'libreta_digital_backup.json',
    type: FileType.custom,
    allowedExtensions: ['json'],
    bytes: Uint8List.fromList(
      utf8.encode(copia),
    ),
  );
}

Future<void> _restaurarCopiaSeguridad() async {
  final archivo = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: ['json'],
  );

  if (archivo == null) {
    return;
  }

  final bytes = await archivo.readAsBytes();

  try {
  final texto = utf8.decode(bytes);
  final datos = jsonDecode(texto) as Map<String, dynamic>;

  final prefs = await SharedPreferences.getInstance();

  for (final entrada in datos.entries) {
    final valor = entrada.value;

    if (valor is String) {
      await prefs.setString(entrada.key, valor);
    } else if (valor is bool) {
      await prefs.setBool(entrada.key, valor);
    } else if (valor is int) {
      await prefs.setInt(entrada.key, valor);
    } else if (valor is double) {
      await prefs.setDouble(entrada.key, valor);
    } else if (valor is List) {
      await prefs.setStringList(
        entrada.key,
        valor.cast<String>(),
      );
    }
  }

  if (!mounted) {
    return;
  }

      ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copia restaurada correctamente.'),
      ),
    );
  } catch (e) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error al restaurar: $e'),
      ),
    );
  }
}

Future<void> _cargarGruposImportados() async {
  final prefs = await SharedPreferences.getInstance();

  final texto = prefs.getString('grupos_importados');

  if (texto == null) {
    return;
  }

  final datos = jsonDecode(texto) as List;

  final nombresImportados = datos
    .map((dato) => dato['nombre'] as String)
    .toSet();

grupos.removeWhere(
  (grupo) =>
      grupo.alumnos.isNotEmpty &&
      !nombresImportados.contains(grupo.nombre),
);

  for (final dato in datos) {
    final alumnos = (dato['alumnos'] as List).map((alumno) {
      return Alumno(
        nombre: alumno['nombre'] as String,
        grupo: alumno['grupo'] as String,
        documento: alumno['documento'] as String,
        foto: alumno['foto'] as String?,
      );
    }).toList();

    final grupo = Grupo(
      nombre: dato['nombre'] as String,
      alumnos: alumnos,
      seleccionado: dato['seleccionado'] as bool? ?? true,
      esMixto: dato['esMixto'] as bool? ?? false,
    );

    final indice = grupos.indexWhere(
      (g) => g.nombre == grupo.nombre,
    );

    if (indice >= 0) {
      grupos[indice] = grupo;
    } else {
      grupos.add(grupo);
    }
  }

  if (mounted) {
    setState(() {});
  }
}


Future<void> _importarOrla() async {
  final archivo = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: ['pdf'],
  );

  if (archivo == null) {
    return;
  }

  final datos = await archivo.readAsBytes();

  final documentoTexto = syncfusion.PdfDocument(
    inputBytes: datos,
  );

  final texto = syncfusion.PdfTextExtractor(
    documentoTexto,
  ).extractText();

documentoTexto.dispose();
final lineas = texto
    .split('\n')
    .map((linea) => linea.trim())
    .where((linea) => linea.isNotEmpty)
    .toList();

final indiceCurso = lineas.indexWhere(
  (linea) => RegExp(r'^\d+º ESO [A-Z]$').hasMatch(linea),
);

final nombres = <String>[];

if (indiceCurso != -1) {
  for (int i = indiceCurso + 1; i < lineas.length; i++) {
    final linea = lineas[i];

    if (!linea.contains(',')) {
      continue;
    }

    final partes = linea.split(',');

    final apellidos = partes[0].trim();
    var nombre = partes.length > 1 ? partes[1].trim() : '';

    if (nombre.isEmpty && i + 1 < lineas.length) {
      nombre = lineas[i + 1].trim();
    }

    if (nombre.isNotEmpty) {
      nombres.add('$apellidos, $nombre');
    }
  }
}

  final pdf = Pdf();
  final documento = await pdf.open(MemorySource(datos));

  final imagenes = <PdfImage>[];

  await for (final imagen
      in documento.extractImages(pages: PdfPages.all())) {
    imagenes.add(imagen);
  }
final alumnosImportados = <Alumno>[];

final fotosExtraidas = imagenes.skip(1).toList();

for (int i = 0; i < nombres.length && i < fotosExtraidas.length; i++) {
  alumnosImportados.add(
    Alumno(
      nombre: nombres[i],
      grupo: lineas[indiceCurso],
      documento: 'ORLA_$i',
      foto: base64Encode(fotosExtraidas[i].data),
    ),
  );
}

debugPrint(
  'ALUMNOS IMPORTADOS: ${alumnosImportados.length}',
);

for (final alumno in alumnosImportados) {
  debugPrint(
    '${alumno.nombre} → ${alumno.grupo} → '
    'foto: ${alumno.foto != null ? "SÍ" : "NO"}',
  );
}
final grupoImportado = Grupo(
  nombre: lineas[indiceCurso],
  alumnos: alumnosImportados,
  seleccionado: true,
);

setState(() {
  grupos.add(grupoImportado);
});
await _guardarGruposImportados();
  await documento.dispose();
  await pdf.dispose();

  if (!mounted) {
    return;
  }

final fotos = imagenes.skip(1).toList();

await showDialog(
  context: context,
  builder: (context) {
    return AlertDialog(
      title: const Text('Fotos extraídas'),
      content: SizedBox(
        width: 700,
        height: 500,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: fotos.length,
itemBuilder: (context, index) {
  return Column(
    children: [
      Expanded(
        child: Image.memory(
          fotos[index].data,
          fit: BoxFit.cover,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        nombres[index],
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
        ),
      ),
    ],
  );
},
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cerrar'),
        ),
      ],
    );
  },
);
}

void _editarGrupo(Grupo grupo) async {
  final controlador = TextEditingController(
    text: grupo.nombre,
  );

  final nombre = await showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Cambiar nombre'),
        content: TextField(
          controller: controlador,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nombre del grupo',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(
                context,
                controlador.text.trim(),
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      );
    },
  );

  controlador.dispose();

  if (!mounted || nombre == null || nombre.isEmpty) {
    return;
  }

setState(() {
  grupo.nombre = nombre;
});

await _guardarGruposPersonalizados();
await _guardarGruposImportados();
await _guardarGrupos();
}

void _eliminarGrupo(Grupo grupo) async {
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Eliminar grupo'),
        content: Text(
          '¿Quieres eliminar el grupo "${grupo.nombre}"?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const Text('Eliminar'),
          ),
        ],
      );
    },
  );

  if (!mounted || confirmar != true) {
    return;
  }

  setState(() {
    grupos.remove(grupo);
  });
  await _guardarGruposPersonalizados();
  await _guardarGruposImportados();
  await _guardarGrupos();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text(
          'LIBRETA DIGITAL',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Row(
        children: [
          // BARRA LATERAL
          Container(
            width: 280,
            color: Colors.indigo.shade50,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MIS GRUPOS',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                Expanded(
                  child: ListView.builder(
                    itemCount: grupos.length,
                    itemBuilder: (context, index) {
                      final grupo = grupos[index];

                      return Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.groups,
                          ),
                          title: Text(
                            grupo.nombre,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [

                              PopupMenuButton<String>(
                                onSelected: (opcion) {
                                  if (opcion == 'editar') {
                                    _editarGrupo(grupo);
                                  }

                                  if (opcion == 'eliminar') {
                                    _eliminarGrupo(grupo);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'editar',
                                    child: Text('Cambiar nombre'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'eliminar',
                                    child: Text('Eliminar grupo'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LibretaDiaria(
                                  grupo: grupo,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),

                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Configuración'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ConfiguracionGruposPage(),
                      ),
                    );
                  },
                ),


        ListTile(
          leading: const Icon(Icons.picture_as_pdf),
          title: const Text('Importar orla'),
          onTap: _importarOrla,
        ),
        
        ListTile(
          leading: const Icon(Icons.backup),
          title: const Text('Copia de seguridad'),
          onTap: () async {
            await _crearCopiaSeguridad();
          },
        ),

        ListTile(
          leading: const Icon(Icons.restore),
          title: const Text('Restaurar copia'),
          onTap: _restaurarCopiaSeguridad,
        ),

                const Divider(),


              ],
            ),
          ),

          // ZONA PRINCIPAL
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.menu_book,
                    size: 80,
                    color: Colors.indigo,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Selecciona un grupo',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Elige un grupo para abrir su libreta',
                    style: TextStyle(
                      fontSize: 17,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}