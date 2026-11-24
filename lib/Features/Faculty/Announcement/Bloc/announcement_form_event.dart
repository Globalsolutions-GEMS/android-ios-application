import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:erp_app/Features/Faculty/E-learning Workarea/model/workarea_subject_model.dart';

import '../model/announcement_model.dart';

@immutable
abstract class AnnouncementFormEvent {
  const AnnouncementFormEvent();
}

/// Warms the recipient cache while the user fills the form so submit
/// does not wait on the two heavy student APIs.
class LoadAnnouncementRecipients extends AnnouncementFormEvent {
  const LoadAnnouncementRecipients(this.subject);

  final WorkAreaSubject subject;
}

class SubmitAnnouncementForm extends AnnouncementFormEvent {
  const SubmitAnnouncementForm({
    required this.subject,
    required this.title,
    required this.content,
    required this.validUntil,
    this.scheduleAt,
    this.file,
    this.existing,
  });

  final WorkAreaSubject subject;
  final String title;
  final String content;
  final DateTime? scheduleAt;
  final DateTime validUntil;
  final File? file;

  /// null = create, not null = update.
  final AnnouncementItem? existing;
}
