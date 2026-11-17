import 'package:flutter/foundation.dart';

@immutable
abstract class WorkAreaSubjectEvent {
  const WorkAreaSubjectEvent();
}

class LoadWorkAreaSubjects extends WorkAreaSubjectEvent {
  const LoadWorkAreaSubjects();
}
