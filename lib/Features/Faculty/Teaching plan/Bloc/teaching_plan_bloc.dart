import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:erp_app/api_manager/api_checker.dart';
import 'package:erp_app/api_manager/api_client.dart';
import 'package:erp_app/api_manager/api_endPoints.dart';

import '../model/teaching_plan_model.dart';
import 'teaching_plan_event.dart';
import 'teaching_plan_state.dart';

/// Loads Units, Topics, Teaching Plans and same-date conflicts for the
/// selected workarea subject.
///
/// GET /units?subjectId=..., GET /topics?unitId=...,
/// GET /api/teaching-plan/allotment/{teacherid},
/// GET /api/teaching-plan/conflicts
class TeachingPlanBloc extends Bloc<TeachingPlanEvent, TeachingPlanState> {
  TeachingPlanBloc({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(),
        super(const TeachingPlanInitial()) {
    on<LoadTeachingPlan>(_onLoadTeachingPlan);
    on<TeachingPlanUnitSelected>(_onUnitSelected);
    on<TeachingPlanCreate>(_onCreate);
    on<TeachingPlanUpdate>(_onUpdate);
    on<TeachingPlanDelete>(_onDelete);
    on<TeachingPlanBulkUpload>(_onBulkUpload);
  }

  final ApiClient _apiClient;
  int? _allotmentId;

  Future<void> _onLoadTeachingPlan(
    LoadTeachingPlan event,
    Emitter<TeachingPlanState> emit,
  ) async {
    emit(const TeachingPlanLoading());
    try {
      final results = await Future.wait([
        _apiClient.getData(
          '${ApiEndPoints.getUnitsBySubject}?subjectId=${event.subject.subjectId}',
        ),
        _apiClient.getData(
          ApiEndPoints.teachingPlanByAllotment(event.subject.allotmentId),
        ),
        _apiClient.getData(ApiEndPoints.teachingPlanConflicts),
      ]);

      final unitsResponse = results[0];
      final plansResponse = results[1];
      final conflictsResponse = results[2];

      final error = [
        ApiChecker.checkApi(unitsResponse),
        ApiChecker.checkApi(plansResponse),
        ApiChecker.checkApi(conflictsResponse),
      ].whereType<String>().firstOrNull;
      if (error != null) {
        emit(TeachingPlanFailure(error));
        return;
      }

      final units = _extractList(unitsResponse.body)
          .whereType<Map>()
          .map((item) =>
              TeachingPlanUnit.fromJson(Map<String, dynamic>.from(item)))
          .where((unit) => unit.id > 0 && unit.unitName.trim().isNotEmpty)
          .toList();

      final plans = _extractList(plansResponse.body)
          .whereType<Map>()
          .map((item) => TeachingPlan.fromJson(Map<String, dynamic>.from(item)))
          .toList();

      final conflicts = _extractList(conflictsResponse.body)
          .whereType<Map>()
          .map((item) =>
              TeachingPlanConflict.fromJson(Map<String, dynamic>.from(item)))
          .toList();

      _allotmentId = event.subject.allotmentId;
      final selectedUnitId = units.isNotEmpty ? units.first.id : null;
      emit(
        TeachingPlanLoaded(
          units: List.unmodifiable(units),
          selectedUnitId: selectedUnitId,
          topics: const [],
          topicsLoading: selectedUnitId != null,
          plans: List.unmodifiable(plans),
          conflicts: List.unmodifiable(conflicts),
        ),
      );

      if (selectedUnitId != null) {
        add(TeachingPlanUnitSelected(selectedUnitId));
      }
    } catch (error) {
      emit(TeachingPlanFailure('Unable to load teaching plan: $error'));
    }
  }

  Future<void> _onUnitSelected(
    TeachingPlanUnitSelected event,
    Emitter<TeachingPlanState> emit,
  ) async {
    final current = state;
    if (current is! TeachingPlanLoaded) return;
    if (current.selectedUnitId == event.unitId &&
        current.topics.isNotEmpty) {
      return;
    }

    emit(current.copyWith(
      selectedUnitId: event.unitId,
      topics: const [],
      topicsLoading: true,
    ));

    try {
      final response = await _apiClient.getData(
        '${ApiEndPoints.getTopicsByUnit}?unitId=${event.unitId}',
      );
      final error = ApiChecker.checkApi(response);
      if (error != null) {
        emit(current.copyWith(topicsLoading: false));
        return;
      }
      final topics = _extractList(response.body)
          .whereType<Map>()
          .map((item) =>
              TeachingPlanTopic.fromJson(Map<String, dynamic>.from(item)))
          .where((topic) => topic.id > 0 && topic.topicName.trim().isNotEmpty)
          .toList();
      emit(current.copyWith(
        topics: List.unmodifiable(topics),
        topicsLoading: false,
      ));
    } catch (_) {
      emit(current.copyWith(topicsLoading: false));
    }
  }

  Future<void> _onCreate(
    TeachingPlanCreate event,
    Emitter<TeachingPlanState> emit,
  ) async {
    final current = state;
    if (current is! TeachingPlanLoaded) return;

    emit(current.copyWith(isMutating: true, clearMutationMessage: true));
    try {
      final response = await _apiClient.postAuthData(
        ApiEndPoints.teachingPlan,
        body: _planBody(event.draft),
      );
      final error = ApiChecker.checkApi(response);
      if (error != null) {
        emit(current.copyWith(
          isMutating: false,
          mutationMessage: error,
        ));
        return;
      }
      final refreshed = await _refreshPlansAndConflicts();
      emit(current.copyWith(
        plans: refreshed.$1,
        conflicts: refreshed.$2,
        isMutating: false,
        mutationMessage: 'Teaching plan created.',
      ));
    } catch (_) {
      emit(current.copyWith(
        isMutating: false,
        mutationMessage: 'Failed to create teaching plan.',
      ));
    }
  }

  Future<void> _onUpdate(
    TeachingPlanUpdate event,
    Emitter<TeachingPlanState> emit,
  ) async {
    final current = state;
    if (current is! TeachingPlanLoaded || event.draft.id == null) return;

    emit(current.copyWith(isMutating: true, clearMutationMessage: true));
    try {
      final response = await _apiClient.putData(
        ApiEndPoints.teachingPlanById(event.draft.id!),
        body: _planBody(event.draft),
      );
      final error = ApiChecker.checkApi(response);
      if (error != null) {
        emit(current.copyWith(
          isMutating: false,
          mutationMessage: error,
        ));
        return;
      }
      final refreshed = await _refreshPlansAndConflicts();
      emit(current.copyWith(
        plans: refreshed.$1,
        conflicts: refreshed.$2,
        isMutating: false,
        mutationMessage: 'Teaching plan updated.',
      ));
    } catch (_) {
      emit(current.copyWith(
        isMutating: false,
        mutationMessage: 'Failed to update teaching plan.',
      ));
    }
  }

  Future<void> _onDelete(
    TeachingPlanDelete event,
    Emitter<TeachingPlanState> emit,
  ) async {
    final current = state;
    if (current is! TeachingPlanLoaded) return;

    emit(current.copyWith(isMutating: true, clearMutationMessage: true));
    try {
      final response =
          await _apiClient.deleteData(ApiEndPoints.teachingPlanById(event.planId));
      final error = ApiChecker.checkApi(response);
      if (error != null) {
        emit(current.copyWith(
          isMutating: false,
          mutationMessage: error,
        ));
        return;
      }
      final refreshed = await _refreshPlansAndConflicts();
      emit(current.copyWith(
        plans: refreshed.$1,
        conflicts: refreshed.$2,
        isMutating: false,
        mutationMessage: 'Teaching plan deleted.',
      ));
    } catch (_) {
      emit(current.copyWith(
        isMutating: false,
        mutationMessage: 'Failed to delete teaching plan.',
      ));
    }
  }

  Future<void> _onBulkUpload(
    TeachingPlanBulkUpload event,
    Emitter<TeachingPlanState> emit,
  ) async {
    final current = state;
    if (current is! TeachingPlanLoaded) return;

    emit(current.copyWith(isMutating: true, clearMutationMessage: true));
    try {
      final response = await _apiClient.uploadFile(
        ApiEndPoints.teachingPlanBulkUpload,
        fileField: 'file',
        file: event.file,
      );
      final error = ApiChecker.checkApi(response);
      if (error != null) {
        emit(current.copyWith(
          isMutating: false,
          mutationMessage: error,
        ));
        return;
      }
      final refreshed = await _refreshPlansAndConflicts();
      emit(current.copyWith(
        plans: refreshed.$1,
        conflicts: refreshed.$2,
        isMutating: false,
        mutationMessage: 'File uploaded successfully!',
      ));
    } catch (_) {
      emit(current.copyWith(
        isMutating: false,
        mutationMessage: 'Failed to upload file',
      ));
    }
  }

  Future<(List<TeachingPlan>, List<TeachingPlanConflict>)>
      _refreshPlansAndConflicts() async {
    if (_allotmentId == null) {
      return (
        <TeachingPlan>[],
        <TeachingPlanConflict>[],
      );
    }
    final results = await Future.wait([
      _apiClient.getData(
        ApiEndPoints.teachingPlanByAllotment(_allotmentId!),
      ),
      _apiClient.getData(ApiEndPoints.teachingPlanConflicts),
    ]);
    final plansResponse = results[0];
    final conflictsResponse = results[1];
    final error = [
      ApiChecker.checkApi(plansResponse),
      ApiChecker.checkApi(conflictsResponse),
    ].whereType<String>().firstOrNull;
    if (error != null) {
      return (
        <TeachingPlan>[],
        <TeachingPlanConflict>[],
      );
    }
    final plans = _extractList(plansResponse.body)
        .whereType<Map>()
        .map((item) => TeachingPlan.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    final conflicts = _extractList(conflictsResponse.body)
        .whereType<Map>()
        .map((item) =>
            TeachingPlanConflict.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    return (
      List<TeachingPlan>.unmodifiable(plans),
      List<TeachingPlanConflict>.unmodifiable(conflicts),
    );
  }

  Map<String, dynamic> _planBody(TeachingPlanDraft draft) => {
        'subjectTeacherAllotmentId': draft.subjectTeacherAllotmentId,
        'unitId': draft.unitId,
        'topicId': draft.topicId.toString(),
        'objective': draft.objective.isEmpty ? null : draft.objective,
        'teachingMode': draft.teachingMode.toLowerCase(),
        'plannedDate': _formatDate(draft.plannedDate),
        'deliveredDate':
            draft.deliveredDate == null ? null : _formatDate(draft.deliveredDate!),
      };

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

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
        'units',
        'topics',
        'plans',
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
