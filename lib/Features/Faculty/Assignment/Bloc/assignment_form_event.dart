import 'dart:io';

import 'package:flutter/foundation.dart';

import '../model/assignment_model.dart';

@immutable
abstract class AssignmentFormEvent {
  const AssignmentFormEvent();
}

class LoadFormStudents extends AssignmentFormEvent {
  const LoadFormStudents({
    required this.courseId,
    required this.subjectId,
    required this.sectionIds,
  });

  final int courseId;
  final int subjectId;
  final List<int> sectionIds;
}

class SubmitAssignmentForm extends AssignmentFormEvent {
  const SubmitAssignmentForm({
    required this.request,
    this.file,
    this.assignmentId,
  });

  final AssignmentRequest request;
  final File? file;

  /// null = create, not null = update.
  final int? assignmentId;
}