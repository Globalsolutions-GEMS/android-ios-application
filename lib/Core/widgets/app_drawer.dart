import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:erp_app/Features/Dashboard/Faculty Dashboard/Bloc/faculty_dashboard_bloc.dart';
import 'package:erp_app/Features/Dashboard/Faculty Dashboard/Bloc/faculty_dashboard_event.dart';
import 'package:erp_app/Features/Login/screens/login_screen.dart';
import 'package:erp_app/Features/Faculty/Syllabus Upload/screens/create_syllabus_screen.dart';
import 'package:erp_app/Features/Faculty/Attendance/screens/mark_attendance_screen.dart';
import 'package:erp_app/Features/Profile/screens/profile_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  static const Color _primary = Color(0xFF6D4AFF);
  static const Color _dark = Color(0xFF172033);
  static const Color _grey = Color(0xFF64748B);
  static const Color _background = Color(0xFFF8FAFC);
  static const Color _border = Color(0xFFE8EAF0);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 310,
      backgroundColor: _background,
      elevation: 8,
      child: SafeArea(
        child: Column(
          children: [
            // Scrollable navigation hierarchy
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 18, 12, 12),
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 12, bottom: 10),
                    child: Text(
                      'MAIN MENU',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: _grey,
                      ),
                    ),
                  ),

                  // Academic
                  _buildExpansionTile(
                    id: 'academic',
                    title: 'Academic',
                    icon: Icons.school_outlined,
                    children: [
                      // Transaction
                      _buildExpansionTile(
                        id: 'academic/transaction',
                        title: 'Transaction',
                        icon: Icons.swap_horiz_rounded,
                        children: [
                          // Administrative Work
                          _buildExpansionTile(
                            id: 'academic/transaction/admin',
                            title: 'Administrative Work',
                            icon: Icons.folder_outlined,
                            children: [
                              // Create Syllabus
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 24,
                                  top: 4,
                                  bottom: 6,
                                ),
                                child: _buildMenuItem(
                                  title: 'Create Syllabus',
                                  icon: Icons.menu_book_rounded,
                                  selected: true,
                                  onPin: () => _addQuickLink(context, 47753959),
                                  onTap: () {
                                    Navigator.pop(context);

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const CreateSyllabusScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Attendance
                  _buildExpansionTile(
                    id: 'attendance',
                    title: 'Attendance',
                    icon: Icons.fact_check_outlined,
                    children: [
                      _buildExpansionTile(
                        id: 'attendance/transaction',
                        title: 'Transaction',
                        icon: Icons.swap_horiz_rounded,
                        children: [
                          _buildExpansionTile(
                            id: 'attendance/transaction/communication',
                            title: 'Communication',
                            icon: Icons.forum_outlined,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 24,
                                  top: 4,
                                  bottom: 6,
                                ),
                                child: _buildMenuItem(
                                  title: 'Mark Attendance',
                                  icon: Icons.how_to_reg_outlined,
                                  onPin: () => _addQuickLink(context, 90280470),
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const MarkAttendanceScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Bottom utility menu
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: _border)),
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    title: 'Profile',
                    icon: Icons.person_outline_rounded,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    title: 'About',
                    icon: Icons.info_outline_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  _buildMenuItem(
                    title: 'Logout',
                    icon: Icons.logout_rounded,
                    iconColor: const Color(0xFFDC2626),
                    textColor: const Color(0xFFDC2626),
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Add a menu item to Quick Links (faculty dashboard only)
  void _addQuickLink(BuildContext context, int menuUniqueId) {
    try {
      context.read<FacultyDashboardBloc>().add(
        QuickLinkAddRequested(menuUniqueId),
      );
      Navigator.pop(context);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quick Links work on the faculty dashboard only.'),
        ),
      );
    }
  }

  // Reusable expandable menu item (always starts closed when the drawer opens)
  Widget _buildExpansionTile({
    required String id,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Theme(
      data: ThemeData(
        splashColor: _primary.withOpacity(0.06),
        highlightColor: _primary.withOpacity(0.04),
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        key: ValueKey(id),
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.only(left: 12),
        visualDensity: const VisualDensity(vertical: -1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        iconColor: _primary,
        collapsedIconColor: _grey,
        leading: Icon(icon, size: 21, color: _grey),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _dark,
          ),
        ),
        children: children,
      ),
    );
  }

  // Reusable regular and selected menu item
  Widget _buildMenuItem({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    VoidCallback? onPin,
    bool selected = false,
    Color? iconColor,
    Color? textColor,
  }) {
    final foreground = textColor ?? (selected ? Colors.white : _grey);

    return Material(
      color: selected ? _primary : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: iconColor ?? foreground),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: foreground,
                  ),
                ),
              ),
              // Add to Quick Links
              if (onPin != null)
                InkWell(
                  onTap: onPin,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.push_pin_outlined,
                      size: 18,
                      color: foreground,
                    ),
                  ),
                ),
              if (selected)
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: Colors.white70,
                ),
            ],
          ),
        ),
      ),
    );
  }
}