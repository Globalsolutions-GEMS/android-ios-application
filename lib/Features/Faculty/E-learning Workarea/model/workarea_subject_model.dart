/// A section assigned to a faculty subject allotment.
class WorkAreaSection {
  final int id;
  final String name;
  final bool isActive;

  const WorkAreaSection({
    required this.id,
    required this.name,
    required this.isActive,
  });

  factory WorkAreaSection.fromJson(Map<String, dynamic> json) {
    return WorkAreaSection(
      id: _toInt(json['sectionId'] ?? json['id']),
      name: json['sectionName']?.toString() ??
          json['name']?.toString() ??
          '',
      isActive: _toBool(json['isActive']),
    );
  }
}

/// Raw allotment row from GET /allotments/all.
class FacultyAllotment {
  final int id;
  final int academicSessionId;
  final int courseId;
  final String courseName;
  final int programId;
  final String programName;
  final int subjectId;
  final String subjectName;
  final String subjectCode;
  final String subjectTypeName;
  final String mediumName;
  final int teacherId;
  final String teacherName;
  final List<WorkAreaSection> sections;
  final bool isActive;

  const FacultyAllotment({
    required this.id,
    required this.academicSessionId,
    required this.courseId,
    required this.courseName,
    required this.programId,
    required this.programName,
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    required this.subjectTypeName,
    required this.mediumName,
    required this.teacherId,
    required this.teacherName,
    required this.sections,
    required this.isActive,
  });

  factory FacultyAllotment.fromJson(Map<String, dynamic> json) {
    final sections = <WorkAreaSection>[];
    final rawSections = json['sections'];
    if (rawSections is List) {
      for (final section in rawSections) {
        if (section is Map) {
          sections.add(
            WorkAreaSection.fromJson(Map<String, dynamic>.from(section)),
          );
        }
      }
    }

    return FacultyAllotment(
      id: _toInt(json['id']),
      academicSessionId: _toInt(json['academicSessionId']),
      courseId: _toInt(json['courseId']),
      courseName: json['courseName']?.toString() ?? '',
      programId: _toInt(json['programId']),
      programName: json['programName']?.toString() ?? '',
      subjectId: _toInt(json['subjectId']),
      subjectName: json['subjectName']?.toString() ?? '',
      subjectCode: json['subjectCode']?.toString() ?? '',
      subjectTypeName: json['subjectTypeName']?.toString() ?? '',
      mediumName: json['mediumName']?.toString() ?? '',
      teacherId: _toInt(json['teacherId']),
      teacherName: json['teacherName']?.toString() ?? '',
      sections: sections,
      isActive: _toBool(json['isActive']),
    );
  }
}

/// A subject card shown on the subject selection screen.
///
/// Carries the full selection context that downstream modules
/// (Teaching Plan, Assignments, ...) need. [allotmentId] is the key
/// value (`teacherid` on the backend) used for module APIs.
class WorkAreaSubject {
  final int allotmentId;
  final int facultyUserId;
  final int subjectId;
  final String subjectName;
  final int courseId;
  final String courseName;
  final String? subjectCode;
  final List<int> sectionIds;
  final List<String> sectionNames;

  const WorkAreaSubject({
    required this.allotmentId,
    required this.facultyUserId,
    required this.subjectId,
    required this.subjectName,
    required this.courseId,
    required this.courseName,
    this.subjectCode,
    this.sectionIds = const [],
    this.sectionNames = const [],
  });

  factory WorkAreaSubject.fromAllotment(FacultyAllotment allotment) {
    final activeSections =
        allotment.sections.where((section) => section.isActive).toList();
    return WorkAreaSubject(
      allotmentId: allotment.id,
      facultyUserId: allotment.teacherId,
      subjectId: allotment.subjectId,
      subjectName: allotment.subjectName.trim(),
      courseId: allotment.courseId,
      courseName: allotment.courseName.trim(),
      subjectCode: allotment.subjectCode.trim().isEmpty
          ? null
          : allotment.subjectCode.trim(),
      sectionIds: activeSections.map((section) => section.id).toList(),
      sectionNames:
          activeSections.map((section) => section.name).toList(),
    );
  }

  /// Backwards-compatible accessors for the previous card layout.
  int get id => subjectId;
  String get name => subjectName;
  String get courseCode => subjectCode ?? '';
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
