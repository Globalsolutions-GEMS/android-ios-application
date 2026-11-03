import 'package:flutter/material.dart';
import 'package:erp_app/Core/theme/app_theme.dart';
import 'package:erp_app/Core/widgets/app_bottom_nav.dart';
import 'package:erp_app/Core/widgets/app_drawer.dart';
import 'package:erp_app/Core/widgets/profile_menu_button.dart';

// Dashboard for students
class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
        drawer: const AppDrawer(),
        appBar: AppBar(
          title: const Text('Student Dashboard'),
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
            'Welcome to Student Dashboard',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        bottomNavigationBar: AppBottomNav(
          role: NavRole.student,
          selectedIndex: _selectedIndex,
          onSelected: (i) => setState(() => _selectedIndex = i),
        ),
      );
}
