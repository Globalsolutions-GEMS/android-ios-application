import 'package:flutter/foundation.dart';

import '../model/announcement_model.dart';

@immutable
abstract class AnnouncementListState {
  const AnnouncementListState();
}

class AnnouncementListInitial extends AnnouncementListState {
  const AnnouncementListInitial();
}

class AnnouncementListLoading extends AnnouncementListState {
  const AnnouncementListLoading();
}

class AnnouncementListLoaded extends AnnouncementListState {
  const AnnouncementListLoaded(this.items);

  final List<AnnouncementItem> items;
}

class AnnouncementListFailed extends AnnouncementListState {
  const AnnouncementListFailed(this.message);

  final String message;
}
