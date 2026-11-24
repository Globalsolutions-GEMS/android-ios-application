import 'package:flutter/foundation.dart';

import '../model/workarea_subject_model.dart';

@immutable
abstract class WorkAreaSubjectState {
  const WorkAreaSubjectState();
}

class WorkAreaSubjectInitial extends WorkAreaSubjectState {
  const WorkAreaSubjectInitial();
}

class WorkAreaSubjectLoading extends WorkAreaSubjectState {
  const WorkAreaSubjectLoading();
}

class WorkAreaSubjectsLoaded extends WorkAreaSubjectState {
  const WorkAreaSubjectsLoaded(this.subjects);

  final List<WorkAreaSubject> subjects;
}

class WorkAreaSubjectFailure extends WorkAreaSubjectState {
  const WorkAreaSubjectFailure(this.message);

  final String message;
}
