import 'package:erp_app/Features/Login/screens/login_screen.dart';
import 'package:erp_app/Features/Profile/Bloc/profile_bloc.dart';
import 'package:erp_app/Features/Profile/Bloc/profile_event.dart';
import 'package:erp_app/Features/Profile/Bloc/profile_state.dart';
import 'package:erp_app/Features/Profile/model/profile_model.dart';
import 'package:erp_app/Features/Profile/screens/profile_avatar.dart';
import 'package:erp_app/Features/Profile/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Account icon for the dashboard app bars. Opens a small profile popup.
class ProfileMenuButton extends StatelessWidget {
  const ProfileMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileBloc()..add(const ProfileLoadRequested()),
      child: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          final profile = state is ProfileDataState ? state.profile : null;
          return GestureDetector(
            onTap: () => showDialog<void>(
              context: context,
              barrierColor: Colors.black26,
              builder: (_) => const _ProfilePopup(),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: ProfileAvatar(
                name: profile?.name ?? 'User',
                photoBase64: profile?.photoBase64,
                radius: 15,
                showUploadButton: false,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProfilePopup extends StatelessWidget {
  const _ProfilePopup();

  static const Color _primary = Color(0xFF6D4AFF);
  static const Color _dark = Color(0xFF172033);
  static const Color _grey = Color(0xFF64748B);
  static const Color _border = Color(0xFFE8EAF0);
  static const Color _red = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top + kToolbarHeight;

    return BlocProvider(
      create: (_) => ProfileBloc()..add(const ProfileLoadRequested()),
      child: Dialog(
        alignment: Alignment.topRight,
        insetPadding: EdgeInsets.fromLTRB(160, topInset, 12, 0),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: BlocBuilder<ProfileBloc, ProfileState>(
              builder: (context, state) {
                if (state is ProfileDataState) {
                  return _details(context, state.profile);
                }
                if (state is ProfileFailure) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(state.message, style: const TextStyle(color: _grey)),
                    ],
                  );
                }
                return const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _details(BuildContext context, ProfileModel profile) {
    final now = DateTime.now();
    final workingDate =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: ProfileAvatar(
            name: profile.name,
            photoBase64: profile.photoBase64,
            radius: 40,
            showUploadButton: false,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            profile.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _dark,
            ),
          ),
        ),
        if (profile.role.isNotEmpty) ...[
          const SizedBox(height: 6),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
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
          ),
        ],
        const SizedBox(height: 20),
        const Divider(height: 1, color: _border),
        const SizedBox(height: 16),
        _infoItem(Icons.email_outlined, 'Email', profile.email),
        const SizedBox(height: 12),
        _infoItem(Icons.calendar_today_outlined, 'Working Date', workingDate),
        const SizedBox(height: 12),
        _infoItem(
          Icons.confirmation_number_outlined,
          'Counter',
          profile.counter.toString(),
        ),
        const SizedBox(height: 20),

        // My Profile
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              final navigator = Navigator.of(context);
              navigator.pop();
              navigator.push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            icon: const Icon(Icons.person_outline_rounded, size: 18),
            label: const Text('My Profile'),
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
        const SizedBox(height: 12),

        // Divider + Logout row
        const Divider(height: 1, color: _border),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _red.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    size: 16,
                    color: _red,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _red,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: _primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: _grey)),
              const SizedBox(height: 2),
              Text(
                value.isEmpty ? '-' : value,
                style: const TextStyle(
                  fontSize: 13,
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
}