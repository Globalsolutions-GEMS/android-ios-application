import 'package:flutter/foundation.dart';

@immutable
abstract class AnnouncementFormState {
  const AnnouncementFormState();
}

class AnnouncementFormInitial extends AnnouncementFormState {
  const AnnouncementFormInitial();
}

class AnnouncementFormSubmitting extends AnnouncementFormState {
  const AnnouncementFormSubmitting();
}

/// Emitted once after a successful create/update (screen should close).
class AnnouncementFormSaved extends AnnouncementFormState {
  const AnnouncementFormSaved();
}

class AnnouncementFormFailed extends AnnouncementFormState {
  const AnnouncementFormFailed(this.message);

  final String message;
}
