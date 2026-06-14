import 'package:flutter/material.dart';
import 'screens/mens_category.dart';

void main() {
  runApp(const ZinthuApp());
}

class ZinthuApp extends StatelessWidget {
  const ZinthuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Zinthu",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: "Arial",
        scaffoldBackgroundColor: const Color(0xfff5f5f5),
      ),
      home: const MensCategoryScreen(),
    );
  }
}