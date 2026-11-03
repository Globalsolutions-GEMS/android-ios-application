import 'package:flutter/material.dart';
import 'package:erp_app/Core/theme/app_theme.dart';
import 'package:erp_app/Core/widgets/profile_menu_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:erp_app/Features/Dashboard/Faculty Dashboard/screens/faculty_dashboard_screen.dart';
import 'package:erp_app/Features/Faculty/Attendance/screens/mark_attendance_screen.dart';
import 'package:erp_app/Features/Faculty/Syllabus Upload/screens/create_syllabus_screen.dart';

enum FacultyMenuItem {
  dashboard,
  markAttendance,
  syllabusUpload,
  subjects,
  schedule,
  reports,
}

class _MenuCardData {
  const _MenuCardData({
    required this.item,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.tint,
  });

  final FacultyMenuItem item;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color tint;
}

/// Faculty home/menu screen.
///
/// Pass [onMenuTap] to connect each card to its existing screen.
class FacultyHomeMenuScreen extends StatefulWidget {
  const FacultyHomeMenuScreen({
    super.key,
    this.onMenuTap,
  });

  final ValueChanged<FacultyMenuItem>? onMenuTap;

  static const Color grey = Color(0xFF64748B);
  static const Color dark = Color(0xFF0F172A);
  static const Color background = Color(0xFFF6F7FB);

  static const List<_MenuCardData> _menuItems = [
    _MenuCardData(
      item: FacultyMenuItem.dashboard,
      title: 'Dashboard',
      subtitle: 'Lectures and progress',
      icon: Icons.space_dashboard_rounded,
      color: Color(0xFF7656E8),
      tint: Color(0xFFF5F3FF),
    ),
    _MenuCardData(
      item: FacultyMenuItem.markAttendance,
      title: 'Mark Attendance',
      subtitle: 'Record student attendance',
      icon: Icons.fact_check_rounded,
      color: Color(0xFF0EA5E9),
      tint: Color(0xFFE0F2FE),
    ),
    _MenuCardData(
      item: FacultyMenuItem.syllabusUpload,
      title: 'Syllabus Upload',
      subtitle: 'Manage units and topics',
      icon: Icons.upload_file_rounded,
      color: Color(0xFF16A34A),
      tint: Color(0xFFDCFCE7),
    ),
    _MenuCardData(
      item: FacultyMenuItem.subjects,
      title: 'My Subjects',
      subtitle: 'Assigned subjects',
      icon: Icons.menu_book_rounded,
      color: Color(0xFFE78628),
      tint: Color(0xFFFFF3E7),
    ),
    _MenuCardData(
      item: FacultyMenuItem.schedule,
      title: 'My Schedule',
      subtitle: 'Today and weekly schedule',
      icon: Icons.calendar_month_rounded,
      color: Color(0xFFE34F83),
      tint: Color(0xFFFFEEF4),
    ),
    _MenuCardData(
      item: FacultyMenuItem.reports,
      title: 'Reports',
      subtitle: 'Academic summaries',
      icon: Icons.analytics_rounded,
      color: Color(0xFF079EAC),
      tint: Color(0xFFE7F8FA),
    ),
  ];

  @override
  State<FacultyHomeMenuScreen> createState() => _FacultyHomeMenuScreenState();
}

class _FacultyHomeMenuScreenState extends State<FacultyHomeMenuScreen> {
  // Dynamic fields
  String _instituteName = '';
  String _instituteAddress = '';
  String _facultyName = '';
  String _lastLoginTime = '';
  DateTime _currentDateTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final preferences = await SharedPreferences.getInstance();
    setState(() {
      _instituteName = preferences.getString('institute_name') ?? '';
      _instituteAddress = preferences.getString('institute_address') ?? '';
      _facultyName = preferences.getString('user_name') ?? '';
      _lastLoginTime = preferences.getString('last_login_time') ?? '';
      _currentDateTime = DateTime.now();
    });
  }

  String _formatLastLogin(String? lastLoginTime) {
    if (lastLoginTime == null || lastLoginTime.isEmpty) {
      return 'First Login';
    }
    try {
      final dateTime = DateTime.parse(lastLoginTime).toLocal();
      return '${dateTime.day} ${_getMonthName(dateTime.month)} ${dateTime.year} at ${_formatTime(dateTime)}';
    } catch (e) {
      return 'First Login';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final formattedHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final formattedMinute = minute.toString().padLeft(2, '0');
    return '$formattedHour:$formattedMinute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FacultyHomeMenuScreen.background,
      appBar: AppBar(
        toolbarHeight: 76,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _instituteName.isNotEmpty ? _instituteName : 'Institute',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (_instituteAddress.trim().isNotEmpty) ...[
              Text(
                _instituteAddress,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: FacultyHomeMenuScreen.grey),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const ProfileMenuButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 14),
            _buildSectionHeader('Quick Access'),
            const SizedBox(height: 10),
            _buildMenuGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppTheme.primaryViolet,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: FacultyHomeMenuScreen.dark,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryViolet.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome back,',
            style: TextStyle(fontSize: 16, color: FacultyHomeMenuScreen.dark),
          ),
          const SizedBox(height: 2),
          Text(
            _facultyName.isNotEmpty ? '$_facultyName!' : 'Faculty!',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: FacultyHomeMenuScreen.dark,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 16, color: FacultyHomeMenuScreen.grey),
              const SizedBox(width: 6),
              Text(
                '${_currentDateTime.day} ${_getMonthName(_currentDateTime.month)} ${_currentDateTime.year}',
                style: const TextStyle(fontSize: 13, color: FacultyHomeMenuScreen.grey),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: FacultyHomeMenuScreen.grey),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Last login: ${_formatLastLogin(_lastLoginTime)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: FacultyHomeMenuScreen.grey),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 11) / 2;
        return Wrap(
          spacing: 11,
          runSpacing: 11,
          children: FacultyHomeMenuScreen._menuItems.map((data) {
            return SizedBox(
              width: cardWidth,
              child: _MenuCard(
                data: data,
                onTap: () {
                  if (data.item == FacultyMenuItem.dashboard) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FacultyDashboardScreen(),
                      ),
                    );
                  } else if (data.item == FacultyMenuItem.markAttendance) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MarkAttendanceScreen(),
                      ),
                    );
                  } else if (data.item == FacultyMenuItem.syllabusUpload) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateSyllabusScreen(),
                      ),
                    );
                  } else {
                    widget.onMenuTap?.call(data.item);
                  }
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.data, required this.onTap});

  final _MenuCardData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: const Color(0xFFF0F1F5)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x080F172A),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 39,
                    height: 39,
                    decoration: BoxDecoration(
                      color: data.tint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(data.icon, color: data.color, size: 22),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: data.color,
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                data.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: FacultyHomeMenuScreen.dark,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                data.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: FacultyHomeMenuScreen.grey,
                  fontSize: 10.5,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


