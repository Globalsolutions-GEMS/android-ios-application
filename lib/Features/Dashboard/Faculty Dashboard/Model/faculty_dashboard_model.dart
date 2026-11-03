/// Topic progress details for display in the topics popup.
class TopicProgress {
  const TopicProgress({
    required this.topicId,
    required this.topicName,
    required this.unitName,
    required this.requiredLectures,
    required this.coveredLectures,
    required this.isCompleted,
  });

  final int topicId;
  final String topicName;
  final String unitName;
  final int requiredLectures;
  final int coveredLectures;
  final bool isCompleted;
}

/// Subject with its topic progress details.
class SubjectTopicProgress {
  const SubjectTopicProgress({
    required this.subjectId,
    required this.subjectName,
    required this.topics,
  });

  final int subjectId;
  final String subjectName;
  final List<TopicProgress> topics;

  int get completedCount => topics.where((t) => t.isCompleted).length;
  int get totalCount => topics.length;
}



/// Next class information for the "Next Class / Today's Schedule" card.
class NextClassModel {
  const NextClassModel({
    required this.subjectName,
    required this.subjectCode,
    required this.fromTime,
    required this.toTime,
    required this.roomName,
    required this.studentCount,
  });

  final String subjectName;
  final String subjectCode;
  final String fromTime;
  final String toTime;
  final String roomName;
  final int studentCount;
}

/// Today's schedule lecture card model (grouped by slot + subject + course + room)
class TodayScheduleLecture {
  const TodayScheduleLecture({
    required this.fromTime,
    required this.toTime,
    required this.subjectName,
    required this.subjectCode,
    required this.subjectType,
    required this.courseName,
    required this.divisions,
    required this.roomName,
    required this.totalStudents,
  });

  final String fromTime;
  final String toTime;
  final String subjectName;
  final String subjectCode;
  final String subjectType;
  final String courseName;
  final List<String> divisions;
  final String roomName;
  final int totalStudents;
}

/// Weekly schedule cell model
class WeeklyScheduleCell {
  const WeeklyScheduleCell({
    required this.subjectName,
    required this.courseName,
    required this.roomName,
    required this.subjectType,
    this.hasOnlineMeeting = false,
  });

  final String subjectName;
  final String courseName;
  final String roomName;
  final String subjectType;
  final bool hasOnlineMeeting;
}

/// Time slot for weekly schedule
class TimeSlot {
  const TimeSlot({required this.fromTime, required this.toTime});

  final String fromTime;
  final String toTime;
}

/// Class-wise attendance statistics for bar chart
class ClassAttendanceStats {
  const ClassAttendanceStats({
    required this.label,
    required this.present,
    required this.total,
  });

  final String label; // Format: "SubjectCode (CourseName)"
  final int present;
  final int total;

  double get percentage => total > 0 ? (present / total) * 100 : 0;
}

/// Overall attendance statistics for donut chart
class OverallAttendanceStats {
  const OverallAttendanceStats({
    required this.present,
    required this.absent,
  });

  final int present;
  final int absent;

  int get total => present + absent;
}

/// Descriptive test awaiting marks entry
class PendingTest {
  const PendingTest({
    required this.id,
    required this.title,
    required this.questionType,
    required this.subjectName,
    required this.courseName,
    required this.maxMarks,
    required this.durationMinutes,
    required this.endDate,
    required this.endTime,
    required this.totalStudents,
    required this.submittedCount,
    required this.subjectId,
    required this.courseId,
    required this.subjectTeacherAllotmentId,
  });

  final int id;
  final String title;
  final String questionType;
  final String subjectName;
  final String courseName;
  final int maxMarks;
  final int durationMinutes;
  final String endDate;
  final String endTime;
  final int totalStudents;
  final int submittedCount;
  final int subjectId;
  final int courseId;
  final int subjectTeacherAllotmentId;

  double get submissionProgress => totalStudents > 0 ? submittedCount / totalStudents : 0;
}

/// Ended assignment awaiting evaluation
class PendingAssignment {
  const PendingAssignment({
    required this.id,
    required this.assignmentTitle,
    required this.subjectName,
    required this.courseName,
    required this.assignmentMarks,
    required this.dateOfSubmission,
    required this.totalStudents,
    required this.submittedCount,
    required this.subjectId,
    required this.courseId,
    required this.subjectTeacherAllotmentId,
  });

  final int id;
  final String assignmentTitle;
  final String subjectName;
  final String courseName;
  final int assignmentMarks;
  final String dateOfSubmission;
  final int totalStudents;
  final int submittedCount;
  final int subjectId;
  final int courseId;
  final int subjectTeacherAllotmentId;

  double get submissionProgress => totalStudents > 0 ? submittedCount / totalStudents : 0;
}

/// Values shown on the three faculty dashboard stat cards.
/// Values shown on the faculty dashboard cards.
class FacultyDashboardStats {
  const FacultyDashboardStats({
    this.subjectsAssigned = 0,
    this.totalStudents = 0,
    this.classesThisWeek = 0,
    this.todayTotal = 0,
    this.todayConducted = 0,
    this.thisMonthConducted = 0,
    this.thisMonthTotal = 0,
    this.totalConducted = 0,
    this.totalLectures = 0,
    this.topicsCompleted = 0,
    this.totalTopics = 0,
    this.nextClass,
  });

  final int subjectsAssigned;
  final int totalStudents;
  final int classesThisWeek;
  final int todayTotal;
  final int todayConducted;
  final int thisMonthConducted;
  final int thisMonthTotal;
  final int totalConducted;
  final int totalLectures;
  final int topicsCompleted;
  final int totalTopics;
  final NextClassModel? nextClass;
}

class FacultyDashboardCalculator {
  FacultyDashboardCalculator._();

  /// `admission_status.id` for "admitted" (same value the web dashboard uses).
  static const int admittedStatusId = 2;

  /// GET /academicsession -> id of the active session.
  /// Falls back to the first item (the API returns newest first).
  static int? currentSessionId(dynamic body) {
    final sessions = _asMapList(body);
    if (sessions.isEmpty) return null;
    for (final session in sessions) {
      if (session['checkIfActive'] == true) return _asInt(session['id']);
    }
    return _asInt(sessions.first['id']);
  }

  /// Find the academic session that has data for this user from allotments
  static int? findSessionWithData(dynamic body, {required int userId}) {
    final allotments = _asMapList(body);
    final sessionIds = <int>{};
    for (final allotment in allotments) {
      if (_asInt(allotment['teacherId']) == userId) {
        final sessionId = _asInt(allotment['academicSessionId']);
        if (sessionId != null) {
          sessionIds.add(sessionId);
        }
      }
    }
    if (sessionIds.isEmpty) return null;
    // Return the first session found (could be multiple, but pick one)
    return sessionIds.first;
  }

  /// GET /allotments/all -> distinct subjectIds assigned to this faculty
  /// in the given session.
  static Set<int> assignedSubjectIds(
    dynamic body, {
    required int userId,
    required int sessionId,
  }) {
    final ids = <int>{};
    for (final allotment in _asMapList(body)) {
      if (_asInt(allotment['teacherId']) != userId) continue;
      if (_asInt(allotment['academicSessionId']) != sessionId) continue;
      final subjectId = _asInt(allotment['subjectId']);
      if (subjectId != null) ids.add(subjectId);
    }
    return ids;
  }

  /// GET /prefrenceselectionfinalall -> distinct admitted students of the
  /// session who chose one of this faculty's subjects.
  static int totalStudents(
    dynamic body, {
    required Set<int> subjectIds,
    required int sessionId,
  }) {
    if (subjectIds.isEmpty) return 0;
    final studentIds = <int>{};
    for (final selection in _asMapList(body)) {
      final status = _asInt(
        _at(selection, ['student', 'admissionStatus', 'id']),
      );
      if (status != admittedStatusId) continue;

      final session = _asInt(
        _at(selection, ['student', 'academicSession', 'id']),
      );
      if (session != sessionId) continue;

      final subjectId = _asInt(_at(selection, ['subjectDefinition', 'id']));
      if (subjectId == null || !subjectIds.contains(subjectId)) continue;

      final studentId = _asInt(_at(selection, ['student', 'id']));
      if (studentId != null) studentIds.add(studentId);
    }
    return studentIds.length;
  }

  /// GET /time-table -> distinct day + slot + subject + course + room
  /// combinations for this faculty in the given session.
  static int classesThisWeek(
    dynamic body, {
    required int userId,
    required int sessionId,
  }) {
    final combos = <String>{};
    for (final row in _asMapList(body)) {
      final teacher = _asInt(_at(row, ['subjectTeacher', 'ourUsers', 'id']));
      if (teacher != userId) continue;

      final session = _asInt(
        _at(row, ['subjectTeacher', 'subject', 'academicSession', 'id']),
      );
      if (session != sessionId) continue;

      combos.add(
        [
          _at(row, ['day', 'id']),
          _at(row, ['slot', 'id']),
          _at(row, ['subjectTeacher', 'subject', 'id']),
          _at(row, ['course', 'id']),
          _at(row, ['room', 'id']),
        ].join('|'),
      );
    }
    return combos.length;
  }

  static const List<String> _dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  /// Today's lectures for this faculty from GET /time-table.
  static int todayTotal(
    dynamic body, {
    required int userId,
    required int sessionId,
  }) {
    final today = _dayNames[DateTime.now().weekday - 1];
    final combos = <String>{};
    for (final row in _asMapList(body)) {
      if (_at(row, ['day', 'day']) != today) continue;
      if (_asInt(_at(row, ['subjectTeacher', 'ourUsers', 'id'])) != userId) {
        continue;
      }
      if (_asInt(
            _at(row, ['subjectTeacher', 'subject', 'academicSession', 'id']),
          ) !=
          sessionId) {
        continue;
      }
      combos.add(
        [
          _at(row, ['slot', 'id']),
          _at(row, ['subjectTeacher', 'subject', 'id']),
          _at(row, ['course', 'id']),
          _at(row, ['room', 'id']),
        ].join('|'),
      );
    }
    return combos.length;
  }

  /// Calculate the next upcoming class for the "Next Class / Today's Schedule" card.
  /// Returns null if no future class exists today.
  static NextClassModel? calculateNextClass({
    required dynamic timeTableBody,
    required dynamic preferencesBody,
    required int userId,
    required int sessionId,
  }) {
    final now = DateTime.now();
    final today = _dayNames[now.weekday - 1];
    final currentTotalMinutes = now.hour * 60 + now.minute;

    // Step 1: Filter today's classes for this faculty and session
    final todayClasses = <Map<String, dynamic>>[];
    for (final row in _asMapList(timeTableBody)) {
      if (_at(row, ['day', 'day']) != today &&
          _at(row, ['day', 'shortName'])?.toString().toLowerCase() !=
              today.toLowerCase()) {
        continue;
      }
      if (_asInt(_at(row, ['subjectTeacher', 'ourUsers', 'id'])) != userId) {
        continue;
      }
      if (_asInt(
            _at(row, ['subjectTeacher', 'subject', 'academicSession', 'id']),
          ) !=
          sessionId) {
        continue;
      }
      todayClasses.add(row);
    }

    if (todayClasses.isEmpty) return null;

    // Step 2: Filter for classes with start time after current time
    final upcomingClasses = <Map<String, dynamic>>[];
    for (final row in todayClasses) {
      final fromTimeStr = _at(row, ['slot', 'fromTime'])?.toString();
      if (fromTimeStr == null) continue;

      final parts = fromTimeStr.split(':');
      if (parts.length < 2) continue;

      final classHours = int.tryParse(parts[0]);
      final classMinutes = int.tryParse(parts[1]);
      if (classHours == null || classMinutes == null) continue;

      final classTotalMinutes = classHours * 60 + classMinutes;
      if (classTotalMinutes > currentTotalMinutes) {
        upcomingClasses.add(row);
      }
    }

    if (upcomingClasses.isEmpty) return null;

    // Step 3: Sort by start time and pick the first one
    upcomingClasses.sort((a, b) {
      final aTime = _at(a, ['slot', 'fromTime'])?.toString() ?? '';
      final bTime = _at(b, ['slot', 'fromTime'])?.toString() ?? '';
      return aTime.compareTo(bTime);
    });

    final nextClass = upcomingClasses.first;

    // Step 4: Extract class details
    final subjectName =
        _at(nextClass, [
          'subjectTeacher',
          'subject',
          'subjectName',
        ])?.toString() ??
        'Unknown Subject';
    final subjectCode =
        _at(nextClass, [
          'subjectTeacher',
          'subject',
          'subjectCode',
        ])?.toString() ??
        '';
    final fromTime =
        _at(nextClass, ['slot', 'fromTime'])?.toString().substring(0, 5) ?? '';
    final toTime =
        _at(nextClass, ['slot', 'toTime'])?.toString().substring(0, 5) ?? '';
    final roomName = _at(nextClass, ['room', 'roomName'])?.toString() ?? 'TBD';

    // Step 5: Calculate student count from preferences API
    // Count unique students where:
    // - selected subject = next class subject
    // - selected course = next class course
    // - admission status = Admitted (ID 2)
    final subjectId = _asInt(
      _at(nextClass, ['subjectTeacher', 'subject', 'id']),
    );
    final courseId = _asInt(_at(nextClass, ['course', 'id']));

    int studentCount = 0;
    if (subjectId != null && courseId != null) {
      final studentIds = <int>{};
      for (final selection in _asMapList(preferencesBody)) {
        final status = _asInt(
          _at(selection, ['student', 'admissionStatus', 'id']),
        );
        if (status != admittedStatusId) continue;

        final session = _asInt(
          _at(selection, ['student', 'academicSession', 'id']),
        );
        if (session != sessionId) continue;

        final selectionSubjectId = _asInt(
          _at(selection, ['subjectDefinition', 'id']),
        );
        if (selectionSubjectId != subjectId) continue;

        final selectionCourseId = _asInt(_at(selection, ['course', 'id']));
        if (selectionCourseId != courseId) continue;

        final studentId = _asInt(_at(selection, ['student', 'id']));
        if (studentId != null) studentIds.add(studentId);
      }
      studentCount = studentIds.length;
    }

    return NextClassModel(
      subjectName: subjectName,
      subjectCode: subjectCode,
      fromTime: fromTime,
      toTime: toTime,
      roomName: roomName,
      studentCount: studentCount,
    );
  }

  /// Lectures conducted today from GET /get-all-attendance.
  static int todayConducted(dynamic body, {required int userId}) {
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    final ids = <dynamic>{};
    for (final row in _asMapList(body)) {
      final schedule = row['attendanceSchedule'];
      if (_at(schedule, ['attendanceDate']) != today) continue;
      if (_asInt(_at(schedule, ['subjectTeacher', 'ourUsers', 'id'])) !=
          userId) {
        continue;
      }
      ids.add(_at(schedule, ['id']));
    }
    return ids.length;
  }

  /// Calculate topic completion stats from topics and attendance data.
  /// Returns a map with 'completed' and 'total' counts.
  static Map<String, int> calculateTopicCompletion({
    required dynamic topicsBody,
    required dynamic attendanceBody,
    required Set<int> assignedSubjectIds,
    required int sessionId,
  }) {
    // Step 1: Filter topics to only those belonging to assigned subjects
    final filteredTopics = <Map<String, dynamic>>[];
    for (final topic in _asMapList(topicsBody)) {
      final subjectId = _asInt(_at(topic, ['unit', 'subject', 'id']));
      if (subjectId != null && assignedSubjectIds.contains(subjectId)) {
        filteredTopics.add(topic);
      }
    }

    final totalTopics = filteredTopics.length;
    if (totalTopics == 0) {
      return {'completed': 0, 'total': 0};
    }

    // Step 2: For each filtered topic, count unique attendance schedules
    // where this topic was covered
    final completedTopics = <int>[];

    for (final topic in filteredTopics) {
      final topicId = _asInt(topic['id']);
      if (topicId == null) continue;

      final noOfLectures = _asInt(topic['noOfLectures']) ?? 1;

      // Find attendance records where this topic is covered
      final scheduleIds = <int>{};
      for (final attendance in _asMapList(attendanceBody)) {
        final schedule = attendance['attendanceSchedule'];
        if (schedule == null) continue;

        // Filter by current academic session
        final attendanceSessionId = _asInt(
          _at(schedule, ['attendanceSession', 'academicSession', 'id']),
        );
        if (attendanceSessionId != sessionId) continue;

        // Check if this topic is in topicsCovered
        final topicsCovered = _at(attendance, ['topicsCovered']);
        if (topicsCovered is! List) continue;

        for (final covered in topicsCovered) {
          final coveredTopicId = _asInt(_at(covered, ['topic', 'id']));
          if (coveredTopicId == topicId) {
            final scheduleId = _asInt(schedule['id']);
            if (scheduleId != null) {
              scheduleIds.add(scheduleId);
            }
            break; // Found the topic in this attendance record
          }
        }
      }

      // Topic is completed if unique schedule count >= noOfLectures
      if (scheduleIds.length >= noOfLectures) {
        completedTopics.add(topicId);
      }
    }

    return {'completed': completedTopics.length, 'total': totalTopics};
  }

  /// Prepare detailed topic progress grouped by subject for the popup.
  /// Returns a list of SubjectTopicProgress with their topics.
  static List<SubjectTopicProgress> prepareTopicProgressDetails({
    required dynamic topicsBody,
    required dynamic attendanceBody,
    required Set<int> assignedSubjectIds,
    required int sessionId,
  }) {
    // Build a map of topicId -> unique scheduleIds for this session
    final topicScheduleMap = <int, Set<int>>{};

    for (final attendance in _asMapList(attendanceBody)) {
      final schedule = attendance['attendanceSchedule'];
      if (schedule == null) continue;

      // Filter by current academic session
      final attendanceSessionId = _asInt(
        _at(schedule, ['attendanceSession', 'academicSession', 'id']),
      );
      if (attendanceSessionId != sessionId) continue;

      final scheduleId = _asInt(schedule['id']);
      if (scheduleId == null) continue;

      final topicsCovered = _at(attendance, ['topicsCovered']);
      if (topicsCovered is! List) continue;

      for (final covered in topicsCovered) {
        final topicId = _asInt(_at(covered, ['topic', 'id']));
        if (topicId != null) {
          topicScheduleMap.putIfAbsent(topicId, () => <int>{});
          topicScheduleMap[topicId]!.add(scheduleId);
        }
      }
    }

    // Group topics by subject
    final subjectTopicsMap = <int, List<TopicProgress>>{};
    final subjectNames = <int, String>{};

    for (final topic in _asMapList(topicsBody)) {
      final subjectId = _asInt(_at(topic, ['unit', 'subject', 'id']));
      if (subjectId == null || !assignedSubjectIds.contains(subjectId)) {
        continue;
      }

      final topicId = _asInt(topic['id']);
      if (topicId == null) continue;

      final topicName =
          _at(topic, ['topicName'])?.toString() ?? 'Unknown Topic';
      final unitName =
          _at(topic, ['unit', 'unitName'])?.toString() ?? 'Unknown Unit';
      final requiredLectures = _asInt(topic['noOfLectures']) ?? 1;
      final coveredLectures = topicScheduleMap[topicId]?.length ?? 0;
      final isCompleted = coveredLectures >= requiredLectures;

      final topicProgress = TopicProgress(
        topicId: topicId,
        topicName: topicName,
        unitName: unitName,
        requiredLectures: requiredLectures,
        coveredLectures: coveredLectures,
        isCompleted: isCompleted,
      );

      subjectTopicsMap.putIfAbsent(subjectId, () => []);
      subjectTopicsMap[subjectId]!.add(topicProgress);

      // Store subject name
      final subjectName =
          _at(topic, ['unit', 'subject', 'subjectName'])?.toString() ??
          'Unknown Subject';
      subjectNames[subjectId] = subjectName;
    }

    // Convert to list of SubjectTopicProgress
    final result = <SubjectTopicProgress>[];
    for (final entry in subjectTopicsMap.entries) {
      result.add(
        SubjectTopicProgress(
          subjectId: entry.key,
          subjectName: subjectNames[entry.key] ?? 'Unknown Subject',
          topics: entry.value,
        ),
      );
    }

    // Sort by subject name
    result.sort((a, b) => a.subjectName.compareTo(b.subjectName));

    return result;
  }

 
  /// Calculate today's schedule grouped by slot + subject + course + room.
  /// Similar to web version: groups divisions with same time, subject, course, room.
  static List<TodayScheduleLecture> calculateTodaySchedule({
    required dynamic timeTableBody,
    required dynamic preferencesBody,
    required int userId,
    required int sessionId,
  }) {
    final now = DateTime.now();
    final today = _dayNames[now.weekday - 1];

    // Step 1: Filter today's classes for this faculty and session
    final todayClasses = <Map<String, dynamic>>[];
    for (final row in _asMapList(timeTableBody)) {
      final dayName = _at(row, ['day', 'day'])?.toString();
      final shortName =
          _at(row, ['day', 'shortName'])?.toString().toLowerCase();

      if (dayName != today && shortName != today.toLowerCase()) continue;

      if (_asInt(_at(row, ['subjectTeacher', 'ourUsers', 'id'])) != userId) {
        continue;
      }
      if (_asInt(
            _at(row, ['subjectTeacher', 'subject', 'academicSession', 'id']),
          ) !=
          sessionId) {
        continue;
      }
      todayClasses.add(row);
    }

    if (todayClasses.isEmpty) return [];

    // Step 2: Group by slot + subject + course + room
    final groups = <String, Map<String, dynamic>>{};
    for (final item in todayClasses) {
      final fromTime =
          _at(item, ['slot', 'fromTime'])?.toString().substring(0, 5) ?? '';
      final toTime =
          _at(item, ['slot', 'toTime'])?.toString().substring(0, 5) ?? '';
      final subjectId = _asInt(_at(item, ['subjectTeacher', 'subject', 'id']));
      final courseId = _asInt(_at(item, ['course', 'id']));
      final roomId = _asInt(_at(item, ['room', 'id']));

      if (subjectId == null || courseId == null) continue;

      final groupKey =
          '$fromTime' + '_' + '$toTime' + '_' + '$subjectId' + '_' + '$courseId' + '_' + '$roomId';

      if (!groups.containsKey(groupKey)) {
        groups[groupKey] = {
          'fromTime': fromTime,
          'toTime': toTime,
          'subjectId': subjectId,
          'courseId': courseId,
          'roomId': roomId,
          'slot': _at(item, ['slot']),
          'subject': _at(item, ['subjectTeacher', 'subject']),
          'course': _at(item, ['course']),
          'room': _at(item, ['room']),
          'sections': <Map<String, dynamic>>[],
          'totalStudents': 0,
        };
      }

      final sectionName =
          _at(item, ['section', 'sectionName'])?.toString() ??
          _at(item, ['section', 'name'])?.toString() ??
          'N/A';
      final sectionId = _asInt(_at(item, ['section', 'id']));
      final mediumId = _asInt(_at(item, ['medium', 'id']));

      // Calculate student count for this division
      int studentCount = 0;
      if (sectionId != null && mediumId != null) {
        final studentIds = <int>{};
        for (final selection in _asMapList(preferencesBody)) {
          final status = _asInt(
            _at(selection, ['student', 'admissionStatus', 'id']),
          );
          if (status != admittedStatusId) continue;

          final session = _asInt(
            _at(selection, ['student', 'academicSession', 'id']),
          );
          if (session != sessionId) continue;

          final selectionSubjectId = _asInt(
            _at(selection, ['subjectDefinition', 'id']),
          );
          if (selectionSubjectId != subjectId) continue;

          final selectionCourseId = _asInt(_at(selection, ['course', 'id']));
          if (selectionCourseId != courseId) continue;

          final selectionSectionId = _asInt(_at(selection, ['section', 'id']));
          final selectionMediumId = _asInt(_at(selection, ['medium', 'id']));

          if (selectionSectionId == sectionId &&
              selectionMediumId == mediumId) {
            final studentId = _asInt(_at(selection, ['student', 'id']));
            if (studentId != null) studentIds.add(studentId);
          }
        }
        studentCount = studentIds.length;
      }

      groups[groupKey]!['sections'].add({
        'name': sectionName,
        'studentCount': studentCount,
      });
      groups[groupKey]!['totalStudents'] =
          (groups[groupKey]!['totalStudents'] as int) + studentCount;
    }

    // Step 3: Convert to TodayScheduleLecture objects
    final result = <TodayScheduleLecture>[];
    for (final group in groups.values) {
      final sections = group['sections'] as List<Map<String, dynamic>>;
      final divisionNames = sections.map((s) => s['name'] as String).toList();

      final subjectType =
          _at(group['subject'], ['subjectType', 'subjectType'])?.toString() ??
          'Theory';

      result.add(
        TodayScheduleLecture(
          fromTime: group['fromTime'] as String,
          toTime: group['toTime'] as String,
          subjectName:
              _at(group['subject'], ['subjectName'])?.toString() ?? 'Unknown',
          subjectCode: _at(group['subject'], ['subjectCode'])?.toString() ?? '',
          subjectType: subjectType,
          courseName:
              _at(group['course'], ['courseName'])?.toString() ?? 'Unknown',
          divisions: divisionNames,
          roomName: _at(group['room'], ['roomName'])?.toString() ?? 'TBD',
          totalStudents: group['totalStudents'] as int,
        ),
      );
    }

    // Sort by time
    result.sort((a, b) => a.fromTime.compareTo(b.fromTime));

    return result;
  }

  /// Calculate weekly schedule as a grid of time slots vs days.
  /// Returns a map: dayName -> map of timeSlotKey -> WeeklyScheduleCell
  static Map<String, Map<String, WeeklyScheduleCell>> calculateWeeklySchedule({
    required dynamic timeTableBody,
    required int userId,
    required int sessionId,
  }) {
    // Step 1: Group by day
    final groupedByDay = <String, List<Map<String, dynamic>>>{};
    for (final row in _asMapList(timeTableBody)) {
      if (_asInt(_at(row, ['subjectTeacher', 'ourUsers', 'id'])) != userId) {
        continue;
      }
      if (_asInt(
            _at(row, ['subjectTeacher', 'subject', 'academicSession', 'id']),
          ) !=
          sessionId) {
        continue;
      }

      final dayName =
          _at(row, ['day', 'day'])?.toString() ??
          _at(row, ['day', 'shortName'])?.toString() ??
          'Unknown';
      groupedByDay.putIfAbsent(dayName, () => []);
      groupedByDay[dayName]!.add(row);
    }

    // Step 2: Extract all unique time slots
    final slotMap = <String, TimeSlot>{};
    for (final dayLectures in groupedByDay.values) {
      for (final lecture in dayLectures) {
        final fromTime =
            _at(lecture, ['slot', 'fromTime'])?.toString().substring(0, 5) ??
            '';
        final toTime =
            _at(lecture, ['slot', 'toTime'])?.toString().substring(0, 5) ?? '';
        if (fromTime.isNotEmpty && toTime.isNotEmpty) {
          final key = '$fromTime-$toTime';
          if (!slotMap.containsKey(key)) {
            slotMap[key] = TimeSlot(fromTime: fromTime, toTime: toTime);
          }
        }
      }
    }

    final uniqueSlots = slotMap.values.toList();
    uniqueSlots.sort((a, b) => a.fromTime.compareTo(b.fromTime));

    // Step 3: Build the grid
    final result = <String, Map<String, WeeklyScheduleCell>>{};
    for (final day in _dayNames) {
      result[day] = {};
      for (final slot in uniqueSlots) {
        final slotKey = '${slot.fromTime}-${slot.toTime}';
        final dayLectures = groupedByDay[day] ?? [];

        final lecture = dayLectures.firstWhere((lec) {
          final lecFrom =
              _at(lec, ['slot', 'fromTime'])?.toString().substring(0, 5) ?? '';
          final lecTo =
              _at(lec, ['slot', 'toTime'])?.toString().substring(0, 5) ?? '';
          return lecFrom == slot.fromTime && lecTo == slot.toTime;
        }, orElse: () => <String, dynamic>{});

        if (lecture.isNotEmpty) {
          final subjectType =
              _at(lecture, [
                'subjectTeacher',
                'subject',
                'subjectType',
                'subjectType',
              ])?.toString() ??
              'Theory';
          result[day]![slotKey] = WeeklyScheduleCell(
            subjectName:
                _at(lecture, [
                  'subjectTeacher',
                  'subject',
                  'subjectName',
                ])?.toString() ??
                'Unknown',
            courseName:
                _at(lecture, ['course', 'courseName'])?.toString() ?? 'Unknown',
            roomName: _at(lecture, ['room', 'roomName'])?.toString() ?? 'TBD',
            subjectType: subjectType,
            hasOnlineMeeting: false, // Can be enhanced later
          );
        }
      }
    }

    return result;
  }

  /// Get unique time slots from weekly schedule for table rendering
  static List<TimeSlot> getUniqueTimeSlots(
    Map<String, Map<String, WeeklyScheduleCell>> weeklySchedule,
  ) {
    final slotSet = <String>{};
    for (final dayData in weeklySchedule.values) {
      slotSet.addAll(dayData.keys);
    }
    final slots =
        slotSet.map((key) {
          final parts = key.split('-');
          return TimeSlot(fromTime: parts[0], toTime: parts[1]);
        }).toList();
    slots.sort((a, b) => a.fromTime.compareTo(b.fromTime));
    return slots;
  }

  /// Calculate overall attendance statistics for today (for donut chart).
  /// Uses GET /get-all-attendance and filters by session and today's date.
  static OverallAttendanceStats calculateOverallAttendance({
    required dynamic attendanceBody,
    required int sessionId,
  }) {
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    int present = 0;
    int absent = 0;

    for (final row in _asMapList(attendanceBody)) {
      final schedule = row['attendanceSchedule'];
      if (schedule == null) continue;

      // Filter by academic session
      final attendanceSessionId = _asInt(
        _at(schedule, ['attendanceSession', 'academicSession', 'id']),
      );
      if (attendanceSessionId != sessionId) continue;

      // Filter by today's date
      final attendanceDate = _at(schedule, ['attendanceDate'])?.toString();
      if (attendanceDate != today) continue;

      // Count attendance status
      final statusName = _at(row, ['attendanceStatus', 'statusName'])?.toString();
      if (statusName == 'Present') {
        present++;
      } else {
        absent++;
      }
    }

    return OverallAttendanceStats(present: present, absent: absent);
  }

  /// Calculate class-wise attendance statistics for today (for bar chart).
  /// Groups by Subject + Course and calculates percentage of enrolled students present.
  static List<ClassAttendanceStats> calculateClassWiseAttendance({
    required dynamic attendanceBody,
    required dynamic preferencesBody,
    required int sessionId,
  }) {
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // Step 1: Calculate enrolled students per Subject + Course (denominator)
    final subjectCourseTotals = <String, Set<int>>{};
    for (final selection in _asMapList(preferencesBody)) {
      final status = _asInt(_at(selection, ['student', 'admissionStatus', 'id']));
      if (status != admittedStatusId) continue;

      final session = _asInt(_at(selection, ['student', 'academicSession', 'id']));
      if (session != sessionId) continue;

      final subjectId = _asInt(_at(selection, ['subjectDefinition', 'id']));
      final courseId = _asInt(_at(selection, ['course', 'id']));
      final studentId = _asInt(_at(selection, ['student', 'id']));

      if (subjectId != null && courseId != null && studentId != null) {
        final key = '${subjectId}_$courseId';
        subjectCourseTotals.putIfAbsent(key, () => <int>{});
        subjectCourseTotals[key]!.add(studentId);
      }
    }

    // Step 2: Build student-subject-course lookup map
    final studentSubjectCourseMap = <String, int>{};
    final studentSubjectCourseNameMap = <String, String>{};
    for (final selection in _asMapList(preferencesBody)) {
      final studentId = _asInt(_at(selection, ['student', 'id']));
      final subjectId = _asInt(_at(selection, ['subjectDefinition', 'id']));
      final courseId = _asInt(_at(selection, ['course', 'id']));
      final courseName = _at(selection, ['course', 'courseName'])?.toString();

      if (studentId != null && subjectId != null && courseId != null && courseName != null) {
        final key = '${studentId}_$subjectId';
        studentSubjectCourseMap[key] = courseId;
        studentSubjectCourseNameMap[key] = courseName;
      }
    }

    // Step 3: Calculate present count per Subject + Course (numerator)
    final classAttendanceMap = <String, int>{};
    for (final row in _asMapList(attendanceBody)) {
      final schedule = row['attendanceSchedule'];
      final student = row['student'];
      if (schedule == null || student == null) continue;

      // Filter by academic session
      final attendanceSessionId = _asInt(
        _at(schedule, ['attendanceSession', 'academicSession', 'id']),
      );
      if (attendanceSessionId != sessionId) continue;

      // Filter by today's date
      final attendanceDate = _at(schedule, ['attendanceDate'])?.toString();
      if (attendanceDate != today) continue;

      // Count only if Present
      final statusName = _at(row, ['attendanceStatus', 'statusName'])?.toString();
      if (statusName != 'Present') continue;

      // Get subject and course
      final subject = _at(schedule, ['subjectTeacher', 'subject']);
      if (subject == null) continue;

      final subjectId = _asInt(subject['id']);
      final studentId = _asInt(student['id']);

      if (subjectId == null || studentId == null) continue;

      // Lookup course for this student-subject pair
      final lookupKey = '${studentId}_$subjectId';
      final courseId = studentSubjectCourseMap[lookupKey];
      if (courseId == null) continue;

      final key = '${subjectId}_$courseId';
      classAttendanceMap.putIfAbsent(key, () => 0);
      classAttendanceMap[key] = classAttendanceMap[key]! + 1;
    }

    // Step 4: Build final stats with labels
    final result = <ClassAttendanceStats>[];
    for (final entry in classAttendanceMap.entries) {
      final key = entry.key;
      final present = entry.value;
      final total = subjectCourseTotals[key]?.length ?? 0;

      if (total == 0) continue;

      // Parse key to get subjectId and courseId
      final parts = key.split('_');
      if (parts.length != 2) continue;

      final subjectId = int.tryParse(parts[0]);
      if (subjectId == null) continue;

      // Find subject name and course name from preferences
      String? subjectCode;
      String? courseName;

      for (final selection in _asMapList(preferencesBody)) {
        final selSubjectId = _asInt(_at(selection, ['subjectDefinition', 'id']));
        if (selSubjectId == subjectId) {
          subjectCode = _at(selection, ['subjectDefinition', 'subjectCode'])?.toString() ??
                       _at(selection, ['subjectDefinition', 'shortName'])?.toString();
          courseName = _at(selection, ['course', 'courseName'])?.toString();
          if (subjectCode != null && courseName != null) break;
        }
      }

      if (subjectCode == null || courseName == null) continue;

      result.add(
        ClassAttendanceStats(
          label: '$subjectCode ($courseName)',
          present: present,
          total: total,
        ),
      );
    }

    // Sort by label for consistent display
    result.sort((a, b) => a.label.compareTo(b.label));

    return result;
  }

  /// Calculate pending descriptive tests awaiting marks entry.
  /// Matches web logic: filters by faculty, session, question type, end date, published status, and submissions.
  static List<PendingTest> calculatePendingTests({
    required dynamic testsBody,
    required Map<int, Map<String, dynamic>> testDistributionsMap,
    required Map<String, Set<int>> studentSubmissionMap,
    required int userId,
    required int sessionId,
  }) {
    final now = DateTime.now();
    final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final result = <PendingTest>[];

    for (final test in _asMapList(testsBody)) {
      // Filter by faculty
      final teacherUserId = _asInt(_at(test, ['subjectTeacherAllotment', 'ourUsers', 'id']));
      if (teacherUserId != userId) continue;

      // Filter by session
      final testSessionId = _asInt(_at(test, ['academicSessionId']));
      if (testSessionId != sessionId) continue;

      // Filter by question type (Descriptive)
      final questionType = _at(test, ['questionType'])?.toString().toLowerCase();
      if (questionType != 'descriptive') continue;

      // Filter by end date (before today)
      final endDate = _at(test, ['endDate'])?.toString();
      if (endDate == null || endDate.compareTo(today) >= 0) continue;

      // Filter by evaluation status (not published)
      final evaluationStatus = _at(test, ['evaluationStatus'])?.toString();
      if (evaluationStatus == 'EVALUATION_PUBLISHED') continue;

      // Get test ID and allotment ID
      final testId = _asInt(test['id']);
      final allotmentId = _asInt(_at(test, ['subjectTeacherAllotment', 'id']));
      if (testId == null || allotmentId == null) continue;

      // Get distribution data for student count
      final distribution = testDistributionsMap[allotmentId];
      final totalStudents = distribution != null ? _asInt(distribution['studentCount']) ?? 0 : 0;

      // Get submitted count from student answers
      final testName = _at(test, ['title'])?.toString() ?? '';
      final submittedCount = studentSubmissionMap[testName]?.length ?? 0;

      // Filter: at least one student has submitted
      if (submittedCount == 0) continue;

      // Build PendingTest
      result.add(
        PendingTest(
          id: testId,
          title: testName,
          questionType: questionType ?? 'Test',
          subjectName: _at(test, ['subjectTeacherAllotment', 'subject', 'subjectName'])?.toString() ?? 'N/A',
          courseName: _at(test, ['subjectTeacherAllotment', 'course', 'courseName'])?.toString() ?? 'N/A',
          maxMarks: _asInt(test['maxMarks']) ?? 0,
          durationMinutes: _asInt(test['durationMinutes']) ?? 0,
          endDate: endDate,
          endTime: _at(test, ['endTime'])?.toString().substring(0, 5) ?? '',
          totalStudents: totalStudents,
          submittedCount: submittedCount,
          subjectId: _asInt(_at(test, ['subjectTeacherAllotment', 'subject', 'id'])) ?? 0,
          courseId: _asInt(_at(test, ['subjectTeacherAllotment', 'course', 'id'])) ?? 0,
          subjectTeacherAllotmentId: allotmentId,
        ),
      );
    }

    return result;
  }

  /// Calculate pending assignments awaiting evaluation.
  /// Matches web logic: filters by published, session, faculty allotment, due date, submissions status.
  static List<PendingAssignment> calculatePendingAssignments({
    required dynamic assignmentsBody,
    required Map<int, List<Map<String, dynamic>>> submissionsMap,
    required Set<int> teacherAllotmentIds,
    required int sessionId,
  }) {
    final now = DateTime.now();

    final result = <PendingAssignment>[];

    for (final assignment in _asMapList(assignmentsBody)) {
      // Filter by published
      final isPublished = assignment['isPublish'] == true;
      if (!isPublished) continue;

      // Filter by session
      final assignmentSessionId = _asInt(assignment['academicSessionId']);
      if (assignmentSessionId != sessionId) continue;

      // Filter by faculty allotment
      final allotmentId = _asInt(assignment['subjectTeacherAllotmentId']);
      if (allotmentId == null || !teacherAllotmentIds.contains(allotmentId)) continue;

      // Filter by due date (has passed)
      final dueDateStr = _at(assignment, ['dateOfSubmission'])?.toString();
      if (dueDateStr == null) continue;
      try {
        final dueDate = DateTime.parse(dueDateStr);
        if (dueDate.isAfter(now)) continue;
      } catch (e) {
        continue;
      }

      // Get submissions
      final submissions = submissionsMap[assignment['assignmentId']] ?? [];

      // Filter: at least one submission exists
      if (submissions.isEmpty) continue;

      // Filter: not all submissions are PUBLISHED
      final allPublished = submissions.every((s) => s['status'] == 'PUBLISHED');
      if (allPublished) continue;

      // Build PendingAssignment
      final assignmentId = _asInt(assignment['assignmentId']) ?? _asInt(assignment['id']) ?? 0;
      final subject = _at(assignment, ['subjectTeacherAllotment', 'subject']);
      final course = _at(assignment, ['subjectTeacherAllotment', 'course']);

      result.add(
        PendingAssignment(
          id: assignmentId,
          assignmentTitle: _at(assignment, ['assignmentTitle'])?.toString() ?? 'N/A',
          subjectName: _at(subject, ['subjectName'])?.toString() ?? 'N/A',
          courseName: _at(course, ['courseName'])?.toString() ?? 'N/A',
          assignmentMarks: _asInt(assignment['assignmentMarks']) ?? 0,
          dateOfSubmission: dueDateStr,
          totalStudents: (assignment['studentIds'] as List?)?.length ?? 0,
          submittedCount: submissions.length,
          subjectId: _asInt(subject['id']) ?? 0,
          courseId: _asInt(course['id']) ?? 0,
          subjectTeacherAllotmentId: allotmentId,
        ),
      );
    }

    return result;
  }
  // ---------- helpers ----------

  static List<Map<String, dynamic>> _asMapList(dynamic body) {
    if (body is! List) return const [];
    return body.whereType<Map<String, dynamic>>().toList();
  }

  static dynamic _at(dynamic json, List<String> path) {
    dynamic current = json;
    for (final key in path) {
      if (current is Map<String, dynamic>) {
        current = current[key];
      } else {
        return null;
      }
    }
    return current;
  }

  static int? _asInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class QuickLink {
  final int id;
  final int userId;
  final int menuUniqueId;
  final String createdAt;

  const QuickLink({
    required this.id,
    required this.userId,
    required this.menuUniqueId,
    required this.createdAt,
  });

  factory QuickLink.fromJson(Map<String, dynamic> json) {
    return QuickLink(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      menuUniqueId: (json['menuUniqueId'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}
