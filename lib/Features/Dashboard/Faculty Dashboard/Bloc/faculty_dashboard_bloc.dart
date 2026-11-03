import 'package:erp_app/Features/Dashboard/Faculty Dashboard/Bloc/faculty_dashboard_event.dart';
import 'package:erp_app/Features/Dashboard/Faculty Dashboard/Bloc/faculty_dashboard_state.dart';
import 'package:erp_app/Features/Dashboard/Faculty Dashboard/Model/faculty_dashboard_model.dart';
import 'package:erp_app/api_manager/api_checker.dart';
import 'package:erp_app/api_manager/api_client.dart';
import 'package:erp_app/api_manager/api_endPoints.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FacultyDashboardBloc
    extends Bloc<FacultyDashboardEvent, FacultyDashboardState> {
  FacultyDashboardBloc({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient(),
      super(const FacultyDashboardInitial()) {
    on<FacultyDashboardLoadRequested>(_onLoadRequested);
    on<QuickLinksLoadRequested>(_onQuickLinksLoad);
    on<QuickLinkDeleteRequested>(_onQuickLinkDelete);
    on<QuickLinkAddRequested>(_onQuickLinkAdd);
  }

  final ApiClient _apiClient;

  // Safe int parse for summary values
  int _toInt(dynamic value) => value is num ? value.toInt() : 0;

  // Helper methods for JSON parsing (match calculator helpers)
  dynamic _at(dynamic json, List<String> path) {
    dynamic current = json;
    for (final key in path) {
      if (current is Map<String, dynamic>) {
        current = current[key];
      } else {
        return null;
      }
    }
    return current;
  }

  int? _asInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Future<void> _onLoadRequested(
    FacultyDashboardLoadRequested event,
    Emitter<FacultyDashboardState> emit,
  ) async {
    emit(
      FacultyDashboardLoading(
        quickLinks: state.quickLinks,
        timetableData: state.timetableData,
        preferencesData: state.preferencesData,
      ),
    );

    try {
      final preferences = await SharedPreferences.getInstance();
      final userId = preferences.getInt('user_id');
      if (userId == null) {
        emit(
          FacultyDashboardFailure(
            'Please log in again.',
            quickLinks: state.quickLinks,
          ),
        );
        return;
      }

      // 1. Current academic session - check if saved in preferences first (like the web app's cookie)
      int? sessionId = preferences.getInt('academic_session_id');

      if (sessionId == null) {
        // If not saved, fetch from API
        final sessionResponse = await _apiClient.getData(
          ApiEndPoints.academicSession,
        );
        final sessionError = ApiChecker.checkApi(sessionResponse);
        if (sessionError != null) {
          emit(
            FacultyDashboardFailure(sessionError, quickLinks: state.quickLinks),
          );
          return;
        }
        sessionId = FacultyDashboardCalculator.currentSessionId(
          sessionResponse.body,
        );
      }

      if (sessionId == null) {
        // No session configured -> nothing to count.
        emit(
          FacultyDashboardLoaded(
            const FacultyDashboardStats(),
            quickLinks: state.quickLinks,
            timetableData: state.timetableData,
            preferencesData: state.preferencesData,
          ),
        );
        return;
      }

      // 2. The data calls run in parallel.
      final responses = await Future.wait([
        _apiClient.getData(ApiEndPoints.allotmentsAll),
        _apiClient.getData(ApiEndPoints.preferenceSelectionsAll),
        _apiClient.getData(ApiEndPoints.timeTable),
        _apiClient.getData(ApiEndPoints.attendanceAll),
        _apiClient.getData(ApiEndPoints.getAllTopics),
        _apiClient.getData(ApiEndPoints.allTests),
        _apiClient.getData(ApiEndPoints.allAssignments),
      ]);
      final allotments = responses[0];
      final selections = responses[1];
      final timeTable = responses[2];
      final attendance = responses[3];
      final topics = responses[4];
      final tests = responses[5];
      final assignments = responses[6];

      // Extract raw data for dynamic Next Class calculation
      final timetableData =
          timeTable.isSuccess
              ? (timeTable.body is List ? timeTable.body as List : [])
              : [];
      final preferencesData =
          selections.isSuccess
              ? (selections.body is List ? selections.body as List : [])
              : [];
      final attendanceData =
          attendance.isSuccess
              ? (attendance.body is List ? attendance.body as List : [])
              : [];

      final errors =
          [
            allotments,
            selections,
            timeTable,
            attendance,
            topics,
            tests,
            assignments,
          ].map(ApiChecker.checkApi).whereType<String>().toList();

      // 3. Check if the selected session has data for this user
      // If not, find the session that actually has data
      if (allotments.isSuccess) {
        final sessionWithData = FacultyDashboardCalculator.findSessionWithData(
          allotments.body,
          userId: userId,
        );
        if (sessionWithData != null && sessionWithData != sessionId) {
          sessionId = sessionWithData;
          // Save this session for future use
          await preferences.setInt('academic_session_id', sessionId);
        }
      }

      // 4. Lecture summary (this month + total) from backend.
      // Called after the final sessionId is decided.
      final summary = await _apiClient.getData(
        '${ApiEndPoints.dashboardSummary}/$userId?sessionId=$sessionId',
      );
      final summaryError = ApiChecker.checkApi(summary);
      if (summaryError != null) errors.add(summaryError);

      final summaryBody = summary.body;
      final summaryMap =
          (summary.isSuccess && summaryBody is Map<String, dynamic>)
              ? summaryBody
              : <String, dynamic>{};

      // A failed call counts as "no data" -> 0 on that card.
      final subjectIds =
          allotments.isSuccess
              ? FacultyDashboardCalculator.assignedSubjectIds(
                allotments.body,
                userId: userId,
                sessionId: sessionId,
              )
              : <int>{};

      // Calculate topic completion
      final topicCompletion =
          (topics.isSuccess && attendance.isSuccess)
              ? FacultyDashboardCalculator.calculateTopicCompletion(
                topicsBody: topics.body,
                attendanceBody: attendance.body,
                assignedSubjectIds: subjectIds,
                sessionId: sessionId,
              )
              : {'completed': 0, 'total': 0};

      // Prepare detailed topic progress for popup
      final topicProgressData =
          (topics.isSuccess && attendance.isSuccess)
              ? FacultyDashboardCalculator.prepareTopicProgressDetails(
                topicsBody: topics.body,
                attendanceBody: attendance.body,
                assignedSubjectIds: subjectIds,
                sessionId: sessionId,
              )
              : <SubjectTopicProgress>[];

     
      // Calculate next class for the "Next Class / Today's Schedule" card
      final nextClass =
          (timeTable.isSuccess && selections.isSuccess)
              ? FacultyDashboardCalculator.calculateNextClass(
                timeTableBody: timeTable.body,
                preferencesBody: selections.body,
                userId: userId,
                sessionId: sessionId,
              )
              : null;

      // Calculate today's schedule and weekly schedule
      final todaySchedule =
          (timeTable.isSuccess && selections.isSuccess)
              ? FacultyDashboardCalculator.calculateTodaySchedule(
                timeTableBody: timeTable.body,
                preferencesBody: selections.body,
                userId: userId,
                sessionId: sessionId,
              )
              : <TodayScheduleLecture>[];

      final weeklySchedule =
          (timeTable.isSuccess)
              ? FacultyDashboardCalculator.calculateWeeklySchedule(
                timeTableBody: timeTable.body,
                userId: userId,
                sessionId: sessionId,
              )
              : <String, Map<String, WeeklyScheduleCell>>{};

      // Calculate attendance statistics for the Attendance Management card
      final overallAttendance =
          (attendance.isSuccess)
              ? FacultyDashboardCalculator.calculateOverallAttendance(
                attendanceBody: attendance.body,
                sessionId: sessionId,
              )
              : const OverallAttendanceStats(present: 0, absent: 0);

      final classWiseAttendance =
          (attendance.isSuccess && selections.isSuccess)
              ? FacultyDashboardCalculator.calculateClassWiseAttendance(
                attendanceBody: attendance.body,
                preferencesBody: selections.body,
                sessionId: sessionId,
              )
              : <ClassAttendanceStats>[];

      // Calculate pending tests and assignments
      final pendingTests = <PendingTest>[];
      final pendingAssignments = <PendingAssignment>[];

      // For tests - simplified version without distributions/student answers
      if (tests.isSuccess) {
        final teacherTests = (tests.body is List ? tests.body as List : [])
            .where((t) =>
                _asInt(_at(t, ['subjectTeacherAllotment', 'ourUsers', 'id'])) == userId &&
                _asInt(_at(t, ['academicSessionId'])) == sessionId)
            .toList();

        pendingTests.addAll(
          FacultyDashboardCalculator.calculatePendingTests(
            testsBody: teacherTests,
            testDistributionsMap: {},
            studentSubmissionMap: {},
            userId: userId,
            sessionId: sessionId,
          ),
        );
      }

      // For assignments - simplified version without submissions
      if (assignments.isSuccess && allotments.isSuccess) {
        final teacherAllotmentIds = (allotments.body is List ? allotments.body as List : [])
            .where((a) => _asInt(_at(a, ['teacherId'])) == userId)
            .map((a) => _asInt(a['id']))
            .whereType<int>()
            .toSet();

        pendingAssignments.addAll(
          FacultyDashboardCalculator.calculatePendingAssignments(
            assignmentsBody: assignments.body is List ? assignments.body as List : [],
            submissionsMap: {},
            teacherAllotmentIds: teacherAllotmentIds,
            sessionId: sessionId,
          ),
        );
      }

      final stats = FacultyDashboardStats(
        subjectsAssigned: subjectIds.length,
        totalStudents:
            selections.isSuccess
                ? FacultyDashboardCalculator.totalStudents(
                  selections.body,
                  subjectIds: subjectIds,
                  sessionId: sessionId,
                )
                : 0,
        classesThisWeek:
            timeTable.isSuccess
                ? FacultyDashboardCalculator.classesThisWeek(
                  timeTable.body,
                  userId: userId,
                  sessionId: sessionId,
                )
                : 0,
        todayTotal:
            timeTable.isSuccess
                ? FacultyDashboardCalculator.todayTotal(
                  timeTable.body,
                  userId: userId,
                  sessionId: sessionId,
                )
                : 0,
        todayConducted:
            attendance.isSuccess
                ? FacultyDashboardCalculator.todayConducted(
                  attendance.body,
                  userId: userId,
                )
                : 0,
        thisMonthConducted: _toInt(summaryMap['thisMonthConducted']),
        thisMonthTotal: _toInt(summaryMap['thisMonthTotal']),
        totalConducted: _toInt(summaryMap['totalConducted']),
        totalLectures: _toInt(summaryMap['totalLectures']),
        topicsCompleted: topicCompletion['completed'] ?? 0,
        totalTopics: topicCompletion['total'] ?? 0,
        nextClass: nextClass,
      );

      if (errors.isEmpty) {
        emit(
          FacultyDashboardLoaded(
            stats,
            topicProgressData: topicProgressData,
            quickLinks: state.quickLinks,
            timetableData: timetableData,
            preferencesData: preferencesData,
            attendanceData: attendanceData,
            todaySchedule: todaySchedule,
            weeklySchedule: weeklySchedule,
            overallAttendance: overallAttendance,
            classWiseAttendance: classWiseAttendance,
            pendingTests: pendingTests,
            pendingAssignments: pendingAssignments,
          ),
        );
      } else {
        emit(
          FacultyDashboardFailure(
            errors.first,
            stats: stats,
            topicProgressData: topicProgressData,
            quickLinks: state.quickLinks,
            timetableData: timetableData,
            preferencesData: preferencesData,
            attendanceData: attendanceData,
            todaySchedule: todaySchedule,
            weeklySchedule: weeklySchedule,
            overallAttendance: overallAttendance,
            classWiseAttendance: classWiseAttendance,
            pendingTests: pendingTests,
            pendingAssignments: pendingAssignments,
          ),
        );
      }
    } catch (_) {
      emit(
        FacultyDashboardFailure(
          'Unable to load dashboard data.',
          quickLinks: state.quickLinks,
        ),
      );
    }
  }

  // Fetch quick links for the logged-in user
  Future<void> _onQuickLinksLoad(
    QuickLinksLoadRequested event,
    Emitter<FacultyDashboardState> emit,
  ) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final userId = preferences.getInt('user_id');
      if (userId == null) return;

      final response = await _apiClient.getData(
        ApiEndPoints.quickLinksByUser(userId),
      );
      final error = ApiChecker.checkApi(response);
      if (error != null) {
        emit(
          QuickLinksFailure(
            error,
            stats: state.stats,
            topicProgressData: state.topicProgressData,
            quickLinks: state.quickLinks,
            timetableData: state.timetableData,
            preferencesData: state.preferencesData,
            attendanceData: state.attendanceData,
            todaySchedule: state.todaySchedule,
            weeklySchedule: state.weeklySchedule,
            overallAttendance: state.overallAttendance,
            classWiseAttendance: state.classWiseAttendance,
            pendingTests: state.pendingTests,
            pendingAssignments: state.pendingAssignments,
          ),
        );
        return;
      }

      final body = response.body;
      final links =
          body is List
              ? body
                  .whereType<Map<String, dynamic>>()
                  .map(QuickLink.fromJson)
                  .toList()
              : <QuickLink>[];

      emit(
        QuickLinksUpdated(
          links,
          stats: state.stats,
          topicProgressData: state.topicProgressData,
          timetableData: state.timetableData,
          preferencesData: state.preferencesData,
          attendanceData: state.attendanceData,
          todaySchedule: state.todaySchedule,
          weeklySchedule: state.weeklySchedule,
          overallAttendance: state.overallAttendance,
          classWiseAttendance: state.classWiseAttendance,
          pendingTests: state.pendingTests,
          pendingAssignments: state.pendingAssignments,
        ),
      );
    } catch (_) {
      emit(
        QuickLinksFailure(
          'Unable to load quick links.',
          stats: state.stats,
          topicProgressData: state.topicProgressData,
          quickLinks: state.quickLinks,
          timetableData: state.timetableData,
          preferencesData: state.preferencesData,
        ),
      );
    }
  }

  // Delete one quick link and remove it from the list
  Future<void> _onQuickLinkDelete(
    QuickLinkDeleteRequested event,
    Emitter<FacultyDashboardState> emit,
  ) async {
    try {
      final response = await _apiClient.deleteData(
        ApiEndPoints.deleteQuickLink(event.id),
      );
      final error = ApiChecker.checkApi(response);
      if (error != null) {
        emit(
          QuickLinksFailure(
            error,
            stats: state.stats,
            topicProgressData: state.topicProgressData,
            quickLinks: state.quickLinks,
            timetableData: state.timetableData,
            preferencesData: state.preferencesData,
            attendanceData: state.attendanceData,
            todaySchedule: state.todaySchedule,
            weeklySchedule: state.weeklySchedule,
            overallAttendance: state.overallAttendance,
            classWiseAttendance: state.classWiseAttendance,
            pendingTests: state.pendingTests,
            pendingAssignments: state.pendingAssignments,
          ),
        );
        return;
      }

      final links = state.quickLinks.where((l) => l.id != event.id).toList();
      emit(
        QuickLinksUpdated(
          links,
          stats: state.stats,
          topicProgressData: state.topicProgressData,
          timetableData: state.timetableData,
          preferencesData: state.preferencesData,
          attendanceData: state.attendanceData,
          todaySchedule: state.todaySchedule,
          weeklySchedule: state.weeklySchedule,
          overallAttendance: state.overallAttendance,
          classWiseAttendance: state.classWiseAttendance,
          pendingTests: state.pendingTests,
          pendingAssignments: state.pendingAssignments,
        ),
      );
    } catch (_) {
      emit(
        QuickLinksFailure(
          'Unable to remove quick link.',
          stats: state.stats,
          topicProgressData: state.topicProgressData,
          quickLinks: state.quickLinks,
          timetableData: state.timetableData,
          preferencesData: state.preferencesData,
        ),
      );
    }
  }

  // Add a quick link, then reload the list
  Future<void> _onQuickLinkAdd(
    QuickLinkAddRequested event,
    Emitter<FacultyDashboardState> emit,
  ) async {
    // Skip if already added
    if (state.quickLinks.any((l) => l.menuUniqueId == event.menuUniqueId)) {
      emit(
        QuickLinksFailure(
          'Already in Quick Links.',
          stats: state.stats,
          topicProgressData: state.topicProgressData,
          quickLinks: state.quickLinks,
          timetableData: state.timetableData,
          preferencesData: state.preferencesData,
          attendanceData: state.attendanceData,
          todaySchedule: state.todaySchedule,
          weeklySchedule: state.weeklySchedule,
          overallAttendance: state.overallAttendance,
          classWiseAttendance: state.classWiseAttendance,
          pendingTests: state.pendingTests,
          pendingAssignments: state.pendingAssignments,
        ),
      );
      return;
    }

    try {
      final preferences = await SharedPreferences.getInstance();
      final userId = preferences.getInt('user_id');
      if (userId == null) return;

      final response = await _apiClient.postData(
        '${ApiEndPoints.quickLinks}?userId=$userId&menuUniqueId=${event.menuUniqueId}',
        authenticated: true,
      );
      final error = ApiChecker.checkApi(response);
      if (error != null) {
        emit(
          QuickLinksFailure(
            error,
            stats: state.stats,
            topicProgressData: state.topicProgressData,
            quickLinks: state.quickLinks,
            timetableData: state.timetableData,
            preferencesData: state.preferencesData,
            attendanceData: state.attendanceData,
            todaySchedule: state.todaySchedule,
            weeklySchedule: state.weeklySchedule,
            overallAttendance: state.overallAttendance,
            classWiseAttendance: state.classWiseAttendance,
            pendingTests: state.pendingTests,
            pendingAssignments: state.pendingAssignments,
          ),
        );
        return;
      }

      // Reload so the list matches the backend (6-link limit applies there)
      add(const QuickLinksLoadRequested());
    } catch (_) {
      emit(
        QuickLinksFailure(
          'Unable to add quick link.',
          stats: state.stats,
          topicProgressData: state.topicProgressData,
          quickLinks: state.quickLinks,
          timetableData: state.timetableData,
          preferencesData: state.preferencesData,
          attendanceData: state.attendanceData,
          todaySchedule: state.todaySchedule,
          weeklySchedule: state.weeklySchedule,
          overallAttendance: state.overallAttendance,
          classWiseAttendance: state.classWiseAttendance,
          pendingTests: state.pendingTests,
          pendingAssignments: state.pendingAssignments,
        ),
      );
    }
  }
}
