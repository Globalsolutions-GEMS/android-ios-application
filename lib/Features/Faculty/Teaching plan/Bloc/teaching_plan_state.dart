import 'package:flutter/foundation.dart';

import '../model/teaching_plan_model.dart';

@immutable
abstract class TeachingPlanState {
  const TeachingPlanState();
}

class TeachingPlanInitial extends TeachingPlanState {
  const TeachingPlanInitial();
}

class TeachingPlanLoading extends TeachingPlanState {
  const TeachingPlanLoading();
}

class TeachingPlanLoaded extends TeachingPlanState {
  const TeachingPlanLoaded({
    required this.units,
    required this.selectedUnitId,
    required this.topics,
    required this.topicsLoading,
    required this.plans,
    required this.conflicts,
    this.isMutating = false,
    this.mutationMessage,
  });

  final List<TeachingPlanUnit> units;
  final int? selectedUnitId;
  final List<TeachingPlanTopic> topics;
  final bool topicsLoading;
  final List<TeachingPlan> plans;
  final List<TeachingPlanConflict> conflicts;
  final bool isMutating;
  final String? mutationMessage;

  TeachingPlanLoaded copyWith({
    List<TeachingPlanUnit>? units,
    int? selectedUnitId,
    bool clearSelectedUnit = false,
    List<TeachingPlanTopic>? topics,
    bool? topicsLoading,
    List<TeachingPlan>? plans,
    List<TeachingPlanConflict>? conflicts,
    bool? isMutating,
    String? mutationMessage,
    bool clearMutationMessage = false,
  }) {
    return TeachingPlanLoaded(
      units: units ?? this.units,
      selectedUnitId:
          clearSelectedUnit ? null : (selectedUnitId ?? this.selectedUnitId),
      topics: topics ?? this.topics,
      topicsLoading: topicsLoading ?? this.topicsLoading,
      plans: plans ?? this.plans,
      conflicts: conflicts ?? this.conflicts,
      isMutating: isMutating ?? this.isMutating,
      mutationMessage: clearMutationMessage
          ? null
          : (mutationMessage ?? this.mutationMessage),
    );
  }
}

class TeachingPlanFailure extends TeachingPlanState {
  const TeachingPlanFailure(this.message);

  final String message;
}
