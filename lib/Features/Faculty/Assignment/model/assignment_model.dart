/// Student shown in the assignment student list / details.
/// Built from /studentadmissions/filter and assignment `admissions`.
class AssignmentStudent {
  final int id;
  final String firstName;
  final String middleName;
  final String surname;
  final String rollNumber;
  final int courseId;
  final int sectionId;
  final int academicSessionId;
  final int admissionStatusId;

  const AssignmentStudent({
    required this.id,
    required this.firstName,
    required this.middleName,
    required this.surname,
    required this.rollNumber,
    this.courseId = 0,
    this.sectionId = 0,
    this.academicSessionId = 0,
    this.admissionStatusId = 0,
  });

  factory AssignmentStudent.fromJson(Map<String, dynamic> json) {
    return AssignmentStudent(
      id: _toInt(json['id']),
      firstName: json['firstName']?.toString() ?? '',
      middleName: json['middleName']?.toString() ?? '',
      surname: json['surname']?.toString() ?? '',
      rollNumber: json['rollNumber']?.toString() ?? '',
      courseId: _toInt(_map(json['course'])['id']),
      sectionId: _toInt(_map(json['section'])['id']),
      academicSessionId: _toInt(_map(json['academicSession'])['id']),
      admissionStatusId: _toInt(_map(json['admissionStatus'])['id']),
    );
  }

  String get fullName => [firstName, middleName, surname]
      .where((part) => part.trim().isNotEmpty)
      .join(' ')
      .trim();
}

/// Row of /prefrenceselectionfinalall: which student took which subject.
class StudentSubjectMapping {
  final int studentId;
  final int subjectId;
  final int courseId;

  const StudentSubjectMapping({
    required this.studentId,
    required this.subjectId,
    required this.courseId,
  });

  factory StudentSubjectMapping.fromJson(Map<String, dynamic> json) {
    return StudentSubjectMapping(
      studentId: _toInt(_map(json['student'])['id']),
      subjectId: _toInt(_map(json['subjectDefinition'])['id']),
      courseId: _toInt(_map(json['course'])['id']),
    );
  }
}

/// Assignment row from GET /api/elearning-assignments/{subjectId}.
class FacultyAssignment {
  final int assignmentId;
  final int subjectId;
  final String title;
  final String description;
  final double marks;
  final DateTime? dueDate;
  final String submission; // "online" or "offline"
  final List<int> studentIds;
  final List<AssignmentStudent> students;
  final bool? isPublish; // can be null for old rows
  final int allotmentId;
  final int? academicSessionId;
  final String? attachmentName;

  const FacultyAssignment({
    required this.assignmentId,
    required this.subjectId,
    required this.title,
    required this.description,
    required this.marks,
    required this.dueDate,
    required this.submission,
    required this.studentIds,
    required this.students,
    required this.isPublish,
    required this.allotmentId,
    required this.academicSessionId,
    required this.attachmentName,
  });

  factory FacultyAssignment.fromJson(Map<String, dynamic> json) {
    final ids = json['studentIds'];
    final admissions = json['admissions'];
    final sessionId = json['academicSessionId'];
    final attachment = json['attachmentName']?.toString();

    return FacultyAssignment(
      assignmentId: _toInt(json['assignmentId']),
      subjectId: _toInt(json['subjectId']),
      title: json['assignmentTitle']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      marks: (json['assignmentMarks'] as num?)?.toDouble() ?? 0,
      dueDate: DateTime.tryParse(json['dateOfSubmission']?.toString() ?? ''),
      submission: (json['submission']?.toString() ?? '').toLowerCase(),
      studentIds: ids is List ? ids.map(_toInt).toList() : <int>[],
      students: admissions is List
          ? admissions
              .whereType<Map>()
              .map((e) =>
                  AssignmentStudent.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : <AssignmentStudent>[],
      isPublish: json['isPublish'] is bool ? json['isPublish'] as bool : null,
      allotmentId: _toInt(json['subjectTeacherAllotmentId']),
      academicSessionId: sessionId == null ? null : _toInt(sessionId),
      attachmentName:
          (attachment == null || attachment.isEmpty) ? null : attachment,
    );
  }

  FacultyAssignment copyWith({bool? isPublish}) {
    return FacultyAssignment(
      assignmentId: assignmentId,
      subjectId: subjectId,
      title: title,
      description: description,
      marks: marks,
      dueDate: dueDate,
      submission: submission,
      studentIds: studentIds,
      students: students,
      isPublish: isPublish ?? this.isPublish,
      allotmentId: allotmentId,
      academicSessionId: academicSessionId,
      attachmentName: attachmentName,
    );
  }

  bool get isPublished => isPublish == true;
  bool get isOffline => submission == 'offline';
  bool get isExpired => dueDate != null && dueDate!.isBefore(DateTime.now());
}

/// Body for create / update assignment (sent as `assignmentRequest`).
class AssignmentRequest {
  final String title;
  final String description;
  final double marks;
  final DateTime dueDate;
  final String submission; // "online" or "offline"
  final int subjectId;
  final int allotmentId;
  final List<int> studentIds;

  const AssignmentRequest({
    required this.title,
    required this.description,
    required this.marks,
    required this.dueDate,
    required this.submission,
    required this.subjectId,
    required this.allotmentId,
    required this.studentIds,
  });

  Map<String, dynamic> toJson() => {
        'assignmentTitle': title,
        'description': description,
        'assignmentMarks': marks,
        'dateOfSubmission': _apiDateTime(dueDate),
        'submission': submission,
        'subjectId': subjectId,
        'hoursReq': null,
        'lastTime': null,
        'documentCompulsion': false,
        'isPublish': false,
        'studentIds': studentIds,
        'subjectTeacherAllotmentId': allotmentId,
      };
}
/// Row of GET /api/assessment/submissions/{assignmentId}.
class AssignmentSubmission {
  final int submissionId;
  final int studentId;
  final String studentName;
  final String textAnswer;
  final int attachmentCount;
  final double? marks;
  final String? remarks;
  final String status; // PENDING, DRAFT, PUBLISHED
  final int assignmentId;
  final int allotmentId;
  final bool approved;

  const AssignmentSubmission({
    required this.submissionId,
    required this.studentId,
    required this.studentName,
    required this.textAnswer,
    required this.attachmentCount,
    required this.marks,
    required this.remarks,
    required this.status,
    required this.assignmentId,
    required this.allotmentId,
    required this.approved,
  });

  factory AssignmentSubmission.fromJson(Map<String, dynamic> json) {
    final attachments = json['attachments'];
    return AssignmentSubmission(
      submissionId: _toInt(json['submissionId']),
      studentId: _toInt(json['studentId']),
      studentName: json['studentFullName']?.toString() ?? '',
      textAnswer: json['textAnswer']?.toString() ?? '',
      attachmentCount: attachments is List ? attachments.length : 0,
      marks: (json['existingMarks'] as num?)?.toDouble(),
      remarks: json['existingRemarks']?.toString(),
      status: json['status']?.toString() ?? '',
      assignmentId: _toInt(json['assignmentId']),
      allotmentId: _toInt(json['subjectTeacherAllotmentId']),
      approved: json['approved'] == true,
    );
  }
}
/// yyyy-MM-ddTHH:mm:00 (same format as the web app).
String _apiDateTime(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)}T${two(d.hour)}:${two(d.minute)}:00';
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}