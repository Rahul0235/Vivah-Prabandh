import 'package:flutter/material.dart';
import 'features/landing/screens/landing_page.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
       title: 'Vivah Prabandh',
       debugShowCheckedModeBanner: false,
       theme: AppTheme.lightTheme,
       home: const LandingPage(),
    );
  }
}