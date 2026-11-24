import 'package:flutter/foundation.dart';

import '../model/assignment_model.dart';

@immutable
abstract class AssignmentListState {
  const AssignmentListState();
}

class AssignmentListInitial extends AssignmentListState {
  const AssignmentListInitial();
}

class AssignmentListLoading extends AssignmentListState {
  const AssignmentListLoading();
}

class AssignmentListLoaded extends AssignmentListState {
  const AssignmentListLoaded(
    this.assignments, {
    this.publishingId,
    this.notice,
    this.noticeIsError = false,
  });

  final List<FacultyAssignment> assignments;

  /// Assignment currently being published (for a button loader).
  final int? publishingId;

  /// One-time message to show as a snackbar.
  final String? notice;
  final bool noticeIsError;
}

class AssignmentListFailed extends AssignmentListState {
  const AssignmentListFailed(this.message);

  final String message;
}