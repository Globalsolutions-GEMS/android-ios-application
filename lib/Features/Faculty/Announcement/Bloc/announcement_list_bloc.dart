import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/announcement_service.dart';
import 'announcement_list_event.dart';
import 'announcement_list_state.dart';

/// Loads announcements for the selected work-area subject.
/// GET /api/announcements returns every row; filtering by
/// subject / course / academic session happens locally (same as web).
class AnnouncementListBloc
    extends Bloc<AnnouncementListEvent, AnnouncementListState> {
  AnnouncementListBloc({AnnouncementService? service})
      : _service = service ?? AnnouncementService(),
        super(const AnnouncementListInitial()) {
    on<LoadAnnouncements>(_onLoad);
  }

  final AnnouncementService _service;

  Future<void> _onLoad(
    LoadAnnouncements event,
    Emitter<AnnouncementListState> emit,
  ) async {
    emit(const AnnouncementListLoading());
    try {
      final all = await _service.fetchAll();
      final items = all
          .where((a) => a.matchesSubject(
                subjectId: event.subject.subjectId,
                courseId: event.subject.courseId,
                academicSessionId: event.subject.academicSessionId,
              ))
          .toList();
      emit(AnnouncementListLoaded(items));
    } catch (error) {
      emit(AnnouncementListFailed('$error'));
    }
  }
}
