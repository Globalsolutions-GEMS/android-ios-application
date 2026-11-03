import 'package:erp_app/Features/Faculty/Attendance/model/mark_attendance_model.dart';

sealed class MarkAttendanceEvent {
  const MarkAttendanceEvent();
}

/// Loads attendance sessions, days and statuses.
class MarkAttendanceLoadRequested extends MarkAttendanceEvent {
  const MarkAttendanceLoadRequested();
}

/// Loads the subjects for the selected session + day.
/// If either value is null, the subject list is cleared.
class MarkAttendanceSubjectsRequested extends MarkAttendanceEvent {
  const MarkAttendanceSubjectsRequested({this.sessionId, this.dayId});

  final int? sessionId;
  final int? dayId;
}

/// Loads students, topics and already marked attendance for the subject.
/// A null group (or missing session/date) clears them.
class MarkAttendanceGroupSelected extends MarkAttendanceEvent {
  const MarkAttendanceGroupSelected({this.group, this.sessionId, this.date});

  final SubjectGroupModel? group;
  final int? sessionId;
  final String? date; // yyyy-MM-dd
}

/// Submits attendance for the selected students.
class MarkAttendanceSubmitRequested extends MarkAttendanceEvent {
  const MarkAttendanceSubmitRequested({
    required this.group,
    required this.sessionId,
    required this.date,
    required this.lectureType,
    required this.topicId,
    required this.studentStatuses,
  });

  final SubjectGroupModel group;
  final int sessionId;
  final String date; // yyyy-MM-dd
  final String lectureType;
  final int topicId;
  final Map<int, int> studentStatuses; // selected studentId -> statusId
}