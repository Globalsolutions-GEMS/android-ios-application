import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:erp_app/api_manager/api_checker.dart';
import 'package:erp_app/api_manager/api_client.dart';
import 'package:erp_app/api_manager/api_endPoints.dart';
import 'package:erp_app/Features/Dashboard/Faculty Dashboard/Model/faculty_dashboard_model.dart';

import '../model/workarea_subject_model.dart';
import 'workarea_subject_event.dart';
import 'workarea_subject_state.dart';

/// Loads the logged-in faculty's subject allotments for the current
/// academic session (GET /allotments/all) and exposes them as
/// [WorkAreaSubject] cards for the workarea subject-selection screen.
class WorkAreaSubjectBloc
    extends Bloc<WorkAreaSubjectEvent, WorkAreaSubjectState> {
  WorkAreaSubjectBloc({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(),
        super(const WorkAreaSubjectInitial()) {
    on<LoadWorkAreaSubjects>(_onLoadWorkAreaSubjects);
  }

  final ApiClient _apiClient;

  Future<void> _onLoadWorkAreaSubjects(
    LoadWorkAreaSubjects event,
    Emitter<WorkAreaSubjectState> emit,
  ) async {
    emit(const WorkAreaSubjectLoading());
    try {
      final preferences = await SharedPreferences.getInstance();
      final userId = preferences.getInt('user_id') ??
          int.tryParse(preferences.getString('user_id') ?? '');
      if (userId == null || userId <= 0) {
        emit(const WorkAreaSubjectFailure(
            'User ID not found. Please sign in again.'));
        return;
      }

      var sessionId = await _resolveSessionId(preferences);
      if (sessionId == null) {
        emit(const WorkAreaSubjectsLoaded(<WorkAreaSubject>[]));
        return;
      }

      final response = await _apiClient.getData(ApiEndPoints.allotmentsAll);
      final error = ApiChecker.checkApi(response);
      if (error != null) {
        emit(WorkAreaSubjectFailure(error));
        return;
      }

      final rawList = _extractList(response.body);

      final allotments = rawList
          .whereType<Map>()
          .map((item) =>
              FacultyAllotment.fromJson(Map<String, dynamic>.from(item)))
          .toList();

      // Matches web: teacherId + academicSessionId + subjectId, and an
      // allotment is excluded only when isActive is explicitly false.
      List<WorkAreaSubject> filterBySession(int session) {
        final subjects = <WorkAreaSubject>[];
        for (final allotment in allotments) {
          final keep = allotment.isActive != false &&
              allotment.teacherId == userId &&
              allotment.academicSessionId == session &&
              allotment.subjectId > 0;
          if (keep) {
            subjects.add(WorkAreaSubject.fromAllotment(allotment));
          }
        }
        return subjects;
      }

      var subjects = filterBySession(sessionId);

      // Same fallback as the faculty dashboard: when the resolved session
      // has no allotments for this teacher, switch to the session that
      // actually has data (the saved academic_session_id can be stale).
      if (subjects.isEmpty) {
        final sessionWithData =
            FacultyDashboardCalculator.findSessionWithData(
          rawList,
          userId: userId,
        );
        if (sessionWithData != null && sessionWithData != sessionId) {
          sessionId = sessionWithData;
          await preferences.setInt('academic_session_id', sessionId);
          subjects = filterBySession(sessionId);
        }
      }

      emit(WorkAreaSubjectsLoaded(List.unmodifiable(subjects)));
    } catch (error) {
      emit(WorkAreaSubjectFailure('Unable to load subjects: $error'));
    }
  }

  /// Same resolution order as the faculty dashboard: saved preference
  /// first, then the active session from GET /academicsession.
  Future<int?> _resolveSessionId(SharedPreferences preferences) async {
    final saved = preferences.getInt('academic_session_id');
    if (saved != null) return saved;

    final response = await _apiClient.getData(ApiEndPoints.academicSession);
    final error = ApiChecker.checkApi(response);
    if (error != null) return null;

    final sessionId = FacultyDashboardCalculator.currentSessionId(response.body);
    if (sessionId != null) {
      await preferences.setInt('academic_session_id', sessionId);
    }
    return sessionId;
  }

  /// Handles JSON strings, lists, and common API envelopes.
  List<dynamic> _extractList(dynamic data) {
    if (data is String) {
      try {
        data = jsonDecode(data);
      } catch (_) {
        return <dynamic>[];
      }
    }
    if (data is List) return data;
    if (data is Map) {
      for (final key in const [
        'data',
        'content',
        'items',
        'result',
        'allotments',
      ]) {
        if (!data.containsKey(key)) continue;
        dynamic value = data[key];
        if (value is String) {
          try {
            value = jsonDecode(value);
          } catch (_) {
            continue;
          }
        }
        if (value is List) return value;
      }
    }
    return <dynamic>[];
  }
}
