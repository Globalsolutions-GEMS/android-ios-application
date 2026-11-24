import 'package:flutter/foundation.dart';

import '../model/assignment_model.dart';

@immutable
abstract class AssignmentListEvent {
  const AssignmentListEvent();
}

class LoadAssignments extends AssignmentListEvent {
  const LoadAssignments({required this.subjectId, required this.allotmentId});

  final int subjectId;
  final int allotmentId;
}

class PublishAssignmentRequested extends AssignmentListEvent {
  const PublishAssignmentRequested(this.assignment);

  final FacultyAssignment assignment;
}