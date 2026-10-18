import 'dart:ui';
import 'package:erp_app/Features/Dashboard/screens/dashboard_screen.dart';
import 'package:erp_app/Features/Forgot%20Password/screens/forgot_password_screen.dart';
import 'package:erp_app/Features/Login/BLoc/login_bloc.dart';
import 'package:erp_app/Features/Login/BLoc/login_event.dart';
import 'package:erp_app/Features/Login/BLoc/login_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:erp_app/Core/theme/app_theme.dart';
import 'package:erp_app/Core/theme/system_theme_wrapper.dart';
import 'package:lottie/lottie.dart';
import 'package:erp_app/Features/Dashboard/screens/admin_dashboard_screen.dart';
import 'package:erp_app/Features/Dashboard/screens/student_dashboard_screen.dart';
import 'package:erp_app/Features/Dashboard/screens/faculty_dashboard_screen.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String? _loginIdError;
  String? _passwordError;

  void _clearLoginIdError() {
    if (_loginIdError != null && _loginIdController.text.isNotEmpty) {
      setState(() {
        _loginIdError = null;
      });
    }
  }

  void _clearPasswordError() {
    if (_passwordError != null && _passwordController.text.isNotEmpty) {
      setState(() {
        _passwordError = null;
      });
    }
  }

  @override
  void dispose() {
    _loginIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SystemThemeWrapper(
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;

          return BlocProvider(
            create: (_) => LoginBloc(),
            child: BlocConsumer<LoginBloc, LoginState>(
              listener: (context, state) {
                if (state is LoginFailure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    AppTheme.showThemedSnackBar(context, state.message),
                  );
                }
             if (state is LoginSuccess) {
  const adminRoles = ['ADMIN', 'STAFF', 'SUPERADMIN'];
  final Widget screen;

  if (adminRoles.contains(state.roleName)) {
    screen = const AdminDashboardScreen();
  } else if (state.roleName == 'STUDENT') {
    screen = const StudentDashboardScreen();
  } else if (state.roleName == 'FACULTY') {
    screen = const FacultyDashboardScreen();
  } else {
    screen = const DashboardScreen(); // fallback for unknown role
  }

  Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (_) => screen),
  );
}
              },
              builder:
                  (context, state) => AppTheme.buildSharedBackground(
                    context,
                    child: Scaffold(
                      backgroundColor: Colors.transparent,
                      body: SafeArea(
                        child: Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildIllustration(colorScheme),
                                const SizedBox(height: 20),
                                _buildLoginColumn(context, state, theme),
                              ],
                            ),
                          ),
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

  Widget _buildIllustration(ColorScheme colorScheme) {
    return SizedBox(
      height: 160,
      width: 160,
      child: Center(
        child: Lottie.asset(
          'assets/Animation/login_animation.json',
          fit: BoxFit.contain,
          repeat: true,
          animate: true,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.blur_on_rounded,
              size: 80,
              color: colorScheme.onSurface.withOpacity(0.8),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoginColumn(
    BuildContext context,
    LoginState state,
    ThemeData theme,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildGlassForm(context, state, theme),
        const SizedBox(height: 20),
        _buildCopyright(theme.colorScheme),
      ],
    );
  }

  Widget _buildCopyright(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Copyright © 2026',
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 10),
        Image.asset('assets/Image/GSlogo.png', height: 36, fit: BoxFit.contain),
      ],
    );
  }

  Widget _buildGlassForm(
    BuildContext context,
    LoginState state,
    ThemeData theme,
  ) {
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth < 380 ? 20.0 : 32.0;

    return Container(
      constraints: const BoxConstraints(maxWidth: 380),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.onSurface.withOpacity(0.12),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
          child: Container(
            color: theme.cardColor,
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    "Welcome Back",
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    "Please enter your user information.",
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                _buildModernTextField(
                  label: "Login-ID",
                  icon: Icons.mail_rounded,
                  controller: _loginIdController,
                  theme: theme,
                  errorText: _loginIdError,
                ),
                const SizedBox(height: 20),

                _buildModernTextField(
                  label: "Password",
                  icon: Icons.lock_rounded,
                  isPassword: true,
                  controller: _passwordController,
                  theme: theme,
                  errorText: _passwordError,
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _rememberMe,
                            activeColor: theme.primaryColor,
                            checkColor: colorScheme.onPrimary,
                            side: BorderSide(
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (val) {
                              setState(() {
                                _rememberMe = val ?? false;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Remember me",
                          style: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
                      child: Text(
                        "Forgot password?",
                        style: TextStyle(color: theme.primaryColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 8,
                      shadowColor: theme.primaryColor.withOpacity(0.4),
                    ),
                    onPressed:
                        state is LoginLoading
                            ? null
                            : () => _submitLogin(context),
                    child:
                        state is LoginLoading
                            ? SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: colorScheme.onPrimary,
                              ),
                            )
                            : Text(
                              "Sign In",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimary,
                                letterSpacing: 0.5,
                              ),
                            ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required ThemeData theme,
    bool isPassword = false,
    String? errorText,
  }) {
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          obscureText: isPassword ? _obscurePassword : false,
          onChanged: (_) {
            if (isPassword) {
              _clearPasswordError();
            } else {
              _clearLoginIdError();
            }
          },
          style: TextStyle(
            color:
                theme.brightness == Brightness.dark
                    ? Colors.white
                    : colorScheme.onSurface,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.5),
              fontSize: 15,
            ),
            floatingLabelStyle: TextStyle(
              color:
                  theme.brightness == Brightness.dark
                      ? Colors.white
                      : theme.primaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),

            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, right: 12),
              child: Icon(icon, color: theme.primaryColor, size: 22),
            ),
            suffixIcon:
                isPassword
                    ? IconButton(
                      padding: const EdgeInsets.only(right: 16),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: theme.primaryColor,
                        size: 22,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    )
                    : null,

            filled: false,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.onSurface.withOpacity(0.25),
                width: 1,
              ),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.primaryColor, width: 2),
            ),

            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.onSurface.withOpacity(0.25),
                width: 1,
              ),
            ),

            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.primaryColor, width: 2),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: Text(
              errorText,
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  void _submitLogin(BuildContext context) {
    setState(() {
      _loginIdError = null;
      _passwordError = null;
    });

    bool hasError = false;

    if (_loginIdController.text.trim().isEmpty) {
      setState(() {
        _loginIdError = 'Login-ID is required';
      });
      hasError = true;
    }

    if (_passwordController.text.isEmpty) {
      setState(() {
        _passwordError = 'Password is required';
      });
      hasError = true;
    }

    if (hasError) return;

    context.read<LoginBloc>().add(
      LoginSubmitted(
        loginId: _loginIdController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }
}
