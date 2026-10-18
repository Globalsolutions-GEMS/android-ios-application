import 'dart:ui';
import 'package:erp_app/Features/Forgot%20Password/BLoc/forgot_password_bloc.dart';
import 'package:erp_app/Features/Forgot%20Password/BLoc/forgot_password_event.dart';
import 'package:erp_app/Features/Forgot%20Password/BLoc/forgot_password_state.dart';
import 'package:erp_app/Features/Forgot%20Password/screens/verify_otp_screen.dart';
import 'package:erp_app/Features/Login/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:erp_app/Core/theme/app_theme.dart';
import 'package:erp_app/Core/theme/system_theme_wrapper.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  // 0 = Email, 1 = Mobile Number, 2 = Student ID
  int _selectedMethodIndex = 0;
  final _inputController = TextEditingController();
  String? _inputError;

  late final AnimationController _floatController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  void _clearInputError() {
    if (_inputError != null && _inputController.text.isNotEmpty) {
      setState(() {
        _inputError = null;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _inputController.addListener(_clearInputError);
  }

  @override
  void dispose() {
    _inputController.removeListener(_clearInputError);
    _floatController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  String get _currentLabel {
    if (_selectedMethodIndex == 0) return "Email";
    if (_selectedMethodIndex == 1) return "Mobile Number";
    return "Student ID";
  }

  @override
  Widget build(BuildContext context) {
    return SystemThemeWrapper(
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;

          return BlocProvider(
            create: (_) => ForgotPasswordBloc(),
            child: BlocConsumer<ForgotPasswordBloc, ForgotPasswordState>(
              listener: (context, state) {
                if (state is ForgotPasswordFailure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    AppTheme.showThemedSnackBar(context, state.message),
                  );
                }
                if (state is ForgotPasswordSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    AppTheme.showThemedSnackBar(context, state.message),
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VerifyOtpScreen(),
                    ),
                  );
                }
              },
              builder: (context, state) {
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
                              _buildIllustration(theme),
                              const SizedBox(height: 20),
                              _buildResetCard(context, state, theme),
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

  Widget _buildIllustration(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return SizedBox(
      height: 150,
      child: Center(
        child: AnimatedBuilder(
          animation: _floatController,
          builder: (context, child) {
            final t = Curves.easeInOut.transform(_floatController.value);
            return Transform.translate(
              offset: Offset(0, -8 + 16 * t), // float up and down
              child: child,
            );
          },
          child: SvgPicture.asset(
            isDark
                ? 'assets/Image/reset_lock_dark.svg'
                : 'assets/Image/reset_lock_light.svg',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildResetCard(
    BuildContext context,
    ForgotPasswordState state,
    ThemeData theme,
  ) {
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth < 380 ? 16.0 : 32.0;

    return Container(
      constraints: const BoxConstraints(maxWidth: 380), // matched login size
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
              vertical: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Title
                Text(
                  "Reset Your Password",
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  "Don't worry, we'll send you a reset link via your preferred method.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),

                // Custom Toggle Buttons
                _buildToggleButtons(theme),
                const SizedBox(height: 24),

                // Dynamic Input Field
                _buildModernTextField(
                  label: _currentLabel,
                  icon:
                      _selectedMethodIndex == 0
                          ? Icons.mail_rounded
                          : _selectedMethodIndex == 1
                          ? Icons.phone_android_rounded
                          : Icons.badge_rounded,
                  controller: _inputController,
                  theme: theme,
                  errorText: _inputError,
                ),
                const SizedBox(height: 20),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 56, // Matched Login
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          14,
                        ), // Matched Login
                      ),
                      elevation: 8,
                      shadowColor: theme.primaryColor.withValues(alpha: 0.4),
                    ),
                    // onPressed: () {
                    //   Navigator.pushReplacement(
                    //     context,
                    //     MaterialPageRoute(
                    //       builder: (context) => const VerifyOtpScreen(),
                    //     ),
                    //   );
                    // },
                    onPressed:
                        state is ForgotPasswordLoading
                            ? null
                            : () => _submitForgotPassword(context),
                    child:
                        state is ForgotPasswordLoading
                            ? SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: colorScheme.onPrimary,
                              ),
                            )
                            : Text(
                              "Get Credentials",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimary,
                                letterSpacing: 0.5,
                              ),
                            ),
                  ),
                ),
                const SizedBox(height: 20),

                // Back to Sign In
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  child: Text(
                    "Back to Sign In",
                    style: TextStyle(
                      color: theme.primaryColor,
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

  Widget _buildToggleButtons(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildTabOption(title: "Email", index: 0, theme: theme),
        const SizedBox(width: 12),
        _buildTabOption(title: "Mobile", index: 1, theme: theme),
        const SizedBox(width: 12),
        _buildTabOption(title: "Stud ID", index: 2, theme: theme),
      ],
    );
  }

  Widget _buildTabOption({
    required String title,
    required int index,
    required ThemeData theme,
  }) {
    final isSelected = _selectedMethodIndex == index;
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedMethodIndex = index;
            _inputController.clear();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? theme.primaryColor
                    : (isDark
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.08)
                        : const Color(0xFFF3F4F9)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color:
                  isSelected
                      ? theme.primaryColor
                      : (isDark ? Colors.transparent : const Color(0xFFE2E4EA)),
              width: 1,
            ),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: theme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                    : [],
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            textAlign: TextAlign.left,
            style: TextStyle(
              color:
                  isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              height: 1.2,
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
    String? errorText,
  }) {
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          onChanged: (value) {
            // Auto-strip non-digits for mobile number
            if (_selectedMethodIndex == 1) {
              final cleanValue = value.replaceAll(RegExp(r'\D'), '');
              if (cleanValue != value) {
                controller.value = TextEditingValue(
                  text: cleanValue,
                  selection: TextSelection.collapsed(offset: cleanValue.length),
                );
              }
            }
            _clearInputError();
          },
          style: TextStyle(
            color: isDark ? Colors.white : colorScheme.onSurface,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
          keyboardType: _selectedMethodIndex == 1
              ? TextInputType.number
              : TextInputType.text,
          maxLength: _selectedMethodIndex == 1 ? 10 : null,
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
            filled: false,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            counterText: _selectedMethodIndex == 1 ? '' : null,
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.onSurface.withValues(alpha: 0.25),
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
              style: const TextStyle(color: Colors.red, fontSize: 12),
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

  void _submitForgotPassword(BuildContext context) {
    setState(() {
      _inputError = null;
    });

    final inputValue = _inputController.text;

    // Common validation: empty field
    if (inputValue.isEmpty) {
      setState(() {
        _inputError = '$_currentLabel is required';
      });
      return;
    }

    // Common validation: only spaces
    if (inputValue.trim().isEmpty) {
      setState(() {
        _inputError = '$_currentLabel cannot be only spaces';
      });
      return;
    }

    // Method-specific validations
    switch (_selectedMethodIndex) {
      case 0: // Email
        final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
        if (!emailRegex.hasMatch(inputValue.trim())) {
          setState(() {
            _inputError = 'Please enter a valid email address';
          });
          return;
        }
        break;

      case 1: // Mobile Number
        final mobileRegex = RegExp(r'^\d{10}$');
        final cleanMobile = inputValue.replaceAll(RegExp(r'\D'), '');
        if (!mobileRegex.hasMatch(cleanMobile)) {
          setState(() {
            _inputError = 'Mobile number must be exactly 10 digits';
          });
          return;
        }
        // Update controller with cleaned value
        _inputController.text = cleanMobile;
        break;

      case 2: // Student ID
        final studentIdRegex = RegExp(r'^[0-9]+$');
        if (!studentIdRegex.hasMatch(inputValue.trim())) {
          setState(() {
            _inputError = 'Student ID must contain only numbers';
          });
          return;
        }
        break;
    }

    context.read<ForgotPasswordBloc>().add(
      ForgotPasswordSubmitted(
        methodIndex: _selectedMethodIndex,
        inputValue: _inputController.text.trim(),
      ),
    );
  }
}
