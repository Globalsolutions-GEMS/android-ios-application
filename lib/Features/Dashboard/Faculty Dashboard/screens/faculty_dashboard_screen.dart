import 'package:flutter/material.dart';
import 'package:erp_app/Core/theme/app_theme.dart';
import 'package:erp_app/Features/Dashboard/Faculty Dashboard/Bloc/faculty_dashboard_bloc.dart';
import 'package:erp_app/Features/Dashboard/Faculty Dashboard/Bloc/faculty_dashboard_event.dart';
import 'package:erp_app/Features/Dashboard/Faculty Dashboard/Bloc/faculty_dashboard_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:erp_app/Core/widgets/app_bottom_nav.dart';
import 'package:erp_app/Core/widgets/profile_menu_button.dart';
import 'package:erp_app/Features/Dashboard/Faculty Dashboard/Config/quick_link_menu.dart';
import 'package:erp_app/Features/Dashboard/Faculty Dashboard/Model/faculty_dashboard_model.dart'
    show
        FacultyDashboardCalculator,
        QuickLink,
        WeeklyScheduleCell;

// Dashboard for faculty (static UI, API later)
class FacultyDashboardScreen extends StatefulWidget {
  const FacultyDashboardScreen({super.key});

  @override
  State<FacultyDashboardScreen> createState() => _FacultyDashboardScreenState();
}

class _FacultyDashboardScreenState extends State<FacultyDashboardScreen> {
  int _selectedIndex = 0;
  int _scheduleTab = 0; // 0 = Today, 1 = Weekly
  int _attendanceTab = 0; // 0 = Class-wise, 1 = Student-wise
  int? _expandedSubjectId; // For accordion in topics popup


  static const Color _grey = Color(0xFF64748B);
  static const Color _dark = Color(0xFF0F172A);

  // Dynamic fields
  String _instituteName = '';
  String _instituteAddress = '';
  String _facultyName = '';
  String _lastLoginTime = '';
  DateTime _currentDateTime = DateTime.now();
  int? _userId;
  int? _sessionId;

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
      _userId = preferences.getInt('user_id');
      _sessionId = preferences.getInt('academic_session_id');
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

  // ---------- Reusable helpers ----------

  Widget _section({
    required String title,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _dark,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _tintTile({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    String? sub,
    VoidCallback? onTap,
  }) {
    final tile = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: _grey),
                ),
              ),
              if (onTap != null)
                Icon(Icons.touch_app, size: 14, color: color.withValues(alpha: 0.5)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _dark,
            ),
          ),
          if (sub != null)
            Text(sub, style: const TextStyle(fontSize: 11, color: _grey)),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: tile);
    }
    return tile;
  }

  Widget _tabs(List<String> labels, int selected, ValueChanged<int> onTap) {
    return Row(
      children: List.generate(labels.length, (i) {
        final active = i == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onTap(i),
            child: Container(
              margin: EdgeInsets.only(right: i == labels.length - 1 ? 0 : 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color:
                    active
                        ? AppTheme.primaryViolet.withValues(alpha: 0.12)
                        : const Color(0xFFF4F6F8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                labels[i],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? AppTheme.primaryViolet : _grey,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _chip(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

  // ---------- Sections ----------

  Widget _welcomeBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
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
            style: TextStyle(fontSize: 16, color: _dark),
          ),
          const SizedBox(height: 2),
          Text(
            _facultyName.isNotEmpty ? '$_facultyName!' : 'Faculty!',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _dark,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 16, color: _grey),
              const SizedBox(width: 6),
              Text(
                '${_currentDateTime.day} ${_getMonthName(_currentDateTime.month)} ${_currentDateTime.year}',
                style: const TextStyle(fontSize: 13, color: _grey),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: _grey),
              const SizedBox(width: 6),
              Text(
                'Last login: ${_formatLastLogin(_lastLoginTime)}',
                style: const TextStyle(fontSize: 13, color: _grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Single stat card (label + value on the left, icon box on the right)
  Widget _statCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: _grey),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _dark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppTheme.primaryViolet.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppTheme.primaryViolet),
          ),
        ],
      ),
    );
  }

  // Three stat cards in a row (below welcome banner)
  Widget _statsRow() {
    return BlocBuilder<FacultyDashboardBloc, FacultyDashboardState>(
      builder: (context, state) {
        final loading = state is FacultyDashboardLoading;
        String show(int value) => loading ? '-' : '$value';

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _statCard(
                    label: 'Subject Assigned',
                    value: show(state.stats.subjectsAssigned),
                    icon: Icons.menu_book_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _statCard(
                    label: 'Total Student',
                    value: show(state.stats.totalStudents),
                    icon: Icons.groups_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _statCard(
                    label: 'Class This Week',
                    value: show(state.stats.classesThisWeek),
                    icon: Icons.event_available_outlined,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _lectureOverview() {
    return BlocBuilder<FacultyDashboardBloc, FacultyDashboardState>(
      builder: (context, state) {
        return _section(
          title: 'Lecture Overview',
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _tintTile(
                      icon: Icons.calendar_today_outlined,
                      color: AppTheme.primaryViolet,
                      label: 'Today',
                      value:
                          '${state.stats.todayConducted} / ${state.stats.todayTotal}',
                      sub: 'Conducted / Total',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _tintTile(
                      icon: Icons.calendar_month_outlined,
                      color: const Color(0xFF0EA5E9),
                      label: 'This Month',
                      value:
                          '${state.stats.thisMonthConducted} / ${state.stats.thisMonthTotal}',
                      sub: 'Conducted / Total',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _tintTile(
                      icon: Icons.bar_chart_rounded,
                      color: const Color(0xFF16A34A),
                      label: 'Total Lectures',
                      value:
                          '${state.stats.totalConducted} / ${state.stats.totalLectures}',
                      sub: 'Conducted / Total',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _tintTile(
                      icon: Icons.trending_down_rounded,
                      color: const Color(0xFFDC2626),
                      label: 'Missing Today',
                      value:
                          '${(state.stats.todayTotal - state.stats.todayConducted).clamp(0, 999)}',
                      sub: 'Pending',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Completion Progress',
                    style: TextStyle(fontSize: 12, color: _grey),
                  ),
                  Text(
                    '${state.stats.todayConducted} / ${state.stats.todayTotal} lectures',
                    style: TextStyle(fontSize: 12, color: _grey),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value:
                      state.stats.todayTotal == 0
                          ? 0.0
                          : state.stats.todayConducted / state.stats.todayTotal,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE2E8F0),
                  color: AppTheme.primaryViolet,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _subjectOverview() {
    return BlocBuilder<FacultyDashboardBloc, FacultyDashboardState>(
      builder: (context, state) {
        return _section(
          title: 'Subject Overview',
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _tintTile(
                      icon: Icons.menu_book_outlined,
                      color: AppTheme.primaryViolet,
                      label: 'Assigned Subjects',
                      value: '${state.stats.subjectsAssigned}',
                      sub: 'Subjects assigned to you',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _tintTile(
                      icon: Icons.checklist_rounded,
                      color: const Color(0xFF0EA5E9),
                      label: 'Topics Completed',
                      value:
                          '${state.stats.topicsCompleted} / ${state.stats.totalTopics}',
                      sub: 'Tap to view details',
                      onTap: () => _showTopicsCompletedPopup(context, state),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Syllabus Progress',
                    style: TextStyle(fontSize: 12, color: _grey),
                  ),
                  Text(
                    '${state.stats.topicsCompleted} / ${state.stats.totalTopics} topics',
                    style: TextStyle(fontSize: 12, color: _grey),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value:
                      state.stats.totalTopics > 0
                          ? state.stats.topicsCompleted /
                              state.stats.totalTopics
                          : 0.0,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE2E8F0),
                  color: AppTheme.primaryViolet,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _quickLinks() {
    return BlocBuilder<FacultyDashboardBloc, FacultyDashboardState>(
      builder: (context, state) {
        final links = state.quickLinks;
        return _section(
          title: 'Quick Links',
          child:
              links.isEmpty
                  ? const Text(
                    'No quick links assigned.',
                    style: TextStyle(fontSize: 13, color: _grey),
                  )
                  : LayoutBuilder(
                    builder: (context, constraints) {
                      final cardWidth = (constraints.maxWidth - 10) / 2;
                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children:
                            links
                                .map(
                                  (link) =>
                                      _quickLinkCard(context, link, cardWidth),
                                )
                                .toList(),
                      );
                    },
                  ),
        );
      },
    );
  }

  Widget _quickLinkCard(BuildContext context, QuickLink link, double width) {
    final menu = quickLinkMenus[link.menuUniqueId];
    final title = menu?.title ?? 'Not available in app';

    return SizedBox(
      width: width,
      child: Material(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (menu == null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content: Text('This page is not available in the app yet.'),
                  ),
                );
              return;
            }
            Navigator.push(context, MaterialPageRoute(builder: menu.builder));
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
            child: Row(
              children: [
                const Icon(Icons.link, size: 18, color: AppTheme.primaryViolet),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _dark,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Colors.red,
                  ),
                  onPressed:
                      () => _confirmDeleteQuickLink(context, link.id, title),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteQuickLink(
    BuildContext context,
    int id,
    String title,
  ) async {
    final bloc = context.read<FacultyDashboardBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Remove Quick Link'),
            content: Text('Remove "$title" from your Quick Links?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Remove'),
              ),
            ],
          ),
    );
    if (confirmed == true) bloc.add(QuickLinkDeleteRequested(id));
  }

  Widget _scheduleBanner() {
    return BlocBuilder<FacultyDashboardBloc, FacultyDashboardState>(
      builder: (context, state) {
        // Dynamically calculate next class based on current time
        final nextClass =
            (_userId != null && _sessionId != null)
                ? FacultyDashboardCalculator.calculateNextClass(
                  timeTableBody: state.timetableData,
                  preferencesBody: state.preferencesData,
                  userId: _userId!,
                  sessionId: _sessionId!,
                )
                : null;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryViolet,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    nextClass != null ? "Next Class" : "Today's Schedule",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (nextClass != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Upcoming',
                        style: TextStyle(
                          color: AppTheme.primaryViolet,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (nextClass != null) ...[
                Text(
                  '${nextClass.subjectName} (${nextClass.subjectCode})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${nextClass.fromTime} - ${nextClass.toTime}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      nextClass.roomName,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.people, size: 16, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      '${nextClass.studentCount} students',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const Text(
                  'No upcoming classes',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 4),
                const Text(
                  'You have completed all scheduled classes for today',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _lectureCard({
    required String time,
    required String name,
    required String room,
    required String students,
    required String courseName,
    required List<String> divisions,
    required String subjectType,
  }) {
    final divisionsText = divisions.join(', ');
    final isPractical = subjectType.toLowerCase() == 'practical';
    final badgeColor =
        isPractical ? const Color(0xFF16A34A) : AppTheme.primaryViolet;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: _grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  time,
                  style: const TextStyle(fontSize: 12, color: _grey),
                ),
              ),
              _chip(subjectType, badgeColor, Colors.white),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _dark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$courseName  |  Divisions: $divisionsText',
            style: const TextStyle(fontSize: 12, color: _grey),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: _grey),
              const SizedBox(width: 4),
              Text(room, style: const TextStyle(fontSize: 12, color: _grey)),
              const SizedBox(width: 12),
              const Icon(Icons.people_outline, size: 14, color: _grey),
              const SizedBox(width: 4),
              Text(
                students,
                style: const TextStyle(fontSize: 12, color: _grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scheduleSection() {
    return BlocBuilder<FacultyDashboardBloc, FacultyDashboardState>(
      builder: (context, state) {
        return _section(
          title: 'Schedule',
          trailing: const Text(
            'View All',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.primaryViolet,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: Column(
            children: [
              _tabs(
                ['Today', 'Weekly'],
                _scheduleTab,
                (i) => setState(() => _scheduleTab = i),
              ),
              const SizedBox(height: 12),
              if (_scheduleTab == 0) ...[
                // Today's Schedule
                if (state.todaySchedule.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No schedule for today.',
                      style: TextStyle(fontSize: 13, color: _grey),
                    ),
                  )
                else
                  ...state.todaySchedule.map((lecture) {
                    return _lectureCard(
                      time: '${lecture.fromTime} - ${lecture.toTime}',
                      name: '${lecture.subjectName} (${lecture.subjectCode})',
                      room: lecture.roomName,
                      students: '${lecture.totalStudents} students',
                      courseName: lecture.courseName,
                      divisions: lecture.divisions,
                      subjectType: lecture.subjectType,
                    );
                  }),
              ] else ...[
                // Weekly Schedule
                if (state.weeklySchedule.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No weekly schedule available.',
                      style: TextStyle(fontSize: 13, color: _grey),
                    ),
                  )
                else
                  _weeklyScheduleTable(state.weeklySchedule),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _weeklyScheduleTable(
    Map<String, Map<String, WeeklyScheduleCell>> weeklySchedule,
  ) {
    final timeSlots = FacultyDashboardCalculator.getUniqueTimeSlots(
      weeklySchedule,
    );
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 12,
        horizontalMargin: 8,
        headingRowHeight: 40,
        dataRowMinHeight: 90,
        dataRowMaxHeight: 90,
        border: TableBorder.all(color: const Color(0xFFE2E8F0), width: 1),
        columns: [
          const DataColumn(
            label: Text(
              'Time',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _dark,
              ),
            ),
          ),
          ...days.map(
            (day) => DataColumn(
              label: Text(
                day.substring(0, 3),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _dark,
                ),
              ),
            ),
          ),
        ],
        rows:
            timeSlots.map((slot) {
              final slotKey = '${slot.fromTime}-${slot.toTime}';
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      '${slot.fromTime} - ${slot.toTime}',
                      style: const TextStyle(fontSize: 11, color: _grey),
                    ),
                  ),
                  ...days.map((day) {
                    final cell = weeklySchedule[day]?[slotKey];
                    if (cell == null) {
                      return const DataCell(
                        Text('-', style: TextStyle(fontSize: 11, color: _grey)),
                      );
                    }
                    final isPractical =
                        cell.subjectType.toLowerCase() == 'practical';
                    final badgeColor =
                        isPractical
                            ? const Color(0xFF16A34A)
                            : AppTheme.primaryViolet;

                    return DataCell(
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                cell.subjectName,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _dark,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              cell.courseName,
                              style: const TextStyle(
                                fontSize: 10,
                                color: _grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1),
                            Text(
                              cell.roomName,
                              style: const TextStyle(
                                fontSize: 10,
                                color: _grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            _chip(cell.subjectType, badgeColor, Colors.white),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              );
            }).toList(),
      ),
    );
  }

  Widget _legendDot(Color c, String t) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(t, style: const TextStyle(fontSize: 12, color: _grey)),
    ],
  );

  Widget _barChart(List<String> labels, List<double> values, Color color) {
    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(labels.length, (i) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '${values[i].round()}',
                style: const TextStyle(fontSize: 11, color: _grey),
              ),
              const SizedBox(height: 2),
              Container(
                width: 36,
                height: values[i] * 0.9,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                labels[i],
                style: const TextStyle(fontSize: 11, color: _grey),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _attendanceSection() {
    return BlocBuilder<FacultyDashboardBloc, FacultyDashboardState>(
      builder: (context, state) {
        final overallAttendance = state.overallAttendance;
        final classWiseAttendance = state.classWiseAttendance;

        // Calculate donut chart present ratio
        final total = overallAttendance.total;
        final presentRatio = total > 0 ? overallAttendance.present / total : 0.0;

        // Prepare bar chart data
        final barLabels = classWiseAttendance.map((stat) => stat.label).toList();
        final barValues = classWiseAttendance.map((stat) => stat.percentage).toList();

        return _section(
          title: 'Attendance Management',
          child: Column(
            children: [
              _tabs(
                ['Class-wise View', 'Student-wise View'],
                _attendanceTab,
                (i) => setState(() => _attendanceTab = i),
              ),
              const SizedBox(height: 16),
              if (_attendanceTab == 0) ...[
                // Class-wise View
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CustomPaint(
                    painter: _DonutPainter(
                      present: presentRatio,
                      presentColor: const Color(0xFF16A34A),
                      absentColor: const Color(0xFFDC2626),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _legendDot(const Color(0xFF16A34A), 'Present'),
                    const SizedBox(width: 16),
                    _legendDot(const Color(0xFFDC2626), 'Absent'),
                  ],
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Class-wise Statistics (%)',
                    style: TextStyle(fontSize: 12, color: _grey),
                  ),
                ),
                const SizedBox(height: 8),
                if (barLabels.isEmpty)
                  const Text(
                    'No attendance data available',
                    style: TextStyle(fontSize: 13, color: _grey),
                  )
                else
                  _barChart(barLabels, barValues, AppTheme.primaryViolet),
              ] else ...[
                // Student-wise View (placeholder for now)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    'Student-wise view coming soon',
                    style: TextStyle(fontSize: 13, color: _grey),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _assessmentSection() {
    return BlocBuilder<FacultyDashboardBloc, FacultyDashboardState>(
      builder: (context, state) {
        final pendingTests = state.pendingTests;
        final pendingAssignments = state.pendingAssignments;

        return _section(
          title: 'Assessment & Marks Entry',
          trailing: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryViolet,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 34),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('+ Create New', style: TextStyle(fontSize: 12)),
          ),
          child: Column(
            children: [
              // Tests Section
              if (pendingTests.isEmpty)
                const Text(
                  'No descriptive tests available',
                  style: TextStyle(fontSize: 13, color: _grey),
                )
              else
                ...pendingTests.map((test) => _testCard(test)),
              const SizedBox(height: 8),
              // Assignments Section
              if (pendingAssignments.isEmpty)
                const Text(
                  'No ended assignments',
                  style: TextStyle(fontSize: 13, color: _grey),
                )
              else
                ...pendingAssignments.map((assignment) => _assignmentCard(assignment)),
            ],
          ),
        );
      },
    );
  }

  Widget _testCard(dynamic test) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  test.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _dark,
                  ),
                ),
              ),
              _chip(
                '${test.questionType} Test',
                AppTheme.primaryViolet,
                Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Subject: ${test.subjectName}',
            style: const TextStyle(fontSize: 12, color: _grey),
          ),
          Text(
            'Course: ${test.courseName}',
            style: const TextStyle(fontSize: 12, color: _grey),
          ),
          Text(
            'Max Marks: ${test.maxMarks}',
            style: const TextStyle(fontSize: 12, color: _grey),
          ),
          Text(
            'Duration: ${test.durationMinutes} min',
            style: const TextStyle(fontSize: 12, color: _grey),
          ),
          Text(
            '📅 ${test.endDate} ${test.endTime}',
            style: const TextStyle(fontSize: 12, color: _grey),
          ),
          const SizedBox(height: 4),
          Text(
            '${test.submittedCount}/${test.totalStudents} submitted',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _dark,
            ),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: test.submissionProgress,
              minHeight: 5,
              backgroundColor: const Color(0xFFE2E8F0),
              color: const Color(0xFF16A34A),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Navigate to marks entry screen (to be implemented)
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primaryViolet,
                padding: const EdgeInsets.symmetric(vertical: 8),
                side: const BorderSide(color: AppTheme.primaryViolet),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Enter Marks', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _assignmentCard(dynamic assignment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  assignment.assignmentTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _dark,
                  ),
                ),
              ),
              _chip(
                'Assignment',
                const Color(0xFF0EA5E9),
                Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Subject: ${assignment.subjectName}',
            style: const TextStyle(fontSize: 12, color: _grey),
          ),
          Text(
            'Course: ${assignment.courseName}',
            style: const TextStyle(fontSize: 12, color: _grey),
          ),
          Text(
            'Max Marks: ${assignment.assignmentMarks}',
            style: const TextStyle(fontSize: 12, color: _grey),
          ),
          Text(
            'Due: ${assignment.dateOfSubmission}',
            style: const TextStyle(fontSize: 12, color: _grey),
          ),
          const SizedBox(height: 4),
          Text(
            '${assignment.submittedCount}/${assignment.totalStudents} submitted',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _dark,
            ),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: assignment.submissionProgress,
              minHeight: 5,
              backgroundColor: const Color(0xFFE2E8F0),
              color: const Color(0xFF16A34A),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Navigate to evaluation screen (to be implemented)
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primaryViolet,
                padding: const EdgeInsets.symmetric(vertical: 8),
                side: const BorderSide(color: AppTheme.primaryViolet),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Enter Marks', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _taskItem(String title, String? sub, String due, Color dueColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.only(left: 10),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: AppTheme.primaryViolet, width: 2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, color: _dark)),
                if (sub != null)
                  Text(sub, style: const TextStyle(fontSize: 11, color: _grey)),
              ],
            ),
          ),
          _chip(due, dueColor, Colors.white),
        ],
      ),
    );
  }

  Widget _pendingTasks() {
    return _section(
      title: 'Pending Tasks',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Academic',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryViolet,
            ),
          ),
          const SizedBox(height: 8),
          _taskItem(
            'Submit Grade Sheet',
            'CS201 Mid-term grades',
            'Due: Today',
            const Color(0xFFDC2626),
          ),
          _taskItem(
            'Assignment Review',
            'CS301',
            'Due: 2 hours',
            const Color(0xFFF59E0B),
          ),
          _taskItem(
            'Update Syllabus Progress',
            null,
            'Due: Tomorrow',
            const Color(0xFF0EA5E9),
          ),
          const SizedBox(height: 4),
          const Text(
            'Admin',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryViolet,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6F8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'No pending admin tasks',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: _grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpiTile(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: _grey),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _dark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reportsSection() {
    const months = ['Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return _section(
      title: 'Reports & Analytics',
      trailing: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.primaryViolet,
          side: const BorderSide(color: AppTheme.primaryViolet),
          minimumSize: const Size(0, 32),
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        child: const Text('Export Report', style: TextStyle(fontSize: 12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _kpiTile('Syllabus Completion', '90%'),
              const SizedBox(width: 8),
              _kpiTile('Student Satisfaction', '4.5/5'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _kpiTile('Average Attendance', '93%'),
              const SizedBox(width: 8),
              _kpiTile('Assignment Submission', '87%'),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Teaching Performance Tracker',
            style: TextStyle(fontSize: 12, color: _grey),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            children: [
              _legendDot(const Color(0xFF3B82F6), 'Syllabus'),
              _legendDot(const Color(0xFF14B8A6), 'Feedback'),
              _legendDot(const Color(0xFFF59E0B), 'Attendance'),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 150,
            width: double.infinity,
            child: CustomPaint(
              painter: _LinePainter(
                series: const [
                  [85, 80, 83, 88, 90],
                  [0, 1, 3, 5, 7],
                  [95, 92, 93, 94, 95],
                ],
                colors: const [
                  Color(0xFF3B82F6),
                  Color(0xFF14B8A6),
                  Color(0xFFF59E0B),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:
                months
                    .map(
                      (m) => Text(
                        m,
                        style: const TextStyle(fontSize: 11, color: _grey),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 16),
          const Text(
            'Assessment Performance Analytics',
            style: TextStyle(fontSize: 12, color: _grey),
          ),
          const SizedBox(height: 8),
          _barChart(
            ['CS201', 'CS301', 'CS401'],
            [85, 87, 82],
            const Color(0xFF3B82F6),
          ),
        ],
      ),
    );
  }

  Widget _defaulterRow(String name, String course, String att, String score) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _dark,
                  ),
                ),
                Text(
                  course,
                  style: const TextStyle(fontSize: 12, color: _grey),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Attendance: $att',
                style: const TextStyle(fontSize: 12, color: _dark),
              ),
              Text(
                'Latest Score: $score',
                style: const TextStyle(fontSize: 12, color: _dark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _defaulterList() {
    return _section(
      title: 'Defaulter List',
      trailing: const Text(
        'View All',
        style: TextStyle(
          fontSize: 13,
          color: AppTheme.primaryViolet,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: Column(
        children: [
          _defaulterRow('Rohit Singh', 'B.Tech CSE', '65%', '38%'),
          _defaulterRow('Sneha Gupta', 'B.Tech CSE', '55%', '35%'),
          _defaulterRow('Arjun Mehta', 'B.Tech CSE', '68%', '42%'),
        ],
      ),
    );
  }

  // ---------- Topics Completed Popup ----------

  void _showTopicsCompletedPopup(
    BuildContext context,
    FacultyDashboardState state,
  ) {
    // Reset so the sheet always opens collapsed.
    _expandedSubjectId = null;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => StatefulBuilder(
            builder:
                (context, setSheetState) => Container(
                  height: MediaQuery.of(context).size.height * 0.85,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Handle bar
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Header
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 20,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryViolet,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Topics Completed',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: _dark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${state.stats.topicsCompleted} / ${state.stats.totalTopics}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: _grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close, color: _grey),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      // Subject list
                      Expanded(
                        child:
                            state.topicProgressData.isEmpty
                                ? const Center(
                                  child: Text(
                                    'No topics available',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _grey,
                                    ),
                                  ),
                                )
                                : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: state.topicProgressData.length,
                                  itemBuilder: (context, index) {
                                    final subject =
                                        state.topicProgressData[index];
                                    final isExpanded =
                                        _expandedSubjectId == subject.subjectId;

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          // Subject header (tap to expand/collapse)
                                          InkWell(
                                            onTap: () {
                                              setSheetState(() {
                                                _expandedSubjectId =
                                                    isExpanded
                                                        ? null
                                                        : subject.subjectId;
                                              });
                                            },
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                  top: Radius.circular(12),
                                                ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    isExpanded
                                                        ? Icons
                                                            .keyboard_arrow_down
                                                        : Icons
                                                            .keyboard_arrow_right,
                                                    color:
                                                        AppTheme.primaryViolet,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          subject.subjectName,
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 15,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: _dark,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          height: 6,
                                                        ),
                                                        Row(
                                                          children: [
                                                            SizedBox(
                                                              width: 100,
                                                              child: ClipRRect(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                  4,
                                                                ),
                                                                child:
                                                                    LinearProgressIndicator(
                                                                  value: subject
                                                                              .totalCount >
                                                                          0
                                                                      ? subject.completedCount /
                                                                          subject.totalCount
                                                                      : 0.0,
                                                                  minHeight: 6,
                                                                  backgroundColor:
                                                                      const Color(
                                                                            0xFFE2E8F0,
                                                                          ),
                                                                  color: AppTheme
                                                                      .primaryViolet,
                                                                ),
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                width: 8),
                                                            Text(
                                                              '${((subject.completedCount / subject.totalCount) * 100).toInt()}%',
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 11,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: _grey,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                          height: 4,
                                                        ),
                                                        Text(
                                                          '${subject.completedCount} / ${subject.totalCount} topics',
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 11,
                                                                color: _grey,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 6,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          subject.completedCount ==
                                                                  subject
                                                                      .totalCount
                                                              ? const Color(
                                                                0xFF16A34A,
                                                              ).withValues(alpha: 0.1)
                                                              : const Color(
                                                                0xFFF59E0B,
                                                              ).withValues(alpha: 
                                                                0.1,
                                                              ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      subject.completedCount ==
                                                              subject.totalCount
                                                          ? 'Complete'
                                                          : 'In Progress',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            subject.completedCount ==
                                                                    subject
                                                                        .totalCount
                                                                ? const Color(
                                                                  0xFF16A34A,
                                                                )
                                                                : const Color(
                                                                  0xFFF59E0B,
                                                                ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          // Topic list (expanded)
                                          if (isExpanded) ...[
                                            const Divider(
                                              height: 1,
                                              color: Color(0xFFE2E8F0),
                                            ),
                                            ...subject.topics.map((topic) {
                                              return Container(
                                                padding: const EdgeInsets.all(
                                                  16,
                                                ),
                                                decoration: const BoxDecoration(
                                                  border: Border(
                                                    top: BorderSide(
                                                      color: Color(0xFFE2E8F0),
                                                      width: 1,
                                                    ),
                                                  ),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          topic.isCompleted
                                                              ? Icons
                                                                  .check_circle
                                                              : Icons
                                                                  .radio_button_unchecked,
                                                          size: 16,
                                                          color:
                                                              topic.isCompleted
                                                                  ? const Color(
                                                                    0xFF16A34A,
                                                                  )
                                                                  : const Color(
                                                                    0xFFCBD5E1,
                                                                  ),
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            topic.topicName,
                                                            style: TextStyle(
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              color:
                                                                  topic.isCompleted
                                                                      ? _dark
                                                                      : _grey,
                                                            ),
                                                          ),
                                                        ),
                                                        Text(
                                                          '${topic.coveredLectures} / ${topic.requiredLectures}',
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 12,
                                                                color: _grey,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      topic.unitName,
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color: _grey,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            topic.isCompleted
                                                                ? const Color(
                                                                  0xFF16A34A,
                                                                ).withValues(alpha: 
                                                                  0.1,
                                                                )
                                                                : const Color(
                                                                  0xFFF59E0B,
                                                                ).withValues(alpha: 
                                                                  0.1,
                                                                ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              6,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        topic.isCompleted
                                                            ? 'Status: Completed'
                                                            : 'Status: Not completed',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color:
                                                              topic.isCompleted
                                                                  ? const Color(
                                                                    0xFF16A34A,
                                                                  )
                                                                  : const Color(
                                                                    0xFFF59E0B,
                                                                  ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }),
                                          ],
                                        ],
                                      ),
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  // ---------- Build ----------

  @override
  Widget build(BuildContext context) => BlocProvider(
    create:
        (_) =>
            FacultyDashboardBloc()
              ..add(const FacultyDashboardLoadRequested())
              ..add(const QuickLinksLoadRequested()),
    child: BlocListener<FacultyDashboardBloc, FacultyDashboardState>(
      listener: (context, state) {
        if (state is FacultyDashboardFailure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.message),
                action: SnackBarAction(
                  label: 'Retry',
                  onPressed:
                      () => context.read<FacultyDashboardBloc>().add(
                        const FacultyDashboardLoadRequested(),
                      ),
                ),
              ),
            );
        }
        if (state is QuickLinksFailure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: _scaffold(),
    ),
  );

  Widget _scaffold() => Scaffold(
    // drawer: const AppDrawer(),
    appBar: AppBar(
      toolbarHeight: 76,
      titleSpacing: 16,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
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
            //const SizedBox(height: 3),
            Text(
              _instituteAddress,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
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
          _welcomeBanner(),
          _statsRow(),
          _lectureOverview(),
          _subjectOverview(),
          _quickLinks(),
          _scheduleBanner(),
          _scheduleSection(),
          _attendanceSection(),
          _assessmentSection(),
          _pendingTasks(),
          _reportsSection(),
          _defaulterList(),
        ],
      ),
    ),
    bottomNavigationBar: AppBottomNav(
      role: NavRole.faculty,
      selectedIndex: _selectedIndex,
      onSelected: (i) => setState(() => _selectedIndex = i),
    ),
  );
}

// Donut chart for present/absent
class _DonutPainter extends CustomPainter {
  final double present; // 0.0 to 1.0
  final Color presentColor;
  final Color absentColor;

  _DonutPainter({
    required this.present,
    required this.presentColor,
    required this.absentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 22.0;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke;
    const start = -3.14159265 / 2;
    const full = 3.14159265 * 2;

    paint.color = presentColor;
    canvas.drawArc(rect, start, full * present, false, paint);
    paint.color = absentColor;
    canvas.drawArc(
      rect,
      start + full * present,
      full * (1 - present),
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.present != present;
}

// Simple multi-line chart (values 0 to 100)
class _LinePainter extends CustomPainter {
  final List<List<double>> series;
  final List<Color> colors;

  _LinePainter({required this.series, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final grid =
        Paint()
          ..color = const Color(0xFFE2E8F0)
          ..strokeWidth = 1;
    for (int i = 0; i <= 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    for (int s = 0; s < series.length; s++) {
      final data = series[s];
      final line =
          Paint()
            ..color = colors[s]
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..strokeJoin = StrokeJoin.round;
      final path = Path();
      for (int i = 0; i < data.length; i++) {
        final x = size.width * i / (data.length - 1);
        final y = size.height * (1 - data[i] / 100);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, line);
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) => false;
}