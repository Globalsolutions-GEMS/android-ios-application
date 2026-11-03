import 'package:flutter/material.dart';
import 'package:erp_app/Core/theme/app_theme.dart';
import 'package:erp_app/Core/widgets/app_bottom_nav.dart';
import 'package:erp_app/Core/widgets/app_drawer.dart';
import 'package:erp_app/Core/widgets/profile_menu_button.dart';

// Common dashboard for Admin, Staff and Superadmin
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
        drawer: const AppDrawer(),
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          actions: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none_rounded),
            ),
            const ProfileMenuButton(),
            const SizedBox(width: 8),
          ],
        ),
        body: const Center(
          child: Text(
            'Welcome to Admin Dashboard',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        bottomNavigationBar: AppBottomNav(
          role: NavRole.admin,
          selectedIndex: _selectedIndex,
          onSelected: (i) => setState(() => _selectedIndex = i),
        ),
      );
}
