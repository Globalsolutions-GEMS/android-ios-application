import 'dart:io';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import 'package:erp_app/api_manager/api_client.dart';
import 'package:erp_app/api_manager/api_endPoints.dart';

class AssignmentFileService {
  AssignmentFileService._();

  /// Downloads the assignment attachment and opens it.
  /// Throws an Exception with a readable message on failure.
  static Future<void> downloadAndOpen({
    required int assignmentId,
    required String fileName,
  }) async {
    final bytes = await ApiClient().downloadBytes(
      ApiEndPoints.downloadAssignment,
      query: {'assignmentId': '$assignmentId'},
    );

    final dir = await getTemporaryDirectory();
    final safeName = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final file = File('${dir.path}/$safeName');
    await file.writeAsBytes(bytes, flush: true);

    final result = await OpenFilex.open(file.path);
    if (result.type != ResultType.done) {
      throw Exception(
        result.message.isNotEmpty
            ? result.message
            : 'No app found to open this file.',
      );
    }
  }
}