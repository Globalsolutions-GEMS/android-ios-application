import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:erp_app/api_manager/api_checker.dart';
import 'package:erp_app/api_manager/api_client.dart';
import 'package:erp_app/api_manager/api_endPoints.dart';

import '../model/assignment_model.dart';
import 'assignment_detail_event.dart';
import 'assignment_detail_state.dart';

/// Loads submissions of one assignment and approves offline requests.
class AssignmentDetailBloc
    extends Bloc<AssignmentDetailEvent, AssignmentDetailState> {
  AssignmentDetailBloc({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(),
        super(const AssignmentDetailInitial()) {
    on<LoadSubmissions>(_onLoad);
    on<ApproveStudents>(_onApprove);
  }

  final ApiClient _apiClient;

  Future<void> _onLoad(
    LoadSubmissions event,
    Emitter<AssignmentDetailState> emit,
  ) async {
    emit(const AssignmentDetailLoading());
    try {
      final items = await _fetch(event.assignmentId, event.allotmentId);
      emit(AssignmentDetailLoaded(items));
    } catch (error) {
      emit(AssignmentDetailFailed(_message(error)));
    }
  }

  Future<void> _onApprove(
    ApproveStudents event,
    Emitter<AssignmentDetailState> emit,
  ) async {
    final current = state;
    if (current is! AssignmentDetailLoaded) return;

    if (event.studentIds.isEmpty) {
      emit(AssignmentDetailLoaded(
        current.submissions,
        notice: 'Please select at least one student to approve.',
        noticeIsError: true,
      ));
      return;
    }

    emit(AssignmentDetailLoaded(current.submissions, isApproving: true));

    final response = await _apiClient.postAuthList(
      ApiEndPoints.approveSubmissions(event.assignmentId),
      event.studentIds,
    );
    final error = ApiChecker.checkApi(response);
    if (error != null) {
      emit(AssignmentDetailLoaded(
        current.submissions,
        notice: 'Failed to approve students: $error',
        noticeIsError: true,
      ));
      return;
    }

    try {
      final updated = await _fetch(event.assignmentId, event.allotmentId);
      emit(AssignmentDetailLoaded(
        updated,
        notice: 'Selected students approved successfully!',
      ));
    } catch (_) {
      // Approved, but refreshing failed: keep old list and tell the user.
      emit(AssignmentDetailLoaded(
        current.submissions,
        notice: 'Approved. Pull to refresh to see the latest status.',
      ));
    }
  }

  Future<List<AssignmentSubmission>> _fetch(
    int assignmentId,
    int allotmentId,
  ) async {
    final response = await _apiClient.getData(
      ApiEndPoints.assessmentSubmissions(assignmentId),
    );
    final error = ApiChecker.checkApi(response);
    if (error != null) throw Exception(error);

    final raw = response.body is List ? response.body as List : const [];
    return raw
        .whereType<Map>()
        .map((e) => AssignmentSubmission.fromJson(Map<String, dynamic>.from(e)))
        .where((s) =>
            s.assignmentId == assignmentId && s.allotmentId == allotmentId)
        .toList();
  }

  String _message(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}