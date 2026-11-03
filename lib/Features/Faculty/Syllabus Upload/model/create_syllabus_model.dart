class FacultySubject {
  final int id;
  final String subjectName;
  final String subjectCode;

  const FacultySubject({
    required this.id,
    required this.subjectName,
    required this.subjectCode,
  });

  factory FacultySubject.fromJson(Map<String, dynamic> json) {
    final subject = json['subject'] as Map<String, dynamic>? ?? json;

    return FacultySubject(
      id: _toInt(subject['id']),
      subjectName: subject['subjectName']?.toString() ?? '',
      subjectCode: subject['subjectCode']?.toString() ?? '',
    );
  }
}

class SyllabusUnit {
  final int id;
  final int subjectId;
  final String unitNo;
  final String unitName;
  final bool active;

  const SyllabusUnit({
    required this.id,
    required this.subjectId,
    required this.unitNo,
    required this.unitName,
    required this.active,
  });

  factory SyllabusUnit.fromJson(Map<String, dynamic> json) {
    final subject = json['subject'] as Map<String, dynamic>?;

    return SyllabusUnit(
      id: _toInt(json['id']),
      subjectId: _toInt(subject?['id']),
      unitNo: json['unitNo']?.toString() ?? '',
      unitName: json['unitName']?.toString() ?? '',
      active: _toBool(json['active']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'unitNo': unitNo,
      'unitName': unitName,
      'active': active,
    };
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool _toBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;

  return value?.toString().toLowerCase() == 'true';
}
class SyllabusTopic {
  final int id;
  final int unitId;
  final String topicNumber;
  final String topicName;
  final String description;
  final int noOfLectures;
  final bool active;

  const SyllabusTopic({
    required this.id,
    required this.unitId,
    required this.topicNumber,
    required this.topicName,
    required this.description,
    required this.noOfLectures,
    required this.active,
  });

  factory SyllabusTopic.fromJson(Map<String, dynamic> json) {
    final unit = json['unit'] is Map
        ? Map<String, dynamic>.from(json['unit'] as Map)
        : null;

    return SyllabusTopic(
      id: _toInt(json['id']),
      unitId: _toInt(unit?['id'] ?? json['unitId']),
      topicNumber: json['topicNumber']?.toString() ?? '',
      topicName: json['topicName']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      noOfLectures: _toInt(json['noOfLectures']),
      active: _toBool(json['active']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'topicNumber': topicNumber,
      'topicName': topicName,
      'description': description,
      'noOfLectures': noOfLectures,
      'active': active,
    };
  }
}