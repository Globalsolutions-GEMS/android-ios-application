import 'package:flutter/foundation.dart';

import '../model/create_syllabus_model.dart';

@immutable
abstract class CreateSyllabusState {
  const CreateSyllabusState();
}

class CreateSyllabusInitial extends CreateSyllabusState {
  const CreateSyllabusInitial();
}

class CreateSyllabusLoading extends CreateSyllabusState {
  const CreateSyllabusLoading();
}

class CreateSyllabusSaving extends CreateSyllabusState {
  const CreateSyllabusSaving();
}

class CreateSyllabusFailure extends CreateSyllabusState {
  final String message;

  const CreateSyllabusFailure(this.message);
}

class FacultySubjectsLoaded extends CreateSyllabusState {
  final List<FacultySubject> subjects;

  const FacultySubjectsLoaded(this.subjects);
}

class SyllabusUnitsLoaded extends CreateSyllabusState {
  final List<FacultySubject> subjects;
  final int selectedSubjectId;
  final List<SyllabusUnit> units;

  const SyllabusUnitsLoaded({
    required this.subjects,
    required this.selectedSubjectId,
    required this.units,
  });
}

class CreateSyllabusSuccess extends CreateSyllabusState {
  final String message;
  final List<FacultySubject> subjects;
  final int selectedSubjectId;
  final List<SyllabusUnit> units;

  const CreateSyllabusSuccess({
    required this.message,
    required this.subjects,
    required this.selectedSubjectId,
    required this.units,
  });
}

class TopicUnitsLoading extends CreateSyllabusState {
  final int subjectId;

  const TopicUnitsLoading({required this.subjectId});
}

class TopicUnitsLoaded extends CreateSyllabusState {
  final int subjectId;
  final List<SyllabusUnit> units;

  const TopicUnitsLoaded({
    required this.subjectId,
    required this.units,
  });
}

class TopicUnitsFailure extends CreateSyllabusState {
  final String message;

  const TopicUnitsFailure(this.message);
}

class SyllabusTopicsLoading extends CreateSyllabusState {
  const SyllabusTopicsLoading();
}

class SyllabusTopicsLoaded extends CreateSyllabusState {
  final int unitId;
  final List<SyllabusTopic> topics;

  const SyllabusTopicsLoaded({
    required this.unitId,
    required this.topics,
  });
}

class SyllabusTopicSaving extends CreateSyllabusState {
  const SyllabusTopicSaving();
}

class SyllabusTopicSuccess extends CreateSyllabusState {
  final String message;
  final int unitId;
  final List<SyllabusTopic> topics;

  const SyllabusTopicSuccess({
    required this.message,
    required this.unitId,
    required this.topics,
  });
}

class CreateSyllabusTopicFailure extends CreateSyllabusState {
  final String message;

  const CreateSyllabusTopicFailure(this.message);
}