class AttendanceSessionModel {
  const AttendanceSessionModel({
    required this.id,
    required this.name,
    this.academicSessionId,
  });

  final int id;
  final String name; // attendanceSessionName
  final int? academicSessionId; // academicSession.id

  factory AttendanceSessionModel.fromJson(Map<String, dynamic> json) =>
      AttendanceSessionModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['attendanceSessionName'] as String? ?? '',
        academicSessionId: (json['academicSession']?['id'] as num?)?.toInt(),
      );
}

class DayModel {
  const DayModel({
    required this.id,
    required this.day,
    required this.shortName,
    this.isWeeklyOff = false,
  });

  final int id;
  final String day;
  final String shortName;
  final bool isWeeklyOff;

  factory DayModel.fromJson(Map<String, dynamic> json) => DayModel(
    id: (json['id'] as num?)?.toInt() ?? 0,
    day: json['day'] as String? ?? '',
    shortName: json['shortName'] as String? ?? '',
    isWeeklyOff: json['isWeeklyOff'] as bool? ?? false,
  );
}

class AttendanceStatusModel {
  const AttendanceStatusModel({
    required this.id,
    required this.name,
    this.isDefault = false,
  });

  final int id;
  final String name; // statusName
  final bool isDefault;

  factory AttendanceStatusModel.fromJson(Map<String, dynamic> json) =>
      AttendanceStatusModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['statusName'] as String? ?? '',
        isDefault: json['isDefault'] as bool? ?? false,
      );
}

int _asInt(dynamic value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;

Map<String, dynamic> _asMap(dynamic value) =>
    value is Map<String, dynamic> ? value : const {};

/// One row of GET /time-table/by-teacher-and-day.
class TimetableItemModel {
  const TimetableItemModel({
    required this.id,
    required this.subjectTeacherId,
    required this.subjectId,
    required this.subjectName,
    required this.courseId,
    required this.courseName,
    required this.sectionId,
    required this.sectionName,
    required this.mediumId,
    required this.slotId,
    required this.slotName,
    required this.fromTime,
    required this.toTime,
    required this.attendanceSessionId,
    required this.academicSessionId,
  });

  final int id;
  final int subjectTeacherId; // subjectTeacher.id (allotment)
  final int subjectId;
  final String subjectName;
  final int courseId;
  final String courseName;
  final int sectionId;
  final String sectionName;
  final int mediumId;
  final int slotId;
  final String slotName;
  final String fromTime;
  final String toTime;
  final int attendanceSessionId;
  final int academicSessionId;

  factory TimetableItemModel.fromJson(Map<String, dynamic> json) {
    final subjectTeacher = _asMap(json['subjectTeacher']);
    final subject = _asMap(subjectTeacher['subject']);
    final course = _asMap(json['course']);
    final section = _asMap(json['section']);
    final medium = _asMap(json['medium']);
    final slot = _asMap(json['slot']);

    return TimetableItemModel(
      id: _asInt(json['id']),
      subjectTeacherId: _asInt(subjectTeacher['id']),
      subjectId: _asInt(subject['id']),
      subjectName: subject['subjectName'] as String? ?? '',
      courseId: _asInt(course['id']),
      courseName: course['courseName'] as String? ?? '',
      sectionId: _asInt(section['id']),
      sectionName: section['sectionName'] as String? ?? '',
      mediumId: _asInt(medium['id']),
      slotId: _asInt(slot['id']),
      slotName: slot['slotName'] as String? ?? '',
      fromTime: slot['fromTime'] as String? ?? '',
      toTime: slot['toTime'] as String? ?? '',
      attendanceSessionId: _asInt(_asMap(json['attendanceSession'])['id']),
      academicSessionId: _asInt(
        _asMap(subjectTeacher['academicSession'])['id'],
      ),
    );
  }
}

/// Same subject + course + slot taught in one or more divisions.
class SubjectGroupModel {
  const SubjectGroupModel({required this.label, required this.divisions});

  final String label;
  final List<TimetableItemModel> divisions;

  static List<SubjectGroupModel> groupFrom(List<TimetableItemModel> items) {
    final groups = <String, List<TimetableItemModel>>{};
    for (final item in items) {
      if (item.subjectId == 0 || item.courseId == 0 || item.slotId == 0) {
        continue;
      }
      groups
          .putIfAbsent(
            '${item.subjectId}|${item.courseId}|${item.slotId}',
            () => [],
          )
          .add(item);
    }

    return groups.values.map((divisions) {
      final first = divisions.first;
      final names = divisions
          .map((d) => d.sectionName.isEmpty ? '?' : d.sectionName)
          .join(', ');
      return SubjectGroupModel(
        label:
            '${first.subjectName} - ${first.courseName} - ${first.slotName} '
            '(${first.fromTime} to ${first.toTime}) (Divisions: $names)',
        divisions: divisions,
      );
    }).toList();
  }
}

/// One student from GET /subject-preference/filter-students.
class StudentModel {
  const StudentModel({
    required this.id,
    required this.firstName,
    required this.middleName,
    required this.surname,
    required this.sectionId,
    required this.sectionName,
    required this.academicSessionId,
    this.rollNumber,
  });

  final int id;
  final String firstName;
  final String middleName;
  final String surname;
  final String? rollNumber;
  final int sectionId;
  final String sectionName;
  final int academicSessionId;

  String get fullName => [
    firstName,
    middleName,
    surname,
  ].where((part) => part.trim().isNotEmpty).join(' ');

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    final section = _asMap(json['section']);
    return StudentModel(
      id: _asInt(json['id']),
      firstName: json['firstName'] as String? ?? '',
      middleName: json['middleName'] as String? ?? '',
      surname: json['surname'] as String? ?? '',
      rollNumber: json['rollNumber']?.toString(),
      sectionId: _asInt(section['id']),
      sectionName: section['sectionName'] as String? ?? '',
      academicSessionId: _asInt(_asMap(json['academicSession'])['id']),
    );
  }
}

/// One topic from GET /topics/by-subject.
class TopicModel {
  const TopicModel({required this.id, required this.name, this.noOfLectures});

  final int id;
  final String name; // topicName
  final int? noOfLectures;

  // Web uses (noOfLectures || 1)
  int get requiredLectures =>
      (noOfLectures == null || noOfLectures == 0) ? 1 : noOfLectures!;

  factory TopicModel.fromJson(Map<String, dynamic> json) => TopicModel(
    id: _asInt(json['id']),
    name: json['topicName'] as String? ?? '',
    noOfLectures: (json['noOfLectures'] as num?)?.toInt(),
  );
}

/// Already marked attendance from GET /attendance-details.
class AttendanceDetailsModel {
  const AttendanceDetailsModel({this.statuses = const {}, this.topicId});

  final Map<int, int> statuses; // studentId -> statusId
  final int? topicId; // topic covered in that lecture

  factory AttendanceDetailsModel.fromJson(dynamic body) {
    if (body is! Map<String, dynamic>) return const AttendanceDetailsModel();

    final statuses = <int, int>{};
    final records = body['studentAttendances'];
    if (records is List) {
      for (final record in records) {
        if (record is! Map<String, dynamic>) continue;
        final studentId = _asInt(_asMap(record['student'])['id']);
        final statusId = _asInt(_asMap(record['attendanceStatus'])['id']);
        if (studentId != 0) statuses[studentId] = statusId;
      }
    }

    int? topicId;
    final topics = body['topicsCovered'];
    if (topics is List && topics.isNotEmpty) {
      final first = topics.first;
      if (first is Map<String, dynamic>) {
        final id = _asInt(_asMap(first['topic'])['id']);
        if (id != 0) topicId = id;
      }
    }

    return AttendanceDetailsModel(statuses: statuses, topicId: topicId);
  }
}

/// Lectures done per topic (topicId -> count).
/// One lecture = one distinct date + slot, same as the web.
Map<int, int> topicCoverageFrom(
  dynamic body, {
  required int subjectId,
  int? academicSessionId,
}) {
  if (body is! List) return {};

  final lectures = <int, Set<String>>{};
  for (final record in body) {
    if (record is! Map<String, dynamic>) continue;

    final schedule = _asMap(record['attendanceSchedule']);
    final subjectTeacher = _asMap(schedule['subjectTeacher']);

    final sessionId = _asInt(_asMap(subjectTeacher['academicSession'])['id']);
    if (academicSessionId != null && sessionId != academicSessionId) continue;
    if (_asInt(_asMap(subjectTeacher['subject'])['id']) != subjectId) continue;

    final date = schedule['attendanceDate'] as String?;
    final slotId = _asInt(_asMap(schedule['attendanceSlot'])['id']);
    if (date == null || slotId == 0) continue;

    final topics = record['topicsCovered'];
    if (topics is! List) continue;
    for (final entry in topics) {
      if (entry is! Map<String, dynamic>) continue;
      final topicId = _asInt(_asMap(entry['topic'])['id']);
      if (topicId != 0) {
        lectures.putIfAbsent(topicId, () => {}).add('$date|$slotId');
      }
    }
  }

  return {for (final e in lectures.entries) e.key: e.value.length};
}
