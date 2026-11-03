import 'package:erp_app/Core/theme/app_theme.dart';
import 'package:erp_app/Features/Profile/Bloc/change_password_bloc.dart';
import 'package:erp_app/Features/Profile/Bloc/change_password_event.dart';
import 'package:erp_app/Features/Profile/Bloc/change_password_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChangePasswordBloc(),
      child: const _ChangePasswordView(),
    );
  }
}

class _ChangePasswordView extends StatefulWidget {
  const _ChangePasswordView();

  @override
  State<_ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<_ChangePasswordView> {
  static const Color _primary = Color(0xFF6D4AFF);
  static const Color _dark = Color(0xFF172033);
  static const Color _grey = Color(0xFF64748B);
  static const Color _border = Color(0xFFE8EAF0);

  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<ChangePasswordBloc>().add(
      ChangePasswordSubmitted(
        currentPassword: _currentController.text,
        newPassword: _newController.text,
      ),
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(AppTheme.showThemedSnackBar(context, message));
  }

  // Same rules as the web form
  String? _validateNew(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Enter new password';
    if (text.length < 8) return 'Minimum 8 characters';
    if (!RegExp(r'[a-z]').hasMatch(text)) return 'Add a lowercase letter';
    if (!RegExp(r'[A-Z]').hasMatch(text)) return 'Add an uppercase letter';
    if (!RegExp(r'[\d\W_]').hasMatch(text)) {
      return 'Add a number, symbol or space';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChangePasswordBloc, ChangePasswordState>(
      listener: (context, state) {
        if (state is ChangePasswordLoaded) {
          _snack(state.message);
          Navigator.of(context).pop();
        } else if (state is ChangePasswordFailed) {
          _snack(state.message);
        }
      },
      builder: (context, state) {
        final loading = state is ChangePasswordLoading;

        return Scaffold(
          backgroundColor: const Color(0xFFF4F6F8),
          appBar: AppBar(
            title: const Text('Change Password'),
            backgroundColor: AppTheme.primaryViolet,
            foregroundColor: Colors.white,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _field(
                        controller: _currentController,
                        label: 'Current password',
                        visible: _showCurrent,
                        onToggle: () =>
                            setState(() => _showCurrent = !_showCurrent),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Enter current password'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      _field(
                        controller: _newController,
                        label: 'New password',
                        visible: _showNew,
                        onToggle: () => setState(() => _showNew = !_showNew),
                        validator: _validateNew,
                      ),
                      const SizedBox(height: 14),
                      _field(
                        controller: _confirmController,
                        label: 'Confirm new password',
                        visible: _showConfirm,
                        onToggle: () =>
                            setState(() => _showConfirm = !_showConfirm),
                        validator: (v) => v != _newController.text
                            ? 'Passwords do not match'
                            : null,
                      ),
                      const SizedBox(height: 18),
                      _requirements(),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: loading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: loading
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Change Password'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: loading
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _grey,
                                side: const BorderSide(color: _border),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required bool visible,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !visible,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline, size: 20, color: _primary),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 20,
            color: _primary,
          ),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary),
        ),
      ),
    );
  }

  Widget _requirements() {
    const rules = [
      'Minimum 8 characters long',
      'At least one lowercase character',
      'At least one uppercase character',
      'At least one number, symbol, or whitespace character',
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Password requirements',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _dark,
            ),
          ),
          const SizedBox(height: 8),
          for (final rule in rules)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline,
                      size: 16, color: _primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rule,
                      style: const TextStyle(fontSize: 12, color: _grey),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
