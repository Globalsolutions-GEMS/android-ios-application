import 'dart:async';
import 'dart:convert';
import 'package:erp_app/Core/theme/app_theme.dart';
import 'package:erp_app/Features/Faculty/Attendance/Bloc/qr_attendance_bloc.dart';
import 'package:erp_app/Features/Faculty/Attendance/Bloc/qr_attendance_event.dart';
import 'package:erp_app/Features/Faculty/Attendance/Bloc/qr_attendance_state.dart';
import 'package:erp_app/Features/Faculty/Attendance/model/qr_attendance_model.dart';
import 'package:erp_app/Services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Shows the QR to the class and the live Present / Absent lists.
class QrDisplayScreen extends StatelessWidget {
  const QrDisplayScreen({
    super.key,
    required this.sessionId,
    required this.date,
    required this.lectureType,
    required this.defaultStatusId,
    required this.topicId,
    required this.divisions,
  });

  final int sessionId;
  final String date; // yyyy-MM-dd
  final String lectureType;
  final int defaultStatusId;
  final int topicId;
  final List<Map<String, int>> divisions;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => QrAttendanceBloc(),
      child: _QrDisplayView(args: this),
    );
  }
}

class _QrDisplayView extends StatefulWidget {
  const _QrDisplayView({required this.args});

  final QrDisplayScreen args;

  @override
  State<_QrDisplayView> createState() => _QrDisplayViewState();
}

class _QrDisplayViewState extends State<_QrDisplayView> {
  static const Color _primary = Color(0xFF6D4AFF);
  static const Color _dark = Color(0xFF172033);
  static const Color _grey = Color(0xFF64748B);
  static const Color _green = Color(0xFF16A34A);
  static const Color _red = Color(0xFFDC2626);

  Timer? _pollTimer;
  Timer? _tickTimer;
  bool _locating = true;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable(); // keep the screen on while the QR is shown

    // Countdown text every second, live data every 5 seconds
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        context.read<QrAttendanceBloc>().add(const QrRefreshRequested());
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _tickTimer?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  // Gets the teacher location, then asks the server to start the QR
  Future<void> _start() async {
    setState(() {
      _locating = true;
      _locationError = null;
    });

    try {
      final position = await LocationService.currentPosition();
      if (!mounted) return;
      setState(() => _locating = false);

      final a = widget.args;
      context.read<QrAttendanceBloc>().add(
        QrStartRequested(
          sessionId: a.sessionId,
          date: a.date,
          lectureType: a.lectureType,
          defaultStatusId: a.defaultStatusId,
          topicId: a.topicId,
          latitude: position.latitude,
          longitude: position.longitude,
          divisions: a.divisions,
        ),
      );
    } on LocationException catch (e) {
      if (!mounted) return;
      setState(() {
        _locating = false;
        _locationError = e.message;
      });
    }
  }

  Future<void> _confirmStop() async {
    final stop = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Stop QR?'),
        content: const Text(
          'Students who have not scanned will be marked Absent.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Stop QR'),
          ),
        ],
      ),
    );
    if (stop == true && mounted) {
      context.read<QrAttendanceBloc>().add(const QrCloseRequested());
    }
  }

  Future<void> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave this screen?'),
        content: const Text(
          'The QR keeps running until it expires. You can open it again from '
          'Generate QR for the same class.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<QrAttendanceBloc, QrAttendanceState>(
      listenWhen: (prev, curr) =>
          curr is QrAttendanceLoaded && curr.message != null,
      listener: (context, state) {
        final message = (state as QrAttendanceLoaded).message;
        if (message != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(AppTheme.showThemedSnackBar(context, message));
        }
      },
      builder: (context, state) {
        final active = state is QrAttendanceLoaded && state.session.isActive;

        return PopScope(
          canPop: !active,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) _confirmLeave();
          },
          child: Scaffold(
            backgroundColor: const Color(0xFFEEF0F6),
            appBar: AppBar(
              title: const Text('Attendance QR'),
              backgroundColor: _primary,
              foregroundColor: Colors.white,
            ),
            body: _body(state),
            bottomNavigationBar: state is QrAttendanceLoaded
                ? _bottomBar(state)
                : null,
          ),
        );
      },
    );
  }

  Widget _body(QrAttendanceState state) {
    if (_locating) return _progress('Getting your location...');
    if (_locationError != null) return _messageView(_locationError!);

    return switch (state) {
      QrAttendanceInitial() ||
      QrAttendanceLoading() => _progress('Generating QR...'),
      QrAttendanceFailure(:final message) => _messageView(message),
      QrAttendanceLoaded() => _loadedView(state),
    };
  }

  Widget _progress(String text) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: _primary),
          const SizedBox(height: 16),
          Text(text, style: const TextStyle(color: _grey)),
        ],
      ),
    );
  }

  Widget _messageView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: _red, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _dark, fontSize: 15),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _start,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadedView(QrAttendanceLoaded s) {
    return RefreshIndicator(
      onRefresh: () async {
        final bloc = context.read<QrAttendanceBloc>();
        bloc.add(const QrRefreshRequested());
        bloc.add(QrStudentsRequested(filter: s.filter, silent: true));
        await Future<void>.delayed(const Duration(milliseconds: 600));
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _qrCard(s),
          const SizedBox(height: 14),
          _counts(s),
          const SizedBox(height: 14),
          _filters(s),
          const SizedBox(height: 10),
          ..._students(s),
        ],
      ),
    );
  }

  Widget _qrCard(QrAttendanceLoaded s) {
    final showQr = s.session.isActive && s.token != null;
    final payload = jsonEncode({
      'qrSessionId': s.session.qrSessionId,
      'token': s.token,
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Text(
            showQr ? 'Scan this QR to mark attendance' : 'QR stopped',
            style: const TextStyle(
              color: _dark,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          if (showQr)
            QrImageView(
              data: payload,
              size: 240,
              backgroundColor: Colors.white,
            )
          else
            const SizedBox(
              height: 240,
              child: Icon(Icons.qr_code_2, size: 120, color: Color(0xFFCBD5E1)),
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer_outlined, size: 18, color: _grey),
              const SizedBox(width: 6),
              Text(
                s.session.isActive
                    ? 'Expires in ${_remaining(s.session.expiresAt)}'
                    : 'Session closed',
                style: const TextStyle(color: _grey, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _counts(QrAttendanceLoaded s) {
    return Row(
      children: [
        _countTile('Present', s.session.presentCount, _green),
        const SizedBox(width: 10),
        _countTile('Absent', s.session.absentCount, _red),
        const SizedBox(width: 10),
        _countTile('Total', s.session.totalStudents, _primary),
      ],
    );
  }

  Widget _countTile(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: _cardDecoration(),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: _grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _filters(QrAttendanceLoaded s) {
    final items = <(String, String)>[
      ('PRESENT', 'Present (${s.session.presentCount})'),
      ('ABSENT', 'Absent (${s.session.absentCount})'),
      if (s.session.alreadyMarkedCount > 0)
        ('MARKED', 'Marked earlier (${s.session.alreadyMarkedCount})'),
    ];

    return Wrap(
      spacing: 8,
      children: [
        for (final (value, label) in items)
          ChoiceChip(
            label: Text(label),
            selected: s.filter == value,
            selectedColor: _primary.withOpacity(0.15),
            onSelected: (_) => context.read<QrAttendanceBloc>().add(
              QrStudentsRequested(filter: value),
            ),
          ),
      ],
    );
  }

  List<Widget> _students(QrAttendanceLoaded s) {
    if (s.studentsLoading && s.students.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator(color: _primary)),
        ),
      ];
    }
    if (s.studentsError != null && s.students.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              s.studentsError!,
              style: const TextStyle(color: _red),
            ),
          ),
        ),
      ];
    }
    if (s.students.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text('No students', style: TextStyle(color: _grey)),
          ),
        ),
      ];
    }

    return [
      for (final student in s.students) _studentTile(student),
      if (s.hasMore)
        TextButton(
          onPressed: s.studentsLoading
              ? null
              : () => context.read<QrAttendanceBloc>().add(
                  QrStudentsRequested(
                    filter: s.filter,
                    page: s.studentsPage + 1,
                  ),
                ),
          child: const Text('Load more'),
        ),
    ];
  }

  Widget _studentTile(QrStudentItem student) {
    final initial = student.fullName.isNotEmpty
        ? student.fullName[0].toUpperCase()
        : '?';
    final time = student.scannedAt;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: _cardDecoration(),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _primary.withOpacity(0.12),
          child: Text(initial, style: const TextStyle(color: _primary)),
        ),
        title: Text(
          student.fullName,
          style: const TextStyle(color: _dark, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          'Roll no: ${student.rollNumber ?? '-'}',
          style: const TextStyle(color: _grey),
        ),
        trailing: time == null
            ? null
            : Text(
                '${time.hour.toString().padLeft(2, '0')}:'
                '${time.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(color: _grey),
              ),
      ),
    );
  }

  Widget _bottomBar(QrAttendanceLoaded s) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          height: 48,
          child: s.session.isActive
              ? ElevatedButton(
                  onPressed: s.closing ? null : _confirmStop,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _red,
                    foregroundColor: Colors.white,
                  ),
                  child: s.closing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Stop QR'),
                )
              : ElevatedButton(
                  onPressed: _start,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Generate QR again'),
                ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: const [
        BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2)),
      ],
    );
  }

  String _remaining(DateTime? expiresAt) {
    if (expiresAt == null) return '--:--';
    final diff = expiresAt.difference(DateTime.now());
    if (diff.isNegative) return '00:00';
    final m = diff.inMinutes.toString().padLeft(2, '0');
    final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}