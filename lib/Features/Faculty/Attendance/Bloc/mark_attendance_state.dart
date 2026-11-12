import 'package:erp_app/Features/Faculty/Attendance/model/mark_attendance_model.dart';

/// Result of a submit, shown once as a snackbar.
class SubmitResult {
  const SubmitResult({required this.success, required this.message});

  final bool success;
  final String message;
}

sealed class MarkAttendanceState {
  const MarkAttendanceState({
    this.sessions = const [],
    this.days = const [],
    this.statuses = const [],
    this.groups = const [],
    this.groupsLoading = false,
    this.groupsError,
    this.students = const [],
    this.topics = const [],
    this.topicCoverage = const {},
    this.studentsLoading = false,
    this.studentsError,
    this.markedStatuses = const {},
    this.markedTopicId = 0,
    this.submitting = false,
    this.submitResult,
  });

  final List<AttendanceSessionModel> sessions;
  final List<DayModel> days;
  final List<AttendanceStatusModel> statuses;
  final List<SubjectGroupModel> groups; // subject dropdown data
  final bool groupsLoading;
  final String? groupsError;
  final List<StudentModel> students;
  final List<TopicModel> topics;
  final Map<int, int> topicCoverage; // topicId -> lectures done
  final bool studentsLoading;
  final String? studentsError;
  final Map<int, int> markedStatuses; // already marked: studentId -> statusId
  final int markedTopicId; // topic of the marked lecture, 0 = none
  final bool submitting;
  final SubmitResult? submitResult;
}

class MarkAttendanceInitial extends MarkAttendanceState {
  const MarkAttendanceInitial();
}

class MarkAttendanceLoading extends MarkAttendanceState {
  const MarkAttendanceLoading();
}

class MarkAttendanceLoaded extends MarkAttendanceState {
  const MarkAttendanceLoaded({
    required super.sessions,
    required super.days,
    required super.statuses,
    super.groups,
    super.groupsLoading,
    super.groupsError,
    super.students,
    super.topics,
    super.topicCoverage,
    super.studentsLoading,
    super.studentsError,
    super.markedStatuses,
    super.markedTopicId,
    super.submitting,
    super.submitResult,
  });

  /// Lists and flags keep their value when not passed.
  /// groupsError, studentsError and submitResult are always replaced
  /// (null clears them).
  MarkAttendanceLoaded copyWith({
    List<SubjectGroupModel>? groups,
    bool? groupsLoading,
    String? groupsError,
    List<StudentModel>? students,
    List<TopicModel>? topics,
    Map<int, int>? topicCoverage,
    bool? studentsLoading,
    String? studentsError,
    Map<int, int>? markedStatuses,
    int? markedTopicId,
    bool? submitting,
    SubmitResult? submitResult,
  }) {
    return MarkAttendanceLoaded(
      sessions: sessions,
      days: days,
      statuses: statuses,
      groups: groups ?? this.groups,
      groupsLoading: groupsLoading ?? this.groupsLoading,
      groupsError: groupsError,
      students: students ?? this.students,
      topics: topics ?? this.topics,
      topicCoverage: topicCoverage ?? this.topicCoverage,
      studentsLoading: studentsLoading ?? this.studentsLoading,
      studentsError: studentsError,
      markedStatuses: markedStatuses ?? this.markedStatuses,
      markedTopicId: markedTopicId ?? this.markedTopicId,
      submitting: submitting ?? this.submitting,
      submitResult: submitResult,
    );
  }
}

class MarkAttendanceFailure extends MarkAttendanceState {
  const MarkAttendanceFailure(this.message);

  final String message;
}