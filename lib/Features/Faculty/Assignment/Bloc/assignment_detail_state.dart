import 'package:flutter/foundation.dart';

import '../model/assignment_model.dart';

@immutable
abstract class AssignmentDetailState {
  const AssignmentDetailState();
}

class AssignmentDetailInitial extends AssignmentDetailState {
  const AssignmentDetailInitial();
}

class AssignmentDetailLoading extends AssignmentDetailState {
  const AssignmentDetailLoading();
}

class AssignmentDetailLoaded extends AssignmentDetailState {
  const AssignmentDetailLoaded(
    this.submissions, {
    this.isApproving = false,
    this.notice,
    this.noticeIsError = false,
  });

  final List<AssignmentSubmission> submissions;
  final bool isApproving;

  /// One-time message to show as a snackbar.
  final String? notice;
  final bool noticeIsError;
}

class AssignmentDetailFailed extends AssignmentDetailState {
  const AssignmentDetailFailed(this.message);

  final String message;
}