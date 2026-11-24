import 'package:flutter/material.dart';
import 'package:erp_app/Core/theme/app_theme.dart';
import 'package:erp_app/Core/widgets/profile_menu_button.dart';
import 'package:erp_app/Core/Config/dashboard_menu_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:erp_app/Features/Dashboard/Faculty Dashboard/screens/faculty_dashboard_screen.dart';
import 'package:erp_app/Features/Faculty/Attendance/screens/mark_attendance_screen.dart';
import 'package:erp_app/Features/Faculty/Syllabus Upload/screens/create_syllabus_screen.dart';
import 'package:erp_app/Features/Faculty/E-learning Workarea/screens/workarea_screen.dart';
import 'package:erp_app/api_manager/api_client.dart';
import 'package:erp_app/api_manager/api_endPoints.dart';
import 'package:erp_app/Features/Faculty/E-learning Workarea/screens/subject_selection_screen.dart';
import 'package:erp_app/Features/Faculty/Assignment/screens/assignment_list_screen.dart';
import 'package:erp_app/Features/Faculty/Teaching plan/screens/teaching_plan_screen.dart';
import 'package:erp_app/Features/Faculty/Announcement/screens/announcement_list_screen.dart';

enum FacultyMenuItem {
  dashboard,
  markAttendance,
  syllabusUpload,
  subjects,
  schedule,
  reports,
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
  List<MobileMenuItem> _dynamicMenuItems = [];
  bool _isLoadingMenu = true;
  bool _menuLoadError = false;
  final Set<String> _expandedModules = {}; // Track which modules are expanded

  final ApiClient _apiClient = ApiClient();

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

    // Load dynamic menu after user data
    await _loadDynamicMenu();
  }

  Future<void> _loadDynamicMenu() async {
    final preferences = await SharedPreferences.getInstance();
    final roleId = preferences.getInt('role_id');
    final instituteId = preferences.getInt('institute_id');

    // Default to empty if roleId or instituteId is missing
    if (roleId == null || instituteId == null) {
      setState(() {
        _dynamicMenuItems = [];        _isLoadingMenu = false;
        _menuLoadError = true;
      });
      return;
    }

    // Super Admin (roleId == 1) sees ALL items (no whitelist)
    if (roleId == 1) {
      setState(() {
        _dynamicMenuItems = mobileMenuItems;
        _isLoadingMenu = false;
      });
      return;
    }

    try {
      // Fetch role menus and institute modules in parallel
      final menusResponse = await _apiClient.getData(
        ApiEndPoints.roleMenus(roleId),
      );
      final modulesResponse = await _apiClient.getData(
        ApiEndPoints.instituteModules(instituteId),
      );

      // Extract allowed menu IDs
      final allowedMenuIds = <int>{};
      if (menusResponse.isSuccess && menusResponse.body is List) {
        for (final item in menusResponse.body as List) {
          if (item is Map<String, dynamic>) {
            final dashboardMenu = item['dashboardMenu'];
            if (dashboardMenu is Map<String, dynamic>) {
              final menuUniqueId = dashboardMenu['menuUniqueId'];
              if (menuUniqueId is int) {
                allowedMenuIds.add(menuUniqueId);
              }
            }
          }
        }
      }

    // Extract enabled modules (flatten arrays from response)
      final enabledModules = <String>{};
      if (modulesResponse.isSuccess && modulesResponse.body is List) {
        for (final item in modulesResponse.body as List) {
          if (item is Map<String, dynamic>) {
            final menuTitles = item['menuTitles'];
            if (menuTitles is List) {
              for (final title in menuTitles) {
                if (title is String && title != 'Unknown Module') {
                  enabledModules.add(title);
                }
              }
            }
          }
        }
      }
      // Check if module data is valid (not empty and not just "Unknown Module")
      final hasValidModuleData = enabledModules.isNotEmpty;

      // Get ALL items from master config (no whitelist - matches web logic)
      // Filter by role permissions + institute modules (if module data is valid)
      final filteredItems = mobileMenuItems.where((item) {
        final isRoleAllowed = allowedMenuIds.contains(item.menuUniqueId);
        // If module data is invalid/empty, skip module check (fallback to role permissions only)
        final isModuleEnabled = hasValidModuleData ? enabledModules.contains(item.module) : true;
        return isRoleAllowed && isModuleEnabled;
      }).toList();
      // Cache filtered action IDs for offline/error scenarios
      final filteredIds = filteredItems.map((a) => a.menuUniqueId.toString()).toList();
      await preferences.setStringList('cached_menu_ids', filteredIds);

      setState(() {
        _dynamicMenuItems = filteredItems;
        _isLoadingMenu = false;
        _menuLoadError = false;
      });
    } catch (e) {
      // On error, try to use cached permissions
      final cachedIds = preferences.getStringList('cached_menu_ids');
      if (cachedIds != null && cachedIds.isNotEmpty) {
        final cachedItems = mobileMenuItems.where((item) {
          return cachedIds.contains(item.menuUniqueId.toString());
        }).toList();
        setState(() {
          _dynamicMenuItems = cachedItems;
          _isLoadingMenu = false;
          _menuLoadError = true;
        });
      } else {
        // No cache available - show empty with retry option
        setState(() {
          _dynamicMenuItems = [];
          _isLoadingMenu = false;
          _menuLoadError = true;
        });
      }
    }
  }

  Future<void> _retryLoadMenu() async {
    setState(() {
      _isLoadingMenu = true;
      _menuLoadError = false;
    });
    await _loadDynamicMenu();
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
    if (_isLoadingMenu) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_dynamicMenuItems.isEmpty && _menuLoadError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: FacultyHomeMenuScreen.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Could not load menu',
              style: TextStyle(
                color: FacultyHomeMenuScreen.dark,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _retryLoadMenu,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryViolet,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_dynamicMenuItems.isEmpty) {
      return const Center(
        child: Text(
          'No menu items available',
          style: TextStyle(
            color: FacultyHomeMenuScreen.grey,
            fontSize: 14,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        // Account for outer padding (16px each side) and inner padding (4px each side)
        final availableWidth = screenWidth - 40; // 16 outer + 8 inner + 16 outer
        final cardWidth = (availableWidth - 11) / 2; // Subtract spacing, divide by 2
        
        // Always show Dashboard card first (static, always visible)
        final dashboardCard = _buildDashboardCard(cardWidth);
        
        // Group items by module
        final itemsByModule = <String, List<MobileMenuItem>>{};
        for (final item in _dynamicMenuItems) {
          itemsByModule.putIfAbsent(item.module, () => []).add(item);
        }

        // Build module sections
        final moduleSections = itemsByModule.entries.map((entry) {
          return _buildModuleSection(entry.key, entry.value, cardWidth, screenWidth);
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            dashboardCard,
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryViolet,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Modules',
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...moduleSections,
          ],
        );
      },
    );
  }
Widget _buildDashboardCard(double cardWidth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _navigateToRoute('/faculty-dashboard'),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A0F172A),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7656E8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.space_dashboard_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard',
                        style: TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Lectures and progress',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Color(0xFF64748B),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModuleSection(String moduleName, List<MobileMenuItem> items, double cardWidth, double screenWidth) {
    final isExpanded = _expandedModules.contains(moduleName);
    final moduleInfo = _getModuleInfo(moduleName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Module header (tap to expand/collapse)
        GestureDetector(
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedModules.remove(moduleName);
              } else {
                _expandedModules.add(moduleName);
              }
            });
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x0A0F172A),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: moduleInfo['color'] as Color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(moduleInfo['icon'] as IconData, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        moduleName,
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${items.length} options',
                        style: TextStyle(
                          color: const Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: const Color(0xFF64748B),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Module items (shown when expanded with original card layout in 2x2 grid)
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildCardsInRows(items, cardWidth, screenWidth),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Map<String, dynamic> _getModuleInfo(String moduleName) {
    switch (moduleName) {
      case 'E-learning':
        return {'icon': Icons.school, 'color': const Color(0xFF7656E8)};
      case 'Attendance':
        return {'icon': Icons.how_to_reg, 'color': const Color(0xFF0EA5E9)};
      case 'Academic':
        return {'icon': Icons.menu_book, 'color': const Color(0xFF16A34A)};
      case 'NEP':
        return {'icon': Icons.auto_awesome, 'color': const Color(0xFFE34F83)};
      case 'Exam':
        return {'icon': Icons.assignment, 'color': const Color(0xFFE78628)};
      case 'FeedBack':
        return {'icon': Icons.feedback, 'color': const Color(0xFF8B5CF6)};
      case 'Leave':
        return {'icon': Icons.event_busy, 'color': const Color(0xFFEC4899)};
      case 'Student Clearance':
        return {'icon': Icons.exit_to_app, 'color': const Color(0xFF14B8A6)};
      case 'Scholarship':
        return {'icon': Icons.school, 'color': const Color(0xFFF59E0B)};
      case 'Authorization':
        return {'icon': Icons.admin_panel_settings, 'color': const Color(0xFF6366F1)};
      case 'Settings':
        return {'icon': Icons.settings, 'color': const Color(0xFF64748B)};
      case 'Payroll':
        return {'icon': Icons.payments, 'color': const Color(0xFF10B981)};
      case 'Event':
        return {'icon': Icons.event, 'color': const Color(0xFF8B5CF6)};
      case 'Data Migration':
        return {'icon': Icons.sync, 'color': const Color(0xFF64748B)};
      case 'CHB Teacher Remuneration':
        return {'icon': Icons.attach_money, 'color': const Color(0xFFF59E0B)};
      default:
        return {'icon': Icons.apps, 'color': const Color(0xFF64748B)};
    }
  }

  Widget _buildRegularCard(MobileMenuItem item, double cardWidth) {
    // Define card colors based on module
    Color color;
    Color tint;
    String subtitle;

    switch (item.module) {
      case 'E-learning':
        color = const Color(0xFF7656E8);
        tint = const Color(0xFFF5F3FF);
        subtitle = 'Lectures and progress';
        break;
      case 'Attendance':
        color = const Color(0xFF0EA5E9);
        tint = const Color(0xFFE0F2FE);
        subtitle = 'Record and manage';
        break;
      case 'Academic':
        color = const Color(0xFF16A34A);
        tint = const Color(0xFFDCFCE7);
        subtitle = 'Manage and organize';
        break;
      case 'NEP':
        color = const Color(0xFFE34F83);
        tint = const Color(0xFFFFEEF4);
        subtitle = 'New Education Policy';
        break;
      case 'Exam':
        color = const Color(0xFFE78628);
        tint = const Color(0xFFFFF3E7);
        subtitle = 'Examination management';
        break;
      case 'FeedBack':
        color = const Color(0xFF8B5CF6);
        tint = const Color(0xFFF3E8FF);
        subtitle = 'Feedback management';
        break;
      case 'Leave':
        color = const Color(0xFFEC4899);
        tint = const Color(0xFFFDF2F8);
        subtitle = 'Leave management';
        break;
      case 'Student Clearance':
        color = const Color(0xFF14B8A6);
        tint = const Color(0xFFE0F2FE);
        subtitle = 'Clearance process';
        break;
      case 'Scholarship':
        color = const Color(0xFFF59E0B);
        tint = const Color(0xFFFEF3C7);
        subtitle = 'Scholarship details';
        break;
      case 'Authorization':
        color = const Color(0xFF6366F1);
        tint = const Color(0xFFE0E7FF);
        subtitle = 'Access control';
        break;
      case 'Settings':
        color = const Color(0xFF64748B);
        tint = const Color(0xFFF1F5F9);
        subtitle = 'System settings';
        break;
      case 'Payroll':
        color = const Color(0xFF10B981);
        tint = const Color(0xFFD1FAE5);
        subtitle = 'Salary management';
        break;
      case 'Event':
        color = const Color(0xFF8B5CF6);
        tint = const Color(0xFFF3E8FF);
        subtitle = 'Event management';
        break;
      case 'Data Migration':
        color = const Color(0xFF64748B);
        tint = const Color(0xFFF1F5F9);
        subtitle = 'Data migration';
        break;
      case 'CHB Teacher Remuneration':
        color = const Color(0xFFF59E0B);
        tint = const Color(0xFFFEF3C7);
        subtitle = 'Remuneration details';
        break;
      default:
        color = const Color(0xFF64748B);
        tint = const Color(0xFFF1F5F9);
        subtitle = 'Manage';
    }

    return _MenuCard(
      title: item.title,
      subtitle: subtitle,
      icon: item.icon ?? Icons.dashboard,
      color: color,
      tint: tint,
      onTap: () => _navigateToRoute(item.routeName),
    );
  }

  Widget _buildCardsInRows(List<MobileMenuItem> items, double cardWidth, double screenWidth) {
    final rows = <Widget>[];
    for (int i = 0; i < items.length; i += 2) {
      final leftItem = items[i];
      final rightItem = i + 1 < items.length ? items[i + 1] : null;
      
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: Row(
            children: [
              SizedBox(
                width: cardWidth,
                child: _buildRegularCard(leftItem, cardWidth),
              ),
              const SizedBox(width: 11),
              if (rightItem != null)
                SizedBox(
                  width: cardWidth,
                  child: _buildRegularCard(rightItem, cardWidth),
                )
              else
                SizedBox(width: cardWidth),
            ],
          ),
        ),
      );
    }
    return Column(
      children: rows,
    );
  }

  void _navigateToRoute(String routeName) {
    // Handle navigation based on route name
    switch (routeName) {
      case '/faculty-dashboard':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const FacultyDashboardScreen(),
          ),
        );
        break;
      case '/mark-attendance':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MarkAttendanceScreen(),
          ),
        );
        break;
      case '/create-syllabus':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CreateSyllabusScreen(),
          ),
        );
        break;
      case '/elearning-workarea':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                UserWorkAreaScreen(onCardTap: _onWorkAreaCardTap),
          ),
        );
        break;
      default:
        // For other routes, pass to callback
        widget.onMenuTap?.call(FacultyMenuItem.dashboard);
    }
  }

  void _onWorkAreaCardTap(WorkAreaItem item) {
    if (item.page == 'teachingplan' ||
        item.page == 'assignment' ||
        item.page == 'annoucement') {
      _openWorkAreaSubjects(moduleName: item.title, page: item.page);
    }
  }

  void _openWorkAreaSubjects({
    required String moduleName,
    required String page,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubjectSelectionScreen(
          moduleName: moduleName,
          onSubjectTap: (subject) {
            if (page == 'assignment') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AssignmentListScreen(subject: subject),
                ),
              );
              return;
            }
            if (page == 'teachingplan') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TeachingPlanScreen(subject: subject),
                ),
              );
              return;
            }
            if (page == 'annoucement') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AnnouncementListScreen(subject: subject),
                ),
              );
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$moduleName for ${subject.subjectName}'),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.tint,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color tint;
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
                      color: tint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: color,
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.visible,
                style: const TextStyle(
                  color: FacultyHomeMenuScreen.dark,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.visible,
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