import 'package:flutter/material.dart';

void main() {
  runApp(const KanakkanApp());
}

class KanakkanApp extends StatelessWidget {
  const KanakkanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kanakkan',
      home: Scaffold(body: Center(child: Text("Kanakkan Setup"))),
    );
  }
}
