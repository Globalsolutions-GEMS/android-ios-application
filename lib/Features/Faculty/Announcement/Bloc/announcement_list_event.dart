import 'package:flutter/foundation.dart';

import 'package:erp_app/Features/Faculty/E-learning Workarea/model/workarea_subject_model.dart';

@immutable
abstract class AnnouncementListEvent {
  const AnnouncementListEvent();
}

class LoadAnnouncements extends AnnouncementListEvent {
  const LoadAnnouncements(this.subject);

  final WorkAreaSubject subject;
}
