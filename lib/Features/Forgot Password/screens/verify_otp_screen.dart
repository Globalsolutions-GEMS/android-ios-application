import 'dart:async';
import 'dart:ui';
import 'package:erp_app/Features/Forgot%20Password/BLoc/verify_otp_bloc.dart';
import 'package:erp_app/Features/Forgot%20Password/BLoc/verify_otp_event.dart';
import 'package:erp_app/Features/Forgot%20Password/BLoc/verify_otp_state.dart';
import 'package:erp_app/Features/Forgot%20Password/screens/set_new_password_screen.dart';
import 'package:erp_app/Features/Login/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:erp_app/Core/theme/app_theme.dart';
import 'package:erp_app/Core/theme/system_theme_wrapper.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VerifyOtpScreen extends StatefulWidget {
  const VerifyOtpScreen({super.key});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  int _secondsRemaining = 120;
  Timer? _timer;
  bool _timeExpired = false;
  String? _otpError;
  String? _successMessage;
  String? _otpSource;
  String? _inputValue;
  String? _maskedEmail;
  String? _maskedMobile;

  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    _loadSavedData();
    _startTimer();
  }

  Future<void> _loadSavedData() async {
    final preferences = await SharedPreferences.getInstance();
    setState(() {
      _otpSource = preferences.getString('otpSource');
      _inputValue = preferences.getString('inputValue');
      _maskedEmail = preferences.getString('maskedEmail');
      _maskedMobile = preferences.getString('maskedMobile');
    });
  }

  Future<void> _saveOtp(String otp) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('otp', otp);
    // Also save email, mobile, studentId for reset password screen
    final inputValue = _inputValue ?? '';
    if (_otpSource == 'email') {
      await preferences.setString('email', inputValue);
    } else if (_otpSource == 'mobile') {
      await preferences.setString('mobile', inputValue);
    } else if (_otpSource == 'studentId') {
      await preferences.setString('studentId', inputValue);
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        setState(() {
          _timeExpired = true;
        });
        _timer?.cancel();
      }
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 120;
      _timeExpired = false;
    });
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _formattedTime {
    int min = _secondsRemaining ~/ 60;
    int sec = _secondsRemaining % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VerifyOtpBloc(),
      child: BlocConsumer<VerifyOtpBloc, VerifyOtpState>(
        listener: (context, state) async {
          if (state is VerifyOtpFailure) {
            setState(() {
              _otpError = state.message;
              _successMessage = null;
            });
          }
          if (state is VerifyOtpSuccess) {
            // Check if this is from resend or verify
            if (_timeExpired) {
              // Resend success - reset timer and clear OTP
              _resetTimer();
              for (var controller in _otpControllers) {
                controller.clear();
              }
              // Load saved data first, then update UI
              await _loadSavedData();
              setState(() {
                _successMessage = 'A new OTP has been sent.';
                _otpError = null;
              });
              Future.delayed(const Duration(seconds: 2), () {
                setState(() {
                  _successMessage = null;
                });
              });
            } else {
              // Verify success - navigate to reset password
              setState(() {
                _successMessage = 'OTP verified successfully!';
                _otpError = null;
              });
              // Save OTP and other data for reset password screen
              final otp = _otpControllers.map((c) => c.text).join();
              _saveOtp(otp);
              Future.delayed(const Duration(seconds: 1), () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SetNewPasswordScreen(),
                  ),
                );
              });
            }
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
                          padding: EdgeInsets.symmetric(
                            horizontal:
                                MediaQuery.sizeOf(context).width < 380
                                    ? 16.0
                                    : 24.0,
                            vertical: 32.0,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildIllustration(colorScheme),
                              const SizedBox(height: 20),
                              _buildOtpCard(context, theme, state),
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
          'assets/Animation/verify_otp.json',
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

  Widget _buildOtpCard(
    BuildContext context,
    ThemeData theme,
    VerifyOtpState state,
  ) {
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth < 380 ? 16.0 : 32.0;

    Color getTimerColor() {
      if (_secondsRemaining < 10) return Colors.red;
      if (_secondsRemaining < 30) return Colors.orange;
      return Colors.green;
    }

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
              vertical: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Verify OTP",
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  "Enter the 6-digit code sent to your email/mobile",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _formattedTime,
                    style: TextStyle(
                      color: getTimerColor(),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                if (_otpError != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      _otpError!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),

                if (_successMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      _successMessage!,
                      style: const TextStyle(color: Colors.green, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),

                _buildOtpInputRow(theme),
                const SizedBox(height: 20),

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
                        state is VerifyOtpLoading
                            ? null
                            : _timeExpired
                            ? () => _handleResendOtp(context)
                            : () => _handleVerifyOtp(context),
                    child:
                        state is VerifyOtpLoading
                            ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                            : Text(
                              _timeExpired ? "Resend OTP" : "Verify",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                  ),
                ),
                const SizedBox(height: 16),

                if (_timeExpired)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      "Time is over, please resend OTP",
                      style: TextStyle(color: Colors.red, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),

                _buildInfoBox(theme),
                const SizedBox(height: 16),

                TextButton(
                  onPressed:
                      () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      ),
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

  Widget _buildOtpInputRow(ThemeData theme) {
    return Row(
      children: List.generate(6, (index) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: index == 0 || index == 5 ? 2.0 : 4.0,
            ),
            child: AspectRatio(
              aspectRatio: 0.8,
              child: TextFormField(
                controller: _otpControllers[index],
                focusNode: _focusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  counterText: "",
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color:
                          _otpError != null
                              ? Colors.red
                              : theme.colorScheme.onSurface.withValues(
                                alpha: 0.25,
                              ),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.primaryColor, width: 2),
                  ),
                ),
                onChanged: (value) {
                  if (_timeExpired) return;
                  if (value.isNotEmpty && index < 5) {
                    _focusNodes[index + 1].requestFocus();
                  } else if (value.isEmpty && index > 0) {
                    _focusNodes[index - 1].requestFocus();
                  }
                  if (_otpError != null) {
                    setState(() {
                      _otpError = null;
                    });
                  }
                },
                onTap: () {
                  if (_otpControllers[index].text.isNotEmpty) {
                    _otpControllers[index]
                        .selection = TextSelection.fromPosition(
                      TextPosition(offset: _otpControllers[index].text.length),
                    );
                  }
                },
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildInfoBox(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    if (_otpSource == null || _timeExpired) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color:
            isDark
                ? colorScheme.primary.withValues(alpha: 0.1)
                : const Color(0xFFF0F8FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              isDark
                  ? colorScheme.primary.withValues(alpha: 0.3)
                  : Colors.blue.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            "OTP Sent!",
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          if (_otpSource == 'email')
            Column(
              children: [
                Text(
                  "We've sent a 6-digit code to your registered email:",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.mark_email_unread_rounded,
                      size: 14,
                      color: isDark ? theme.primaryColor : Colors.blue.shade400,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _maskEmail(_maskedEmail ?? _inputValue ?? ''),
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          if (_otpSource == 'mobile')
            Column(
              children: [
                Text(
                  "We've sent a 6-digit code to your registered mobile:",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.phone_android_rounded,
                      size: 14,
                      color: isDark ? theme.primaryColor : Colors.blue.shade400,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _maskMobile(_maskedMobile ?? _inputValue ?? ''),
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          if (_otpSource == 'studentId')
            Column(
              children: [
                Text(
                  "We've sent a 6-digit code to both your registered contacts:",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.mark_email_unread_rounded,
                      size: 14,
                      color: isDark ? theme.primaryColor : Colors.blue.shade400,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _maskEmail(_maskedEmail ?? _inputValue ?? ''),
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.phone_android_rounded,
                      size: 14,
                      color: isDark ? theme.primaryColor : Colors.blue.shade400,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _maskMobile(_maskedMobile ?? _inputValue ?? ''),
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _maskEmail(String email) {
    if (email.isEmpty) return '';
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 3) return email;
    return '${name.substring(0, 3)}****@$domain';
  }

  String _maskMobile(String mobile) {
    if (mobile.isEmpty) return '';
    if (mobile.length <= 4) return mobile;
    return '${mobile.substring(0, 2)}***${mobile.substring(mobile.length - 2)}';
  }

  void _handleVerifyOtp(BuildContext context) {
    final otp = _otpControllers.map((c) => c.text).join();

    if (otp.isEmpty || otp.length != 6) {
      setState(() {
        _otpError = 'Please enter a valid 6-digit OTP';
      });
      return;
    }

    if (_timeExpired) {
      setState(() {
        _otpError = 'OTP has expired. Please request a new one.';
      });
      return;
    }

    String? email;
    String? mobile;
    String? studentId;

    if (_otpSource == 'email') {
      email = _inputValue;
    } else if (_otpSource == 'mobile') {
      mobile = _inputValue;
    } else if (_otpSource == 'studentId') {
      studentId = _inputValue;
    }

    context.read<VerifyOtpBloc>().add(
      VerifyOtpSubmitted(
        otp: otp,
        email: email,
        mobile: mobile,
        studentId: studentId,
        instituteId: '1', // Default institute ID
      ),
    );
  }

  void _handleResendOtp(BuildContext context) {
    String? email;
    String? mobile;
    String? studentId;

    if (_otpSource == 'email') {
      email = _inputValue;
    } else if (_otpSource == 'mobile') {
      mobile = _inputValue;
    } else if (_otpSource == 'studentId') {
      studentId = _inputValue;
    }

    context.read<VerifyOtpBloc>().add(
      ResendOtp(email: email, mobile: mobile, studentId: studentId),
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
}
