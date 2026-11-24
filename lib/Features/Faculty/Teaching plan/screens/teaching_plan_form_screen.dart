import 'package:erp_app/Core/widgets/app_form_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../Bloc/teaching_plan_bloc.dart';
import '../Bloc/teaching_plan_event.dart';
import '../Bloc/teaching_plan_state.dart';
import '../model/teaching_plan_model.dart';

const Color _primary = Color(0xFF7B61FF);
const Color _ink = Color(0xFF0F172A);
const Color _muted = Color(0xFF64748B);
const Color _canvas = Color(0xFFF6F7FB);
const Color _line = Color(0xFFE8ECF2);


class TeachingPlanFormScreen extends StatefulWidget {
  const TeachingPlanFormScreen({
    super.key,
    required this.bloc,
    required this.units,
    required this.topics,
    required this.teachingModes,
    required this.existingPlans,
    required this.conflicts,
    required this.subjectName,
    required this.courseName,
    required this.academicSessionId,
    required this.subjectId,
    required this.courseId,
    required this.allotmentId,
    this.editingPlan,
  });

  final TeachingPlanBloc bloc;
  final List<TeachingPlanUnit> units;
  final List<TeachingPlanTopic> topics;
  final List<String> teachingModes;
  final List<TeachingPlan> existingPlans;
  final List<TeachingPlanConflict> conflicts;
  final String subjectName;
  final String courseName;
  final int academicSessionId;
  final int subjectId;
  final int courseId;
  final int allotmentId;
  final TeachingPlan? editingPlan;

  @override
  State<TeachingPlanFormScreen> createState() =>
      _TeachingPlanFormScreenState();
}

class _TeachingPlanFormScreenState extends State<TeachingPlanFormScreen> {
  TeachingPlanUnit? _selectedUnit;
  TeachingPlanTopic? _selectedTopic;
  String? _selectedMode;
  DateTime? _plannedDate;
  DateTime? _deliveredDate;
  final _objectiveController = TextEditingController();
  int _conflictPage = 0;
  String? _objectiveError;

  @override
  void initState() {
    super.initState();
    if (widget.editingPlan != null) {
      final plan = widget.editingPlan!;
      _selectedUnit = widget.units.firstWhere(
        (u) => u.id == plan.unitId,
        orElse: () => widget.units.first,
      );
      // Topics for this unit load async via TeachingPlanUnitSelected;
      // _topicSelector picks the matching topic once they arrive.
      _selectedTopic = null;
      _selectedMode = _titleCase(plan.teachingMode);
      _plannedDate = plan.plannedDate;
      _deliveredDate = plan.deliveredDate;
      _objectiveController.text = plan.objective ?? '';
      _objectiveError = _validateObjective(_objectiveController.text);
      // Trigger topic load for the selected unit
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.bloc.add(TeachingPlanUnitSelected(_selectedUnit!.id));
      });
    } else {
      _selectedUnit = null;
      _selectedTopic = null;
      _selectedMode = null;
      _plannedDate = null;
      _deliveredDate = null;
      _objectiveController.clear();
      _objectiveError = null;
    }
  }

  @override
  void dispose() {
    _objectiveController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool delivered}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate:
          delivered ? (_deliveredDate ?? now) : (_plannedDate ?? now),
      firstDate: delivered
          ? (_deliveredDate ?? _plannedDate ?? today)
          : today,
      lastDate: DateTime(now.year + 5),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (delivered) {
          _deliveredDate = picked;
        } else {
          _plannedDate = picked;
          _conflictPage = 0; // Reset pagination on date change
        }
      });
    }
  }

  bool _isDuplicateUnitTopic() {
    if (_selectedUnit == null || _selectedTopic == null) return false;
    return widget.existingPlans.any(
      (plan) =>
          plan.unitId == _selectedUnit!.id &&
          plan.topicId == _selectedTopic!.id &&
          (widget.editingPlan == null || plan.id != widget.editingPlan!.id),
    );
  }

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  String? _validateObjective(String value) {
    if (value.trim().isEmpty) return null; // Optional field
    if (value.trim().isEmpty) return 'Objective cannot be empty spaces.';
    if (RegExp(r'^\d+$').hasMatch(value.trim())) {
      return 'Objective cannot be only numeric.';
    }
    if (RegExp(r'^[^a-zA-Z0-9]+$').hasMatch(value.trim())) {
      return 'Objective cannot be only special characters.';
    }
    return null;
  }

  bool _isFutureDate(DateTime? date) {
    if (date == null) return false;
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    final dateMidnight = DateTime(date.year, date.month, date.day);
    return dateMidnight.isAfter(todayMidnight);
  }

  bool get _isFormEditable {
    if (widget.editingPlan == null) return true; // Create mode
    // Edit mode: check if future date
    return _isFutureDate(widget.editingPlan!.plannedDate);
  }

  List<TeachingPlanConflict> _sameDateConflicts() {
    if (_plannedDate == null) return const [];
    final day = DateTime(
      _plannedDate!.year,
      _plannedDate!.month,
      _plannedDate!.day,
    );
    return widget.conflicts.where((conflict) {
      final d = conflict.plannedDate;
      if (d == null) return false;
      final sameDay = DateTime(d.year, d.month, d.day) == day;
      final sameSession = conflict.academicSession == widget.academicSessionId;
      // Exclude the plan being edited from conflict check
      if (widget.editingPlan != null && conflict.planId == widget.editingPlan!.id) {
        return false;
      }
      // Exclude current subject/course from conflict display
      final sameSubject = conflict.subjectName.trim().toLowerCase() ==
          widget.subjectName.trim().toLowerCase();
      final sameCourse = conflict.courseName.trim().toLowerCase() ==
          widget.courseName.trim().toLowerCase();
      return sameDay && sameSession && !(sameSubject && sameCourse);
    }).toList();
  }

  List<TeachingPlanConflict> _paginatedConflicts() {
    final conflicts = _sameDateConflicts();
    final pageSize = 5;
    final start = _conflictPage * pageSize;
    if (start >= conflicts.length) return const [];
    final end = (start + pageSize).clamp(0, conflicts.length);
    return conflicts.sublist(start, end);
  }

  int get _totalConflictPages {
    final conflicts = _sameDateConflicts();
    return (conflicts.length / 5).ceil();
  }

  Future<void> _save() async {
    if (_selectedUnit == null ||
        _selectedTopic == null ||
        _selectedMode == null ||
        _plannedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields.' ,style: const TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.white,),
      );
      return;
    }

    // Validate objective
    final objectiveError = _validateObjective(_objectiveController.text);
    if (objectiveError != null) {
      setState(() => _objectiveError = objectiveError);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            objectiveError,
            style: const TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.white,
        ),
      );
      return;
    }

    if (_isDuplicateUnitTopic()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'A plan for this unit and topic already exists.',
          style: const TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.white,
        ),
      );
      return;
    }

    final conflicts = _sameDateConflicts();
    if (conflicts.isNotEmpty) {
      final proceed = await _showConflictWarning(conflicts);
      if (proceed != true || !mounted) return;
    }

    Navigator.pop(
      context,
      TeachingPlanDraft(
        unitId: _selectedUnit!.id,
        unitName: _selectedUnit!.unitName,
        topicId: _selectedTopic!.id,
        topicName: _selectedTopic!.topicName,
        plannedDate: _plannedDate!,
        teachingMode: _selectedMode!,
        objective: _objectiveController.text.trim(),
        deliveredDate: _deliveredDate,
        id: widget.editingPlan?.id,
        subjectTeacherAllotmentId: widget.allotmentId,
      ),
    );
  }

  Future<bool?> _showConflictWarning(
    List<TeachingPlanConflict> conflicts,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Schedule conflict'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You already have ${conflicts.length} plan(s) on this date:',
              style: const TextStyle(fontSize: 13, color: _muted),
            ),
            const SizedBox(height: 10),
            for (final c in conflicts.take(4))
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '• ${c.subjectName} — ${c.unitName} / ${c.topic}',
                  style: const TextStyle(fontSize: 12.5, color: _ink),
                ),
              ),
            if (conflicts.length > 4)
              Text(
                '…and ${conflicts.length - 4} more',
                style: const TextStyle(fontSize: 12, color: _muted),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: _primary),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _cancel() {
    setState(() {
      _selectedUnit = null;
      _selectedTopic = null;
      _selectedMode = null;
      _plannedDate = null;
      _deliveredDate = null;
      _objectiveController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        title: Text(
          widget.editingPlan != null ? 'Edit Teaching Plan' : 'Create Teaching Plan',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        elevation: 0,
        surfaceTintColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _unitDropdown(),
                const SizedBox(height: 13),
                _topicSelector(),
                const SizedBox(height: 13),
                AppPickerField(
                  label: 'Planned date',
                  hint: 'Select planned date',
                  text: _plannedDate == null
                      ? null
                      : _formatDate(_plannedDate!),
                  onTap: () => _pickDate(delivered: false),
                  enabled: _isFormEditable,
                ),
                const SizedBox(height: 6),
                if (_plannedDate != null) _conflictCard(),
                const SizedBox(height: 13),
                AppDropdown<String>(
                  label: 'Teaching mode',
                  hint: 'Select teaching mode',
                  value: _selectedMode,
                  items: widget.teachingModes
                      .map(
                        (mode) => AppDropdownItem<String>(
                          value: mode,
                          label: mode,
                        ),
                      )
                      .toList(),
                  onChanged: (mode) {
                    if (_isFormEditable) {
                      setState(() => _selectedMode = mode);
                    }
                  },
                  enabled: _isFormEditable,
                ),
                const SizedBox(height: 13),
                _fieldLabel('Objective'),
                const SizedBox(height: 6),
                TextField(
                  controller: _objectiveController,
                  minLines: 2,
                  maxLines: 4,
                  enabled: _isFormEditable,
                  decoration: _inputDecoration(
                    'Enter teaching objective',
                    null,
                  ).copyWith(
                    errorText: _objectiveError,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _objectiveError = _validateObjective(value);
                    });
                  },
                ),
                const SizedBox(height: 13),
                AppPickerField(
                  label: 'Delivered date',
                  hint: _deliveredDate == null
                      ? 'Auto-filled when topic is completed'
                      : _formatDate(_deliveredDate!),
                  text: _deliveredDate == null
                      ? null
                      : _formatDate(_deliveredDate!),
                  onTap: () => _pickDate(delivered: true),
                  required: false,
                  enabled: widget.editingPlan != null && _deliveredDate != null,
                ),
                const SizedBox(height: 5),
                Text(
                  _deliveredDate != null
                      ? 'Topic completed on ${_formatDate(_deliveredDate!)}'
                      : 'This date can be updated when the topic is fully delivered.',
                  style: const TextStyle(color: _muted, fontSize: 11.5),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: FilledButton.icon(
                          onPressed: _save,
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: Text(
                            widget.editingPlan != null ? 'Update' : 'Submit',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: widget.editingPlan != null
                          ? () => Navigator.pop(context)
                          : _cancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _muted,
                        side: const BorderSide(color: _line),
                        minimumSize: const Size(88, 46),
                        textStyle: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _unitDropdown() {
    if (widget.units.isEmpty) {
      return _disabledField('No units available for this subject');
    }
    final isEditing = widget.editingPlan != null;
    return AppDropdown<TeachingPlanUnit>(
      label: 'Unit',
      hint: 'Select unit',
      value: _selectedUnit,
      items: widget.units
          .map(
            (unit) => AppDropdownItem<TeachingPlanUnit>(
              value: unit,
              label: unit.displayName,
            ),
          )
          .toList(),
      onChanged: (unit) {
        if (!isEditing) {
          setState(() {
            _selectedUnit = unit;
            _selectedTopic = null;
          });
          if (unit != null) {
            widget.bloc.add(TeachingPlanUnitSelected(unit.id));
          }
        }
      },
      enabled: !isEditing,
    );
  }

  Widget _topicSelector() {
    final isEditing = widget.editingPlan != null;
    return BlocBuilder<TeachingPlanBloc, TeachingPlanState>(
      bloc: widget.bloc,
      builder: (context, state) {
        if (state is! TeachingPlanLoaded) {
          return _disabledField('Loading topics...');
        }
        if (state.topicsLoading) {
          return _disabledField('Loading topics...');
        }
        final topics = state.topics;
        if (topics.isEmpty) {
          return _disabledField('Select a unit first');
        }
        // In edit mode, pick the plan's topic once its unit's topics load.
        if (widget.editingPlan != null && _selectedTopic == null) {
          final match = topics.where(
            (t) => t.id == widget.editingPlan!.topicId,
          );
          if (match.isNotEmpty) {
            _selectedTopic = match.first;
          }
        }
        // Clear selection if it's no longer in the new topic list.
        if (_selectedTopic != null &&
            !topics.contains(_selectedTopic)) {
          _selectedTopic = null;
        }
        return AppDropdown<TeachingPlanTopic>(
          label: 'Topic',
          hint: 'Select topic',
          value: _selectedTopic,
          items: topics
              .map(
                (topic) => AppDropdownItem<TeachingPlanTopic>(
                  value: topic,
                  label: topic.displayName,
                ),
              )
              .toList(),
          onChanged: (topic) {
            if (!isEditing) {
              setState(() => _selectedTopic = topic);
            }
          },
          enabled: !isEditing,
        );
      },
    );
  }

  Widget _disabledField(String text) {
    return InputDecorator(
      decoration: _inputDecoration('', null).copyWith(
        filled: true,
        fillColor: const Color(0xFFF2F3F6),
      ),
      child: Text(
        text,
        style: const TextStyle(color: _muted, fontSize: 12.5),
      ),
    );
  }

  Widget _conflictCard() {
    final pageConflicts = _paginatedConflicts();
    final totalPages = _totalConflictPages;

    if (pageConflicts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFD97706),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Schedules on this date',
                style: TextStyle(
                  color: _ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '${_conflictPage + 1} / $totalPages',
                style: const TextStyle(color: _muted, fontSize: 11.5),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _conflictTable(pageConflicts),
          if (totalPages > 1) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _conflictPage > 0
                      ? () => setState(() => _conflictPage--)
                      : null,
                  icon: const Icon(Icons.chevron_left, size: 18),
                  color: _ink,
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 16),
                Text(
                  'Page ${_conflictPage + 1} of $totalPages',
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: _conflictPage < totalPages - 1
                      ? () => setState(() => _conflictPage++)
                      : null,
                  icon: const Icon(Icons.chevron_right, size: 18),
                  color: _ink,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _conflictTable(List<TeachingPlanConflict> conflicts) {
    return Column(
      children: [
        for (final c in conflicts) _conflictRow(c),
      ],
    );
  }

  Widget _conflictRow(TeachingPlanConflict c) {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            c.courseName,
            style: const TextStyle(
              color: _ink,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            c.subjectName,
            style: const TextStyle(
              color: _muted,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.topic_outlined,
                size: 12,
                color: _muted,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  c.topic,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 12,
                color: _muted,
              ),
              const SizedBox(width: 4),
              Text(
                c.plannedDate == null
                    ? '-'
                    : _formatDate(c.plannedDate!),
                style: const TextStyle(
                  color: _ink,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text, {bool required = false}) => RichText(
        text: TextSpan(
          style: const TextStyle(
            color: _ink,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
          children: [
            TextSpan(text: text),
            if (required)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: Color(0xFFE05252)),
              ),
          ],
        ),
      );

  InputDecoration _inputDecoration(String hint, IconData? icon) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFA0A8B6), fontSize: 12.5),
        prefixIcon: icon == null ? null : Icon(icon, size: 18, color: _muted),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 1.3),
        ),
      );

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      );

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')} ${_month(date.month)} ${date.year}';

  String _month(int month) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][month - 1];
}
