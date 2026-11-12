import 'package:erp_app/Features/Dashboard/Faculty Dashboard/Model/faculty_dashboard_model.dart';

sealed class FacultyDashboardState {
  const FacultyDashboardState({
    this.stats = const FacultyDashboardStats(),
    this.topicProgressData = const [],
    this.quickLinks = const [],
    this.timetableData = const [],
    this.preferencesData = const [],
    this.attendanceData = const [],
    this.todaySchedule = const [],
    this.weeklySchedule = const {},
    this.overallAttendance = const OverallAttendanceStats(present: 0, absent: 0),
    this.classWiseAttendance = const [],
    this.pendingTests = const [],
    this.pendingAssignments = const [],
  });

  /// Always safe to read: defaults to 0 for every card.
  final FacultyDashboardStats stats;

  /// Topic progress details grouped by subject for the popup.
  final List<SubjectTopicProgress> topicProgressData;

  /// User's quick links (kept across dashboard reloads).
  final List<QuickLink> quickLinks;

  /// Raw timetable data for dynamic "Next Class" calculation.
  final List<dynamic> timetableData;

  /// Raw preferences data for dynamic student count calculation.
  final List<dynamic> preferencesData;

  /// Raw attendance data for attendance calculations.
  final List<dynamic> attendanceData;

  /// Today's schedule lectures (grouped by slot + subject + course + room).
  final List<TodayScheduleLecture> todaySchedule;

  /// Weekly schedule grid (day -> timeSlot -> cell data).
  final Map<String, Map<String, WeeklyScheduleCell>> weeklySchedule;

  /// Overall attendance statistics for donut chart.
  final OverallAttendanceStats overallAttendance;

  /// Class-wise attendance statistics for bar chart.
  final List<ClassAttendanceStats> classWiseAttendance;

  /// Pending descriptive tests awaiting marks entry.
  final List<PendingTest> pendingTests;

  /// Pending assignments awaiting evaluation.
  final List<PendingAssignment> pendingAssignments;
}

class FacultyDashboardInitial extends FacultyDashboardState {
  const FacultyDashboardInitial();
}

class FacultyDashboardLoading extends FacultyDashboardState {
  const FacultyDashboardLoading({
    List<QuickLink> quickLinks = const [],
    List<dynamic> timetableData = const [],
    List<dynamic> preferencesData = const [],
    List<dynamic> attendanceData = const [],
    List<TodayScheduleLecture> todaySchedule = const [],
    Map<String, Map<String, WeeklyScheduleCell>> weeklySchedule = const {},
    List<PendingTest> pendingTests = const [],
    List<PendingAssignment> pendingAssignments = const [],
  }) : super(
         quickLinks: quickLinks,
         timetableData: timetableData,
         preferencesData: preferencesData,
         attendanceData: attendanceData,
         todaySchedule: todaySchedule,
         weeklySchedule: weeklySchedule,
         pendingTests: pendingTests,
         pendingAssignments: pendingAssignments,
       );
}

class FacultyDashboardLoaded extends FacultyDashboardState {
  const FacultyDashboardLoaded(
    FacultyDashboardStats stats, {
    List<SubjectTopicProgress> topicProgressData = const [],
    List<QuickLink> quickLinks = const [],
    List<dynamic> timetableData = const [],
    List<dynamic> preferencesData = const [],
    List<dynamic> attendanceData = const [],
    List<TodayScheduleLecture> todaySchedule = const [],
    Map<String, Map<String, WeeklyScheduleCell>> weeklySchedule = const {},
    OverallAttendanceStats overallAttendance = const OverallAttendanceStats(present: 0, absent: 0),
    List<ClassAttendanceStats> classWiseAttendance = const [],
    List<PendingTest> pendingTests = const [],
    List<PendingAssignment> pendingAssignments = const [],
  }) : super(
         stats: stats,
         topicProgressData: topicProgressData,
         quickLinks: quickLinks,
         timetableData: timetableData,
         preferencesData: preferencesData,
         attendanceData: attendanceData,
         todaySchedule: todaySchedule,
         weeklySchedule: weeklySchedule,
         overallAttendance: overallAttendance,
         classWiseAttendance: classWiseAttendance,
         pendingTests: pendingTests,
         pendingAssignments: pendingAssignments,
       );
}

/// At least one request failed. [stats] still holds whatever could be
/// computed (0 for the cards that failed).
class FacultyDashboardFailure extends FacultyDashboardState {
  const FacultyDashboardFailure(
    this.message, {
    FacultyDashboardStats stats = const FacultyDashboardStats(),
    List<SubjectTopicProgress> topicProgressData = const [],
    List<QuickLink> quickLinks = const [],
    List<dynamic> timetableData = const [],
    List<dynamic> preferencesData = const [],
    List<dynamic> attendanceData = const [],
    List<TodayScheduleLecture> todaySchedule = const [],
    Map<String, Map<String, WeeklyScheduleCell>> weeklySchedule = const {},
    OverallAttendanceStats overallAttendance = const OverallAttendanceStats(present: 0, absent: 0),
    List<ClassAttendanceStats> classWiseAttendance = const [],
    List<PendingTest> pendingTests = const [],
    List<PendingAssignment> pendingAssignments = const [],
  }) : super(
         stats: stats,
         topicProgressData: topicProgressData,
         quickLinks: quickLinks,
         timetableData: timetableData,
         preferencesData: preferencesData,
         attendanceData: attendanceData,
         todaySchedule: todaySchedule,
         weeklySchedule: weeklySchedule,
         overallAttendance: overallAttendance,
         classWiseAttendance: classWiseAttendance,
         pendingTests: pendingTests,
         pendingAssignments: pendingAssignments,
       );

  final String message;
}

/// Quick links loaded or changed (fetch / delete success).
class QuickLinksUpdated extends FacultyDashboardState {
  const QuickLinksUpdated(
    List<QuickLink> quickLinks, {
    FacultyDashboardStats stats = const FacultyDashboardStats(),
    List<SubjectTopicProgress> topicProgressData = const [],
    List<dynamic> timetableData = const [],
    List<dynamic> preferencesData = const [],
    List<dynamic> attendanceData = const [],
    List<TodayScheduleLecture> todaySchedule = const [],
    Map<String, Map<String, WeeklyScheduleCell>> weeklySchedule = const {},
    OverallAttendanceStats overallAttendance = const OverallAttendanceStats(present: 0, absent: 0),
    List<ClassAttendanceStats> classWiseAttendance = const [],
    List<PendingTest> pendingTests = const [],
    List<PendingAssignment> pendingAssignments = const [],
  }) : super(
         stats: stats,
         topicProgressData: topicProgressData,
         quickLinks: quickLinks,
         timetableData: timetableData,
         preferencesData: preferencesData,
         attendanceData: attendanceData,
         todaySchedule: todaySchedule,
         weeklySchedule: weeklySchedule,
         overallAttendance: overallAttendance,
         classWiseAttendance: classWiseAttendance,
         pendingTests: pendingTests,
         pendingAssignments: pendingAssignments,
       );
}

/// Quick link request failed. Existing data is kept.
class QuickLinksFailure extends FacultyDashboardState {
  const QuickLinksFailure(
    this.message, {
    FacultyDashboardStats stats = const FacultyDashboardStats(),
    List<SubjectTopicProgress> topicProgressData = const [],
    List<QuickLink> quickLinks = const [],
    List<dynamic> timetableData = const [],
    List<dynamic> preferencesData = const [],
    List<dynamic> attendanceData = const [],
    List<TodayScheduleLecture> todaySchedule = const [],
    Map<String, Map<String, WeeklyScheduleCell>> weeklySchedule = const {},
    OverallAttendanceStats overallAttendance = const OverallAttendanceStats(present: 0, absent: 0),
    List<ClassAttendanceStats> classWiseAttendance = const [],
    List<PendingTest> pendingTests = const [],
    List<PendingAssignment> pendingAssignments = const [],
  }) : super(
         stats: stats,
         topicProgressData: topicProgressData,
         quickLinks: quickLinks,
         timetableData: timetableData,
         preferencesData: preferencesData,
         attendanceData: attendanceData,
         todaySchedule: todaySchedule,
         weeklySchedule: weeklySchedule,
         overallAttendance: overallAttendance,
         classWiseAttendance: classWiseAttendance,
         pendingTests: pendingTests,
         pendingAssignments: pendingAssignments,
       );

  final String message;
}
