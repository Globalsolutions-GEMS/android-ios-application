import 'package:erp_app/Core/theme/app_theme.dart';
import 'package:erp_app/Features/Profile/Bloc/profile_bloc.dart';
import 'package:erp_app/Features/Profile/Bloc/profile_event.dart';
import 'package:erp_app/Features/Profile/Bloc/profile_state.dart';
import 'package:erp_app/Features/Profile/model/profile_model.dart';
import 'package:erp_app/Features/Profile/screens/change_password_screen.dart';
import 'package:erp_app/Features/Profile/screens/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileBloc()..add(const ProfileLoadRequested()),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatefulWidget {
  const _ProfileView();

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> {
  static const Color _primary = Color(0xFF6D4AFF);
  static const Color _dark = Color(0xFF172033);
  static const Color _grey = Color(0xFF64748B);
  static const Color _border = Color(0xFFE8EAF0);

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  bool _editing = false;

  // Local copy of the photo (upload / remove update it instantly)
  String? _photo;
  bool _photoInit = false;

  @override
  void dispose() {
    _emailController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  void _startEdit(ProfileModel profile) {
    _emailController.text = profile.email;
    _mobileController.text = profile.mobile;
    setState(() => _editing = true);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    context.read<ProfileBloc>().add(
      ProfileUpdateRequested(
        email: _emailController.text.trim(),
        mobile: _mobileController.text.trim(),
        photoBase64: _photo,
      ),
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
      ),
    );
  }

  Future<void> _confirmRemovePhoto() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(
              Icons.delete_outline,
              color: Colors.red,
              size: 28,
            ),
            SizedBox(width: 12),
            Text(
              'Remove Photo?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: const Text(
          'Your profile photo will be deleted. This action cannot be undone.',
          style: TextStyle(fontSize: 14, color: _grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: _grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      context.read<ProfileBloc>().add(const ProfilePhotoRemoveRequested());
    }
  }

  String _formatLastLogin(String iso) {
    final date = DateTime.tryParse(iso);
    if (date == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour12 = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.day} ${months[date.month - 1]} ${date.year}, '
        '$hour12:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileSaveSuccess) {
          setState(() {
            _editing = false;
            if (state.message == ProfileBloc.photoRemovedMessage) {
              _photo = null;
            }
          });
          _snack(state.message);
        } else if (state is ProfileSaveFailure) {
          _snack(state.message);
        }
      },
      builder: (context, state) {
        final profile = state is ProfileDataState ? state.profile : null;
        if (profile != null && !_photoInit) {
          _photo = profile.photoBase64;
          _photoInit = true;
        }
        final busy = state is ProfileSaving;

        return Scaffold(
          backgroundColor: const Color(0xFFF4F6F8),
          appBar: AppBar(
            title: Text(_editing ? 'Edit Profile' : 'Profile'),
            backgroundColor: AppTheme.primaryViolet,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: profile != null
              ? _content(profile, busy: busy)
              : state is ProfileFailure
              ? _failure(context, state.message)
              : const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  Widget _content(ProfileModel profile, {required bool busy}) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Gradient banner with the header card overlapping it
        Stack(
          children: [
            Container(
              height: 120,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7B61FF), Color(0xFF4A2FD6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 56, 16, 0),
              child: _card(
                child: Column(
                  children: [
                    ProfileAvatar(
                      name: profile.name,
                      photoBase64: _photo,
                      radius: 46,
                      onImageUpdated: (base64) =>
                          setState(() => _photo = base64),
                      onRemove: busy ? null : _confirmRemovePhoto,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      profile.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _dark,
                      ),
                    ),
                    if (profile.role.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          profile.role,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(
                      _editing ? 'Basic Information' : 'About Me',
                    ),
                    const SizedBox(height: 16),
                    _editing ? _editForm(profile, busy) : _viewRows(profile),
                  ],
                ),
              ),
              if (!_editing) ...[
                const SizedBox(height: 16),
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Security'),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ChangePasswordScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.lock_outline, size: 18),
                          label: const Text('Change Password'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _primary,
                            side: const BorderSide(color: _primary),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: _primary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _dark,
          ),
        ),
      ],
    );
  }

  // Read-only view
  Widget _viewRows(ProfileModel profile) {
    final rows = <Widget>[
      if (profile.instituteName.isNotEmpty)
        _infoRow(
          Icons.apartment_outlined,
          'Institute Name',
          profile.instituteName,
        ),
      _infoRow(Icons.person_outline_rounded, 'Full Name', profile.name),
      _infoRow(Icons.email_outlined, 'Email', profile.email),
      _infoRow(Icons.phone_outlined, 'Mobile', profile.mobile),
    ];

    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const Divider(height: 24, color: _border),
          rows[i],
        ],
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _startEdit(profile),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit Profile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Edit mode: email and mobile editable, rest read-only
  Widget _editForm(ProfileModel profile, bool saving) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _infoRow(Icons.person_outline_rounded, 'Full Name', profile.name),
          const Divider(height: 24, color: _border),
          _infoRow(
            Icons.confirmation_number_outlined,
            'Counter',
            profile.counter.toString(),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: _inputDecoration('Email', Icons.email_outlined),
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) return 'Please enter email';
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
                return 'Enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _mobileController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: _inputDecoration('Mobile Number', Icons.phone_outlined),
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) return 'Please enter mobile number';
              if (text.length != 10) return 'Enter a 10 digit mobile number';
              return null;
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: saving
                      ? null
                      : () => setState(() => _editing = false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _grey,
                    side: const BorderSide(color: _border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: _primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: _grey)),
              const SizedBox(height: 2),
              Text(
                value.isEmpty ? '-' : value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _dark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: _grey),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
    );
  }

  Widget _failure(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: const TextStyle(color: _grey)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () =>
                context.read<ProfileBloc>().add(const ProfileLoadRequested()),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
