import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:erp_app/api_manager/api_checker.dart';
import 'package:erp_app/api_manager/api_client.dart';
import 'package:erp_app/api_manager/api_endPoints.dart';

import '../model/assignment_model.dart';
import 'assignment_form_event.dart';
import 'assignment_form_state.dart';

/// Loads eligible students and saves (create / update) an assignment.
class AssignmentFormBloc
    extends Bloc<AssignmentFormEvent, AssignmentFormState> {
  AssignmentFormBloc({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(),
        super(const AssignmentFormInitial()) {
    on<LoadFormStudents>(_onLoadStudents);
    on<SubmitAssignmentForm>(_onSubmit);
  }

  final ApiClient _apiClient;

  Future<void> _onLoadStudents(
    LoadFormStudents event,
    Emitter<AssignmentFormState> emit,
  ) async {
    emit(const AssignmentFormLoading());
    try {
      final preferences = await SharedPreferences.getInstance();
      final sessionId = preferences.getInt('academic_session_id');

      final responses = await Future.wait([
        _apiClient.getData(
          '${ApiEndPoints.studentAdmissionsFilter}?courseId=${event.courseId}',
        ),
        _apiClient.getData(ApiEndPoints.preferenceSelectionsAll),
      ]);

      for (final response in responses) {
        final error = ApiChecker.checkApi(response);
        if (error != null) {
          emit(AssignmentFormFailed(error));
          return;
        }
      }

      final students = _asMapList(responses[0].body)
          .map(AssignmentStudent.fromJson)
          .where((s) => s.admissionStatusId == 2)
          .toList();

      final mappings = _asMapList(responses[1].body)
          .map(StudentSubjectMapping.fromJson)
          .toList();

      final eligible = students.where((s) {
        final courseMatch = s.courseId == event.courseId;
        final sessionMatch = sessionId == null || s.academicSessionId == sessionId;
        final sectionMatch = event.sectionIds.isEmpty ||
            event.sectionIds.contains(s.sectionId);
        final subjectMatch = mappings.any((m) =>
            m.studentId == s.id &&
            m.subjectId == event.subjectId &&
            m.courseId == event.courseId);
        return courseMatch && sessionMatch && sectionMatch && subjectMatch;
      }).toList()
        ..sort((a, b) => _compareRoll(a.rollNumber, b.rollNumber));

      emit(AssignmentFormLoaded(eligible));
    } catch (error) {
      emit(AssignmentFormFailed('Unable to load students: $error'));
    }
  }

  Future<void> _onSubmit(
    SubmitAssignmentForm event,
    Emitter<AssignmentFormState> emit,
  ) async {
    final current = state;
    if (current is! AssignmentFormLoaded) return;

    emit(AssignmentFormLoaded(current.students, isSubmitting: true));

    final isEdit = event.assignmentId != null;
    final response = await _apiClient.sendMultipart(
      isEdit ? 'PUT' : 'POST',
      isEdit
          ? ApiEndPoints.updateAssignment(
              event.request.subjectId,
              event.assignmentId!,
            )
          : ApiEndPoints.createAssignment,
      jsonField: 'assignmentRequest',
      json: event.request.toJson(),
      file: event.file,
    );

    final error = ApiChecker.checkApi(response);
    if (error != null) {
      emit(AssignmentFormLoaded(
        current.students,
        notice: 'Failed to submit assignment: $error',
        noticeIsError: true,
      ));
      return;
    }

    emit(AssignmentFormLoaded(
      current.students,
      saved: true,
      notice: isEdit
          ? 'Assignment updated successfully!'
          : 'Assignment created successfully!',
    ));
  }

  List<Map<String, dynamic>> _asMapList(dynamic body) {
    if (body is! List) return const [];
    return body
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// Roll numbers: empty last, numbers compared as numbers.
  int _compareRoll(String a, String b) {
    if (a.isEmpty && b.isNotEmpty) return 1;
    if (a.isNotEmpty && b.isEmpty) return -1;
    final na = int.tryParse(a);
    final nb = int.tryParse(b);
    if (na != null && nb != null) return na.compareTo(nb);
    return a.toLowerCase().compareTo(b.toLowerCase());
  }
}