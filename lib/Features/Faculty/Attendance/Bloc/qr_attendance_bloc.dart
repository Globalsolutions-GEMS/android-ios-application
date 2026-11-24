import 'package:erp_app/Features/Faculty/Attendance/Bloc/qr_attendance_event.dart';
import 'package:erp_app/Features/Faculty/Attendance/Bloc/qr_attendance_state.dart';
import 'package:erp_app/Features/Faculty/Attendance/model/qr_attendance_model.dart';
import 'package:erp_app/api_manager/api_checker.dart';
import 'package:erp_app/api_manager/api_client.dart';
import 'package:erp_app/api_manager/api_endPoints.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class QrAttendanceBloc extends Bloc<QrAttendanceEvent, QrAttendanceState> {
  QrAttendanceBloc({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient(),
      super(const QrAttendanceInitial()) {
    on<QrStartRequested>(_onStart);
    on<QrRefreshRequested>(_onRefresh);
    on<QrStudentsRequested>(_onStudents);
    on<QrCloseRequested>(_onClose);
  }

  static const int _pageSize = 100;

  final ApiClient _apiClient;
  bool _refreshing = false;
  int _studentsRequestId = 0; // ignores outdated list responses

  Map<String, dynamic>? _map(dynamic body) =>
      body is Map ? Map<String, dynamic>.from(body) : null;

  Future<void> _onStart(
    QrStartRequested event,
    Emitter<QrAttendanceState> emit,
  ) async {
    emit(const QrAttendanceLoading());

    try {
      final response = await _apiClient.postAuthData(
        ApiEndPoints.qrSession,
        body: {
          'attendanceSessionId': event.sessionId,
          'attendanceDate': event.date,
          'lectureType': event.lectureType,
          'defaultStatusId': event.defaultStatusId,
          'topicId': event.topicId,
          'latitude': event.latitude,
          'longitude': event.longitude,
          'divisions': event.divisions,
        },
      );

      final error = ApiChecker.checkApi(response);
      final json = _map(response.body);
      if (error != null || json == null) {
        emit(QrAttendanceFailure(error ?? 'Unable to start the QR.'));
        return;
      }

      final session = QrSessionModel.fromJson(json);
      emit(
        QrAttendanceLoaded(
          session: session,
          token: session.token,
          tokenValidTill: session.tokenValidTill,
        ),
      );
      add(const QrStudentsRequested(filter: 'PRESENT'));
    } catch (_) {
      emit(const QrAttendanceFailure('Unable to start the QR.'));
    }
  }

  Future<void> _onRefresh(
    QrRefreshRequested event,
    Emitter<QrAttendanceState> emit,
  ) async {
    final current = state;
    if (current is! QrAttendanceLoaded || _refreshing) return;
    if (!current.session.isActive) return;

    _refreshing = true;
    try {
      final id = current.session.qrSessionId;
      final responses = await Future.wait([
        _apiClient.getData(ApiEndPoints.qrStatus(id)),
        _apiClient.getData(ApiEndPoints.qrToken(id)),
      ]);

      // State may have changed while waiting
      final latest = state;
      if (latest is! QrAttendanceLoaded) return;

      var session = latest.session;
      var token = latest.token;
      var validTill = latest.tokenValidTill;

      if (responses[0].isSuccess) {
        final json = _map(responses[0].body);
        if (json != null) session = QrSessionModel.fromJson(json);
      }
      if (responses[1].isSuccess) {
        final json = _map(responses[1].body);
        if (json != null) {
          final t = QrTokenModel.fromJson(json);
          if (t.token != null) {
            token = t.token;
            validTill = t.validTill;
          }
        }
      }

      final changed =
          session.presentCount != latest.session.presentCount ||
          session.absentCount != latest.session.absentCount ||
          session.status != latest.session.status;

      emit(
        latest.copyWith(session: session, token: token, tokenValidTill: validTill),
      );

      // Reload the list only when it is a single page (long lists use pull to refresh)
      if (changed && !latest.hasMore && latest.studentsPage == 0) {
        add(QrStudentsRequested(filter: latest.filter, silent: true));
      }
    } catch (_) {
      // Next timer tick will try again
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _onStudents(
    QrStudentsRequested event,
    Emitter<QrAttendanceState> emit,
  ) async {
    final current = state;
    if (current is! QrAttendanceLoaded) return;

    final requestId = ++_studentsRequestId;
    final isFirstPage = event.page == 0;

    if (!event.silent) {
      emit(
        current.copyWith(
          filter: event.filter,
          students: isFirstPage ? const [] : current.students,
          studentsLoading: true,
          clearStudentsError: true,
        ),
      );
    }

    try {
      final response = await _apiClient.getData(
        '${ApiEndPoints.qrStudents(current.session.qrSessionId)}'
        '?filter=${event.filter}&page=${event.page}&size=$_pageSize',
      );
      if (requestId != _studentsRequestId) return; // newer request started

      final latest = state;
      if (latest is! QrAttendanceLoaded) return;

      final error = ApiChecker.checkApi(response);
      final json = _map(response.body);
      if (error != null || json == null) {
        emit(
          latest.copyWith(
            filter: event.filter,
            studentsLoading: false,
            studentsError: error ?? 'Unable to load students.',
          ),
        );
        return;
      }

      final page = QrStudentPage.fromJson(json);
      emit(
        latest.copyWith(
          filter: event.filter,
          students: isFirstPage
              ? page.content
              : [...latest.students, ...page.content],
          studentsPage: page.page,
          hasMore: page.page + 1 < page.totalPages,
          studentsLoading: false,
          clearStudentsError: true,
        ),
      );
    } catch (_) {
      if (requestId != _studentsRequestId) return;
      final latest = state;
      if (latest is QrAttendanceLoaded) {
        emit(
          latest.copyWith(
            studentsLoading: false,
            studentsError: 'Unable to load students.',
          ),
        );
      }
    }
  }

  Future<void> _onClose(
    QrCloseRequested event,
    Emitter<QrAttendanceState> emit,
  ) async {
    final current = state;
    if (current is! QrAttendanceLoaded || current.closing) return;

    emit(current.copyWith(closing: true));

    try {
      final response = await _apiClient.postAuthData(
        ApiEndPoints.qrClose(current.session.qrSessionId),
      );

      final latest = state;
      if (latest is! QrAttendanceLoaded) return;

      final error = ApiChecker.checkApi(response);
      final json = _map(response.body);
      if (error != null || json == null) {
        emit(
          latest.copyWith(
            closing: false,
            message: error ?? 'Unable to stop the QR.',
          ),
        );
        return;
      }

      emit(
        latest.copyWith(
          session: QrSessionModel.fromJson(json),
          closing: false,
          message: 'QR stopped. Students who did not scan are marked Absent.',
        ),
      );
      add(QrStudentsRequested(filter: latest.filter, silent: true));
    } catch (_) {
      final latest = state;
      if (latest is QrAttendanceLoaded) {
        emit(latest.copyWith(closing: false, message: 'Unable to stop the QR.'));
      }
    }
  }
}