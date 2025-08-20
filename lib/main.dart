import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const CompoundXApp());
}

class CompoundXApp extends StatelessWidget {
  const CompoundXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CompoundX - Crypto Trading Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.purple,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        cardColor: const Color(0xFF1A1A1A),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}
