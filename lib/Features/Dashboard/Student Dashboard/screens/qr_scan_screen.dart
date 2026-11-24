import 'package:erp_app/Features/Dashboard/Student%20Dashboard/Bloc/qr_scan_bloc.dart';
import 'package:erp_app/Features/Dashboard/Student%20Dashboard/Bloc/qr_scan_event.dart';
import 'package:erp_app/Features/Dashboard/Student%20Dashboard/Bloc/qr_scan_state.dart';
import 'package:erp_app/Features/Faculty/Attendance/model/qr_attendance_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Student scans the teacher's QR to mark attendance.
class QrScanScreen extends StatelessWidget {
  const QrScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => QrScanBloc(),
      child: const _QrScanView(),
    );
  }
}

class _QrScanView extends StatefulWidget {
  const _QrScanView();

  @override
  State<_QrScanView> createState() => _QrScanViewState();
}

class _QrScanViewState extends State<_QrScanView> {
  static const Color _primary = Color(0xFF6D4AFF);
  static const Color _dark = Color(0xFF172033);
  static const Color _grey = Color(0xFF64748B);
  static const Color _green = Color(0xFF16A34A);
  static const Color _red = Color(0xFFDC2626);

  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    facing: CameraFacing.back,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<QrScanBloc, QrScanState>(
      listener: (context, state) {
        // Camera is not needed after a successful scan
        if (state is QrScanLoaded) _controller.stop();
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: const Text('Scan QR'),
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            actions: [
              if (state is! QrScanLoaded)
                IconButton(
                  tooltip: 'Flash',
                  onPressed: () => _controller.toggleTorch(),
                  icon: const Icon(Icons.flashlight_on_outlined),
                ),
            ],
          ),
          body: state is QrScanLoaded
              ? _success(context, state.result)
              : _scanner(context, state),
        );
      },
    );
  }

  Widget _scanner(BuildContext context, QrScanState state) {
    return Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: (capture) {
            if (capture.barcodes.isEmpty) return;
            final value = capture.barcodes.first.rawValue;
            if (value == null || value.isEmpty) return;
            context.read<QrScanBloc>().add(QrScanSubmitted(value));
          },
          errorBuilder: (context, error, child) => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Camera is not available. Please allow camera permission '
                'from the app settings.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),

        // Square frame
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),

        const Positioned(
          left: 24,
          right: 24,
          bottom: 48,
          child: Text(
            'Point the camera at the QR shown by your teacher',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 15),
          ),
        ),

        if (state is QrScanLoading)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Marking attendance...',
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ],
              ),
            ),
          ),

        if (state is QrScanFailure)
          Container(
            color: Colors.black54,
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: _red, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: _dark, fontSize: 15),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () =>
                            context.read<QrScanBloc>().add(const QrScanReset()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Scan again'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _success(BuildContext context, QrScanResultModel result) {
    final time = result.markedAt;

    return Container(
      color: const Color(0xFFEEF0F6),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: _green, size: 72),
              const SizedBox(height: 12),
              const Text(
                'Attendance marked',
                style: TextStyle(
                  color: _dark,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              if (result.subjectName != null)
                Text(
                  result.subjectName!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _dark, fontSize: 16),
                ),
              if (result.statusName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Status: ${result.statusName}',
                    style: const TextStyle(color: _grey, fontSize: 14),
                  ),
                ),
              if (time != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Time: ${time.hour.toString().padLeft(2, '0')}:'
                    '${time.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: _grey, fontSize: 14),
                  ),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}