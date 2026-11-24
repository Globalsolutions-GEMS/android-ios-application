import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:erp_app/Core/widgets/app_confirm_dialog.dart';
import 'package:erp_app/Features/Faculty/E-learning Workarea/model/workarea_subject_model.dart';

import '../Bloc/teaching_plan_bloc.dart';
import '../Bloc/teaching_plan_event.dart';
import '../Bloc/teaching_plan_state.dart';
import '../model/teaching_plan_model.dart';
import '../services/teaching_plan_excel_service.dart';
import 'teaching_plan_form_screen.dart';

const Color _primary = Color(0xFF7B61FF);
const Color _ink = Color(0xFF0F172A);
const Color _muted = Color(0xFF64748B);
const Color _canvas = Color(0xFFF6F7FB);
const Color _line = Color(0xFFE8ECF2);

/// Teaching Plan screen for one selected workarea subject.
///
/// Loads units, topics, plans and same-date conflicts through
/// [TeachingPlanBloc] using [subject.subjectId] and
/// [subject.allotmentId] (teacherid).
class TeachingPlanScreen extends StatelessWidget {
  const TeachingPlanScreen({
    super.key,
    required this.subject,
    this.onSavePlan,
    this.onBulkUpload,
  });

  final WorkAreaSubject subject;
  final Future<void> Function(TeachingPlanDraft draft)? onSavePlan;
  final Future<void> Function()? onBulkUpload;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TeachingPlanBloc()
        ..add(LoadTeachingPlan(subject)),
      child: _TeachingPlanView(
        subject: subject,
        onSavePlan: onSavePlan,
        onBulkUpload: onBulkUpload,
      ),
    );
  }
}

class _TeachingPlanView extends StatefulWidget {
  const _TeachingPlanView({
    required this.subject,
    required this.onSavePlan,
    required this.onBulkUpload,
  });

  final WorkAreaSubject subject;
  final Future<void> Function(TeachingPlanDraft draft)? onSavePlan;
  final Future<void> Function()? onBulkUpload;

  @override
  State<_TeachingPlanView> createState() => _TeachingPlanViewState();
}

class _TeachingPlanViewState extends State<_TeachingPlanView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _searchController = TextEditingController();
  File? _selectedBulkFile;
  bool _bulkBusy = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openCreateForm() async {
    final bloc = context.read<TeachingPlanBloc>();
    final state = bloc.state;
    if (state is! TeachingPlanLoaded) return;

    final draft = await Navigator.push<TeachingPlanDraft>(
      context,
      MaterialPageRoute(
        builder: (_) => TeachingPlanFormScreen(
          bloc: bloc,
          units: state.units,
          topics: state.topics,
          teachingModes: const ['Offline', 'Online'],
          existingPlans: state.plans,
          conflicts: state.conflicts,
          subjectName: widget.subject.subjectName,
          courseName: widget.subject.courseName,
          subjectId: widget.subject.subjectId,
          courseId: widget.subject.courseId,
          academicSessionId: widget.subject.academicSessionId,
          allotmentId: widget.subject.allotmentId,
        ),
      ),
    );
    if (draft == null || !mounted) return;

    if (widget.onSavePlan != null) {
      await widget.onSavePlan!(draft);
      if (!mounted) return;
      _message('Teaching plan saved.');
    } else {
      bloc.add(TeachingPlanCreate(draft));
    }
  }

  Future<void> _openEditForm(TeachingPlanItem plan) async {
    final bloc = context.read<TeachingPlanBloc>();
    final state = bloc.state;
    if (state is! TeachingPlanLoaded) return;

    final editingPlan = state.plans.firstWhere((p) => p.id == plan.id);

    // Check if future date for edit restrictions
    final isFuture = _isFutureDate(editingPlan.plannedDate);
    if (!isFuture && editingPlan.deliveredDate == null) {
      _message('Past or current sessions cannot be edited!');
      return;
    }
    if (!isFuture && editingPlan.deliveredDate != null) {
      _message('Only the Delivered Date can be edited for past/current sessions.');
    }

    final draft = await Navigator.push<TeachingPlanDraft>(
      context,
      MaterialPageRoute(
        builder: (_) => TeachingPlanFormScreen(
          bloc: bloc,
          units: state.units,
          topics: state.topics,
          teachingModes: const ['Offline', 'Online'],
          existingPlans: state.plans,
          conflicts: state.conflicts,
          subjectName: widget.subject.subjectName,
          courseName: widget.subject.courseName,
          subjectId: widget.subject.subjectId,
          courseId: widget.subject.courseId,
          academicSessionId: widget.subject.academicSessionId,
          allotmentId: widget.subject.allotmentId,
          editingPlan: editingPlan,
        ),
      ),
    );
    if (draft == null || !mounted) return;

    if (widget.onSavePlan != null) {
      await widget.onSavePlan!(draft);
      if (!mounted) return;
      _message('Teaching plan updated.');
    } else {
      bloc.add(TeachingPlanUpdate(draft));
    }
  }

  bool _isFutureDate(DateTime? date) {
    if (date == null) return false;
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    final dateMidnight = DateTime(date.year, date.month, date.day);
    return dateMidnight.isAfter(todayMidnight);
  }

  Future<void> _openDeleteDialog(TeachingPlanItem plan) async {
    final isFuture = _isFutureDate(plan.plannedDate);
    if (!isFuture) {
      _message('Past or current sessions cannot be deleted!');
      return;
    }

    final confirmed = await AppConfirmDialog.show(
      context,
      icon: Icons.delete_outline_rounded,
      title: 'Delete teaching plan?',
      subtitle: '${plan.unit} • ${plan.topic}',
      message:
          'This teaching plan will be permanently deleted and cannot be recovered.',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (confirmed && mounted) {
      context.read<TeachingPlanBloc>().add(TeachingPlanDelete(plan.id));
    }
  }

  void _message(String value) => ScaffoldMessenger.of(context)
      .showSnackBar(
        SnackBar(
          content: Text(
            value,
            style: const TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.white,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        title: const Text(
          'Teaching Plan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        elevation: 0,
        surfaceTintColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          labelColor: _primary,
          unselectedLabelColor: _muted,
          indicatorColor: _primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.menu_book_outlined, size: 18),
              text: 'Teaching Plan',
            ),
            Tab(
              icon: Icon(Icons.upload_file_outlined, size: 18),
              text: 'Bulk Upload',
            ),
          ],
        ),
      ),
      body: BlocListener<TeachingPlanBloc, TeachingPlanState>(
        listener: (context, state) {
          if (state is TeachingPlanLoaded &&
              state.mutationMessage != null &&
              state.mutationMessage!.isNotEmpty) {
            _message(state.mutationMessage!);
          }
        },
        child: TabBarView(
          controller: _tabs,
          children: [
            _teachingPlanTab(),
            _bulkUploadTab(),
          ],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabs,
        builder: (context, _) => _tabs.index == 0
            ? FloatingActionButton.extended(
                onPressed: _openCreateForm,
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create'),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _teachingPlanTab() {
    return BlocBuilder<TeachingPlanBloc, TeachingPlanState>(
      builder: (context, state) {
        if (state is TeachingPlanFailure) {
          return _errorView(
            message: state.message,
            onRetry: () => context
                .read<TeachingPlanBloc>()
                .add(LoadTeachingPlan(widget.subject)),
          );
        }
        if (state is! TeachingPlanLoaded) {
          return const Center(
            child: CircularProgressIndicator(color: _primary),
          );
        }

        final plans = state.plans
            .map(TeachingPlanItem.fromPlan)
            .toList();
        final query = _searchController.text.trim().toLowerCase();
        final visiblePlans = plans.where((plan) {
          return plan.unit.toLowerCase().contains(query) ||
              plan.topic.toLowerCase().contains(query);
        }).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
          children: [
            _subjectBanner(),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: _sectionTitle(
                  'Teaching plan records',
                  '${visiblePlans.length} plans',
                  Icons.event_note_outlined,
                ),
              ),
            ]),
            const SizedBox(height: 10),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: _inputDecoration(
                'Search by unit or topic',
                Icons.search_rounded,
              ),
            ),
            const SizedBox(height: 12),
            if (visiblePlans.isEmpty)
              _emptyState()
            else
              ...visiblePlans.map(
                (plan) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _planCard(plan),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _subjectBanner() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _primary.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.school_outlined, color: _primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.subject.subjectName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Course: ${widget.subject.courseName}',
                  style: const TextStyle(color: _muted, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ]),
      );

  Widget _sectionTitle(String title, String subtitle, IconData icon) =>
      Row(children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFEDE9FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _primary, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
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
              Text(
                subtitle,
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ]);

  Widget _planCard(TeachingPlanItem plan) => Container(
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(
                plan.topic,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            _statusPill(
              plan.deliveredDate == null ? 'Not delivered' : 'Delivered',
            ),
          ]),
          const SizedBox(height: 7),
          Text(
            plan.unit,
            style: const TextStyle(
              color: _muted,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 14,
                  runSpacing: 8,
                  children: [
                    _meta(Icons.calendar_today_outlined, _date(plan.plannedDate)),
                    _meta(Icons.cast_for_education_outlined, plan.teachingMode),
                    if (plan.deliveredDate != null)
                      _meta(
                        Icons.check_circle_outline,
                        'Delivered ${_date(plan.deliveredDate!)}',
                      ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => _openEditForm(plan),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: _primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _openDeleteDialog(plan),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: Color(0xFFD64D5C),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (plan.objective?.isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Text(
              plan.objective!,
              style: const TextStyle(
                color: _muted,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ],
        ]),
      );

  Future<void> _downloadTemplate(TeachingPlanLoaded state) async {
    setState(() => _bulkBusy = true);
    try {
      await TeachingPlanExcelService.downloadAndOpenTemplate(
        units: state.units,
        plans: state.plans,
        allotmentId: widget.subject.allotmentId,
        subjectId: widget.subject.subjectId,
      );
      _message('Template downloaded.');
    } catch (error) {
      _message(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _bulkBusy = false);
    }
  }

  Future<void> _pickBulkFile() async {
    setState(() => _bulkBusy = true);
    try {
      final file = await TeachingPlanExcelService.pickExcelFile();
      if (file == null) return;
      final error = await TeachingPlanExcelService.validateHeaders(file);
      if (error != null) {
        _message(error);
        return;
      }
      setState(() => _selectedBulkFile = file);
    } catch (error) {
      _message('Failed to read Excel file.');
    } finally {
      if (mounted) setState(() => _bulkBusy = false);
    }
  }

  Future<void> _uploadBulkFile() async {
    final file = _selectedBulkFile;
    if (file == null) {
      _message('Please select a file first!');
      return;
    }
    setState(() => _bulkBusy = true);
    try {
      final normalized = await TeachingPlanExcelService.normalizeAndSave(file);
      if (!mounted) return;
      context.read<TeachingPlanBloc>().add(TeachingPlanBulkUpload(normalized));
      setState(() => _selectedBulkFile = null);
    } catch (error) {
      _message('Failed to process Excel file.');
    } finally {
      if (mounted) setState(() => _bulkBusy = false);
    }
  }

  Widget _bulkUploadTab() => BlocBuilder<TeachingPlanBloc, TeachingPlanState>(
        builder: (context, state) {
          final loaded = state is TeachingPlanLoaded ? state : null;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _subjectBanner(),
              const SizedBox(height: 18),
              _sectionTitle(
                'Bulk upload teaching plan',
                'Upload multiple teaching plan records together',
                Icons.cloud_upload_outlined,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: _cardDecoration(),
                child: Column(children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEDE9FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.upload_file_rounded,
                      color: _primary,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Upload your teaching plan file',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Download the template, fill it in Excel, then upload the completed file.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _muted, fontSize: 12.5, height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: loaded == null || _bulkBusy
                          ? null
                          : () => _downloadTemplate(loaded),
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Download Excel Template'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primary,
                        side: const BorderSide(color: _primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: _bulkBusy ? null : _pickBulkFile,
                      icon: const Icon(Icons.attach_file_rounded),
                      label: Text(
                        _selectedBulkFile == null
                            ? 'Choose completed file'
                            : _selectedBulkFile!.path.split('/').last,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primary,
                        side: const BorderSide(color: _primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: FilledButton.icon(
                      onPressed: _selectedBulkFile == null || _bulkBusy
                          ? null
                          : _uploadBulkFile,
                      icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                      label: const Text('Upload'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ],
          );
        },
      );

  Widget _emptyState() => Container(
        padding: const EdgeInsets.all(24),
        decoration: _cardDecoration(),
        child: const Column(children: [
          Icon(
            Icons.event_note_outlined,
            color: Color(0xFF9B8BEA),
            size: 34,
          ),
          SizedBox(height: 9),
          Text(
            'No teaching plans found',
            style: TextStyle(
              color: _ink,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Tap Create to add your first teaching plan.',
            style: TextStyle(color: _muted, fontSize: 12.5),
          ),
        ]),
      );

  InputDecoration _inputDecoration(String hint, IconData? icon) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFA0A8B6), fontSize: 12.5),
        prefixIcon:
            icon == null ? null : Icon(icon, size: 18, color: _muted),
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

  Widget _statusPill(String status) {
    final delivered = status == 'Delivered';
    final color = delivered ? const Color(0xFF159A68) : const Color(0xFFB7791F);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String value) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _muted),
          const SizedBox(width: 5),
          Text(
            value,
            style: const TextStyle(
              color: _muted,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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

  String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')} ${_month(date.month)} ${date.year}';

  String _month(int month) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][month - 1];

  Widget _errorView({required String message, required VoidCallback onRetry}) =>
      Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 44,
                color: Color(0xFFD64D5C),
              ),
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
