import 'dart:convert';

import 'package:erp_app/Features/Dashboard/Student%20Dashboard/Bloc/qr_scan_event.dart';
import 'package:erp_app/Features/Dashboard/Student%20Dashboard/Bloc/qr_scan_state.dart';
import 'package:erp_app/Features/Faculty/Attendance/model/qr_attendance_model.dart';
import 'package:erp_app/Services/location_service.dart';
import 'package:erp_app/api_manager/api_checker.dart';
import 'package:erp_app/api_manager/api_client.dart';
import 'package:erp_app/api_manager/api_endPoints.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class QrScanBloc extends Bloc<QrScanEvent, QrScanState> {
  QrScanBloc({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient(),
      super(const QrScanInitial()) {
    on<QrScanSubmitted>(_onSubmitted);
    on<QrScanReset>((event, emit) => emit(const QrScanInitial()));
  }

  final ApiClient _apiClient;

  Future<void> _onSubmitted(
    QrScanSubmitted event,
    Emitter<QrScanState> emit,
  ) async {
    // The camera keeps firing, so only the first read is used
    if (state is! QrScanInitial) return;
    emit(const QrScanLoading());

    // QR content: {"qrSessionId": 1, "token": "..."}
    int? qrSessionId;
    String? token;
    try {
      final data = jsonDecode(event.rawValue);
      if (data is Map) {
        final id = data['qrSessionId'];
        qrSessionId = id is num ? id.toInt() : int.tryParse('$id');
        token = data['token']?.toString();
      }
    } catch (_) {
      // handled below
    }
    if (qrSessionId == null || token == null || token.isEmpty) {
      emit(const QrScanFailure('This is not a valid attendance QR.'));
      return;
    }

    try {
      final position = await LocationService.currentPosition();

      final response = await _apiClient.postAuthData(
        ApiEndPoints.qrScan,
        body: {
          'qrSessionId': qrSessionId,
          'token': token,
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
      );

      final error = ApiChecker.checkApi(response);
      if (error != null || response.body is! Map) {
        emit(QrScanFailure(error ?? 'Unable to mark attendance.'));
        return;
      }

      emit(
        QrScanLoaded(
          QrScanResultModel.fromJson(Map<String, dynamic>.from(response.body)),
        ),
      );
    } on LocationException catch (e) {
      emit(QrScanFailure(e.message));
    } catch (_) {
      emit(const QrScanFailure('Unable to mark attendance.'));
    }
  }
}