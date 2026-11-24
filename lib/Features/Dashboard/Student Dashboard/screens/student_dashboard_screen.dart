import 'package:flutter/material.dart';
import 'package:erp_app/Core/theme/app_theme.dart';
import 'package:erp_app/Core/widgets/app_bottom_nav.dart';
import 'package:erp_app/Core/widgets/app_drawer.dart';
import 'package:erp_app/Core/widgets/profile_menu_button.dart';
import 'package:erp_app/Features/Dashboard/Student%20Dashboard/screens/qr_scan_screen.dart';

// Dashboard for students
class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  int _selectedIndex = 0;

  // Open camera to scan the teacher's QR
  void _openQrScan() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const QrScanScreen()),
    );
  }

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
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Welcome to Student Dashboard',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.qr_code_scanner_rounded, size: 32),
                title: const Text('Scan QR'),
                subtitle: const Text('Mark your attendance'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _openQrScan,
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openQrScan,
          icon: const Icon(Icons.qr_code_scanner_rounded),
          label: const Text('Scan QR'),
        ),
        bottomNavigationBar: AppBottomNav(
          role: NavRole.student,
          selectedIndex: _selectedIndex,
          onSelected: (i) => setState(() => _selectedIndex = i),
        ),
      );
}