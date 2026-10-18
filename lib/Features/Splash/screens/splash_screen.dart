import 'package:erp_app/Features/Login/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:erp_app/Core/theme/app_theme.dart';
import 'package:erp_app/Core/theme/system_theme_wrapper.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const LoginScreen(),
            transitionsBuilder:
                (_, animation, __, child) =>
                    FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. WRAP WITH SYSTEM THEME
    return SystemThemeWrapper(
      child: Builder(
        // Builder ensures we read the newly injected theme
        builder: (context) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;

          return Scaffold(
            body: AppTheme.buildSharedBackground(
              context,
              child: SafeArea(
                child: Center(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 200,
                          height: 200,
                          child: Lottie.asset(
                            'assets/Animation/login_animation.json',
                            fit: BoxFit.contain,
                            repeat: true,
                            animate: true,
                            errorBuilder:
                                (context, error, stackTrace) => Icon(
                                  Icons.blur_on_rounded,
                                  size: 80,
                                  color: colorScheme.onSurface.withOpacity(0.8),
                                ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          "ERP PORTAL",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface, // Adaptive Color
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Enterprise Management Suite",
                          style: TextStyle(
                            fontSize: 16,
                            color:
                                colorScheme
                                    .onSurfaceVariant, // Adaptive Subtitle
                          ),
                        ),
                        const SizedBox(height: 60),
                        SizedBox(
                          width: 150,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              minHeight: 4,
                              backgroundColor: colorScheme.onSurface
                                  .withOpacity(0.12),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
