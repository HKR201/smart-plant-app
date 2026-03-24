import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/dashboard.dart';

void main() {
  runApp(const SmartPlantApp());
}

class SmartPlantApp extends StatelessWidget {
  const SmartPlantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Plant Care',
      debugShowCheckedModeBanner: false,
      // ဖုန်းရဲ့ System setting အတိုင်း လိုက်ပြောင်းပေးမယ့် Theme Logic
      themeMode: ThemeMode.system, 
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.green,
        fontFamily: 'sans-serif', // မြန်မာစာအတွက် Standard font
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.green,
      ),
      home: const Dashboard(),
    );
  }
}
