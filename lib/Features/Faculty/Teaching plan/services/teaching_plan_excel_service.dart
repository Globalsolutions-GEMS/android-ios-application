import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:xml/xml.dart';

import 'package:erp_app/api_manager/api_checker.dart';
import 'package:erp_app/api_manager/api_client.dart';
import 'package:erp_app/api_manager/api_endPoints.dart';

import '../model/teaching_plan_model.dart';

/// Excel template download, validation and date normalization for the
/// Teaching Plan bulk upload tab. Mirrors the web flow in
/// teachingplan/page.js.
class TeachingPlanExcelService {
  TeachingPlanExcelService._();

  static const List<String> expectedHeaders = [
    'subjectTeacherAllotmentId',
    'unitName',
    'topic',
    'objective',
    'teachingMode',
    'plannedDate',
  ];

  /// Builds the template workbook: one row per topic of every unit,
  /// pre-filled from existing plans, then saves and opens it.
  static Future<void> downloadAndOpenTemplate({
    required List<TeachingPlanUnit> units,
    required List<TeachingPlan> plans,
    required int allotmentId,
    required int subjectId,
  }) async {
    final apiClient = ApiClient();
    final allRows = <List<dynamic>>[];

    for (final unit in units) {
      final topics = await _fetchTopics(apiClient, unit.id);
      for (final topic in topics) {
        TeachingPlan? existingPlan;
        for (final plan in plans) {
          final sameUnit = plan.unitName == unit.unitName;
          final sameTopic = plan.topicName == topic.topicName ||
              plan.topicId.toString() == topic.id.toString();
          if (sameUnit && sameTopic) {
            existingPlan = plan;
            break;
          }
        }
        allRows.add([
          allotmentId,
          unit.unitName,
          topic.topicName,
          existingPlan?.objective ?? '',
          existingPlan?.teachingMode ?? '',
          existingPlan?.plannedDate == null
              ? ''
              : _formatDate(existingPlan!.plannedDate!),
        ]);
      }
    }

    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];
    sheet.appendRow(expectedHeaders.map(TextCellValue.new).toList());
    for (final row in allRows) {
      sheet.appendRow(row.map(_cellValue).toList());
    }

    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('Failed to generate Excel template.');
    }

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/TeachingPlanTemplate_Subject_$subjectId.xlsx',
    );
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

  /// Lets the user pick an .xlsx/.xls file. Returns null when cancelled.
  /// Uses withData so the bytes are available even when the platform
  /// returns a content URI without a readable path.
  static Future<File?> pickExcelFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx', 'xls'],
      withData: true,
    );
    final picked = result?.files.single;
    if (picked == null) return null;

    if (picked.path != null) return File(picked.path!);

    final bytes = picked.bytes;
    if (bytes == null) return null;
    final dir = await getTemporaryDirectory();
    final ext = picked.extension ?? 'xlsx';
    final file = File('${dir.path}/picked_teaching_plan.$ext');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Returns an error message when the header row does not match the
  /// template, otherwise null.
  static Future<String?> validateHeaders(File file) async {
    try {
      final rows = await _readRows(file);
      if (rows.isEmpty) {
        return 'Excel format is invalid. Please use the downloaded template.';
      }
      final headerRow = rows.first;
      if (headerRow.length != expectedHeaders.length) {
        return 'Excel format is invalid. Please use the downloaded template.';
      }
      for (var i = 0; i < expectedHeaders.length; i++) {
        final cellText = headerRow[i]?.text?.trim() ?? '';
        if (cellText != expectedHeaders[i]) {
          return 'Excel format is invalid. Please use the downloaded template.';
        }
      }
      return null;
    } catch (_) {
      return 'Failed to read Excel file.';
    }
  }

  /// Reads the workbook, normalizes every plannedDate to YYYY-MM-DD and
  /// writes a new workbook that is ready for upload.
  static Future<File> normalizeAndSave(File file) async {
    final rows = await _readRows(file);
    if (rows.isEmpty) {
      throw Exception('Excel file has no rows.');
    }
    final headerRow = rows.first;

    final out = Excel.createExcel();
    final outSheet = out['Sheet1'];
    outSheet.appendRow(
      headerRow.map((cell) => TextCellValue(cell?.text ?? '')).toList(),
    );

    // Locate plannedDate by header name instead of a fixed index so a
    // column offset in the user's file cannot shift the mapping.
    final dateCol = headerRow.indexWhere(
      (cell) => cell?.text?.trim() == 'plannedDate',
    );

    for (var r = 1; r < rows.length; r++) {
      final row = rows[r];
      if (row.every((cell) => cell == null)) continue;

      final values = <CellValue>[];
      for (var c = 0; c < row.length; c++) {
        if (c == dateCol) {
          final normalized = _normalizePlannedDate(row[c]);
          values.add(TextCellValue(normalized ?? ''));
        } else {
          values.add(_cellToValue(row[c]));
        }
      }
      outSheet.appendRow(values);
    }

    final encoded = out.encode();
    if (encoded == null) {
      throw Exception('Failed to process Excel file.');
    }

    final dir = await getTemporaryDirectory();
    final normalized = File('${dir.path}/TeachingPlanUpload_normalized.xlsx');
    await normalized.writeAsBytes(encoded, flush: true);
    return normalized;
  }

  static Future<List<TeachingPlanTopic>> _fetchTopics(
    ApiClient apiClient,
    int unitId,
  ) async {
    try {
      final response = await apiClient.getData(
        '${ApiEndPoints.getTopicsByUnit}?unitId=$unitId',
      );
      if (ApiChecker.checkApi(response) != null) return const [];
      return _extractList(response.body)
          .whereType<Map>()
          .map((item) =>
              TeachingPlanTopic.fromJson(Map<String, dynamic>.from(item)))
          .where((topic) => topic.id > 0 && topic.topicName.trim().isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static String? _normalizePlannedDate(_XlsxCell? cell) {
    if (cell == null) return null;

    // Excel stores dates as serial numbers; the plannedDate column is
    // always a date, so a numeric value is treated as a serial.
    if (cell.number != null) {
      final date =
          DateTime(1899, 12, 30).add(Duration(days: cell.number!.toInt()));
      return _formatDate(date);
    }

    final text = cell.text?.trim() ?? '';
    if (text.isEmpty) return null;

    // Already YYYY-MM-DD.
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text)) return text;

    // DD-MM-YYYY or DD/MM/YYYY.
    final parts = text.split(RegExp(r'[-/]'));
    if (parts.length == 3) {
      final dd = parts[0].padLeft(2, '0');
      final mm = parts[1].padLeft(2, '0');
      final yyyy = parts[2];
      if (RegExp(r'^\d+$').hasMatch(dd) &&
          RegExp(r'^\d+$').hasMatch(mm) &&
          RegExp(r'^\d+$').hasMatch(yyyy)) {
        return '$yyyy-$mm-$dd';
      }
    }

    final parsed = DateTime.tryParse(text);
    return parsed == null ? text : _formatDate(parsed);
  }

  /// Rebuilds a cell keeping its native type (numbers stay numeric), like
  /// the web's json_to_sheet rebuild.
  static CellValue _cellToValue(_XlsxCell? cell) {
    if (cell == null) return TextCellValue('');
    final number = cell.number;
    if (number != null) {
      return number == number.roundToDouble()
          ? IntCellValue(number.toInt())
          : DoubleCellValue(number);
    }
    return TextCellValue(cell.text ?? '');
  }

  /// Minimal .xlsx reader. The `excel` package's decoder throws on files
  /// re-saved by Excel/WPS ("custom numFmtId starts at 164..."), so the
  /// first worksheet is parsed directly from the OOXML zip instead.
  static Future<List<List<_XlsxCell?>>> _readRows(File file) async {
    final archive = ZipDecoder().decodeBytes(await file.readAsBytes());

    ArchiveFile? findFile(String name) {
      for (final entry in archive.files) {
        if (entry.name == name || entry.name.endsWith('/$name')) {
          return entry;
        }
      }
      return null;
    }

    // Shared strings table.
    final sharedStrings = <String>[];
    final sstFile = findFile('xl/sharedStrings.xml');
    if (sstFile != null) {
      final doc = XmlDocument.parse(utf8.decode(sstFile.content as List<int>));
      for (final si in doc.findAllElements('si')) {
        sharedStrings.add(
          si.findAllElements('t').map((e) => e.innerText).join(),
        );
      }
    }

    // Resolve the first worksheet through workbook rels.
    var sheetPath = 'xl/worksheets/sheet1.xml';
    final workbookFile = findFile('xl/workbook.xml');
    final relsFile = findFile('xl/_rels/workbook.xml.rels');
    if (workbookFile != null && relsFile != null) {
      final workbook =
          XmlDocument.parse(utf8.decode(workbookFile.content as List<int>));
      final rels = XmlDocument.parse(utf8.decode(relsFile.content as List<int>));
      final firstSheet = workbook.findAllElements('sheet').firstOrNull;
      String? relId;
      if (firstSheet != null) {
        for (final attr in firstSheet.attributes) {
          if (attr.name.local == 'id' && attr.name.prefix == 'r') {
            relId = attr.value;
          }
        }
      }
      if (relId != null) {
        for (final rel in rels.findAllElements('Relationship')) {
          if (rel.getAttribute('Id') == relId) {
            var target = rel.getAttribute('Target') ?? '';
            if (target.startsWith('/')) target = target.substring(1);
            if (!target.startsWith('xl/')) target = 'xl/$target';
            sheetPath = target;
          }
        }
      }
    }

    final sheetFile = findFile(sheetPath);
    if (sheetFile == null) {
      throw Exception('Worksheet not found in Excel file.');
    }
    final sheetDoc =
        XmlDocument.parse(utf8.decode(sheetFile.content as List<int>));

    final rows = <List<_XlsxCell?>>[];
    for (final rowEl in sheetDoc.findAllElements('row')) {
      final cells = <_XlsxCell?>[];
      for (final cellEl in rowEl.findElements('c')) {
        final ref = cellEl.getAttribute('r') ?? '';
        final index = ref.isEmpty ? cells.length : _columnIndex(ref);
        while (cells.length <= index) {
          cells.add(null);
        }
        cells[index] = _cellFromXml(cellEl, sharedStrings);
      }
      rows.add(cells);
    }
    return rows;
  }

  /// 'A' -> 0, 'B' -> 1, 'AA' -> 26 ...
  static int _columnIndex(String ref) {
    var index = 0;
    for (final unit in ref.codeUnits) {
      if (unit < 65 || unit > 90) break;
      index = index * 26 + (unit - 64);
    }
    return index - 1;
  }

  static _XlsxCell? _cellFromXml(XmlElement cell, List<String> sharedStrings) {
    final type = cell.getAttribute('t');
    final value = cell.findElements('v').firstOrNull?.innerText.trim();
    final inline = cell.findElements('is').firstOrNull;

    if (type == 'inlineStr' || (value == null && inline != null)) {
      final text = inline
              ?.findAllElements('t')
              .map((e) => e.innerText)
              .join() ??
          '';
      return _XlsxCell.text(text);
    }
    if (value == null || value.isEmpty) return null;

    switch (type) {
      case 's':
        final idx = int.tryParse(value) ?? -1;
        final text =
            idx >= 0 && idx < sharedStrings.length ? sharedStrings[idx] : '';
        return _XlsxCell.text(text);
      case 'str':
      case 'e':
        return _XlsxCell.text(value);
      case 'b':
        return _XlsxCell.text(value == '1' ? 'TRUE' : 'FALSE');
      default:
        final number = double.tryParse(value);
        return number == null
            ? _XlsxCell.text(value)
            : _XlsxCell.number(number);
    }
  }

  static CellValue _cellValue(dynamic value) {
    if (value is int) return IntCellValue(value);
    if (value is double) return DoubleCellValue(value);
    return TextCellValue(value?.toString() ?? '');
  }

  static List<dynamic> _extractList(dynamic data) {
    if (data is String) {
      try {
        data = jsonDecode(data);
      } catch (_) {
        return <dynamic>[];
      }
    }
    if (data is List) return data;
    if (data is Map) {
      for (final key in const ['data', 'content', 'items', 'result', 'topics']) {
        if (!data.containsKey(key)) continue;
        dynamic value = data[key];
        if (value is String) {
          try {
            value = jsonDecode(value);
          } catch (_) {
            continue;
          }
        }
        if (value is List) return value;
      }
    }
    return <dynamic>[];
  }

  static String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

/// A single cell read from the raw worksheet XML: either text or a
/// numeric value (Excel serials included).
class _XlsxCell {
  const _XlsxCell.text(this.text) : number = null;
  const _XlsxCell.number(this.number) : text = null;

  final String? text;
  final double? number;
}
