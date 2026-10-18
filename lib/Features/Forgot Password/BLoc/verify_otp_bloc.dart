import 'package:erp_app/Features/Forgot Password/BLoc/verify_otp_event.dart';
import 'package:erp_app/Features/Forgot Password/BLoc/verify_otp_state.dart';
import 'package:erp_app/Features/Forgot Password/Model/verify_otp_model.dart';
import 'package:erp_app/Features/Forgot Password/Model/forgot_password_model.dart';
import 'package:erp_app/api_manager/api_checker.dart';
import 'package:erp_app/api_manager/api_client.dart';
import 'package:erp_app/api_manager/api_endPoints.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class VerifyOtpBloc extends Bloc<VerifyOtpEvent, VerifyOtpState> {
  VerifyOtpBloc({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient(),
      super(const VerifyOtpInitial()) {
    on<VerifyOtpSubmitted>(_onVerifyOtpSubmitted);
    on<ResendOtp>(_onResendOtp);
  }

  final ApiClient _apiClient;

  Future<void> _onVerifyOtpSubmitted(
    VerifyOtpSubmitted event,
    Emitter<VerifyOtpState> emit,
  ) async {
    emit(const VerifyOtpLoading());

    final request = VerifyOtpRequest(
      otp: event.otp,
      email: event.email,
      mobile: event.mobile,
      studentId: event.studentId,
      instituteId: event.instituteId,
    );

    final response = await _apiClient.postData(
      ApiEndPoints.verifyOtp,
      body: request.toJson(),
    );

    final apiError = ApiChecker.checkApi(response);
    if (apiError != null) {
      String errorMessage = _getErrorMessage(
        response.statusCode,
        response.body,
        apiError,
      );
      emit(VerifyOtpFailure(errorMessage));
      return;
    }

    if (response.body is! Map<String, dynamic>) {
      emit(const VerifyOtpFailure('Invalid response from server.'));
      return;
    }

    final verifyOtpResponse = VerifyOtpResponse.fromJson(
      response.body as Map<String, dynamic>,
    );

    if (verifyOtpResponse.statusCode == 200) {
      emit(const VerifyOtpSuccess());
    } else {
      emit(
        VerifyOtpFailure(
          verifyOtpResponse.message.isNotEmpty
              ? verifyOtpResponse.message
              : 'Invalid OTP. Please try again.',
        ),
      );
    }
  }

  Future<void> _onResendOtp(
    ResendOtp event,
    Emitter<VerifyOtpState> emit,
  ) async {
    emit(const VerifyOtpLoading());

    ForgotPasswordRequest request;
    if (event.email != null) {
      request = ForgotPasswordRequest(email: event.email);
    } else if (event.mobile != null) {
      request = ForgotPasswordRequest(mobile: event.mobile);
    } else if (event.studentId != null) {
      request = ForgotPasswordRequest(studentId: event.studentId);
    } else {
      request = ForgotPasswordRequest();
    }

    final response = await _apiClient.postData(
      ApiEndPoints.requestReset,
      body: request.toJson(),
    );

    final apiError = ApiChecker.checkApi(response);
    if (apiError != null) {
      String errorMessage = _getErrorMessage(
        response.statusCode,
        response.body,
        apiError,
      );
      emit(VerifyOtpFailure(errorMessage));
      return;
    }

    if (response.body is! Map<String, dynamic>) {
      emit(const VerifyOtpFailure('Invalid response from server.'));
      return;
    }

    final forgotPasswordResponse = ForgotPasswordResponse.fromJson(
      response.body as Map<String, dynamic>,
    );

    if (forgotPasswordResponse.statusCode == 200) {
      // Don't overwrite SharedPreferences - data is already saved from forgot password screen
      emit(const VerifyOtpSuccess());
    } else if (forgotPasswordResponse.statusCode == 409) {
      String errorMessage =
          event.email != null
              ? 'Duplicate email found. Please use Student ID to reset password.'
              : event.mobile != null
              ? 'Duplicate mobile found. Please use Student ID to reset password.'
              : 'Failed to resend OTP. Please try again.';
      emit(VerifyOtpFailure(errorMessage));
    } else {
      emit(
        VerifyOtpFailure(
          forgotPasswordResponse.message.isNotEmpty
              ? forgotPasswordResponse.message
              : 'Failed to resend OTP. Please try again.',
        ),
      );
    }
  }

  String _getErrorMessage(int statusCode, dynamic body, String fallback) {
    final message =
        body is Map<String, dynamic> && body['message'] is String
            ? body['message'] as String
            : fallback;

    if (statusCode == 404) {
      return 'Email not found. Please check your email or try other options.';
    }
    if (statusCode == 400) {
      return 'Invalid input. Please check your details and try again.';
    }
    if (statusCode == 500) {
      return 'Server error. Please try again later.';
    }
    if (statusCode == 1) {
      return 'Network error. Please check your connection.';
    }

    return message.isNotEmpty ? message : 'Request failed. Please try again.';
  }
}
