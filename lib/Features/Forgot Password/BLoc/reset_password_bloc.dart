import 'package:erp_app/Features/Forgot Password/BLoc/reset_password_event.dart';
import 'package:erp_app/Features/Forgot Password/BLoc/reset_password_state.dart';
import 'package:erp_app/Features/Forgot Password/Model/reset_password_model.dart';
import 'package:erp_app/api_manager/api_checker.dart';
import 'package:erp_app/api_manager/api_client.dart';
import 'package:erp_app/api_manager/api_endPoints.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ResetPasswordBloc extends Bloc<ResetPasswordEvent, ResetPasswordState> {
  ResetPasswordBloc({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient(),
      super(const ResetPasswordInitial()) {
    on<ResetPasswordSubmitted>(_onResetPasswordSubmitted);
  }

  final ApiClient _apiClient;

  Future<void> _onResetPasswordSubmitted(
    ResetPasswordSubmitted event,
    Emitter<ResetPasswordState> emit,
  ) async {
    // Validate passwords
    final validationError = _validatePassword(
      event.newPassword,
      event.confirmNewPassword,
    );

    if (validationError != null) {
      emit(ResetPasswordFailure(validationError));
      return;
    }

    emit(const ResetPasswordLoading());

    final request = ResetPasswordRequest(
      otp: event.otp,
      newPassword: event.newPassword,
      email: event.email,
      mobile: event.mobile,
      studentId: event.studentId,
    );

    final response = await _apiClient.postData(
      ApiEndPoints.confirmReset,
      body: request.toJson(),
    );

    final apiError = ApiChecker.checkApi(response);
    if (apiError != null) {
      String errorMessage = _getErrorMessage(
        response.statusCode,
        response.body,
        apiError,
      );
      emit(ResetPasswordFailure(errorMessage));
      return;
    }

    if (response.body is! Map<String, dynamic>) {
      emit(const ResetPasswordFailure('Invalid response from server.'));
      return;
    }

    final resetPasswordResponse = ResetPasswordResponse.fromJson(
      response.body as Map<String, dynamic>,
    );

    if (resetPasswordResponse.statusCode == 200) {
      emit(const ResetPasswordSuccess());
    } else {
      emit(
        ResetPasswordFailure(
          resetPasswordResponse.message.isNotEmpty
              ? resetPasswordResponse.message
              : 'Failed to reset password. Please try again.',
        ),
      );
    }
  }

  String? _validatePassword(String newPassword, String confirmNewPassword) {
    if (newPassword.isEmpty) {
      return 'New password is required';
    }

    if (newPassword.length < 8) {
      return 'Password must be at least 8 characters long';
    }

    if (!newPassword.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    if (!newPassword.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    if (!newPassword.contains(RegExp(r'[0-9]')) &&
        !newPassword.contains(
          RegExp(r'[!@#$%^&*()_+\-=\[\]{};":\\|,.<>\/?]'),
        )) {
      return 'Password must contain at least one number or special character';
    }

    if (confirmNewPassword.isEmpty) {
      return 'Please confirm your password';
    }

    if (newPassword != confirmNewPassword) {
      return 'Passwords do not match';
    }

    return null;
  }

  String _getErrorMessage(int statusCode, dynamic body, String fallback) {
    final message =
        body is Map<String, dynamic> && body['message'] is String
            ? body['message'] as String
            : fallback;

    if (statusCode == 400) {
      return 'Invalid input. Please check your details and try again.';
    }
    if (statusCode == 404) {
      return 'Invalid OTP or user not found.';
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
