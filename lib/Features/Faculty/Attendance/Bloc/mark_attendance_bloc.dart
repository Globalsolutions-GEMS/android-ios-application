import 'package:erp_app/Features/Dashboard/Faculty Dashboard/Model/faculty_dashboard_model.dart';
import 'package:erp_app/Features/Faculty/Attendance/Bloc/mark_attendance_event.dart';
import 'package:erp_app/Features/Faculty/Attendance/Bloc/mark_attendance_state.dart';
import 'package:erp_app/Features/Faculty/Attendance/model/mark_attendance_model.dart';
import 'package:erp_app/api_manager/api_checker.dart';
import 'package:erp_app/api_manager/api_client.dart';
import 'package:erp_app/api_manager/api_endPoints.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MarkAttendanceBloc
    extends Bloc<MarkAttendanceEvent, MarkAttendanceState> {
  MarkAttendanceBloc({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient(),
      super(const MarkAttendanceInitial()) {
    on<MarkAttendanceLoadRequested>(_onLoadRequested);
    on<MarkAttendanceSubjectsRequested>(_onSubjectsRequested);
    on<MarkAttendanceGroupSelected>(_onGroupSelected);
    on<MarkAttendanceSubmitRequested>(_onSubmitRequested);
  }

  final ApiClient _apiClient;
  int _subjectsRequestId = 0; // ignores outdated subject responses
  int _studentsRequestId = 0; // ignores outdated student responses

  Future<void> _onLoadRequested(
    MarkAttendanceLoadRequested event,
    Emitter<MarkAttendanceState> emit,
  ) async {
    emit(const MarkAttendanceLoading());

    try {
      // Three calls run in parallel
      final responses = await Future.wait([
        _apiClient.getData(ApiEndPoints.attendanceSessions),
        _apiClient.getData(ApiEndPoints.daySequence),
        _apiClient.getData(ApiEndPoints.attendanceStatusAll),
      ]);

      for (final response in responses) {
        final error = ApiChecker.checkApi(response);
        if (error != null) {
          emit(MarkAttendanceFailure(error));
          return;
        }
      }

      emit(
        MarkAttendanceLoaded(
          sessions: _parseList(
            responses[0].body,
            AttendanceSessionModel.fromJson,
          ),
          days: _parseList(responses[1].body, DayModel.fromJson),
          statuses: _parseList(
            responses[2].body,
            AttendanceStatusModel.fromJson,
          ),
        ),
      );
    } catch (_) {
      emit(const MarkAttendanceFailure('Unable to load attendance data.'));
    }
  }

  Future<void> _onSubjectsRequested(
    MarkAttendanceSubjectsRequested event,
    Emitter<MarkAttendanceState> emit,
  ) async {
    if (state is! MarkAttendanceLoaded) return;
    final requestId = ++_subjectsRequestId;
    _studentsRequestId++; // drop any student load in progress

    // Session or date missing -> clear everything below
    if (event.sessionId == null || event.dayId == null) {
      _update(
        emit,
        (s) => s.copyWith(
          groups: const [],
          groupsLoading: false,
          students: const [],
          topics: const [],
          topicCoverage: const {},
          studentsLoading: false,
          markedStatuses: const {},
          markedTopicId: 0,
        ),
      );
      return;
    }

    _update(
      emit,
      (s) => s.copyWith(
        groups: const [],
        groupsLoading: true,
        students: const [],
        topics: const [],
        topicCoverage: const {},
        studentsLoading: false,
        markedStatuses: const {},
        markedTopicId: 0,
      ),
    );

    try {
      final preferences = await SharedPreferences.getInstance();
      final teacherId = preferences.getInt('user_id');
      if (teacherId == null) {
        _update(
          emit,
          (s) => s.copyWith(
            groupsLoading: false,
            groupsError: 'Please log in again.',
          ),
        );
        return;
      }

      final academicSessionId = await _academicSessionId(preferences);

      final response = await _apiClient.getData(
        '${ApiEndPoints.timeTableByTeacherAndDay}'
        '?teacherId=$teacherId&dayId=${event.dayId}',
      );
      if (requestId != _subjectsRequestId) return; // newer request started

      final error = ApiChecker.checkApi(response);
      if (error != null) {
        _update(emit, (s) => s.copyWith(groupsLoading: false, groupsError: error));
        return;
      }

      // Same filters as the web
      final items = _parseList(response.body, TimetableItemModel.fromJson)
          .where(
            (item) =>
                item.attendanceSessionId == event.sessionId &&
                (academicSessionId == null ||
                    item.academicSessionId == academicSessionId),
          )
          .toList();

      _update(
        emit,
        (s) => s.copyWith(
          groups: SubjectGroupModel.groupFrom(items),
          groupsLoading: false,
        ),
      );
    } catch (_) {
      if (requestId == _subjectsRequestId) {
        _update(
          emit,
          (s) => s.copyWith(
            groupsLoading: false,
            groupsError: 'Unable to load subjects.',
          ),
        );
      }
    }
  }

  Future<void> _onGroupSelected(
    MarkAttendanceGroupSelected event,
    Emitter<MarkAttendanceState> emit,
  ) async {
    if (state is! MarkAttendanceLoaded) return;
    final requestId = ++_studentsRequestId;
    final group = event.group;
    final sessionId = event.sessionId;
    final date = event.date;

    // Subject cleared -> clear students, topics and marked data
    if (group == null || sessionId == null || date == null) {
      _update(
        emit,
        (s) => s.copyWith(
          students: const [],
          topics: const [],
          topicCoverage: const {},
          studentsLoading: false,
          markedStatuses: const {},
          markedTopicId: 0,
        ),
      );
      return;
    }

    _update(
      emit,
      (s) => s.copyWith(
        students: const [],
        topics: const [],
        topicCoverage: const {},
        studentsLoading: true,
        markedStatuses: const {},
        markedTopicId: 0,
      ),
    );

    try {
      final preferences = await SharedPreferences.getInstance();
      final academicSessionId = await _academicSessionId(preferences);
      final count = group.divisions.length;
      final subjectId = group.divisions.first.subjectId;

      // Students per division, topics, marked attendance per division,
      // and all attendance (for the covered lectures count)
      final responses = await Future.wait([
        for (final d in group.divisions)
          _apiClient.getData(
            '${ApiEndPoints.filterStudents}?subjectId=${d.subjectId}'
            '&courseId=${d.courseId}&sectionId=${d.sectionId}'
            '&mediumId=${d.mediumId}',
          ),
        _apiClient.getData(
          '${ApiEndPoints.topicsBySubject}?subjectId=$subjectId',
        ),
        for (final d in group.divisions)
          _apiClient.getData(_detailsUrl(d, sessionId, date)),
        _apiClient.getData(ApiEndPoints.attendanceAll),
      ]);
      if (requestId != _studentsRequestId) return; // newer request started

      // Students and topics must succeed
      for (var i = 0; i <= count; i++) {
        final error = ApiChecker.checkApi(responses[i]);
        if (error != null) {
          _update(
            emit,
            (s) => s.copyWith(studentsLoading: false, studentsError: error),
          );
          return;
        }
      }

      final students = <StudentModel>[];
      for (var i = 0; i < count; i++) {
        students.addAll(
          _parseList(responses[i].body, StudentModel.fromJson).where(
            (s) =>
                academicSessionId == null ||
                s.academicSessionId == academicSessionId,
          ),
        );
      }
      final topics = _parseList(responses[count].body, TopicModel.fromJson);

      // No attendance yet is fine (like the web), so errors are ignored here
      final marked = <int, int>{};
      var markedTopicId = 0;
      for (var i = count + 1; i < responses.length - 1; i++) {
        if (!responses[i].isSuccess) continue;
        final details = AttendanceDetailsModel.fromJson(responses[i].body);
        marked.addAll(details.statuses);
        if (markedTopicId == 0 && details.topicId != null) {
          markedTopicId = details.topicId!;
        }
      }

      // Covered lectures per topic (empty if the call failed, like the web)
      final allAttendance = responses.last;
      final coverage = allAttendance.isSuccess
          ? topicCoverageFrom(
              allAttendance.body,
              subjectId: subjectId,
              academicSessionId: academicSessionId,
            )
          : <int, int>{};

      _update(
        emit,
        (s) => s.copyWith(
          students: students,
          topics: topics,
          topicCoverage: coverage,
          studentsLoading: false,
          markedStatuses: marked,
          markedTopicId: markedTopicId,
        ),
      );
    } catch (_) {
      if (requestId == _studentsRequestId) {
        _update(
          emit,
          (s) => s.copyWith(
            studentsLoading: false,
            studentsError: 'Failed to fetch data for the selected subject.',
          ),
        );
      }
    }
  }

  Future<void> _onSubmitRequested(
    MarkAttendanceSubmitRequested event,
    Emitter<MarkAttendanceState> emit,
  ) async {
    final base = state;
    if (base is! MarkAttendanceLoaded || base.submitting) return;

    final group = event.group;
    final alreadyMarked = base.markedStatuses.keys.toSet();
    final calls = <Future<Response>>[];
    final callStudents = <Map<int, int>>[]; // students sent in each call
    var skipped = 0;

    // One request per division, only for students not yet marked
    for (final d in group.divisions) {
      final divisionIds = base.students
          .where((s) => s.sectionId == d.sectionId)
          .map((s) => s.id)
          .toSet();
      final selected = event.studentStatuses.keys
          .where(divisionIds.contains)
          .toList();
      final toMark = selected.where((id) => !alreadyMarked.contains(id)).toList();
      skipped += selected.length - toMark.length;
      if (toMark.isEmpty) continue;

      final studentMap = {for (final id in toMark) id: event.studentStatuses[id]!};
      callStudents.add(studentMap);
      calls.add(
        _apiClient.postAuthData(
          ApiEndPoints.markAttendance,
          body: {
            'attendanceSessionId': '${event.sessionId}',
            'attendanceDate': event.date,
            'lectureType': event.lectureType,
            'attendanceSlotId': d.slotId,
            'subjectTeacherId': d.subjectTeacherId,
            'sectionId': d.sectionId,
            'topicIds': ['${event.topicId}'],
            'studentAttendanceMap': {
              for (final e in studentMap.entries) '${e.key}': e.value,
            },
          },
        ),
      );
    }

    if (calls.isEmpty) {
      _update(
        emit,
        (s) => s.copyWith(
          submitResult: const SubmitResult(
            success: false,
            message: 'Attendance for all selected students has already been marked',
          ),
        ),
      );
      return;
    }

    _update(emit, (s) => s.copyWith(submitting: true));

    try {
      final results = await Future.wait(calls);
      final marked = {...base.markedStatuses};
      var recorded = 0;
      var failedDivisions = 0;

      for (var i = 0; i < results.length; i++) {
        if (ApiChecker.checkApi(results[i]) == null) {
          marked.addAll(callStudents[i]);
          recorded += callStudents[i].length;
        } else {
          failedDivisions++;
        }
      }

      if (recorded == 0) {
        _update(
          emit,
          (s) => s.copyWith(
            submitting: false,
            submitResult: SubmitResult(
              success: false,
              message: results.length > 1
                  ? 'Failed to record attendance for all divisions.'
                  : 'Failed to submit attendance. Please try again.',
            ),
          ),
        );
        return;
      }

      // Refresh marked data from the server (keeps local data if it fails)
      try {
        final refreshed = await Future.wait([
          for (final d in group.divisions)
            _apiClient.getData(_detailsUrl(d, event.sessionId, event.date)),
        ]);
        if (refreshed.every((r) => r.isSuccess)) {
          for (final r in refreshed) {
            marked.addAll(AttendanceDetailsModel.fromJson(r.body).statuses);
          }
        }
      } catch (_) {}

      // Refresh covered lectures (keeps old counts if it fails)
      var coverage = base.topicCoverage;
      try {
        final preferences = await SharedPreferences.getInstance();
        final academicSessionId = await _academicSessionId(preferences);
        final all = await _apiClient.getData(ApiEndPoints.attendanceAll);
        if (all.isSuccess) {
          coverage = topicCoverageFrom(
            all.body,
            subjectId: group.divisions.first.subjectId,
            academicSessionId: academicSessionId,
          );
        }
      } catch (_) {}

      var message = group.divisions.length > 1
          ? 'Attendance recorded for $recorded student(s) across '
                '${results.length - failedDivisions} division(s)!'
          : 'Attendance recorded successfully for $recorded student(s)!';
      if (skipped > 0) message += ' ($skipped already marked, skipped)';
      if (failedDivisions > 0) {
        message += ' Failed for $failedDivisions division(s).';
      }

      _update(
        emit,
        (s) => s.copyWith(
          submitting: false,
          markedStatuses: marked,
          markedTopicId: event.topicId,
          topicCoverage: coverage,
          submitResult: SubmitResult(success: true, message: message),
        ),
      );
    } catch (_) {
      _update(
        emit,
        (s) => s.copyWith(
          submitting: false,
          submitResult: const SubmitResult(
            success: false,
            message: 'Failed to submit attendance. Please try again.',
          ),
        ),
      );
    }
  }

  // GET /attendance-details for one division
  String _detailsUrl(TimetableItemModel d, int sessionId, String date) =>
      '${ApiEndPoints.attendanceDetails}?attendanceSessionId=$sessionId'
      '&attendanceDate=$date&slotAllotmentId=${d.slotId}'
      '&subjectTeacherId=${d.subjectTeacherId}&sectionId=${d.sectionId}';

  // Current academic session (saved by the dashboard, else fetched)
  Future<int?> _academicSessionId(SharedPreferences preferences) async {
    final saved = preferences.getInt('academic_session_id');
    if (saved != null) return saved;

    final response = await _apiClient.getData(ApiEndPoints.academicSession);
    if (ApiChecker.checkApi(response) != null) return null;
    return FacultyDashboardCalculator.currentSessionId(response.body);
  }

  // Emits a changed copy of the latest Loaded state
  void _update(
    Emitter<MarkAttendanceState> emit,
    MarkAttendanceLoaded Function(MarkAttendanceLoaded latest) change,
  ) {
    final latest = state;
    if (latest is MarkAttendanceLoaded) emit(change(latest));
  }

  // Converts a JSON list into model objects
  List<T> _parseList<T>(
    dynamic body,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (body is! List) return const [];
    return body.whereType<Map<String, dynamic>>().map(fromJson).toList();
  }
}