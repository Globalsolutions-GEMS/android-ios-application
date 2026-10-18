import 'package:flutter/material.dart';

class AppTheme {
  // Warmer, softer violet (not too bold)
  static const Color primaryViolet = Color(0xFF7B61FF);

  // ----------------------------------------------------
  // AUTHENTICATION THEMES (Responsive to System Setting)
  // ----------------------------------------------------

  static ThemeData get authLightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Nunito',
      brightness: Brightness.light,
      primaryColor: primaryViolet,
      scaffoldBackgroundColor: const Color(0xFFF4F6F8), // Soft light background
      cardColor: Colors.white.withOpacity(0.95), // White frosted card
      shadowColor: Colors.black12,
      colorScheme: const ColorScheme.light(
        primary: primaryViolet,
        onPrimary: Colors.white,
        surface: Colors.white,
        onSurface: Color(0xFF0F172A), // Dark text for light mode
        onSurfaceVariant: Color(0xFF64748B), // Subtitle grey
      ),
    );
  }

  static ThemeData get authDarkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Nunito',
      brightness: Brightness.dark,
      primaryColor: primaryViolet,
      scaffoldBackgroundColor: const Color(0xFF0A0E21), // Deep dark background
      cardColor: Colors.white.withOpacity(0.06), // Dark frosted card
      shadowColor: Colors.black,
      colorScheme: const ColorScheme.dark(
        primary: primaryViolet,
        onPrimary: Colors.white,
        surface: Color(0xFF0A0E21),
        onSurface: Colors.white, // White text for dark mode
        onSurfaceVariant: Color(0xFF94A3B8), // Subtitle light grey
      ),
    );
  }

  // ----------------------------------------------------
  // MAIN APP THEME (Fixed - Ignores System Setting)
  // ----------------------------------------------------
  
  static ThemeData get fixedMainTheme => authLightTheme; 

  // ----------------------------------------------------
  // SHARED BACKGROUND (Adapts automatically via Theme)
  // ----------------------------------------------------

  static Widget buildSharedBackground(BuildContext context, {required Widget child}) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        // 1. Adaptive Background
        Container(color: theme.scaffoldBackgroundColor),

        // 2. Top Left - Soft Glow
        Positioned(
          top: -50,
          left: -50,
          child: Container(
            width: 430,
            height: 430,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withOpacity(isDark ? 0.25 : 0.15),
                  blurRadius: 190,
                  spreadRadius: 85,
                ),
              ],
            ),
          ),
        ),

        // 3. Bottom Right - Soft Glow
        Positioned(
          top: size.height * 0.55,
          left: size.width * 0.5,
          child: Container(
            width: 500,
            height: 500,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withOpacity(isDark ? 0.20 : 0.12),
                  blurRadius: 200,
                  spreadRadius: 95,
                ),
              ],
            ),
          ),
        ),

        // 4. The actual screen content
        child,
      ],
    );
  }

  // ----------------------------------------------------
  // THEMED SNACKBAR (Adapts to Light/Dark Mode)
  // ----------------------------------------------------

  static SnackBar showThemedSnackBar(BuildContext context, String message) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SnackBar(
      content: Text(
        message,
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF0F172A),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: isDark
          ? const Color(0xFF1E293B)
          : Colors.white,
      //behavior: SnackBarBehavior.floating,
      elevation: isDark ? 8 : 4,
      duration: const Duration(seconds: 3),
    );
  }
}