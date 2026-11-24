import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../Bloc/assignment_detail_bloc.dart';
import '../Bloc/assignment_detail_event.dart';
import '../Bloc/assignment_detail_state.dart';
import '../model/assignment_model.dart';

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

/// Assignment details. Offline assignments also show requests + Approve.
class AssignmentDetailScreen extends StatelessWidget {
  const AssignmentDetailScreen({super.key, required this.assignment});

  final FacultyAssignment assignment;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final bloc = AssignmentDetailBloc();
        // Submissions are only needed for offline approval.
        if (assignment.isOffline) {
          bloc.add(LoadSubmissions(
            assignmentId: assignment.assignmentId,
            allotmentId: assignment.allotmentId,
          ));
        }
        return bloc;
      },
      child: _DetailView(assignment: assignment),
    );
  }
}

class _DetailView extends StatefulWidget {
  const _DetailView({required this.assignment});

  final FacultyAssignment assignment;

  @override
  State<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<_DetailView> {
  final _search = TextEditingController();
  final Set<int> _selected = {};

  FacultyAssignment get _a => widget.assignment;

  @override
  void dispose() {
    _search.dispose();
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

  void _load(BuildContext context) {
    context.read<AssignmentDetailBloc>().add(LoadSubmissions(
          assignmentId: _a.assignmentId,
          allotmentId: _a.allotmentId,
        ));
  }

  Future<void> _refresh(BuildContext context) async {
    if (!_a.isOffline) return;
    final bloc = context.read<AssignmentDetailBloc>();
    _load(context);
    await bloc.stream.firstWhere((s) => s is! AssignmentDetailLoading);
  }

  void _toggle(int studentId) {
    setState(() {
      if (!_selected.remove(studentId)) _selected.add(studentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AssignmentDetailBloc, AssignmentDetailState>(
      listenWhen: (_, s) => s is AssignmentDetailLoaded && s.notice != null,
      listener: (context, state) {
        final s = state as AssignmentDetailLoaded;
        _snack(s.notice!, error: s.noticeIsError);
        if (!s.noticeIsError) setState(_selected.clear);
      },
      builder: (context, state) {
        final loaded = state is AssignmentDetailLoaded ? state : null;
        final submissions = loaded?.submissions ?? const <AssignmentSubmission>[];
        final byStudent = {for (final s in submissions) s.studentId: s};

        final all = [..._a.students]
          ..sort((x, y) => _compareRoll(x.rollNumber, y.rollNumber));
        final query = _search.text.trim().toLowerCase();
        final visible = query.isEmpty
            ? all
            : all
                .where((s) =>
                    s.fullName.toLowerCase().contains(query) ||
                    s.rollNumber.toLowerCase().contains(query))
                .toList();

        return Scaffold(
          backgroundColor: _page,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            foregroundColor: _ink,
            title: const Text(
              'Assignment Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          body: SafeArea(
            child: (_a.isOffline && state is AssignmentDetailFailed)
                ? _DetailError(
                    message: state.message,
                    onRetry: () => _load(context),
                  )
                : RefreshIndicator(
                    color: _primary,
                    onRefresh: () => _refresh(context),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      children: [
                        _headerCard(),
                        if (_a.isOffline) ...[
                          const SizedBox(height: 14),
                          _statsRow(loaded, all, byStudent),
                        ],
                        const SizedBox(height: 14),
                        _studentsCard(visible, byStudent, loaded),
                      ],
                    ),
                  ),
          ),
          bottomNavigationBar: _a.isOffline
              ? SafeArea(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: _border)),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: (loaded == null || loaded.isApproving)
                            ? null
                            : () => context.read<AssignmentDetailBloc>().add(
                                  ApproveStudents(
                                    assignmentId: _a.assignmentId,
                                    allotmentId: _a.allotmentId,
                                    studentIds: _selected.toList(),
                                  ),
                                ),
                        style: FilledButton.styleFrom(
                          backgroundColor: _primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          (loaded?.isApproving ?? false)
                              ? 'Approving...'
                              : 'Approve (${_selected.length})',
                        ),
                      ),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  // ---------- sections ----------

  Widget _headerCard() {
    final marks =
        _a.marks % 1 == 0 ? _a.marks.toInt().toString() : '${_a.marks}';
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _a.title,
            style: const TextStyle(
              color: _ink,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (_a.description.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _a.description,
              style: const TextStyle(color: _muted, fontSize: 13),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _a.isExpired
                  ? const _Tag('Expired', _red)
                  : const _Tag('Active', _green),
              _a.isPublished
                  ? const _Tag('Published', _primary)
                  : const _Tag('Draft', _amber),
              _a.isOffline
                  ? const _Tag('Offline', _teal)
                  : const _Tag('Online', _blue),
            ],
          ),
          const SizedBox(height: 14),
          _InfoRow(Icons.grade_outlined, 'Marks', marks),
          _InfoRow(
            Icons.event_outlined,
            'Due date',
            _a.dueDate == null ? '-' : _formatDateTime(_a.dueDate!),
          ),
          _InfoRow(
            Icons.group_outlined,
            'Students',
            '${_a.students.length}',
          ),
          if (_a.attachmentName != null)
            _InfoRow(Icons.attach_file_rounded, 'Attachment', _a.attachmentName!),
        ],
      ),
    );
  }

  Widget _statsRow(
    AssignmentDetailLoaded? loaded,
    List<AssignmentStudent> all,
    Map<int, AssignmentSubmission> byStudent,
  ) {
    String value(int Function() count) => loaded == null ? '-' : '${count()}';

    final requested = value(
      () => loaded!.submissions.where((s) => !s.approved).length,
    );
    final approved = value(
      () => loaded!.submissions.where((s) => s.approved).length,
    );
    final pending = value(
      () => all.where((s) => !byStudent.containsKey(s.id)).length,
    );

    return Row(
      children: [
        Expanded(child: _Stat('Requested', requested, _amber)),
        const SizedBox(width: 10),
        Expanded(child: _Stat('Pending', pending, _muted)),
        const SizedBox(width: 10),
        Expanded(child: _Stat('Approved', approved, _green)),
      ],
    );
  }

  Widget _studentsCard(
    List<AssignmentStudent> visible,
    Map<int, AssignmentSubmission> byStudent,
    AssignmentDetailLoaded? loaded,
  ) {
    final offline = _a.isOffline;

    // Students whose request is waiting for approval.
    final selectable = visible.where((s) {
      final sub = byStudent[s.id];
      return sub != null && !sub.approved;
    }).toList();
    final allSelected =
        selectable.isNotEmpty && selectable.every((s) => _selected.contains(s.id));

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Students',
            style: TextStyle(
              color: _ink,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search by name or roll no',
              prefixIcon: const Icon(Icons.search_rounded, color: _muted),
              isDense: true,
              filled: true,
              fillColor: _page,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (offline && loaded == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(color: _primary)),
            )
          else ...[
            if (offline && selectable.isNotEmpty) ...[
              const SizedBox(height: 6),
              CheckboxListTile(
                value: allSelected,
                onChanged: (_) => setState(() {
                  if (allSelected) {
                    _selected.removeAll(selectable.map((s) => s.id));
                  } else {
                    _selected.addAll(selectable.map((s) => s.id));
                  }
                }),
                title: const Text(
                  'Select all pending requests',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: _primary,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ],
            const SizedBox(height: 6),
            const Divider(height: 1, color: _border),
            if (visible.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  _a.students.isEmpty
                      ? 'No students allotted.'
                      : 'No matching students.',
                  style: const TextStyle(color: _muted, fontSize: 13),
                ),
              )
            else
              for (final s in visible) ...[
                _studentRow(s, byStudent[s.id]),
                const Divider(height: 1, color: _border),
              ],
          ],
        ],
      ),
    );
  }

  Widget _studentRow(AssignmentStudent s, AssignmentSubmission? sub) {
    final offline = _a.isOffline;
    final hasRequest = sub != null;
    final approved = sub?.approved ?? false;

    Widget status;
    if (!hasRequest) {
      status = const _Tag('No Request', _muted);
    } else if (approved) {
      status = const _Tag('Approved', _green);
    } else {
      status = const _Tag('Not Approved', _red);
    }

    return InkWell(
      onTap: !offline
          ? null
          : () {
              if (!hasRequest) {
                _snack(
                  'Student has not submitted the request for assignment.',
                  error: true,
                );
              } else if (!approved) {
                _toggle(s.id);
              }
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            if (offline)
              Checkbox(
                value: approved || _selected.contains(s.id),
                onChanged: (!hasRequest || approved) ? null : (_) => _toggle(s.id),
                activeColor: _primary,
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.fullName.isEmpty ? 'Unnamed Student' : s.fullName,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Roll No: ${s.rollNumber.isEmpty ? 'N/A' : s.rollNumber}',
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (offline) status,
          ],
        ),
      ),
    );
  }
}

// ---------- small widgets ----------

class _Card extends StatelessWidget {
  const _Card({required this.child});

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
      child: child,
    );
  }
}

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

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 17, color: _muted),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: _muted, fontSize: 13)),
          Expanded(
            child: Text(
              value,
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
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.message, required this.onRetry});

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

/// Roll numbers: empty last, numbers compared as numbers.
int _compareRoll(String a, String b) {
  if (a.isEmpty && b.isNotEmpty) return 1;
  if (a.isNotEmpty && b.isEmpty) return -1;
  final na = int.tryParse(a);
  final nb = int.tryParse(b);
  if (na != null && nb != null) return na.compareTo(nb);
  return a.toLowerCase().compareTo(b.toLowerCase());
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