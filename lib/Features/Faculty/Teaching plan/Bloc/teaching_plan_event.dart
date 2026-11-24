import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:erp_app/Features/Faculty/E-learning Workarea/model/workarea_subject_model.dart';
import 'package:erp_app/Features/Faculty/Teaching plan/model/teaching_plan_model.dart';

@immutable
abstract class TeachingPlanEvent {
  const TeachingPlanEvent();
}

class LoadTeachingPlan extends TeachingPlanEvent {
  const LoadTeachingPlan(this.subject);

  final WorkAreaSubject subject;
}

class TeachingPlanUnitSelected extends TeachingPlanEvent {
  const TeachingPlanUnitSelected(this.unitId);

  final int unitId;
}

class TeachingPlanCreate extends TeachingPlanEvent {
  const TeachingPlanCreate(this.draft);

  final TeachingPlanDraft draft;
}

class TeachingPlanUpdate extends TeachingPlanEvent {
  const TeachingPlanUpdate(this.draft);

  final TeachingPlanDraft draft;
}

class TeachingPlanDelete extends TeachingPlanEvent {
  const TeachingPlanDelete(this.planId);

  final int planId;
}

class TeachingPlanBulkUpload extends TeachingPlanEvent {
  const TeachingPlanBulkUpload(this.file);

  final File file;
}
