import 'package:flutter/material.dart';
import 'package:erp_app/Core/theme/app_theme.dart';
import 'package:erp_app/Features/Splash/screens/splash_screen.dart';

void main() {
  runApp(const ERPApp());
}

class ERPApp extends StatelessWidget {
  const ERPApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ERP Portal',
      debugShowCheckedModeBanner: false, 
      // Locks the entire app to the fixed theme by default
      theme: AppTheme.fixedMainTheme,
      // Make sure you DO NOT have themeMode: ThemeMode.system here
      home: const SplashScreen(),
    );   
  }
}
