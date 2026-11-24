// Models for QR attendance (used by teacher and student screens)

int _int(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

DateTime? _date(dynamic v) => v == null ? null : DateTime.tryParse('$v');

class QrSessionModel {
  const QrSessionModel({
    required this.qrSessionId,
    required this.status,
    required this.totalStudents,
    required this.presentCount,
    required this.absentCount,
    required this.alreadyMarkedCount,
    required this.tokenIntervalSeconds,
    this.expiresAt,
    this.token,
    this.tokenValidTill,
  });

  final int qrSessionId;
  final String status; // ACTIVE / CLOSED
  final DateTime? expiresAt;
  final String? token;
  final DateTime? tokenValidTill;
  final int tokenIntervalSeconds;
  final int totalStudents;
  final int presentCount;
  final int absentCount;
  final int alreadyMarkedCount;

  bool get isActive => status == 'ACTIVE';

  factory QrSessionModel.fromJson(Map<String, dynamic> json) {
    return QrSessionModel(
      qrSessionId: _int(json['qrSessionId']),
      status: (json['status'] ?? '').toString(),
      expiresAt: _date(json['expiresAt']),
      token: json['token']?.toString(),
      tokenValidTill: _date(json['tokenValidTill']),
      tokenIntervalSeconds: _int(json['tokenIntervalSeconds']),
      totalStudents: _int(json['totalStudents']),
      presentCount: _int(json['presentCount']),
      absentCount: _int(json['absentCount']),
      alreadyMarkedCount: _int(json['alreadyMarkedCount']),
    );
  }
}

class QrTokenModel {
  const QrTokenModel({
    required this.status,
    this.token,
    this.validTill,
    this.expiresAt,
    this.intervalSeconds = 0,
  });

  final String status;
  final String? token;
  final DateTime? validTill;
  final DateTime? expiresAt;
  final int intervalSeconds;

  factory QrTokenModel.fromJson(Map<String, dynamic> json) {
    return QrTokenModel(
      status: (json['status'] ?? '').toString(),
      token: json['token']?.toString(),
      validTill: _date(json['validTill']),
      expiresAt: _date(json['expiresAt']),
      intervalSeconds: _int(json['intervalSeconds']),
    );
  }
}

class QrStudentItem {
  const QrStudentItem({
    required this.studentId,
    required this.fullName,
    required this.status,
    this.rollNumber,
    this.sectionName,
    this.scannedAt,
  });

  final int studentId;
  final String fullName;
  final String? rollNumber;
  final String? sectionName;
  final String status;
  final DateTime? scannedAt;

  factory QrStudentItem.fromJson(Map<String, dynamic> json) {
    return QrStudentItem(
      studentId: _int(json['studentId']),
      fullName: (json['fullName'] ?? '').toString(),
      rollNumber: json['rollNumber']?.toString(),
      sectionName: json['sectionName']?.toString(),
      status: (json['status'] ?? '').toString(),
      scannedAt: _date(json['scannedAt']),
    );
  }
}

class QrStudentPage {
  const QrStudentPage({
    required this.content,
    required this.page,
    required this.totalElements,
    required this.totalPages,
  });

  final List<QrStudentItem> content;
  final int page;
  final int totalElements;
  final int totalPages;

  factory QrStudentPage.fromJson(Map<String, dynamic> json) {
    final list = json['content'];
    return QrStudentPage(
      content: list is List
          ? list
                .whereType<Map>()
                .map((e) => QrStudentItem.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : const [],
      page: _int(json['page']),
      totalElements: _int(json['totalElements']),
      totalPages: _int(json['totalPages']),
    );
  }
}

class QrScanResultModel {
  const QrScanResultModel({
    required this.success,
    required this.message,
    this.subjectName,
    this.statusName,
    this.markedAt,
  });

  final bool success;
  final String message;
  final String? subjectName;
  final String? statusName;
  final DateTime? markedAt;

  factory QrScanResultModel.fromJson(Map<String, dynamic> json) {
    return QrScanResultModel(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
      subjectName: json['subjectName']?.toString(),
      statusName: json['statusName']?.toString(),
      markedAt: _date(json['markedAt']),
    );
  }
}