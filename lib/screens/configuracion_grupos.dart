import 'package:flutter/material.dart';

class ConfiguracionGruposPage extends StatelessWidget {
  const ConfiguracionGruposPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CONFIGURACIÓN DE GRUPOS',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: const Center(
        child: Text(
          'Aquí configuraremos tus grupos',
          style: TextStyle(
            fontSize: 22,
          ),
        ),
      ),
    );
  }
}