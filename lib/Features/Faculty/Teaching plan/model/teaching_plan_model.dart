/// Unit returned by GET /units?subjectId=.
class TeachingPlanUnit {
  final int id;
  final String unitNo;
  final String unitName;

  const TeachingPlanUnit({
    required this.id,
    required this.unitNo,
    required this.unitName,
  });

  String get displayName =>
      unitNo.trim().isEmpty ? unitName : '$unitNo - $unitName';

  factory TeachingPlanUnit.fromJson(Map<String, dynamic> json) {
    return TeachingPlanUnit(
      id: _toInt(json['id']),
      unitNo: json['unitNo']?.toString() ??
          json['unitNumber']?.toString() ??
          '',
      unitName: json['unitName']?.toString() ??
          json['name']?.toString() ??
          '',
    );
  }
}

/// Topic returned by GET /topics?unitId=.
class TeachingPlanTopic {
  final int id;
  final int unitId;
  final String topicNumber;
  final String topicName;
  final bool active;

  const TeachingPlanTopic({
    required this.id,
    required this.unitId,
    required this.topicNumber,
    required this.topicName,
    required this.active,
  });

  String get displayName => topicName;

  factory TeachingPlanTopic.fromJson(Map<String, dynamic> json) {
    final unit = json['unit'];
    return TeachingPlanTopic(
      id: _toInt(json['id']),
      unitId: _toInt(
        unit is Map ? unit['id'] : (json['unitId'] ?? 0),
      ),
      topicNumber: json['topicNumber']?.toString() ?? '',
      topicName: json['topicName']?.toString() ??
          json['name']?.toString() ??
          '',
      active: _toBool(json['active']),
    );
  }
}

/// A saved teaching plan returned by
/// GET /api/teaching-plan/allotment/{teacherid}.
class TeachingPlan {
  final int id;
  final int allotmentId;
  final int courseId;
  final int subjectId;
  final String subjectName;
  final int unitId;
  final String unitName;
  final int topicId;
  final String topicName;
  final String? objective;
  final String teachingMode;
  final DateTime? plannedDate;
  final String status;
  final bool editable;
  final int academicSession;
  final DateTime? deliveredDate;

  const TeachingPlan({
    required this.id,
    required this.allotmentId,
    required this.courseId,
    required this.subjectId,
    required this.subjectName,
    required this.unitId,
    required this.unitName,
    required this.topicId,
    required this.topicName,
    required this.objective,
    required this.teachingMode,
    required this.plannedDate,
    required this.status,
    required this.editable,
    required this.academicSession,
    required this.deliveredDate,
  });

  bool get isDelivered => deliveredDate != null;

  factory TeachingPlan.fromJson(Map<String, dynamic> json) {
    return TeachingPlan(
      id: _toInt(json['id']),
      allotmentId: _toInt(json['subjectTeacherAllotmentId'] ?? json['allotmentId']),
      courseId: _toInt(json['courseId']),
      subjectId: _toInt(json['subjectId']),
      subjectName: json['subjectName']?.toString() ?? '',
      unitId: _toInt(json['unitId']),
      unitName: json['unitName']?.toString() ?? '',
      topicId: _toInt(json['topicId']),
      topicName: json['topicName']?.toString() ?? '',
      objective: json['objective']?.toString(),
      teachingMode: json['teachingMode']?.toString() ?? '',
      plannedDate: _toDate(json['plannedDate']),
      status: json['status']?.toString() ?? '',
      editable: _toBool(json['editable']),
      academicSession: _toInt(json['academicSession']),
      deliveredDate: _toDate(json['deliveredDate']),
    );
  }
}

/// A plan on a given date returned by GET /api/teaching-plan/conflicts,
/// used for same-date conflict awareness across subjects.
class TeachingPlanConflict {
  final int planId;
  final String subjectName;
  final String unitName;
  final String topic;
  final DateTime? plannedDate;
  final String courseName;
  final int academicSession;

  const TeachingPlanConflict({
    required this.planId,
    required this.subjectName,
    required this.unitName,
    required this.topic,
    required this.plannedDate,
    required this.courseName,
    required this.academicSession,
  });

  factory TeachingPlanConflict.fromJson(Map<String, dynamic> json) {
    return TeachingPlanConflict(
      planId: _toInt(json['planId'] ?? json['id']),
      subjectName: json['subjectName']?.toString() ?? '',
      unitName: json['unitName']?.toString() ?? '',
      topic: json['topic']?.toString() ??
          json['topicName']?.toString() ??
          '',
      plannedDate: _toDate(json['plannedDate']),
      courseName: json['courseName']?.toString() ?? '',
      academicSession: _toInt(json['academicSession']),
    );
  }
}

/// Card item shown in the teaching plan list (mobile view of [TeachingPlan]).
class TeachingPlanItem {
  const TeachingPlanItem({
    required this.id,
    required this.unit,
    required this.topic,
    required this.plannedDate,
    required this.teachingMode,
    this.deliveredDate,
    this.objective,
    this.editable = true,
    this.status = 'PLANNED',
  });
  final int id;
  final String unit;
  final String topic;
  final DateTime plannedDate;
  final String teachingMode;
  final DateTime? deliveredDate;
  final String? objective;
  final bool editable;
  final String status;

  factory TeachingPlanItem.fromPlan(TeachingPlan plan) {
    return TeachingPlanItem(
      id: plan.id,
      unit: plan.unitName,
      topic: plan.topicName,
      plannedDate: plan.plannedDate ?? DateTime.now(),
      teachingMode: plan.teachingMode,
      deliveredDate: plan.deliveredDate,
      objective: plan.objective,
      editable: plan.editable,
      status: plan.status,
    );
  }
}

/// Payload returned by the create/edit form screen.
class TeachingPlanDraft {
  const TeachingPlanDraft({
    required this.unitId,
    required this.unitName,
    required this.topicId,
    required this.topicName,
    required this.plannedDate,
    required this.teachingMode,
    required this.objective,
    this.deliveredDate,
    this.id, // Set when editing
    required this.subjectTeacherAllotmentId,
  });
  final int unitId;
  final String unitName;
  final int topicId;
  final String topicName;
  final DateTime plannedDate;
  final String teachingMode;
  final String objective;
  final DateTime? deliveredDate;
  final int? id; // Present only for edits
  final int subjectTeacherAllotmentId;
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool _toBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  return value?.toString().toLowerCase() == 'true';
}

DateTime? _toDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}
