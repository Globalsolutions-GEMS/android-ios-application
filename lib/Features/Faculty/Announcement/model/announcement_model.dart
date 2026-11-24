/// Announcement model for the faculty Announcement module.
///
/// [AnnouncementItem] is parsed from GET /api/announcements rows.
/// [AnnouncementRequest] is the JSON part sent as `request` in the
/// multipart create/update calls.
class AnnouncementItem {
  final int id;
  final String title;
  final String content;
  final DateTime? scheduleAt;
  final DateTime validUntil;
  final String? attachmentName;
  final String? attachmentType;
  final int? attachmentSize;

  /// Context ids used to filter the list for the selected work-area
  /// subject (subjectTeacherAllotment.subject.id / course.id /
  /// academic session on the backend).
  final int subjectId;
  final int courseId;

  /// Top-level `academicSession` of the announcement (int id or null),
  /// same field the web screen compares against the current session.
  final int? academicSessionId;

  /// Recipients stored on the announcement (used when editing, like web).
  final List<int> studentIds;

  const AnnouncementItem({
    required this.id,
    required this.title,
    required this.content,
    required this.validUntil,
    this.scheduleAt,
    this.attachmentName,
    this.attachmentType,
    this.attachmentSize,
    this.subjectId = 0,
    this.courseId = 0,
    this.academicSessionId,
    this.studentIds = const [],
  });

  factory AnnouncementItem.fromJson(Map<String, dynamic> json) {
    final allotment = _map(json['subjectTeacherAllotment']);
    final subject = _map(allotment['subject']);
    final course = _map(allotment['course']);

    // The web screen filters on the top-level `academicSession` field
    // (an int id, or null for older rows).
    int? sessionId;
    final rawSession = json['academicSession'];
    if (rawSession is num || rawSession is String) {
      sessionId = _toInt(rawSession);
    } else {
      sessionId = _toInt(_map(rawSession)['id']);
    }

    final attachmentName = json['attachmentName']?.toString();
    final attachmentType = json['attachmentType']?.toString();
    final attachmentSize = json['attachmentSize'];

    return AnnouncementItem(
      id: _toInt(json['announcementId'] ?? json['id']),
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      scheduleAt: DateTime.tryParse(json['scheduleAt']?.toString() ?? ''),
      validUntil: DateTime.tryParse(json['validUntil']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      attachmentName:
          (attachmentName == null || attachmentName.isEmpty)
              ? null
              : attachmentName,
      attachmentType:
          (attachmentType == null || attachmentType.isEmpty)
              ? null
              : attachmentType,
      attachmentSize: attachmentSize == null ? null : _toInt(attachmentSize),
      subjectId: _toInt(subject['id']),
      courseId: _toInt(course['id']),
      academicSessionId: sessionId,
      studentIds: json['studentIds'] is List
          ? (json['studentIds'] as List).map(_toInt).toList()
          : const [],
    );
  }

  /// True when this announcement belongs to the selected work-area
  /// subject. Mirrors the web filter: subject + course always checked;
  /// when a session id is known the announcement's own
  /// `academicSession` must match it (null sessions are excluded, same
  /// as the web `a.academicSession === currentSessionId` check).
  bool matchesSubject({
    required int subjectId,
    required int courseId,
    int? academicSessionId,
  }) {
    if (this.subjectId != 0 && this.subjectId != subjectId) return false;
    if (this.courseId != 0 && this.courseId != courseId) return false;
    if (academicSessionId != null &&
        this.academicSessionId != academicSessionId) {
      return false;
    }
    return true;
  }

  bool get isExpired => validUntil.isBefore(DateTime.now());

  bool get isScheduled =>
      scheduleAt != null && scheduleAt!.isAfter(DateTime.now());

  bool get hasAttachment =>
      attachmentName != null && attachmentName!.trim().isNotEmpty;
}

/// Payload sent as the `request` part of the multipart create/update.
class AnnouncementRequest {
  final String title;
  final String content;
  final DateTime? scheduleAt;
  final DateTime validUntil;
  final int subjectTeacherAllotmentId;
  final int instituteId;
  final List<int> studentIds;

  const AnnouncementRequest({
    required this.title,
    required this.content,
    required this.validUntil,
    required this.subjectTeacherAllotmentId,
    required this.instituteId,
    required this.studentIds,
    this.scheduleAt,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'content': content,
        'scheduleAt': scheduleAt == null ? null : _apiDateTime(scheduleAt!),
        'validUntil': _apiDateTime(validUntil),
        'subjectTeacherAllotmentId': subjectTeacherAllotmentId,
        'instituteId': instituteId,
        'studentIds': studentIds,
      };
}

/// yyyy-MM-ddTHH:mm:ss (same format as the web app).
String _apiDateTime(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)}'
      'T${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

/// dd/MM/yyyy (also used for search)
String formatAnnouncementDate(DateTime? d) {
  if (d == null) return '';
  final day = d.day.toString().padLeft(2, '0');
  final month = d.month.toString().padLeft(2, '0');
  return '$day/$month/${d.year}';
}

/// 05 Nov 2026, 3:30 PM
String formatAnnouncementDateTime(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final period = d.hour >= 12 ? 'PM' : 'AM';
  final day = d.day.toString().padLeft(2, '0');
  final minute = d.minute.toString().padLeft(2, '0');
  return '$day ${months[d.month - 1]} ${d.year}, $hour:$minute $period';
}
