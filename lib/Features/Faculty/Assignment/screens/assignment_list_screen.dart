import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'assignment_detail_screen.dart';
import 'package:erp_app/Features/Faculty/E-learning Workarea/model/workarea_subject_model.dart';
import 'assignment_form_screen.dart';
import '../Bloc/assignment_list_bloc.dart';
import '../Bloc/assignment_list_event.dart';
import '../Bloc/assignment_list_state.dart';
import '../model/assignment_model.dart';
import 'assignment_form_screen.dart';
import 'assignment_detail_screen.dart';
import 'package:erp_app/Core/widgets/app_confirm_dialog.dart';

const Color _primary = Color(0xFF7B61FF);
const Color _page = Color(0xFFF6F7FB);
const Color _ink = Color(0xFF0F172A);
const Color _muted = Color(0xFF64748B);
const Color _border = Color(0xFFE8ECF2);
const Color _green = Color(0xFF16A34A);
const Color _red = Color(0xFFDC2626);
const Color _amber = Color(0xFFD97706);
const Color _blue = Color(0xFF2878C7);
const Color _teal = Color(0xFF0D9488);

/// Faculty assignment list for one selected subject.
class AssignmentListScreen extends StatelessWidget {
  const AssignmentListScreen({super.key, required this.subject});

  final WorkAreaSubject subject;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AssignmentListBloc()
        ..add(LoadAssignments(
          subjectId: subject.subjectId,
          allotmentId: subject.allotmentId,
        )),
      child: _AssignmentListView(subject: subject),
    );
  }
}

class _AssignmentListView extends StatelessWidget {
  const _AssignmentListView({required this.subject});

  final WorkAreaSubject subject;

  void _reload(BuildContext context) {
    context.read<AssignmentListBloc>().add(LoadAssignments(
          subjectId: subject.subjectId,
          allotmentId: subject.allotmentId,
        ));
  }

  void _snack(BuildContext context, String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: error ? _red : _green,
      ));
  }

  Future<void> _onPublish(BuildContext context, FacultyAssignment a) async {
    if (a.isExpired) {
      _snack(context, 'Expired assignments cannot be published.', error: true);
      return;
    }
    if (a.isPublished) {
      _snack(context, 'Assignment is already published.', error: true);
      return;
    }
          final ok = await AppConfirmDialog.show(
      context,
      icon: Icons.send_rounded,
      title: 'Publish assignment?',
      subtitle: a.title,
      message:
          'Once published, it cannot be edited or unpublished. Students will be notified.',
      confirmText: 'Publish',
    );
    if (ok == true && context.mounted) {
      context.read<AssignmentListBloc>().add(PublishAssignmentRequested(a));
    }
  }

   void _onEdit(BuildContext context, FacultyAssignment a) {
    if (a.isExpired) {
      _snack(context, 'Expired assignments cannot be updated.', error: true);
      return;
    }
    if (a.isPublished) {
      _snack(context, 'Published assignments cannot be updated.', error: true);
      return;
    }
    _openForm(context, a);
  }

  void _onView(BuildContext context, FacultyAssignment a) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AssignmentDetailScreen(assignment: a),
      ),
    );
  }

  void _onCreate(BuildContext context) {
    _openForm(context, null);
  }

  Future<void> _openForm(BuildContext context, FacultyAssignment? a) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AssignmentFormScreen(subject: subject, assignment: a),
      ),
    );
    if (saved == true && context.mounted) _reload(context);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _page,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: _ink,
        title: const Text(
          'Assignments',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          Builder(
            builder: (ctx) => IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => _reload(ctx),
            ),
          ),
        ],
      ),
      floatingActionButton: Builder(
        builder: (ctx) => FloatingActionButton.extended(
          onPressed: () => _onCreate(ctx),
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Create'),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<AssignmentListBloc, AssignmentListState>(
          listenWhen: (_, s) => s is AssignmentListLoaded && s.notice != null,
          listener: (context, state) {
            final s = state as AssignmentListLoaded;
            _snack(context, s.notice!, error: s.noticeIsError);
          },
          builder: (context, state) {
            if (state is AssignmentListFailed) {
              return _ErrorView(
                message: state.message,
                onRetry: () => _reload(context),
              );
            }
            if (state is! AssignmentListLoaded) {
              return const Center(
                child: CircularProgressIndicator(color: _primary),
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                _SubjectBanner(subject: subject),
                const SizedBox(height: 14),
                if (state.assignments.isEmpty)
                  const _EmptyView()
                else
                  for (final a in state.assignments) ...[
                    _AssignmentCard(
                      assignment: a,
                      publishing: state.publishingId == a.assignmentId,
                      onView: () => _onView(context, a),
                      onEdit: () => _onEdit(context, a),
                      onPublish: () => _onPublish(context, a),
                    ),
                    const SizedBox(height: 12),
                  ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SubjectBanner extends StatelessWidget {
  const _SubjectBanner({required this.subject});

  final WorkAreaSubject subject;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _primary.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.assignment_outlined, color: _primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject.subjectName,
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
                  subject.courseName,
                  style: const TextStyle(color: _muted, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({
    required this.assignment,
    required this.publishing,
    required this.onView,
    required this.onEdit,
    required this.onPublish,
  });

  final FacultyAssignment assignment;
  final bool publishing;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    final a = assignment;
    final marks = a.marks % 1 == 0 ? a.marks.toInt().toString() : '${a.marks}';

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
          Text(
            a.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ink,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (a.description.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              a.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _muted, fontSize: 12.5),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              a.isExpired
                  ? const _Tag('Expired', _red)
                  : const _Tag('Active', _green),
              a.isPublished
                  ? const _Tag('Published', _primary)
                  : const _Tag('Draft', _amber),
              a.isOffline
                  ? const _Tag('Offline', _teal)
                  : const _Tag('Online', _blue),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Info(Icons.grade_outlined, '$marks marks'),
              ),
              Expanded(
                child: _Info(
                  Icons.group_outlined,
                  '${a.studentIds.length} students',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _Info(
            Icons.event_outlined,
            a.dueDate == null ? 'No due date' : 'Due ${_formatDue(a.dueDate!)}',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onView,
                  icon: const Icon(Icons.visibility_outlined, size: 17),
                  label: const Text('View'),
                  style: _outlineStyle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  label: const Text('Edit'),
                  style: _outlineStyle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: _publishButton()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _publishButton() {
    if (assignment.isPublished) {
      return FilledButton.icon(
        onPressed: null,
        icon: const Icon(Icons.check_circle_outline, size: 17),
        label: const Text('Published'),
        style: _filledStyle,
      );
    }
    return FilledButton.icon(
      onPressed: publishing ? null : onPublish,
      icon: publishing
          ? const SizedBox(
              height: 14,
              width: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.send_rounded, size: 16),
      label: const Text('Publish'),
      style: _filledStyle,
    );
  }
}

final ButtonStyle _outlineStyle = OutlinedButton.styleFrom(
  foregroundColor: _ink,
  side: const BorderSide(color: _border),
  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
  textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
);

final ButtonStyle _filledStyle = FilledButton.styleFrom(
  backgroundColor: _primary,
  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
  textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
);

class _Tag extends StatelessWidget {
  const _Tag(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _muted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _muted, fontSize: 12.5),
          ),
        ),
      ],
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.assignment_outlined, size: 48, color: _muted),
          SizedBox(height: 10),
          Text(
            'No assignments yet',
            style: TextStyle(
              color: _ink,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Tap Create to add your first assignment.',
            style: TextStyle(color: _muted, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

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

String _formatDue(DateTime d) {
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