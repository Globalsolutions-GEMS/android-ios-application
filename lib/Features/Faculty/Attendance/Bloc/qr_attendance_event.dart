sealed class QrAttendanceEvent {
  const QrAttendanceEvent();
}

/// Teacher taps Generate QR (also used to re-generate).
class QrStartRequested extends QrAttendanceEvent {
  const QrStartRequested({
    required this.sessionId,
    required this.date,
    required this.lectureType,
    required this.defaultStatusId,
    required this.topicId,
    required this.latitude,
    required this.longitude,
    required this.divisions,
  });

  final int sessionId;
  final String date; // yyyy-MM-dd
  final String lectureType;
  final int defaultStatusId;
  final int topicId;
  final double latitude;
  final double longitude;

  /// Each item: subjectTeacherId, sectionId, attendanceSlotId.
  final List<Map<String, int>> divisions;
}

/// Reloads counts and token (called by a timer on the screen).
class QrRefreshRequested extends QrAttendanceEvent {
  const QrRefreshRequested();
}

/// Loads a student list: PRESENT, ABSENT or MARKED. Page 0 replaces the list.
class QrStudentsRequested extends QrAttendanceEvent {
  const QrStudentsRequested({
    required this.filter,
    this.page = 0,
    this.silent = false,
  });

  final String filter;
  final int page;
  final bool silent; // no loading spinner (background refresh)
}

/// Teacher stops the QR.
class QrCloseRequested extends QrAttendanceEvent {
  const QrCloseRequested();
}