import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:erp_app/api_manager/api_checker.dart';
import 'package:erp_app/api_manager/api_client.dart';
import 'package:erp_app/api_manager/api_endPoints.dart';

import '../model/assignment_model.dart';
import 'assignment_list_event.dart';
import 'assignment_list_state.dart';

/// Loads this faculty's assignments for one subject and handles publish.
class AssignmentListBloc
    extends Bloc<AssignmentListEvent, AssignmentListState> {
  AssignmentListBloc({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(),
        super(const AssignmentListInitial()) {
    on<LoadAssignments>(_onLoad);
    on<PublishAssignmentRequested>(_onPublish);
  }

  final ApiClient _apiClient;

  Future<void> _onLoad(
    LoadAssignments event,
    Emitter<AssignmentListState> emit,
  ) async {
    emit(const AssignmentListLoading());
    try {
      final preferences = await SharedPreferences.getInstance();
      final sessionId = preferences.getInt('academic_session_id');

      final response = await _apiClient.getData(
        ApiEndPoints.assignmentsBySubject(event.subjectId),
      );
      final error = ApiChecker.checkApi(response);
      if (error != null) {
        emit(AssignmentListFailed(error));
        return;
      }

      final raw = response.body is List ? response.body as List : const [];
      var items = raw
          .whereType<Map>()
          .map((e) => FacultyAssignment.fromJson(Map<String, dynamic>.from(e)))
          .where((a) => a.allotmentId == event.allotmentId)
          .where((a) => sessionId == null || a.academicSessionId == sessionId)
          .toList();

      // Latest first.
      items.sort((a, b) => b.assignmentId.compareTo(a.assignmentId));

      items = await Future.wait(items.map(_withPublishStatus));
      emit(AssignmentListLoaded(items));
    } catch (error) {
      emit(AssignmentListFailed('Unable to load assignments: $error'));
    }
  }

  /// Old rows have isPublish = null, so ask the status API only for them.
  Future<FacultyAssignment> _withPublishStatus(FacultyAssignment a) async {
    if (a.isPublish != null) return a;
    final res = await _apiClient.getData(
      ApiEndPoints.assignmentPublishStatus(a.assignmentId),
    );
    return a.copyWith(isPublish: res.isSuccess && res.body == true);
  }

  Future<void> _onPublish(
    PublishAssignmentRequested event,
    Emitter<AssignmentListState> emit,
  ) async {
    final current = state;
    if (current is! AssignmentListLoaded) return;
    final assignment = event.assignment;

    if (assignment.isExpired) {
      emit(AssignmentListLoaded(
        current.assignments,
        notice: 'Expired assignments cannot be published.',
        noticeIsError: true,
      ));
      return;
    }
    if (assignment.isPublished) {
      emit(AssignmentListLoaded(
        current.assignments,
        notice: 'Assignment is already published.',
        noticeIsError: true,
      ));
      return;
    }

    emit(AssignmentListLoaded(
      current.assignments,
      publishingId: assignment.assignmentId,
    ));

    final response = await _apiClient.putData(
      '${ApiEndPoints.publishAssignment(assignment.assignmentId)}?isPublish=true',
    );
    final error = ApiChecker.checkApi(response);
    if (error != null) {
      emit(AssignmentListLoaded(
        current.assignments,
        notice: error,
        noticeIsError: true,
      ));
      return;
    }

    final updated = current.assignments
        .map((a) => a.assignmentId == assignment.assignmentId
            ? a.copyWith(isPublish: true)
            : a)
        .toList();
    emit(AssignmentListLoaded(
      updated,
      notice: 'Assignment published successfully.',
    ));
  }
}