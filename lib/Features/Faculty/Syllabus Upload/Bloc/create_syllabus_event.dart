import 'package:flutter/foundation.dart';

@immutable
abstract class CreateSyllabusEvent {
  const CreateSyllabusEvent();
}

class LoadFacultySubjects extends CreateSyllabusEvent {
  const LoadFacultySubjects();
}

class LoadSyllabusUnits extends CreateSyllabusEvent {
  final int subjectId;

  const LoadSyllabusUnits({required this.subjectId});
}

class CreateSyllabusUnit extends CreateSyllabusEvent {
  final int subjectId;
  final String unitNo;
  final String unitName;
  final bool active;

  const CreateSyllabusUnit({
    required this.subjectId,
    required this.unitNo,
    required this.unitName,
    required this.active,
  });
}

class UpdateSyllabusUnit extends CreateSyllabusEvent {
  final int unitId;
  final int subjectId;
  final String unitNo;
  final String unitName;
  final bool active;

  const UpdateSyllabusUnit({
    required this.unitId,
    required this.subjectId,
    required this.unitNo,
    required this.unitName,
    required this.active,
  });
}

class ResetCreateSyllabus extends CreateSyllabusEvent {
  const ResetCreateSyllabus();
}

class LoadTopicUnits extends CreateSyllabusEvent {
  final int subjectId;

  const LoadTopicUnits({required this.subjectId});
}

class LoadSyllabusTopics extends CreateSyllabusEvent {
  final int unitId;

  const LoadSyllabusTopics({required this.unitId});
}

class CreateSyllabusTopic extends CreateSyllabusEvent {
  final int unitId;
  final String topicNumber;
  final String topicName;
  final String description;
  final int noOfLectures;
  final bool active;

  const CreateSyllabusTopic({
    required this.unitId,
    required this.topicNumber,
    required this.topicName,
    required this.description,
    required this.noOfLectures,
    required this.active,
  });
}

class UpdateSyllabusTopic extends CreateSyllabusEvent {
  final int topicId;
  final int unitId;
  final String topicNumber;
  final String topicName;
  final String description;
  final int noOfLectures;
  final bool active;

  const UpdateSyllabusTopic({
    required this.topicId,
    required this.unitId,
    required this.topicNumber,
    required this.topicName,
    required this.description,
    required this.noOfLectures,
    required this.active,
  });
}

class ResetSyllabusTopics extends CreateSyllabusEvent {
  const ResetSyllabusTopics();
}