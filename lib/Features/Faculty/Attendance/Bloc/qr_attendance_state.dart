import 'package:erp_app/Features/Faculty/Attendance/model/qr_attendance_model.dart';

sealed class QrAttendanceState {
  const QrAttendanceState();
}

class QrAttendanceInitial extends QrAttendanceState {
  const QrAttendanceInitial();
}

class QrAttendanceLoading extends QrAttendanceState {
  const QrAttendanceLoading();
}

class QrAttendanceLoaded extends QrAttendanceState {
  const QrAttendanceLoaded({
    required this.session,
    this.token,
    this.tokenValidTill,
    this.filter = 'PRESENT',
    this.students = const [],
    this.studentsPage = 0,
    this.hasMore = false,
    this.studentsLoading = false,
    this.studentsError,
    this.closing = false,
    this.message,
  });

  final QrSessionModel session;
  final String? token;
  final DateTime? tokenValidTill;
  final String filter;
  final List<QrStudentItem> students;
  final int studentsPage;
  final bool hasMore;
  final bool studentsLoading;
  final String? studentsError;
  final bool closing;

  /// One-time message for a snackbar (cleared by the next state).
  final String? message;

  QrAttendanceLoaded copyWith({
    QrSessionModel? session,
    String? token,
    DateTime? tokenValidTill,
    String? filter,
    List<QrStudentItem>? students,
    int? studentsPage,
    bool? hasMore,
    bool? studentsLoading,
    String? studentsError,
    bool clearStudentsError = false,
    bool? closing,
    String? message,
  }) {
    return QrAttendanceLoaded(
      session: session ?? this.session,
      token: token ?? this.token,
      tokenValidTill: tokenValidTill ?? this.tokenValidTill,
      filter: filter ?? this.filter,
      students: students ?? this.students,
      studentsPage: studentsPage ?? this.studentsPage,
      hasMore: hasMore ?? this.hasMore,
      studentsLoading: studentsLoading ?? this.studentsLoading,
      studentsError: clearStudentsError
          ? null
          : (studentsError ?? this.studentsError),
      closing: closing ?? this.closing,
      message: message,
    );
  }
}

class QrAttendanceFailure extends QrAttendanceState {
  const QrAttendanceFailure(this.message);

  final String message;
}