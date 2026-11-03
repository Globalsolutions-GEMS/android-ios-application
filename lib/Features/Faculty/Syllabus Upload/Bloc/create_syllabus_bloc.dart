import 'dart:convert';

import 'package:erp_app/api_manager/api_checker.dart';
import 'package:erp_app/api_manager/api_client.dart';
import 'package:erp_app/api_manager/api_endPoints.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/create_syllabus_model.dart';
import 'create_syllabus_event.dart';
import 'create_syllabus_state.dart';

class CreateSyllabusBloc extends Bloc<CreateSyllabusEvent, CreateSyllabusState> {
  CreateSyllabusBloc({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(),
        super(const CreateSyllabusInitial()) {
    on<LoadFacultySubjects>(_onLoadFacultySubjects);
    on<LoadSyllabusUnits>(_onLoadSyllabusUnits);
    on<CreateSyllabusUnit>(_onCreateSyllabusUnit);
    on<UpdateSyllabusUnit>(_onUpdateSyllabusUnit);
    on<ResetCreateSyllabus>(_onResetCreateSyllabus);
    on<LoadTopicUnits>(_onLoadTopicUnits);
    on<LoadSyllabusTopics>(_onLoadSyllabusTopics);
    on<CreateSyllabusTopic>(_onCreateSyllabusTopic);
    on<UpdateSyllabusTopic>(_onUpdateSyllabusTopic);
    on<ResetSyllabusTopics>(_onResetSyllabusTopics);
  }

  final ApiClient _apiClient;
  List<FacultySubject> _subjects = <FacultySubject>[];
  List<SyllabusUnit> _units = <SyllabusUnit>[];
  List<SyllabusTopic> _topics = <SyllabusTopic>[];
  int? _selectedSubjectId;
  int? _selectedTopicUnitId;

  Future<void> _onLoadFacultySubjects(
    LoadFacultySubjects event,
    Emitter<CreateSyllabusState> emit,
  ) async {
    emit(const CreateSyllabusLoading());
    try {
      final preferences = await SharedPreferences.getInstance();
      final userId = preferences.getInt('user_id') ??
          int.tryParse(preferences.getString('user_id') ?? '');
      if (userId == null || userId <= 0) {
        emit(const CreateSyllabusFailure('User ID not found. Please sign in again.'));
        return;
      }

      final response = await _apiClient.getData(
        '${ApiEndPoints.getFacultySubjectsByUser}?userId=$userId',
      );
      final error = ApiChecker.checkApi(response);
      if (error != null) {
        emit(CreateSyllabusFailure(error.toString()));
        return;
      }

      _subjects = _extractList(response)
          .whereType<Map>()
          .map((item) => FacultySubject.fromJson(Map<String, dynamic>.from(item)))
          .where((subject) => subject.id > 0 && subject.subjectName.trim().isNotEmpty)
          .toList();
      emit(FacultySubjectsLoaded(List<FacultySubject>.unmodifiable(_subjects)));
    } catch (error) {
      emit(CreateSyllabusFailure('Unable to load assigned subjects: $error'));
    }
  }

  Future<void> _onLoadSyllabusUnits(
    LoadSyllabusUnits event,
    Emitter<CreateSyllabusState> emit,
  ) async {
    _selectedSubjectId = event.subjectId;
    _units = <SyllabusUnit>[];
    emit(const CreateSyllabusLoading());
    try {
      _units = await _fetchUnits(event.subjectId);
      emit(SyllabusUnitsLoaded(
        subjects: List<FacultySubject>.unmodifiable(_subjects),
        selectedSubjectId: event.subjectId,
        units: List<SyllabusUnit>.unmodifiable(_units),
      ));
    } catch (error) {
      emit(CreateSyllabusFailure('Unable to load syllabus units: $error'));
    }
  }

  Future<void> _onCreateSyllabusUnit(
    CreateSyllabusUnit event,
    Emitter<CreateSyllabusState> emit,
  ) async {
    emit(const CreateSyllabusSaving());
    try {
      final response = await _apiClient.postData(
        '${ApiEndPoints.createUnit}?subjectId=${event.subjectId}',
        body: {
          'unitNo': event.unitNo,
          'unitName': event.unitName,
          'active': event.active,
        },
        authenticated: true,
      );
      final error = ApiChecker.checkApi(response);
      if (error != null) {
        emit(CreateSyllabusFailure(error.toString()));
        return;
      }
      _selectedSubjectId = event.subjectId;
      _units = await _fetchUnits(event.subjectId);
      emit(CreateSyllabusSuccess(
        message: 'Syllabus unit created successfully.',
        subjects: List<FacultySubject>.unmodifiable(_subjects),
        selectedSubjectId: event.subjectId,
        units: List<SyllabusUnit>.unmodifiable(_units),
      ));
    } catch (error) {
      emit(CreateSyllabusFailure('Unable to create syllabus unit: $error'));
    }
  }

  Future<void> _onUpdateSyllabusUnit(
    UpdateSyllabusUnit event,
    Emitter<CreateSyllabusState> emit,
  ) async {
    emit(const CreateSyllabusSaving());
    try {
      final response = await _apiClient.putData(
        '${ApiEndPoints.updateUnit}?id=${event.unitId}',
        body: {
          'unitNo': event.unitNo,
          'unitName': event.unitName,
          'active': event.active,
        },
      );
      final error = ApiChecker.checkApi(response);
      if (error != null) {
        emit(CreateSyllabusFailure(error.toString()));
        return;
      }
      _selectedSubjectId = event.subjectId;
      _units = await _fetchUnits(event.subjectId);
      emit(CreateSyllabusSuccess(
        message: 'Syllabus unit updated successfully.',
        subjects: List<FacultySubject>.unmodifiable(_subjects),
        selectedSubjectId: event.subjectId,
        units: List<SyllabusUnit>.unmodifiable(_units),
      ));
    } catch (error) {
      emit(CreateSyllabusFailure('Unable to update syllabus unit: $error'));
    }
  }

  Future<void> _onLoadTopicUnits(
    LoadTopicUnits event,
    Emitter<CreateSyllabusState> emit,
  ) async {
    emit(TopicUnitsLoading(subjectId: event.subjectId));
    try {
      final units = await _fetchUnits(event.subjectId);
      emit(TopicUnitsLoaded(
        subjectId: event.subjectId,
        units: List<SyllabusUnit>.unmodifiable(units),
      ));
    } catch (error) {
      emit(TopicUnitsFailure('Unable to load units for topics: $error'));
    }
  }

  Future<void> _onLoadSyllabusTopics(
    LoadSyllabusTopics event,
    Emitter<CreateSyllabusState> emit,
  ) async {
    _selectedTopicUnitId = event.unitId;
    _topics = <SyllabusTopic>[];
    emit(const SyllabusTopicsLoading());
    try {
      _topics = await _fetchTopics(event.unitId);
      emit(SyllabusTopicsLoaded(
        unitId: event.unitId,
        topics: List<SyllabusTopic>.unmodifiable(_topics),
      ));
    } catch (error) {
      emit(CreateSyllabusTopicFailure('Unable to load syllabus topics: $error'));
    }
  }

  Future<void> _onCreateSyllabusTopic(
    CreateSyllabusTopic event,
    Emitter<CreateSyllabusState> emit,
  ) async {
    emit(const SyllabusTopicSaving());
    try {
      final response = await _apiClient.postData(
        '${ApiEndPoints.createTopic}?unitId=${event.unitId}',
        body: _topicBody(
          topicNumber: event.topicNumber,
          topicName: event.topicName,
          description: event.description,
          noOfLectures: event.noOfLectures,
          active: event.active,
        ),
        authenticated: true,
      );
      final error = ApiChecker.checkApi(response);
      if (error != null) {
        emit(CreateSyllabusTopicFailure(error.toString()));
        return;
      }
      _selectedTopicUnitId = event.unitId;
      _topics = await _fetchTopics(event.unitId);
      emit(SyllabusTopicSuccess(
        message: 'Syllabus topic created successfully.',
        unitId: event.unitId,
        topics: List<SyllabusTopic>.unmodifiable(_topics),
      ));
    } catch (error) {
      emit(CreateSyllabusTopicFailure('Unable to create syllabus topic: $error'));
    }
  }

  Future<void> _onUpdateSyllabusTopic(
    UpdateSyllabusTopic event,
    Emitter<CreateSyllabusState> emit,
  ) async {
    emit(const SyllabusTopicSaving());
    try {
      final response = await _apiClient.putData(
        '${ApiEndPoints.updateTopic}?id=${event.topicId}',
        body: _topicBody(
          topicNumber: event.topicNumber,
          topicName: event.topicName,
          description: event.description,
          noOfLectures: event.noOfLectures,
          active: event.active,
        ),
      );
      final error = ApiChecker.checkApi(response);
      if (error != null) {
        emit(CreateSyllabusTopicFailure(error.toString()));
        return;
      }
      _selectedTopicUnitId = event.unitId;
      _topics = await _fetchTopics(event.unitId);
      emit(SyllabusTopicSuccess(
        message: 'Syllabus topic updated successfully.',
        unitId: event.unitId,
        topics: List<SyllabusTopic>.unmodifiable(_topics),
      ));
    } catch (error) {
      emit(CreateSyllabusTopicFailure('Unable to update syllabus topic: $error'));
    }
  }

  Future<void> _onResetCreateSyllabus(
    ResetCreateSyllabus event,
    Emitter<CreateSyllabusState> emit,
  ) async {
    _units = <SyllabusUnit>[];
    _selectedSubjectId = null;
    emit(const CreateSyllabusInitial());
    add(const LoadFacultySubjects());
  }

  Future<void> _onResetSyllabusTopics(
    ResetSyllabusTopics event,
    Emitter<CreateSyllabusState> emit,
  ) async {
    _topics = <SyllabusTopic>[];
    _selectedTopicUnitId = null;
    emit(const SyllabusTopicsLoaded(unitId: 0, topics: <SyllabusTopic>[]));
  }

  Future<List<SyllabusUnit>> _fetchUnits(int subjectId) async {
    final response = await _apiClient.getData(
      '${ApiEndPoints.getUnitsBySubject}?subjectId=$subjectId',
    );
    final error = ApiChecker.checkApi(response);
    if (error != null) throw Exception(error.toString());
    return _extractList(response)
        .whereType<Map>()
        .map((item) => SyllabusUnit.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<SyllabusTopic>> _fetchTopics(int unitId) async {
    final response = await _apiClient.getData(
      '${ApiEndPoints.getTopicsByUnit}?unitId=$unitId',
    );
    final error = ApiChecker.checkApi(response);
    if (error != null) throw Exception(error.toString());
    return _extractList(response)
        .whereType<Map>()
        .map((item) => SyllabusTopic.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Map<String, dynamic> _topicBody({
    required String topicNumber,
    required String topicName,
    required String description,
    required int noOfLectures,
    required bool active,
  }) => {
        'topicNumber': topicNumber,
        'topicName': topicName,
        'description': description,
        'noOfLectures': noOfLectures,
        'active': active,
      };

  /// Handles ApiClient's Response wrapper, JSON strings, lists, and common API envelopes.
  List<dynamic> _extractList(dynamic response) {
    dynamic data = response;
    if (data is Response) data = data.body;
    if (data is String) {
      try {
        data = jsonDecode(data);
      } catch (_) {
        return <dynamic>[];
      }
    }
    if (data is List) return data;
    if (data is Map) {
      for (final key in const ['data', 'content', 'items', 'result', 'subjects', 'units', 'topics']) {
        if (!data.containsKey(key)) continue;
        dynamic value = data[key];
        if (value is String) {
          try { value = jsonDecode(value); } catch (_) { continue; }
        }
        if (value is List) return value;
        if (value is Map) {
          for (final nestedKey in const ['data', 'content', 'items', 'result', 'subjects', 'units', 'topics']) {
            final nested = value[nestedKey];
            if (nested is List) return nested;
            if (nested is String) {
              try { final decoded = jsonDecode(nested); if (decoded is List) return decoded; } catch (_) {}
            }
          }
        }
      }
    }
    return <dynamic>[];
  }

}
