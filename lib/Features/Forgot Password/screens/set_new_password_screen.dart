import 'dart:async';
import 'dart:ui';
import 'package:erp_app/Features/Forgot%20Password/BLoc/reset_password_bloc.dart';
import 'package:erp_app/Features/Forgot%20Password/BLoc/reset_password_event.dart';
import 'package:erp_app/Features/Forgot%20Password/BLoc/reset_password_state.dart';
import 'package:erp_app/Features/Login/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:erp_app/Core/theme/app_theme.dart';
import 'package:erp_app/Core/theme/system_theme_wrapper.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SetNewPasswordScreen extends StatefulWidget {
  const SetNewPasswordScreen({super.key});

  @override
  State<SetNewPasswordScreen> createState() => _SetNewPasswordScreenState();
}

class _SetNewPasswordScreenState extends State<SetNewPasswordScreen> {
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String? _newPasswordError;
  String? _confirmPasswordError;

  // Password validation requirements
  bool _minLength = false;
  bool _hasLowerCase = false;
  bool _hasUpperCase = false;
  bool _hasNumberOrSpecial = false;

  // Data from SharedPreferences
  String? _otp;
  String? _email;
  String? _mobile;
  String? _studentId;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final preferences = await SharedPreferences.getInstance();
    setState(() {
      _otp = preferences.getString('otp');
      _email = preferences.getString('email');
      _mobile = preferences.getString('mobile');
      _studentId = preferences.getString('studentId');
    });
  }

  void _validatePasswordRequirements(String password) {
    setState(() {
      _minLength = password.length >= 8;
      _hasLowerCase = password.contains(RegExp(r'[a-z]'));
      _hasUpperCase = password.contains(RegExp(r'[A-Z]'));
      _hasNumberOrSpecial =
          password.contains(RegExp(r'[0-9]')) ||
          password.contains(RegExp(r'[!@#$%^&*()_+\-=\[\]{};":\\|,.<>\/?]'));
    });
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ResetPasswordBloc(),
      child: BlocConsumer<ResetPasswordBloc, ResetPasswordState>(
        listener: (context, state) async {
          if (state is ResetPasswordFailure) {
            setState(() {
              _newPasswordError = state.message;
              _confirmPasswordError = null;
            });
          }
          if (state is ResetPasswordSuccess) {
            if (!mounted) return;
            // Dispose keyboard
            FocusScope.of(context).unfocus();
            // Briefly confirm success before returning to sign in.
            _showSuccessDialog(context);
            // Clear SharedPreferences
            SharedPreferences.getInstance().then((preferences) {
              preferences.remove('otp');
              preferences.remove('email');
              preferences.remove('mobile');
              preferences.remove('studentId');
              preferences.remove('otpSource');
              preferences.remove('inputValue');
              preferences.remove('maskedEmail');
              preferences.remove('maskedMobile');
            });
          }
        },
        builder: (context, state) {
          return SystemThemeWrapper(
            child: Builder(
              builder: (context) {
                final theme = Theme.of(context);
                final colorScheme = theme.colorScheme;

                return AppTheme.buildSharedBackground(
                  context,
                  child: Scaffold(
                    backgroundColor: Colors.transparent,
                    body: SafeArea(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24.0,
                            vertical: 32.0,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildIllustration(colorScheme),
                              const SizedBox(height: 20),
                              _buildResetCard(context, theme, state),
                              const SizedBox(height: 32),
                              _buildCopyright(colorScheme),
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
        },
      ),
    );
  }

  Widget _buildIllustration(ColorScheme colorScheme) {
    return SizedBox(
      height: 150,
      child: Center(
        child: Lottie.asset(
          'assets/Animation/set_new_password.json',
          fit: BoxFit.contain,
          repeat: true,
          animate: true,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.blur_on_rounded,
              size: 100,
              color: colorScheme.onSurface.withValues(alpha: 0.8),
            );
          },
        ),
      ),
    );
  }

  Widget _buildResetCard(
    BuildContext context,
    ThemeData theme,
    ResetPasswordState state,
  ) {
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth < 380 ? 20.0 : 32.0;

    return Container(
      constraints: const BoxConstraints(maxWidth: 380),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.12),
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
              vertical: 28,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Set New Password",
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  "Create a new password for your account.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 28),

                _buildModernTextField(
                  label: "New Password",
                  icon: Icons.lock_outline_rounded,
                  isPassword: true,
                  obscurePassword: _obscureNew,
                  controller: _newPasswordController,
                  theme: theme,
                  errorText: _newPasswordError,
                  onToggleVisibility: () {
                    setState(() {
                      _obscureNew = !_obscureNew;
                    });
                  },
                  onChanged: (value) {
                    _validatePasswordRequirements(value);
                    if (_newPasswordError != null) {
                      setState(() {
                        _newPasswordError = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),

                // Password requirements
                if (_newPasswordController.text.isNotEmpty &&
                    !(_minLength &&
                        _hasLowerCase &&
                        _hasUpperCase &&
                        _hasNumberOrSpecial))
                  _buildPasswordRequirements(colorScheme),

                const SizedBox(height: 20),

                _buildModernTextField(
                  label: "Confirm Password",
                  icon: Icons.lock_outline_rounded,
                  isPassword: true,
                  obscurePassword: _obscureConfirm,
                  controller: _confirmPasswordController,
                  theme: theme,
                  errorText: _confirmPasswordError,
                  onToggleVisibility: () {
                    setState(() {
                      _obscureConfirm = !_obscureConfirm;
                    });
                  },
                  onChanged: (value) {
                    if (_confirmPasswordError != null) {
                      setState(() {
                        _confirmPasswordError = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 8,
                      shadowColor: theme.primaryColor.withValues(alpha: 0.4),
                    ),
                    onPressed:
                        state is ResetPasswordLoading
                            ? null
                            : () => _showConfirmationDialog(context),
                    child:
                        state is ResetPasswordLoading
                            ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                            : Text(
                              "Reset Password",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimary,
                                letterSpacing: 0.5,
                              ),
                            ),
                  ),
                ),
                const SizedBox(height: 16),

                TextButton(
                  onPressed:
                      () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      ),
                  child: Text(
                    "Back to Sign In",
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
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
    bool isPassword = false,
    required bool obscurePassword,
    TextEditingController? controller,
    required VoidCallback onToggleVisibility,
    required ThemeData theme,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          obscureText: obscurePassword,
          style: TextStyle(
            color: isDark ? Colors.white : colorScheme.onSurface,
            fontSize: 16,
          ),
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 15,
            ),
            floatingLabelStyle: TextStyle(
              color: isDark ? Colors.white : theme.primaryColor,
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
                        obscurePassword
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: theme.primaryColor,
                        size: 22,
                      ),
                      onPressed: onToggleVisibility,
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
                color: colorScheme.onSurface.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.primaryColor, width: 2),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 12),
            child: Text(
              errorText,
              style: TextStyle(color: colorScheme.error, fontSize: 13),
            ),
          ),
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

  Widget _buildPasswordRequirements(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Use a secure password',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          _buildRequirementItem(
            'At least 8 characters',
            _minLength,
            colorScheme,
          ),
          _buildRequirementItem(
            'One lowercase letter',
            _hasLowerCase,
            colorScheme,
          ),
          _buildRequirementItem(
            'One uppercase letter',
            _hasUpperCase,
            colorScheme,
          ),
          _buildRequirementItem(
            'One number or special character',
            _hasNumberOrSpecial,
            colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(
    String text,
    bool isMet,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color:
                isMet ? const Color(0xFF22A06B) : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color:
                  isMet
                      ? const Color(0xFF22A06B)
                      : colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context) {
    // Validate before showing dialog
    String? newPasswordError;
    String? confirmPasswordError;

    if (_newPasswordController.text.isEmpty) {
      newPasswordError = 'New password is required';
    } else if (!(_minLength &&
        _hasLowerCase &&
        _hasUpperCase &&
        _hasNumberOrSpecial)) {
      newPasswordError = 'Password does not meet requirements';
    }

    if (_confirmPasswordController.text.isEmpty) {
      confirmPasswordError = 'Please confirm your password';
    } else if (_newPasswordController.text != _confirmPasswordController.text) {
      confirmPasswordError = 'Passwords do not match';
    }

    if (newPasswordError != null || confirmPasswordError != null) {
      setState(() {
        _newPasswordError = newPasswordError;
        _confirmPasswordError = confirmPasswordError;
      });
      return;
    }

    final bloc = context.read<ResetPasswordBloc>();
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.54),
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final colorScheme = theme.colorScheme;
        final isDark = theme.brightness == Brightness.dark;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF151B33) : colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : colorScheme.primary.withValues(alpha: 0.14),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.18),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(
                            alpha: isDark ? 0.24 : 0.12,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.lock_reset_rounded,
                          color: colorScheme.primary,
                          size: 25,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: colorScheme.onSurfaceVariant,
                          size: 24,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Reset your password?',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your current password will be replaced. You will use the new password the next time you sign in.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        _handleResetPassword(bloc);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        elevation: 0,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Reset Password',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleResetPassword(ResetPasswordBloc bloc) {
    setState(() {
      _newPasswordError = null;
      _confirmPasswordError = null;
    });

    bloc.add(
      ResetPasswordSubmitted(
        newPassword: _newPasswordController.text,
        confirmNewPassword: _confirmPasswordController.text,
        otp: _otp ?? '',
        email: _email,
        mobile: _mobile,
        studentId: _studentId,
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    // This callback sits above SystemThemeWrapper in the widget tree, so use
    // the device brightness directly instead of the app's root (light) theme.
    final isDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final theme = isDark ? AppTheme.authDarkTheme : AppTheme.authLightTheme;
    final colorScheme = theme.colorScheme;
    const successColor = Color(0xFF22A06B);
    final dialogSurface =
        isDark ? const Color(0xFF171C31) : colorScheme.surface;
    final successTint = successColor.withValues(alpha: isDark ? 0.24 : 0.12);

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: isDark ? 0.68 : 0.42),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
              decoration: BoxDecoration(
                color: dialogSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: successColor.withValues(alpha: isDark ? 0.38 : 0.24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.55 : 0.16),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: successTint,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: successColor,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Password reset successfully',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    });
  }
}
