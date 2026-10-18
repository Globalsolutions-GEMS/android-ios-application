import 'package:erp_app/Features/Forgot Password/BLoc/forgot_password_event.dart';
import 'package:erp_app/Features/Forgot Password/BLoc/forgot_password_state.dart';
import 'package:erp_app/Features/Forgot Password/Model/forgot_password_model.dart';
import 'package:erp_app/Features/Forgot Password/Model/fetch_user_contact_model.dart';
import 'package:erp_app/api_manager/api_checker.dart';
import 'package:erp_app/api_manager/api_client.dart';
import 'package:erp_app/api_manager/api_endPoints.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ForgotPasswordBloc
    extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  ForgotPasswordBloc({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient(),
      super(const ForgotPasswordInitial()) {
    on<ForgotPasswordSubmitted>(_onForgotPasswordSubmitted);
  }

  final ApiClient _apiClient;

  Future<void> _onForgotPasswordSubmitted(
    ForgotPasswordSubmitted event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    emit(const ForgotPasswordLoading());

    String otpSource;
    String maskedEmail = '';
    String maskedMobile = '';
    String successMessage = 'OTP sent successfully!';

    switch (event.methodIndex) {
      case 0: // Email
        otpSource = 'email';
        maskedEmail = event.inputValue;
        successMessage = 'OTP sent to your email!';
        final request = ForgotPasswordRequest(email: event.inputValue);
        final response = await _apiClient.postData(
          ApiEndPoints.requestReset,
          body: request.toJson(),
        );
        final apiError = ApiChecker.checkApi(response);
        if (apiError != null) {
          String errorMessage = _getEmailErrorMessage(
            response.statusCode,
            response.body,
            apiError,
          );
          emit(ForgotPasswordFailure(errorMessage));
          return;
        }
        if (response.body is! Map<String, dynamic>) {
          emit(const ForgotPasswordFailure('Failed to send OTP. Please try again.'));
          return;
        }
        final forgotPasswordResponse = ForgotPasswordResponse.fromJson(
          response.body as Map<String, dynamic>,
        );
        if (forgotPasswordResponse.statusCode != 200) {
          String errorMessage = _getEmailErrorMessage(
            forgotPasswordResponse.statusCode,
            response.body,
            forgotPasswordResponse.message.isNotEmpty
                ? forgotPasswordResponse.message
                : 'Failed to send OTP. Please try again.',
          );
          emit(ForgotPasswordFailure(errorMessage));
          return;
        }
        break;

      case 1: // Mobile
        otpSource = 'mobile';
        maskedMobile = event.inputValue;
        successMessage = 'OTP sent to your mobile!';
        final request = ForgotPasswordRequest(mobile: event.inputValue);
        final response = await _apiClient.postData(
          ApiEndPoints.requestReset,
          body: request.toJson(),
        );
        final apiError = ApiChecker.checkApi(response);
        if (apiError != null) {
          String errorMessage = _getMobileErrorMessage(
            response.statusCode,
            response.body,
            apiError,
          );
          emit(ForgotPasswordFailure(errorMessage));
          return;
        }
        if (response.body is! Map<String, dynamic>) {
          emit(const ForgotPasswordFailure('Failed to send OTP. Please try again.'));
          return;
        }
        final forgotPasswordResponse = ForgotPasswordResponse.fromJson(
          response.body as Map<String, dynamic>,
        );
        if (forgotPasswordResponse.statusCode != 200) {
          emit(
            ForgotPasswordFailure(
              forgotPasswordResponse.message.isNotEmpty
                  ? forgotPasswordResponse.message
                  : 'Failed to send OTP. Please try again.',
            ),
          );
          return;
        }
        break;

      case 2: // Student ID
        otpSource = 'studentId';
        successMessage = 'OTP sent successfully!';
        // First call fetch-user-contact API
        final fetchRequest = FetchUserContactRequest(
          studentId: event.inputValue,
        );
        final fetchResponse = await _apiClient.postData(
          ApiEndPoints.fetchUserContact,
          body: fetchRequest.toJson(),
        );
        final fetchApiError = ApiChecker.checkApi(fetchResponse);
        if (fetchApiError != null) {
          String errorMessage = _getStudentIdErrorMessage(
            fetchResponse.statusCode,
            fetchResponse.body,
            fetchApiError,
          );
          emit(ForgotPasswordFailure(errorMessage));
          return;
        }
        if (fetchResponse.body is! Map<String, dynamic>) {
          emit(const ForgotPasswordFailure('Error fetching user contact or sending OTP. Please try again.'));
          return;
        }
        final userContactResponse = FetchUserContactResponse.fromJson(
          fetchResponse.body as Map<String, dynamic>,
        );
        if (userContactResponse.statusCode != 200 ||
            userContactResponse.data == null) {
          if (userContactResponse.statusCode == 403) {
            emit(const ForgotPasswordFailure('Login has been disabled. Password reset not allowed.'));
          } else {
            emit(
              ForgotPasswordFailure(
                userContactResponse.message.isNotEmpty
                    ? userContactResponse.message
                    : 'No user found for this Student ID.',
              ),
            );
          }
          return;
        }
        // Save email and mobile from fetch response
        maskedEmail = userContactResponse.data!.email;
        maskedMobile = userContactResponse.data!.mobile;

        // Then call request-reset API with studentId
        final resetRequest = ForgotPasswordRequest(studentId: event.inputValue);
        final resetResponse = await _apiClient.postData(
          ApiEndPoints.requestReset,
          body: resetRequest.toJson(),
        );
        final resetApiError = ApiChecker.checkApi(resetResponse);
        if (resetApiError != null) {
          String errorMessage = _getStudentIdErrorMessage(
            resetResponse.statusCode,
            resetResponse.body,
            resetApiError,
          );
          emit(ForgotPasswordFailure(errorMessage));
          return;
        }
        if (resetResponse.body is! Map<String, dynamic>) {
          emit(const ForgotPasswordFailure('Error fetching user contact or sending OTP. Please try again.'));
          return;
        }
        final forgotPasswordResponse = ForgotPasswordResponse.fromJson(
          resetResponse.body as Map<String, dynamic>,
        );
        if (forgotPasswordResponse.statusCode != 200) {
          if (forgotPasswordResponse.statusCode == 403) {
            emit(const ForgotPasswordFailure('Login has been disabled. Password reset not allowed.'));
          } else {
            emit(
              ForgotPasswordFailure(
                forgotPasswordResponse.message.isNotEmpty
                    ? forgotPasswordResponse.message
                    : 'Failed to send OTP. Please try again.',
              ),
            );
          }
          return;
        }
        break;

      default:
        emit(const ForgotPasswordFailure('Invalid selection.'));
        return;
    }

    // Save to SharedPreferences
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('otpSource', otpSource);
    await preferences.setString('inputValue', event.inputValue);
    await preferences.setString('maskedEmail', maskedEmail);
    await preferences.setString('maskedMobile', maskedMobile);
    await preferences.setString('email', maskedEmail);
    await preferences.setString('mobile', maskedMobile);
    await preferences.setString(
      'studentId',
      event.methodIndex == 2 ? event.inputValue : '',
    );

    emit(ForgotPasswordSuccess(successMessage));
  }

  String _getEmailErrorMessage(int statusCode, dynamic body, String fallback) {
    if (statusCode == 200) {
      return 'OTP sent to your email!';
    }
    if (statusCode == 404) {
      return 'Email not found. Please check your email or try other options.';
    }
    if (statusCode == 409) {
      return 'Duplicate email found. Please use other options to reset your password.';
    }
    if (statusCode == 403) {
      return 'Login has been disabled. Password reset not allowed.';
    }

    final message =
        body is Map<String, dynamic> && body['message'] is String
            ? body['message'] as String
            : fallback;

    return message.isNotEmpty ? message : 'Failed to send OTP. Please try again.';
  }

  String _getMobileErrorMessage(int statusCode, dynamic body, String fallback) {
    final message =
        body is Map<String, dynamic> && body['message'] is String
            ? body['message'] as String
            : fallback;

    if (statusCode == 200) {
      return 'OTP sent to your mobile!';
    }
    if (statusCode == 404) {
      return 'Mobile number not found. Please check your number or try other options.';
    }
    if (statusCode == 409) {
      return 'Duplicate mobile number found. Please use other options to reset your password.';
    }
    if (statusCode == 403) {
      return 'Login has been disabled. Password reset not allowed.';
    }

    return 'Failed to send OTP. Please try again.';
  }

  String _getStudentIdErrorMessage(int statusCode, dynamic body, String fallback) {
    final message =
        body is Map<String, dynamic> && body['message'] is String
            ? body['message'] as String
            : fallback;

    if (statusCode == 200) {
      return 'OTP sent successfully!';
    }
    if (statusCode == 403) {
      return 'Login has been disabled. Password reset not allowed.';
    }

    return 'Failed to send OTP. Please try again.';
  }
}
