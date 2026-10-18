import 'package:flutter/material.dart';
import 'package:erp_app/Core/theme/app_theme.dart';

class SystemThemeWrapper extends StatelessWidget {
  final Widget child;

  const SystemThemeWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Detect the device's native system brightness
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isLight = brightness == Brightness.light;

    return Theme(
      // Apply the Light or Dark auth theme dynamically
      data: isLight ? AppTheme.authLightTheme : AppTheme.authDarkTheme,
      child: child,
    );
  }
}