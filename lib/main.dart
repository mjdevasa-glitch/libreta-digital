import 'package:flutter/material.dart';

import 'screens/grupos_page.dart';

void main() {
  runApp(const LibretaApp());
}

class LibretaApp extends StatelessWidget {
  const LibretaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Libreta digital',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
        ),
        useMaterial3: true,
      ),
      home: GruposPage(),
    );
  }
}



