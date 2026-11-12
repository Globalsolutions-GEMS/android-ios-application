import 'package:erp_app/Core/theme/app_theme.dart';
import 'package:erp_app/Core/widgets/app_form_fields.dart';
import 'package:erp_app/Features/Faculty/Attendance/Bloc/mark_attendance_bloc.dart';
import 'package:erp_app/Features/Faculty/Attendance/Bloc/mark_attendance_event.dart';
import 'package:erp_app/Features/Faculty/Attendance/Bloc/mark_attendance_state.dart';
import 'package:erp_app/Features/Faculty/Attendance/model/mark_attendance_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MarkAttendanceScreen extends StatelessWidget {
  const MarkAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          MarkAttendanceBloc()..add(const MarkAttendanceLoadRequested()),
      child: const _MarkAttendanceView(),
    );
  }
}

class _MarkAttendanceView extends StatefulWidget {
  const _MarkAttendanceView();

  @override
  State<_MarkAttendanceView> createState() => _MarkAttendanceViewState();
}

class _MarkAttendanceViewState extends State<_MarkAttendanceView> {
  static const Color _primary = Color(0xFF6D4AFF);
  static const Color _dark = Color(0xFF172033);
  static const Color _grey = Color(0xFF64748B);
  static const Color _border = Color(0xFFD5DAE5);
  static const Color _red = Color(0xFFDC2626);

  static const List<String> _classTypes = [
    'Regular Lecture',
    'Extra Lecture',
    'Alternate Lecture',
  ];

  int? _selectedSessionId;
  DateTime? _selectedDate;
  int? _selectedDayId;
  int _backdatedDays = 0; // from backdated-config API later
  String? _selectedClassType;
  int? _selectedStatusId; // null = use the default status
  int? _selectedGroupIndex; // index in the subject list
  int? _selectedTopic;
  final Set<int> _selectedStudents = {}; // only students not yet marked
  final Map<int, int> _studentStatuses = {}; // studentId -> statusId
  final Map<String, String> _errors = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF0F6),
      appBar: AppBar(
        title: const Text('Mark Attendance'),
        backgroundColor: AppTheme.primaryViolet,
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<MarkAttendanceBloc, MarkAttendanceState>(
        // Fires once when a submit result arrives
        listenWhen: (previous, current) =>
            current.submitResult != null &&
            !identical(previous.submitResult, current.submitResult),
        listener: (context, state) {
          final result = state.submitResult!;
          _snack(result.message);
          if (result.success) {
            // Those students are marked now, so clear the selection
            setState(() {
              _selectedStudents.clear();
              _studentStatuses.clear();
            });
          }
        },
        builder: (context, state) {
          if (state is MarkAttendanceLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is MarkAttendanceFailure) {
            return Center(child: Text(state.message));
          }

          final statusId =
              _selectedStatusId ?? _defaultStatusId(state.statuses);
          final groups = state.groups;
          final groupIndex =
              (_selectedGroupIndex != null &&
                  _selectedGroupIndex! < groups.length)
              ? _selectedGroupIndex
              : null;
          final subjectHint = state.groupsLoading
              ? 'Loading subjects...'
              : (_selectedSessionId != null &&
                    _selectedDate != null &&
                    groups.isEmpty)
              ? 'No classes found for this day'
              : 'Select Subject';

          // Topic of an already marked lecture is selected automatically
          final effectiveTopic = _effectiveTopic(state);
          final topicValue = state.topics.any((t) => t.id == effectiveTopic)
              ? effectiveTopic
              : null;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Attendance session
                    AppDropdown<int>(
                      label: 'Attendance Session',
                      hint: 'Select Attendance Session',
                      value: _selectedSessionId,
                      items: [
                        for (final s in state.sessions)
                          AppDropdownItem(value: s.id, label: s.name),
                      ],
                      errorText: _errors['session'],
                      onChanged: (value) {
                        setState(() {
                          _selectedSessionId = value;
                          _resetSubject();
                          _errors.remove('session');
                        });
                        _loadSubjects();
                      },
                    ),
                    const SizedBox(height: 16),

                    // Attendance date
                    AppPickerField(
                      label: 'Attendance Date',
                      hint: 'Select date',
                      text: _selectedDate == null
                          ? null
                          : _formatDate(_selectedDate!),
                      errorText: _errors['date'],
                      onTap: () => _pickDate(state.days),
                    ),
                    const SizedBox(height: 16),

                    // Class type
                    AppDropdown<String>(
                      label: 'Class Type',
                      hint: 'Select Class Type',
                      value: _selectedClassType,
                      items: [
                        for (final t in _classTypes)
                          AppDropdownItem(value: t, label: t),
                      ],
                      errorText: _errors['classType'],
                      onChanged: (value) => setState(() {
                        _selectedClassType = value;
                        _errors.remove('classType');
                      }),
                    ),
                    const SizedBox(height: 16),

                    // Default status (changing it resets all student statuses)
                    AppDropdown<int>(
                      label: 'Default Status',
                      hint: 'Select Status',
                      required: false,
                      value: statusId,
                      items: [
                        for (final s in state.statuses)
                          AppDropdownItem(value: s.id, label: s.name),
                      ],
                      onChanged: (value) => setState(() {
                        _selectedStatusId = value;
                        _studentStatuses.clear();
                      }),
                    ),
                    const SizedBox(height: 16),

                    // Subject (from timetable API)
                    AppDropdown<int>(
                      label: 'Subject Name',
                      hint: subjectHint,
                      value: groupIndex,
                      items: [
                        for (var i = 0; i < groups.length; i++)
                          AppDropdownItem(value: i, label: groups[i].label),
                      ],
                      errorText: _errors['subject'] ?? state.groupsError,
                                           onChanged: (value) {
                        setState(() {
                          _selectedGroupIndex = value;
                          _selectedTopic = null;
                          _selectedStudents.clear();
                          _studentStatuses.clear();
                          _errors.remove('subject');
                          _errors.remove('topic');
                        });
                        context.read<MarkAttendanceBloc>().add(
                          (value != null &&
                                  _selectedSessionId != null &&
                                  _selectedDate != null)
                              ? MarkAttendanceGroupSelected(
                                  group: groups[value],
                                  sessionId: _selectedSessionId,
                                  date: _formatDate(_selectedDate!),
                                )
                              : const MarkAttendanceGroupSelected(),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Topic with covered / required lectures
                    AppDropdown<int>(
                      label: 'Topic Covered',
                      hint: state.studentsLoading
                          ? 'Loading topics...'
                          : 'Select Topic',
                      value: topicValue,
                      items: state.topics.map((t) {
                        final required = t.requiredLectures;
                        final covered = state.topicCoverage[t.id] ?? 0;
                        final done = covered >= required;
                        return AppDropdownItem(
                          value: t.id,
                          label: done
                              ? '${t.name} (Completed - $required/$required)'
                              : '${t.name} ($covered/$required lectures)',
                          enabled: !done, // fully covered topics are disabled
                        );
                      }).toList(),
                      errorText: _errors['topic'],
                      onChanged: (value) {
                        // Same rule as the web
                        if (state.markedStatuses.isNotEmpty &&
                            value != effectiveTopic) {
                          _snack(
                            'Please unmark the attendance first before '
                            'changing the topic.',
                          );
                          return;
                        }
                        setState(() {
                          _selectedTopic = value;
                          _errors.remove('topic');
                        });
                      },
                    ),
                    const SizedBox(height: 22),

                    // Confirm / Cancel
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: state.submitting ? null : _onConfirm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: state.submitting
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Confirm'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: state.submitting ? null : _onCancel,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _grey,
                              side: const BorderSide(color: _border),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _card(child: _studentSection(state, statusId)),
            ],
          );
        },
      ),
    );
  }

  // ---------- Student section ----------

  Widget _studentSection(MarkAttendanceState state, int? defaultStatusId) {
    final students = state.students;
    final marked = state.markedStatuses;
    final markedCount = students.where((s) => marked.containsKey(s.id)).length;
    final allSelected =
        students.isNotEmpty &&
        students.every(
          (s) => marked.containsKey(s.id) || _selectedStudents.contains(s.id),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Student Attendance',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _dark,
                ),
              ),
            ),
            if (students.isNotEmpty)
              Text(
                '${markedCount + _selectedStudents.length}/${students.length}  ',
                style: const TextStyle(fontSize: 12, color: _grey),
              ),
            const Text('Select All', style: TextStyle(fontSize: 12, color: _grey)),
            Checkbox(
              value: allSelected,
              onChanged: students.isEmpty
                  ? null
                  : (checked) => setState(() {
                      _selectedStudents.clear();
                      if (checked == true) {
                        _selectedStudents.addAll(
                          students
                              .where((s) => !marked.containsKey(s.id))
                              .map((s) => s.id),
                        );
                      }
                    }),
            ),
          ],
        ),
        const Divider(height: 1, color: _border),
        if (state.studentsLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (state.studentsError != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Center(
              child: Text(
                state.studentsError!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: _red),
              ),
            ),
          )
        else if (students.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Center(
              child: Text(
                _selectedGroupIndex == null
                    ? 'Please select a subject to view students'
                    : 'No students found for the selected subject',
                style: const TextStyle(fontSize: 13, color: _grey),
              ),
            ),
          )
        else
          ...students.map((s) => _studentTile(s, state, defaultStatusId)),
      ],
    );
  }

  Widget _studentTile(
    StudentModel student,
    MarkAttendanceState state,
    int? defaultStatusId,
  ) {
    final statuses = state.statuses;
    final markedStatusId = state.markedStatuses[student.id];
    final isMarked = markedStatusId != null;
    final selected = _selectedStudents.contains(student.id);
    final statusValue = isMarked
        ? markedStatusId
        : (_studentStatuses[student.id] ?? defaultStatusId);

    String recorded = '';
    if (isMarked) {
      for (final s in statuses) {
        if (s.id == markedStatusId) recorded = s.name;
      }
    }

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(4, 6, 10, 6),
      decoration: BoxDecoration(
        color: isMarked
            ? const Color(0xFFF1F5F9)
            : selected
            ? _primary.withOpacity(0.06)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? _primary.withOpacity(0.5) : _border,
          width: selected ? 1.4 : 1.1,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: isMarked || selected,
            onChanged: isMarked
                ? null
                : (checked) => setState(() {
                    if (checked == true) {
                      _selectedStudents.add(student.id);
                    } else {
                      _selectedStudents.remove(student.id);
                    }
                  }),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.fullName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _dark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Roll No: ${student.rollNumber ?? '-'}  •  '
                  'Div: ${student.sectionName.isEmpty ? '-' : student.sectionName}  •  '
                  'ID: ${student.id}',
                  style: const TextStyle(fontSize: 11, color: _grey),
                ),
                if (isMarked)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Marked  •  Recorded: $recorded',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          DropdownButton<int>(
            value: statuses.any((s) => s.id == statusValue) ? statusValue : null,
            isDense: true,
            underline: const SizedBox.shrink(),
            items: statuses
                .map(
                  (s) => DropdownMenuItem(
                    value: s.id,
                    child: Text(s.name, style: const TextStyle(fontSize: 13)),
                  ),
                )
                .toList(),
            onChanged: isMarked
                ? null
                : (value) {
                    if (value != null) {
                      setState(() => _studentStatuses[student.id] = value);
                    }
                  },
          ),
        ],
      ),
    );
  }

  // ---------- Actions ----------

  // Asks the bloc for subjects of the selected session + day
  void _loadSubjects() {
    context.read<MarkAttendanceBloc>().add(
      MarkAttendanceSubjectsRequested(
        sessionId: _selectedSessionId,
        dayId: _selectedDayId,
      ),
    );
  }

  // Opens date picker (today back to allowed backdated days)
  Future<void> _pickDate(List<DayModel> days) async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? today,
      firstDate: today.subtract(Duration(days: _backdatedDays)),
      lastDate: today,
    );
    if (picked == null) return;
    setState(() {
      _selectedDate = picked;
      _selectedDayId = _dayIdFor(picked, days);
      _resetSubject();
      _errors.remove('date');
    });
    _loadSubjects();
  }

  // Finds dayId for a date (case-insensitive, like the web)
  int? _dayIdFor(DateTime date, List<DayModel> days) {
    const names = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    final name = names[date.weekday - 1];
    for (final d in days) {
      if (d.day.toLowerCase() == name || d.shortName.toLowerCase() == name) {
        return d.id;
      }
    }
    return null;
  }

  // Default status = the one marked isDefault
  int? _defaultStatusId(List<AttendanceStatusModel> statuses) {
    for (final s in statuses) {
      if (s.isDefault) return s.id;
    }
    return null;
  }

  // Chosen topic, or the topic of the already marked lecture
  int? _effectiveTopic(MarkAttendanceState state) =>
      _selectedTopic ?? (state.markedTopicId == 0 ? null : state.markedTopicId);

  // Clears the subject and everything that depends on it
  void _resetSubject() {
    _selectedGroupIndex = null;
    _selectedTopic = null;
    _selectedStudents.clear();
    _studentStatuses.clear();
  }

  bool _validate(MarkAttendanceState state) {
    final errors = <String, String>{};
    if (_selectedSessionId == null) {
      errors['session'] = 'Please select attendance session';
    }
    if (_selectedDate == null) {
      errors['date'] = 'Please select attendance date';
    }
    if (_selectedClassType == null) {
      errors['classType'] = 'Please select lecture type';
    }
    if (_selectedGroupIndex == null) {
      errors['subject'] = 'Please select subject';
    } else if (state.topics.isEmpty) {
      errors['topic'] =
          'No topics available for this subject. Please add topics first.';
    } else if (_effectiveTopic(state) == null) {
      errors['topic'] = 'Please select a topic';
    }
    setState(() {
      _errors
        ..clear()
        ..addAll(errors);
    });
    return errors.isEmpty;
  }

  void _onConfirm() {
    final bloc = context.read<MarkAttendanceBloc>();
    final state = bloc.state;
    if (state.submitting || !_validate(state)) return;

    if (_selectedStudents.isEmpty) {
      _snack(
        state.markedStatuses.isNotEmpty
            ? 'Attendance for all selected students has already been marked'
            : 'Please select at least one student',
      );
      return;
    }

    // Status of every selected student (own status or the default one)
    final defaultId = _selectedStatusId ?? _defaultStatusId(state.statuses);
    final studentStatuses = <int, int>{};
    for (final id in _selectedStudents) {
      final status = _studentStatuses[id] ?? defaultId;
      if (status == null) {
        _snack('Please select a status');
        return;
      }
      studentStatuses[id] = status;
    }

    bloc.add(
      MarkAttendanceSubmitRequested(
        group: state.groups[_selectedGroupIndex!],
        sessionId: _selectedSessionId!,
        date: _formatDate(_selectedDate!),
        lectureType: _selectedClassType!,
        topicId: _effectiveTopic(state)!,
        studentStatuses: studentStatuses,
      ),
    );
  }

  void _onCancel() {
    setState(() {
      _selectedSessionId = null;
      _selectedDate = null;
      _selectedDayId = null;
      _selectedClassType = null;
      _selectedStatusId = null;
      _resetSubject();
      _errors.clear();
    });
    _loadSubjects(); // clears subjects, students and topics
  }

  void _snack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(AppTheme.showThemedSnackBar(context, message));
  }

  // ---------- Small UI helpers ----------

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}