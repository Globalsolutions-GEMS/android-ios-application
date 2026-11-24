import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:erp_app/Features/Faculty/E-learning Workarea/model/workarea_subject_model.dart';
import '../services/assignment_file_service.dart';
import '../Bloc/assignment_form_bloc.dart';
import '../Bloc/assignment_form_event.dart';
import '../Bloc/assignment_form_state.dart';
import '../model/assignment_model.dart';

const Color _primary = Color(0xFF7B61FF);
const Color _page = Color(0xFFF6F7FB);
const Color _ink = Color(0xFF0F172A);
const Color _muted = Color(0xFF64748B);
const Color _border = Color(0xFFE8ECF2);
const Color _green = Color(0xFF16A34A);
const Color _red = Color(0xFFDC2626);

const int _maxFileBytes = 20 * 1024 * 1024;

/// Create / edit assignment form. Pops with `true` after a successful save.
class AssignmentFormScreen extends StatelessWidget {
  const AssignmentFormScreen({
    super.key,
    required this.subject,
    this.assignment,
  });

  final WorkAreaSubject subject;

  /// null = create, not null = edit.
  final FacultyAssignment? assignment;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AssignmentFormBloc()
        ..add(LoadFormStudents(
          courseId: subject.courseId,
          subjectId: subject.subjectId,
          sectionIds: subject.sectionIds,
        )),
      child: _AssignmentFormView(subject: subject, assignment: assignment),
    );
  }
}

class _AssignmentFormView extends StatefulWidget {
  const _AssignmentFormView({required this.subject, required this.assignment});

  final WorkAreaSubject subject;
  final FacultyAssignment? assignment;

  @override
  State<_AssignmentFormView> createState() => _AssignmentFormViewState();
}

class _AssignmentFormViewState extends State<_AssignmentFormView> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _marks = TextEditingController();

  DateTime? _dueDate;
  String _submission = '';
  File? _file;
  String? _fileName;

  final Set<int> _selected = {};
  late final Set<int> _locked;

  String? _dueError;
  String? _typeError;
  String? _fileError;
  bool _downloading = false;

  bool get _isEdit => widget.assignment != null;

  @override
  void initState() {
    super.initState();
    final a = widget.assignment;
    _locked = <int>{...?a?.studentIds};
    _selected.addAll(_locked);
    if (a != null) {
      _title.text = a.title;
      _description.text = a.description;
      _marks.text =
          a.marks % 1 == 0 ? a.marks.toInt().toString() : '${a.marks}';
      _dueDate = a.dueDate;
      _submission = a.submission;
      _fileName = a.attachmentName;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _marks.dispose();
    super.dispose();
  }

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: error ? _red : _green,
      ));
  }

  // ---------- validators (same rules as the web form) ----------

  String? _validateText(String value, String requiredMsg, String name) {
    if (value.isEmpty) return requiredMsg;
    if (value.trim().isEmpty) return '$name cannot be only spaces';
    if (RegExp(r'^\d+$').hasMatch(value)) {
      return '$name cannot be only numbers';
    }
    if (RegExp(r'^[^a-zA-Z0-9 ]+$').hasMatch(value)) {
      return '$name cannot be only special characters';
    }
    return null;
  }

  String? _validateMarks(String value) {
    if (value.isEmpty) return 'Assignment Marks are required';
    if (value.trim().isEmpty) return 'Assignment Marks cannot be spaces only';
    if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(value)) {
      return 'Assignment Marks accept only numeric values (integer or decimal)';
    }
    if (RegExp(r'^0+(\.0+)?$').hasMatch(value)) {
      return 'Assignment Marks cannot be 0';
    }
    return null;
  }

  // ---------- pickers ----------

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final initial =
        (_dueDate != null && _dueDate!.isAfter(now)) ? _dueDate! : now;

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;

    final picked = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      _dueDate = picked;
      _dueError =
          picked.isBefore(now) ? 'Due date cannot be in the past' : null;
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    );
    if (result == null || result.files.single.path == null) return;

    final picked = result.files.single;
    if (picked.size > _maxFileBytes) {
      setState(() => _fileError = 'File size must not exceed 20 MB.');
      return;
    }
    setState(() {
      _file = File(picked.path!);
      _fileName = picked.name;
      _fileError = null;
    });
  }
  Future<void> _downloadExisting() async {
    final a = widget.assignment;
    final name = a?.attachmentName;
    if (a == null || name == null || _downloading) return;

    setState(() => _downloading = true);
    try {
      await AssignmentFileService.downloadAndOpen(
        assignmentId: a.assignmentId,
        fileName: name,
      );
    } catch (error) {
      if (mounted) {
        _snack(
          'Failed to download attachment: '
          '${error.toString().replaceFirst('Exception: ', '')}',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }
  void _clearPickedFile() {
    setState(() {
      _file = null;
      _fileName = widget.assignment?.attachmentName;
      _fileError = null;
    });
  }

  // ---------- submit ----------

  void _submit() {
    final formOk = _formKey.currentState?.validate() ?? false;

    String? dueError;
    if (_dueDate == null) {
      dueError = 'Due Date is required';
    } else if (_dueDate!.isBefore(DateTime.now())) {
      dueError = 'Due date cannot be in the past';
    }
    final typeError = _submission.isEmpty ? 'Submission Type is required' : null;

    setState(() {
      _dueError = dueError;
      _typeError = typeError;
    });
    if (!formOk || dueError != null || typeError != null || _fileError != null) {
      return;
    }
    if (_selected.isEmpty) {
      _snack('Please select at least one student.', error: true);
      return;
    }

    final request = AssignmentRequest(
      title: _title.text.trim(),
      description: _description.text.trim(),
      marks: double.parse(_marks.text.trim()),
      dueDate: _dueDate!,
      submission: _submission,
      subjectId: widget.subject.subjectId,
      allotmentId: widget.subject.allotmentId,
      studentIds: _selected.toList()..sort(),
    );

    context.read<AssignmentFormBloc>().add(SubmitAssignmentForm(
          request: request,
          file: _file,
          assignmentId: widget.assignment?.assignmentId,
        ));
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AssignmentFormBloc, AssignmentFormState>(
      listenWhen: (_, s) => s is AssignmentFormLoaded && s.notice != null,
      listener: (context, state) {
        final s = state as AssignmentFormLoaded;
        _snack(s.notice!, error: s.noticeIsError);
        if (s.saved) Navigator.pop(context, true);
      },
      builder: (context, state) {
        final loaded = state is AssignmentFormLoaded ? state : null;
        final submitting = loaded?.isSubmitting ?? false;

        return Scaffold(
          backgroundColor: _page,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            foregroundColor: _ink,
            title: Text(
              _isEdit ? 'Edit Assignment' : 'Create Assignment',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          body: SafeArea(
            child: state is AssignmentFormFailed
                ? _FormError(
                    message: state.message,
                    onRetry: () => context.read<AssignmentFormBloc>().add(
                          LoadFormStudents(
                            courseId: widget.subject.courseId,
                            subjectId: widget.subject.subjectId,
                            sectionIds: widget.subject.sectionIds,
                          ),
                        ),
                  )
                : _buildForm(loaded),
          ),
          bottomNavigationBar: SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: _border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: submitting ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _ink,
                        side: const BorderSide(color: _border),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: (submitting || loaded == null) ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: _primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        submitting
                            ? 'Processing...'
                            : (_isEdit ? 'Update' : 'Submit'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildForm(AssignmentFormLoaded? loaded) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _subjectLine(),
          const SizedBox(height: 14),
          _Card(
            title: 'Assignment details',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _title,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _decoration('Title', hint: 'Enter title'),
                  validator: (v) =>
                      _validateText(v ?? '', 'Title is required', 'Title'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _description,
                  minLines: 2,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration:
                      _decoration('Description', hint: 'Enter description'),
                  validator: (v) => _validateText(
                    v ?? '',
                    'Description is required',
                    'Description',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _marks,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      _decoration('Assignment marks', hint: 'Enter marks'),
                  validator: (v) => _validateMarks(v ?? ''),
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: _pickDueDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    isEmpty: _dueDate == null,
                    decoration: _decoration(
                      'Due date & time',
                      hint: 'Select date and time',
                      errorText: _dueError,
                    ).copyWith(
                      suffixIcon: const Icon(Icons.event_outlined, color: _muted),
                    ),
                    child: Text(
                      _dueDate == null ? '' : _formatDateTime(_dueDate!),
                      style: const TextStyle(color: _ink, fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Submission type *',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _TypeOption(
                        label: 'Online',
                        icon: Icons.language_rounded,
                        selected: _submission == 'online',
                        onTap: () => setState(() {
                          _submission = 'online';
                          _typeError = null;
                        }),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _TypeOption(
                        label: 'Offline',
                        icon: Icons.edit_note_rounded,
                        selected: _submission == 'offline',
                        onTap: () => setState(() {
                          _submission = 'offline';
                          _typeError = null;
                        }),
                      ),
                    ),
                  ],
                ),
                if (_typeError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4),
                    child: Text(
                      _typeError!,
                      style: const TextStyle(color: _red, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 16),
                _attachmentSection(),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _studentsCard(loaded),
        ],
      ),
    );
  }

  Widget _subjectLine() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _primary.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.menu_book_outlined, color: _primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${widget.subject.subjectName} • ${widget.subject.courseName}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _ink,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _attachmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attachment (optional)',
          style: TextStyle(
            color: _ink,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.attach_file_rounded, size: 18),
              label: const Text('Choose file'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primary,
                side: const BorderSide(color: _border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(width: 10),
                       Expanded(
              child: (_isEdit && _file == null && _fileName != null)
                  ? InkWell(
                      onTap: _downloadExisting,
                      child: Text(
                        _downloading ? 'Downloading...' : _fileName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _primary,
                          fontSize: 12.5,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    )
                  : Text(
                      _fileName ?? 'No file chosen',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _muted, fontSize: 12.5),
                    ),
            ),
            if (_file != null)
              IconButton(
                tooltip: 'Remove',
                onPressed: _clearPickedFile,
                icon: const Icon(Icons.close_rounded, size: 18, color: _muted),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _fileError ?? 'PDF, Word or image. Max 20 MB.',
          style: TextStyle(
            color: _fileError == null ? _muted : _red,
            fontSize: 11.5,
          ),
        ),
      ],
    );
  }

  Widget _studentsCard(AssignmentFormLoaded? loaded) {
    final students = loaded?.students ?? const <AssignmentStudent>[];
    final allSelected =
        students.isNotEmpty && students.every((s) => _selected.contains(s.id));

    return _Card(
      title: 'Students',
      trailing: students.isEmpty
          ? null
          : Text(
              '${_selected.length} selected',
              style: const TextStyle(
                color: _primary,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
      child: Builder(builder: (context) {
        if (loaded == null) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(color: _primary)),
          );
        }
        if (students.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No students found for this subject.',
              style: TextStyle(color: _muted, fontSize: 13),
            ),
          );
        }
        return Column(
          children: [
            CheckboxListTile(
              value: allSelected,
              onChanged: (_) => setState(() {
                if (allSelected) {
                  _selected
                    ..clear()
                    ..addAll(_locked);
                } else {
                  _selected.addAll(students.map((s) => s.id));
                }
              }),
              title: const Text(
                'Select all',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: _primary,
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            const Divider(height: 1, color: _border),
            for (final s in students) ...[
              CheckboxListTile(
                value: _selected.contains(s.id),
                onChanged: _locked.contains(s.id)
                    ? null
                    : (v) => setState(() {
                          if (v == true) {
                            _selected.add(s.id);
                          } else {
                            _selected.remove(s.id);
                          }
                        }),
                title: Text(
                  s.fullName.isEmpty ? 'Unnamed Student' : s.fullName,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Roll No: ${s.rollNumber.isEmpty ? 'N/A' : s.rollNumber}'
                  '${_locked.contains(s.id) ? '  •  Already added' : ''}',
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: _primary,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              const Divider(height: 1, color: _border),
            ],
          ],
        );
      }),
    );
  }
}

InputDecoration _decoration(String label, {String? hint, String? errorText}) {
  OutlineInputBorder outline(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c),
      );
  return InputDecoration(
    labelText: '$label *',
    hintText: hint,
    errorText: errorText,
    errorMaxLines: 2,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: outline(_border),
    enabledBorder: outline(_border),
    focusedBorder: outline(_primary),
    errorBorder: outline(_red),
    focusedErrorBorder: outline(_red),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D172033),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _TypeOption extends StatelessWidget {
  const _TypeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? _primary.withValues(alpha: 0.10) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _primary : _border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? _primary : _muted),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? _primary : _ink,
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormError extends StatelessWidget {
  const _FormError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 44, color: _red),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, fontSize: 13),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: _primary),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final period = d.hour >= 12 ? 'PM' : 'AM';
  final day = d.day.toString().padLeft(2, '0');
  final minute = d.minute.toString().padLeft(2, '0');
  return '$day ${months[d.month - 1]} ${d.year}, $hour:$minute $period';
}