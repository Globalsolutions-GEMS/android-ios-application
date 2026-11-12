import 'package:erp_app/Features/Faculty/Attendance/screens/mark_attendance_screen.dart';
import 'package:erp_app/Features/Faculty/Syllabus Upload/screens/create_syllabus_screen.dart';
import 'package:flutter/material.dart';

class QuickLinkMenu {
  const QuickLinkMenu({required this.title, required this.builder});

  final String title;
  final WidgetBuilder builder;
}

// menuUniqueId (from web) -> app screen
final Map<int, QuickLinkMenu> quickLinkMenus = {
  90280470: QuickLinkMenu(
    title: 'Mark Attendance',
    builder: (_) => const MarkAttendanceScreen(),
  ),
  47753959: QuickLinkMenu(
    title: 'Create Syllabus',
    builder: (_) => const CreateSyllabusScreen(),
  ),
};