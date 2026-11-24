import 'package:erp_app/Features/Faculty/Attendance/model/qr_attendance_model.dart';

sealed class QrScanState {
  const QrScanState();
}

class QrScanInitial extends QrScanState {
  const QrScanInitial();
}

class QrScanLoading extends QrScanState {
  const QrScanLoading();
}

class QrScanLoaded extends QrScanState {
  const QrScanLoaded(this.result);

  final QrScanResultModel result;
}

class QrScanFailure extends QrScanState {
  const QrScanFailure(this.message);

  final String message;
}