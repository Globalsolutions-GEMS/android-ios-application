import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_filex/open_filex.dart';

import 'package:erp_app/Features/Faculty/E-learning Workarea/model/workarea_subject_model.dart';
import '../Bloc/announcement_list_bloc.dart';
import '../Bloc/announcement_list_event.dart';
import '../Bloc/announcement_list_state.dart';
import '../model/announcement_model.dart';
import '../services/announcement_service.dart';
import 'announcement_form_screen.dart';

const Color _primary = Color(0xFF7B61FF);
const Color _page = Color(0xFFF6F7FB);
const Color _ink = Color(0xFF0F172A);
const Color _muted = Color(0xFF64748B);
const Color _border = Color(0xFFE8ECF2);
const Color _green = Color(0xFF16A34A);
const Color _red = Color(0xFFDC2626);
const Color _amber = Color(0xFFD97706);

const int _pageSize = 5;

/// Faculty announcement list for one selected subject.
class AnnouncementListScreen extends StatefulWidget {
  const AnnouncementListScreen({super.key, required this.subject});

  final WorkAreaSubject subject;

  @override
  State<AnnouncementListScreen> createState() => _AnnouncementListScreenState();
}

class _AnnouncementListScreenState extends State<AnnouncementListScreen> {
  final _search = TextEditingController();
  final AnnouncementService _service = AnnouncementService();
  final AnnouncementListBloc _bloc = AnnouncementListBloc();
  String _query = '';
  int _pageNo = 1;

  @override
  void initState() {
    super.initState();
    _bloc.add(LoadAnnouncements(widget.subject));
  }

  @override
  void dispose() {
    _search.dispose();
    _bloc.close();
    super.dispose();
  }

  void _reload() => _bloc.add(LoadAnnouncements(widget.subject));

  // ---------- filter + pagination ----------

  List<AnnouncementItem> _filtered(List<AnnouncementItem> items) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((a) {
      return a.title.toLowerCase().contains(q) ||
          formatAnnouncementDate(a.scheduleAt).contains(q) ||
          formatAnnouncementDate(a.validUntil).contains(q) ||
          (a.attachmentName ?? '').toLowerCase().contains(q);
    }).toList();
  }

  int _totalPages(int count) {
    final n = (count / _pageSize).ceil();
    return n == 0 ? 1 : n;
  }

  List<AnnouncementItem> _pageItems(List<AnnouncementItem> filtered) {
    final start = (_pageNo - 1) * _pageSize;
    if (start >= filtered.length) return const [];
    final end = (start + _pageSize).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  // ---------- actions ----------

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: error ? _red : _green,
      ));
  }

  Future<void> _openForm([AnnouncementItem? item]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AnnouncementFormScreen(
          subject: widget.subject,
          announcement: item,
        ),
      ),
    );
    if (saved != true || !mounted) return;
    _reload();
    _snack(item == null
        ? 'Announcement submitted successfully!'
        : 'Announcement updated successfully!');
  }

  void _onEdit(AnnouncementItem a) {
    if (a.isExpired) {
      _snack('Validity date expired – you cannot edit', error: true);
      return;
    }
    _openForm(a);
  }

  Future<void> _onDownload(AnnouncementItem a) async {
    try {
      final file = await _service.downloadAttachment(a.attachmentName!);
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done && mounted) {
        _snack(result.message.isNotEmpty
            ? result.message
            : 'No app found to open this file.');
      }
    } catch (e) {
      if (mounted) {
        _snack('Download failed: ${e.toString().replaceFirst('Exception: ', '')}',
            error: true);
      }
    }
  }

  // ---------- UI ----------

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
          'Announcements',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _reload,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create'),
      ),
      body: SafeArea(
        child: BlocBuilder<AnnouncementListBloc, AnnouncementListState>(
          bloc: _bloc,
          builder: (context, state) {
            if (state is AnnouncementListLoading ||
                state is AnnouncementListInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is AnnouncementListFailed) {
              return _ErrorView(
                message: state.message.replaceFirst('Exception: ', ''),
                onRetry: _reload,
              );
            }

            final source =
                state is AnnouncementListLoaded ? state.items : const <AnnouncementItem>[];
            final filtered = _filtered(source);
            final items = _pageItems(filtered);
            final totalPages = _totalPages(filtered.length);

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                _SubjectBanner(subject: widget.subject),
                const SizedBox(height: 14),
                _searchField(),
                const SizedBox(height: 14),
                if (items.isEmpty)
                  _EmptyView(searching: _query.trim().isNotEmpty)
                else
                  for (final a in items) ...[
                    _AnnouncementCard(
                      item: a,
                      onEdit: () => _onEdit(a),
                      onDownload: () => _onDownload(a),
                    ),
                    const SizedBox(height: 12),
                  ],
                if (filtered.length > _pageSize) _pager(totalPages),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _searchField() {
    OutlineInputBorder outline(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c),
        );
    return TextField(
      controller: _search,
      onChanged: (v) => setState(() {
        _query = v;
        _pageNo = 1;
      }),
      decoration: InputDecoration(
        hintText: 'Search title, date or file',
        prefixIcon: const Icon(Icons.search_rounded, color: _muted),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () => setState(() {
                  _search.clear();
                  _query = '';
                  _pageNo = 1;
                }),
              ),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: outline(_border),
        enabledBorder: outline(_border),
        focusedBorder: outline(_primary),
      ),
    );
  }

  Widget _pager(int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _pageNo > 1 ? () => setState(() => _pageNo--) : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Text(
            'Page $_pageNo of $totalPages',
            style: const TextStyle(
              color: _ink,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          IconButton(
            onPressed: _pageNo < totalPages
                ? () => setState(() => _pageNo++)
                : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
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
            child: const Icon(Icons.campaign_outlined, color: _primary),
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

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({
    required this.item,
    required this.onEdit,
    required this.onDownload,
  });

  final AnnouncementItem item;
  final VoidCallback onEdit;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final a = item;
    final expired = a.isExpired;

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  a.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (expired)
                const _Tag('Expired', _red)
              else if (a.isScheduled)
                const _Tag('Scheduled', _amber)
              else
                const _Tag('Live', _green),
            ],
          ),
          const SizedBox(height: 12),
          _Info(
            Icons.event_available_outlined,
            a.scheduleAt == null
                ? 'Published immediately'
                : 'Schedule ${formatAnnouncementDateTime(a.scheduleAt!)}',
          ),
          const SizedBox(height: 6),
          _Info(
            Icons.event_busy_outlined,
            'Valid till ${formatAnnouncementDateTime(a.validUntil)}',
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _attachmentRow(expired)),
              const SizedBox(width: 8),
              expired
                  ? FilledButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.warning_amber_rounded, size: 16),
                      label: const Text('Expired'),
                      style: FilledButton.styleFrom(
                        disabledBackgroundColor:
                            _red.withValues(alpha: 0.12),
                        disabledForegroundColor: _red,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    )
                  : OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _ink,
                        side: const BorderSide(color: _border),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _attachmentRow(bool expired) {
    if (!item.hasAttachment) {
      return const _Info(Icons.attach_file_rounded, 'No attachment');
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 2, 2, 2),
      decoration: BoxDecoration(
        color: _page,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            Icons.insert_drive_file_outlined,
            size: 16,
            color: expired ? _muted : _primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.attachmentName!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: expired ? _muted : _ink,
                fontSize: 12.5,
              ),
            ),
          ),
          IconButton(
            tooltip: expired ? 'Expired' : 'Download',
            // expired = download disabled (same as web)
            onPressed: expired ? null : onDownload,
            icon: const Icon(Icons.download_rounded, size: 20),
            color: _primary,
          ),
        ],
      ),
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
  const _EmptyView({required this.searching});

  final bool searching;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            searching ? Icons.search_off_rounded : Icons.campaign_outlined,
            size: 48,
            color: _muted,
          ),
          const SizedBox(height: 10),
          Text(
            searching ? 'No announcements found' : 'No announcements yet',
            style: const TextStyle(
              color: _ink,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            searching
                ? 'Try a different search.'
                : 'Tap Create to add your first announcement.',
            style: const TextStyle(color: _muted, fontSize: 12.5),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 42, color: _muted),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, fontSize: 13),
            ),
            const SizedBox(height: 12),
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
