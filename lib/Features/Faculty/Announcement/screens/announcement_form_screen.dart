import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:erp_app/Core/widgets/app_form_fields.dart';
import 'package:erp_app/Features/Faculty/E-learning Workarea/model/workarea_subject_model.dart';
import '../Bloc/announcement_form_bloc.dart';
import '../Bloc/announcement_form_event.dart';
import '../Bloc/announcement_form_state.dart';
import '../model/announcement_model.dart';

const Color _primary = Color(0xFF7B61FF);
const Color _page = Color(0xFFF6F7FB);
const Color _ink = Color(0xFF0F172A);
const Color _muted = Color(0xFF64748B);
const Color _border = Color(0xFFE8ECF2);
const Color _red = Color(0xFFDC2626);

const int _maxFileBytes = 20 * 1024 * 1024;
const List<String> _allowedExt = [
  'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx',
];

/// Create / edit announcement. Pops with the saved [AnnouncementItem].
class AnnouncementFormScreen extends StatefulWidget {
  const AnnouncementFormScreen({
    super.key,
    required this.subject,
    this.announcement,
  });

  final WorkAreaSubject subject;

  /// null = create, not null = edit.
  final AnnouncementItem? announcement;

  @override
  State<AnnouncementFormScreen> createState() => _AnnouncementFormScreenState();
}

class _AnnouncementFormScreenState extends State<AnnouncementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _content = TextEditingController();

  DateTime? _schedule;
  DateTime? _validity;
  File? _file;
  String? _fileName;

  String? _scheduleError;
  String? _validityError;
  String? _fileError;

  final AnnouncementFormBloc _formBloc = AnnouncementFormBloc();

  bool get _isEdit => widget.announcement != null;

  @override
  void initState() {
    super.initState();
    // Warm the recipient cache in the background so submit is fast.
    _formBloc.add(LoadAnnouncementRecipients(widget.subject));
    final a = widget.announcement;
    if (a != null) {
      _title.text = a.title;
      _content.text = a.content;
      _schedule = a.scheduleAt;
      _validity = a.validUntil;
      _fileName = a.attachmentName;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    _formBloc.close();
    super.dispose();
  }

  // ---------- validators (same rules as the web form) ----------

  String? _validateText(String value, String name) {
    if (value.isEmpty) return '$name is required.';
    if (value.trim().isEmpty) return '$name cannot contain only spaces.';
    if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
      return '$name must contain at least one letter.';
    }
    return null;
  }

  // ---------- pickers ----------

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  Future<DateTime?> _pickDateTime({
    required DateTime? current,
    required DateTime first,
  }) async {
    var initial = current ?? DateTime.now();
    if (initial.isBefore(first)) initial = first;

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (date == null || !mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _pickSchedule() async {
    final picked = await _pickDateTime(current: _schedule, first: _today);
    if (picked == null) return;

    String? error;
    if (picked.isBefore(DateTime.now())) {
      error = 'Schedule Date cannot be in the past.';
    } else if (_validity != null && picked.isAfter(_validity!)) {
      error = 'Schedule Date cannot be greater than Validity Date.';
    }
    setState(() {
      _schedule = picked;
      _scheduleError = error;
    });
  }

  Future<void> _pickValidity() async {
    final first = _schedule == null
        ? _today
        : DateTime(_schedule!.year, _schedule!.month, _schedule!.day);
    final picked = await _pickDateTime(current: _validity, first: first);
    if (picked == null) return;

    String? error;
    if (_schedule != null && picked.isBefore(_schedule!)) {
      error = 'Validity must be greater than or equal to Schedule Date.';
    } else if (picked.isBefore(DateTime.now())) {
      error = 'Validity cannot be in the past.';
    }
    setState(() {
      _validity = picked;
      _validityError = error;
      // re-check schedule against the new validity
      if (_schedule != null && _schedule!.isAfter(picked)) {
        _scheduleError = 'Schedule Date cannot be greater than Validity Date.';
      } else if (_scheduleError != null &&
          _scheduleError!.contains('greater than Validity')) {
        _scheduleError = null;
      }
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedExt,
    );
    if (result == null || result.files.single.path == null) return;

    final picked = result.files.single;
    final ext = (picked.extension ?? '').toLowerCase();

    if (picked.size > _maxFileBytes) {
      setState(() => _fileError = 'File size should not exceed 20MB.');
      return;
    }
    if (!_allowedExt.contains(ext)) {
      setState(() => _fileError =
          'Only PDF, Word, Excel and PowerPoint files are allowed.');
      return;
    }
    setState(() {
      _file = File(picked.path!);
      _fileName = picked.name;
      _fileError = null;
    });
  }

  void _clearPickedFile() {
    setState(() {
      _file = null;
      _fileName = widget.announcement?.attachmentName;
      _fileError = null;
    });
  }

  // ---------- submit ----------

  void _submit() {
    final formOk = _formKey.currentState?.validate() ?? false;

    String? validityError;
    String? scheduleError;
    if (_validity == null) {
      validityError = 'Validity is required';
    } else if (_validity!.isBefore(DateTime.now())) {
      validityError = 'Validity cannot be in the past.';
    }
    if (_schedule != null && _validity != null) {
      if (_schedule!.isAfter(_validity!)) {
        scheduleError = 'Schedule Date cannot be greater than Validity Date.';
      }
    }

    setState(() {
      _validityError = validityError;
      _scheduleError = scheduleError;
    });
    if (!formOk ||
        validityError != null ||
        scheduleError != null ||
        _fileError != null) {
      return;
    }

    _formBloc.add(
      SubmitAnnouncementForm(
        subject: widget.subject,
        title: _title.text.trim(),
        content: _content.text.trim(),
        scheduleAt: _schedule,
        validUntil: _validity!,
        file: _file,
        existing: widget.announcement,
      ),
    );
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    return BlocListener<AnnouncementFormBloc, AnnouncementFormState>(
      bloc: _formBloc,
      listener: (context, state) {
        if (state is AnnouncementFormSaved) {
          Navigator.pop(context, true);
        } else if (state is AnnouncementFormFailed) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to ${_isEdit ? 'update' : 'create'} announcement: '
                  '${state.message.replaceFirst('Exception: ', '')}',
                ),
                backgroundColor: _red,
              ),
            );
        }
      },
      child: Scaffold(
      backgroundColor: _page,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: _ink,
        title: Text(
          _isEdit ? 'Edit Announcement' : 'Create Announcement',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _subjectLine(),
              const SizedBox(height: 14),
              _Card(
                title: 'Announcement details',
                child: Column(
                  children: [
                    TextFormField(
                      controller: _title,
                      textCapitalization: TextCapitalization.sentences,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: _decoration('Title', hint: 'Enter title'),
                      validator: (v) => _validateText(v ?? '', 'Title'),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _content,
                      minLines: 4,
                      maxLines: 6,
                      textCapitalization: TextCapitalization.sentences,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration:
                          _decoration('Content', hint: 'Enter content'),
                      validator: (v) => _validateText(v ?? '', 'Content'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _Card(
                title: 'Schedule',
                child: Column(
                  children: [
                    AppPickerField(
                      label: 'Schedule date & time',
                      hint: 'Publish now ',
                      required: false,
                      icon: Icons.event_available_outlined,
                      text: _schedule == null
                          ? null
                          : formatAnnouncementDateTime(_schedule!),
                      errorText: _scheduleError,
                      // locked while editing an already scheduled announcement
                      enabled: !(_isEdit && _schedule != null),
                      onTap: _pickSchedule,
                    ),
                    const SizedBox(height: 14),
                    AppPickerField(
                      label: 'Validity',
                      hint: 'Select date and time',
                      icon: Icons.event_busy_outlined,
                      text: _validity == null
                          ? null
                          : formatAnnouncementDateTime(_validity!),
                      errorText: _validityError,
                      onTap: _pickValidity,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _Card(title: 'Attachment', child: _attachmentSection()),
            ],
          ),
        ),
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
                  onPressed: () => Navigator.pop(context),
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
                child: BlocBuilder<AnnouncementFormBloc, AnnouncementFormState>(
                  bloc: _formBloc,
                  builder: (context, state) {
                    final submitting = state is AnnouncementFormSubmitting;
                    return FilledButton(
                      onPressed: submitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: _primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: submitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_isEdit ? 'Update' : 'Submit'),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
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
          const Icon(Icons.campaign_outlined, color: _primary, size: 20),
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
              child: Text(
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
        const SizedBox(height: 6),
        Text(
          _fileError ?? 'PDF, Word, Excel or PowerPoint. Max 20 MB. (optional)',
          style: TextStyle(
            color: _fileError == null ? _muted : _red,
            fontSize: 11.5,
          ),
        ),
      ],
    );
  }
}

InputDecoration _decoration(String label, {String? hint}) {
  OutlineInputBorder outline(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c),
      );
  return InputDecoration(
    labelText: '$label *',
    hintText: hint,
    errorMaxLines: 2,
    alignLabelWithHint: true,
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
  const _Card({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
          Text(
            title,
            style: const TextStyle(
              color: _ink,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
