import 'package:flutter/foundation.dart';

@immutable
abstract class AssignmentDetailEvent {
  const AssignmentDetailEvent();
}

class LoadSubmissions extends AssignmentDetailEvent {
  const LoadSubmissions({required this.assignmentId, required this.allotmentId});

  final int assignmentId;
  final int allotmentId;
}

class ApproveStudents extends AssignmentDetailEvent {
  const ApproveStudents({
    required this.assignmentId,
    required this.allotmentId,
    required this.studentIds,
  });

  final int assignmentId;
  final int allotmentId;
  final List<int> studentIds;
}