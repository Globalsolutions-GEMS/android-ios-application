import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'package:erp_app/api_manager/api_checker.dart';
import 'package:erp_app/api_manager/api_client.dart';
import 'package:erp_app/api_manager/api_endPoints.dart';
import 'package:erp_app/Features/Faculty/Assignment/model/assignment_model.dart';
import 'package:erp_app/Features/Faculty/E-learning Workarea/model/workarea_subject_model.dart';

import '../model/announcement_model.dart';

/// API layer for the faculty Announcement module.
///
/// - GET  /api/announcements                    → [fetchAll]
/// - POST /api/announcements                    → [save] (multipart `request`)
/// - PUT  /api/announcements/{id}               → [save] (multipart `request`)
/// - GET  /api/announcements/download/{file}    → [downloadAttachment]
class AnnouncementService {
  AnnouncementService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  /// Fetches every announcement; the caller filters by subject locally
  /// (same approach as the web screen).
  Future<List<AnnouncementItem>> fetchAll() async {
    final response = await _apiClient.getData(ApiEndPoints.announcements);
    final error = ApiChecker.checkApi(response);
    if (error != null) throw Exception(error);

    final body = response.body;
    if (body is! List) return const [];
    return body
        .whereType<Map>()
        .map((e) => AnnouncementItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Creates ([existing] == null) or updates an announcement.
  /// [request] is sent as the `request` JSON part; [file] is the optional
  /// `attachment` part.
  Future<AnnouncementItem> save({
    AnnouncementItem? existing,
    required AnnouncementRequest request,
    File? file,
  }) async {
    final isEdit = existing != null;
    final response = await _apiClient.sendMultipart(
      isEdit ? 'PUT' : 'POST',
      isEdit
          ? ApiEndPoints.announcementById(existing.id)
          : ApiEndPoints.announcements,
      jsonField: 'request',
      json: request.toJson(),
      file: file,
      jsonAsBlob: true,
    );

    final error = ApiChecker.checkApi(response);
    if (error != null) throw Exception(error);

    final body = response.body;
    if (body is Map) {
      return AnnouncementItem.fromJson(Map<String, dynamic>.from(body));
    }
    return AnnouncementItem(
      id: existing?.id ?? 0,
      title: request.title,
      content: request.content,
      scheduleAt: request.scheduleAt,
      validUntil: request.validUntil,
      subjectId: 0,
      courseId: 0,
      studentIds: request.studentIds,
    );
  }

  /// Recipient ids are cached per subject for the app session — the two
  /// backing APIs return very large payloads, so refetching on every
  /// submit/open is what made the form feel slow.
  static final Map<String, List<int>> _recipientCache = {};

  static String _recipientKey(WorkAreaSubject subject) =>
      '${subject.courseId}|${subject.subjectId}|'
      '${subject.academicSessionId}|${subject.sectionIds.join(',')}';

  /// Derives the recipient student ids for the selected subject.
  /// Mirrors the web screen: admitted students (admissionStatus.id == 2)
  /// of the course whose subject-preference mapping matches the subject
  /// and whose section is in the allotment's sections.
  Future<List<int>> fetchEligibleStudentIds(WorkAreaSubject subject) async {
    final key = _recipientKey(subject);
    final cached = _recipientCache[key];
    if (cached != null) return cached;

    final ids = await _loadEligibleStudentIds(subject);
    _recipientCache[key] = ids;
    return ids;
  }

  Future<List<int>> _loadEligibleStudentIds(WorkAreaSubject subject) async {
    final responses = await Future.wait([
      _apiClient.getData(
        '${ApiEndPoints.studentAdmissionsFilter}?courseId=${subject.courseId}',
      ),
      _apiClient.getData(ApiEndPoints.preferenceSelectionsAll),
    ]);

    for (final response in responses) {
      final error = ApiChecker.checkApi(response);
      if (error != null) throw Exception(error);
    }

    // Web: response.data.filter(s => s.admissionStatus?.id === 2)
    final students = _asMapList(responses[0].body)
        .map(AssignmentStudent.fromJson)
        .where((s) => s.admissionStatusId == 2)
        .toList();

    // Web: preferenceSelections.filter(i => i.subjectDefinition?.id === subjectId)
    final matchingStudentIds = _asMapList(responses[1].body)
        .map(StudentSubjectMapping.fromJson)
        .where((m) => m.subjectId == subject.subjectId)
        .map((m) => m.studentId)
        .toSet();

    return students
        .where((s) =>
            matchingStudentIds.contains(s.id) &&
            (subject.sectionIds.isEmpty ||
                subject.sectionIds.contains(s.sectionId)))
        .map((s) => s.id)
        .toList();
  }

  /// Downloads an announcement attachment and returns the local file.
  Future<File> downloadAttachment(String fileName) async {
    final safeName = fileName.split(RegExp(r'[\\/]')).last;
    final bytes = await _apiClient.downloadBytes(
      ApiEndPoints.announcementDownload(safeName),
    );
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$safeName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  List<Map<String, dynamic>> _asMapList(dynamic body) {
    if (body is! List) return const [];
    return body
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}
