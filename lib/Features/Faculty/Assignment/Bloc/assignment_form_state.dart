import 'package:flutter/foundation.dart';

import '../model/assignment_model.dart';

@immutable
abstract class AssignmentFormState {
  const AssignmentFormState();
}

class AssignmentFormInitial extends AssignmentFormState {
  const AssignmentFormInitial();
}

class AssignmentFormLoading extends AssignmentFormState {
  const AssignmentFormLoading();
}

class AssignmentFormLoaded extends AssignmentFormState {
  const AssignmentFormLoaded(
    this.students, {
    this.isSubmitting = false,
    this.saved = false,
    this.notice,
    this.noticeIsError = false,
  });

  final List<AssignmentStudent> students;
  final bool isSubmitting;

  /// true after a successful create/update (screen should close).
  final bool saved;

  /// One-time message to show as a snackbar.
  final String? notice;
  final bool noticeIsError;
}

class AssignmentFormFailed extends AssignmentFormState {
  const AssignmentFormFailed(this.message);

  final String message;
}