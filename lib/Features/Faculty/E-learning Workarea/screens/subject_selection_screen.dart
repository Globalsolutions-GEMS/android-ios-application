import 'package:erp_app/Core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Bloc/workarea_subject_bloc.dart';
import '../Bloc/workarea_subject_event.dart';
import '../Bloc/workarea_subject_state.dart';
import '../model/workarea_subject_model.dart';

/// Subject selection page used before opening a workarea module
/// (Teaching Plan, Assignments, ...).
///
/// Loads the logged-in faculty's subject allotments for the current
/// academic session via [WorkAreaSubjectBloc]. Tapping a subject saves
/// the selected context to SharedPreferences, then calls
/// [onSubjectTap] so the caller can open the module screen.
class SubjectSelectionScreen extends StatefulWidget {
  final String moduleName;
  final ValueChanged<WorkAreaSubject> onSubjectTap;
  final VoidCallback? onBack;

  const SubjectSelectionScreen({
    super.key,
    required this.moduleName,
    required this.onSubjectTap,
    this.onBack,
  });

  @override
  State<SubjectSelectionScreen> createState() =>
      _SubjectSelectionScreenState();
}

class _SubjectSelectionScreenState extends State<SubjectSelectionScreen> {
  static const Color _ink = Color(0xFF172033);
  static const Color _muted = Color(0xFF64748B);
  static const Color _page = Color(0xFFF4F6FA);

  final TextEditingController _searchController = TextEditingController();
  final WorkAreaSubjectBloc _bloc = WorkAreaSubjectBloc();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _bloc.add(const LoadWorkAreaSubjects());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bloc.close();
    super.dispose();
  }

  List<WorkAreaSubject> _filterSubjects(List<WorkAreaSubject> subjects) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return subjects;
    return subjects.where((subject) {
      return subject.subjectName.toLowerCase().contains(query) ||
          subject.courseName.toLowerCase().contains(query) ||
          (subject.subjectCode ?? '').toLowerCase().contains(query) ||
          subject.sectionNames.any(
            (section) => section.toLowerCase().contains(query),
          );
    }).toList();
  }

  Future<void> _onSubjectTap(WorkAreaSubject subject) async {
    // Persist the selected context so module screens (Teaching Plan,
    // Assignments, ...) can call their APIs with the allotment id.
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(
      'workarea_faculty_user_id',
      subject.facultyUserId,
    );
    await preferences.setInt('workarea_subject_id', subject.subjectId);
    await preferences.setString('workarea_subject_name', subject.subjectName);
    await preferences.setInt('workarea_course_id', subject.courseId);
    await preferences.setString('workarea_course_name', subject.courseName);
    await preferences.setInt('workarea_allotment_id', subject.allotmentId);
    await preferences.setInt('workarea_academic_session_id', subject.academicSessionId);
    await preferences.setStringList(
      'workarea_section_ids',
      subject.sectionIds.map((id) => id.toString()).toList(),
    );
    await preferences.setStringList(
      'workarea_section_names',
      subject.sectionNames,
    );
    if (!mounted) return;
    widget.onSubjectTap(subject);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: _page,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        leading: widget.onBack == null
            ? null
            : IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
        title: Text(
          widget.moduleName,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        top: false,
        child: BlocBuilder<WorkAreaSubjectBloc, WorkAreaSubjectState>(
          bloc: _bloc,
          builder: (context, state) {
            if (state is WorkAreaSubjectLoading ||
                state is WorkAreaSubjectInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is WorkAreaSubjectFailure) {
              return _ErrorView(
                message: state.message,
                onRetry: () => _bloc.add(const LoadWorkAreaSubjects()),
              );
            }

            final subjects = state is WorkAreaSubjectsLoaded
                ? state.subjects
                : const <WorkAreaSubject>[];
            final filtered = _filterSubjects(subjects);

            return LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding = constraints.maxWidth >= 900
                    ? 28.0
                    : (constraints.maxWidth >= 600 ? 20.0 : 12.0);
                const cardSpacing = 12.0;
                final availableWidth = constraints.maxWidth > 1500
                    ? 1500.0
                    : constraints.maxWidth;
                final cardWidth = (availableWidth -
                        (horizontalPadding * 2) -
                        cardSpacing) /
                    2;

                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    14,
                    horizontalPadding,
                    24,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1500),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InstructionBanner(moduleName: widget.moduleName),
                          const SizedBox(height: 14),
                          _SearchField(
                            controller: _searchController,
                            onChanged: (value) =>
                                setState(() => _searchQuery = value),
                          ),
                          const SizedBox(height: 14),
                          if (filtered.isEmpty)
                            _EmptySubjects(
                              isSearching: _searchQuery.isNotEmpty,
                            )
                          else
                            Wrap(
                              spacing: cardSpacing,
                              runSpacing: cardSpacing,
                              children: filtered.map((subject) {
                                return SizedBox(
                                  width: cardWidth,
                                  child: _SubjectCard(
                                    subject: subject,
                                    onTap: () => _onSubjectTap(subject),
                                  ),
                                );
                              }).toList(),
                            ),
                          const SizedBox(height: 12),
                          if (filtered.isNotEmpty)
                            Text(
                              'Choose a subject to continue to ${widget.moduleName}.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: _muted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _InstructionBanner extends StatelessWidget {
  final String moduleName;
  const _InstructionBanner({required this.moduleName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),
        border: Border.all(color: const Color(0xFFC8DFFF)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: Color(0xFF3975C6), size: 21),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: const TextStyle(
                  color: Color(0xFF29466B),
                  fontSize: 14,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(text: 'Select a subject to proceed to '),
                  TextSpan(
                    text: moduleName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search subjects or courses',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE1E7F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE1E7F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryViolet, width: 1.4),
        ),
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final WorkAreaSubject subject;
  final VoidCallback onTap;

  const _SubjectCard({required this.subject, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: const Color(0xFFE8ECF3)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x09172033),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0EDFF),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: AppTheme.primaryViolet,
                      size: 17,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_outward_rounded,
                    size: 15,
                    color: Color(0xFF9AA5B5),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                subject.subjectName,
                softWrap: true,
                style: const TextStyle(
                  color: Color(0xFF263247),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 7),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(
                      Icons.school_outlined,
                      size: 14,
                      color: Color(0xFF7B8798),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      subject.courseName,
                      softWrap: true,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
              if (subject.sectionNames.isNotEmpty) ...[
                const SizedBox(height: 5),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.groups_outlined,
                        size: 14,
                        color: Color(0xFF7B8798),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Sections: ${subject.sectionNames.join(', ')}',
                        softWrap: true,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 9),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'View subject',
                      style: TextStyle(
                        color: AppTheme.primaryViolet,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppTheme.primaryViolet,
                    size: 15,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptySubjects extends StatelessWidget {
  final bool isSearching;
  const _EmptySubjects({required this.isSearching});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECF3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.menu_book_outlined,
              size: 42, color: Color(0xFF9AA5B5)),
          const SizedBox(height: 12),
          Text(
            isSearching ? 'No matching subjects found' : 'No subjects available',
            style: const TextStyle(
              color: Color(0xFF263247),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            isSearching
                ? 'Try a different subject or course name.'
                : 'Your assigned subjects will be visible here once allocation is completed.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 42, color: Color(0xFF9AA5B5)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryViolet,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
