import 'package:flutter/material.dart';

import 'pages/home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Balloon Animation', // task-switcher name
      theme: ThemeData(
        primarySwatch: Colors.blue, // change accent colour here
      ),
      home: const HomeScreen(),
    );
  }
}
