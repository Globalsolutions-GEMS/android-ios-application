import 'package:flutter_bloc/flutter_bloc.dart';

import '../model/announcement_model.dart';
import '../services/announcement_service.dart';
import 'announcement_form_event.dart';
import 'announcement_form_state.dart';

/// Creates / updates an announcement via the multipart API.
/// Recipients are derived automatically: all eligible students of the
/// selected subject (admissionStatus 2 + section + subject mapping).
class AnnouncementFormBloc
    extends Bloc<AnnouncementFormEvent, AnnouncementFormState> {
  AnnouncementFormBloc({AnnouncementService? service})
      : _service = service ?? AnnouncementService(),
        super(const AnnouncementFormInitial()) {
    on<LoadAnnouncementRecipients>(_onLoadRecipients);
    on<SubmitAnnouncementForm>(_onSubmit);
  }

  final AnnouncementService _service;

  Future<void> _onLoadRecipients(
    LoadAnnouncementRecipients event,
    Emitter<AnnouncementFormState> emit,
  ) async {
    try {
      await _service.fetchEligibleStudentIds(event.subject);
    } catch (_) {
      // Cache stays cold; submit will retry and surface the error.
    }
  }

  Future<void> _onSubmit(
    SubmitAnnouncementForm event,
    Emitter<AnnouncementFormState> emit,
  ) async {
    emit(const AnnouncementFormSubmitting());
    try {
      // Web parity: editing keeps the announcement's original recipients;
      // create sends every eligible student of the subject.
      var studentIds = event.existing?.studentIds ?? const <int>[];
      if (studentIds.isEmpty) {
        studentIds =
            await _service.fetchEligibleStudentIds(event.subject);
      }
      if (studentIds.isEmpty) {
        emit(const AnnouncementFormFailed(
          'No matching students found for this subject.',
        ));
        return;
      }

      final request = AnnouncementRequest(
        title: event.title,
        content: event.content,
        scheduleAt: event.scheduleAt,
        validUntil: event.validUntil,
        subjectTeacherAllotmentId: event.subject.allotmentId,
        instituteId: event.subject.facultyUserId,
        studentIds: studentIds,
      );

      await _service.save(
        existing: event.existing,
        request: request,
        file: event.file,
      );
      emit(const AnnouncementFormSaved());
    } catch (error) {
      emit(AnnouncementFormFailed('$error'));
    }
  }
}
