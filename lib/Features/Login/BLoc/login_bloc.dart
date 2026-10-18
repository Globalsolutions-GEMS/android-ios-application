import 'package:erp_app/Features/Login/BLoc/login_event.dart';
import 'package:erp_app/Features/Login/BLoc/login_state.dart';
import 'package:erp_app/Features/Login/Model/login_model.dart';
import 'package:erp_app/api_manager/api_checker.dart';
import 'package:erp_app/api_manager/api_client.dart';
import 'package:erp_app/api_manager/api_endPoints.dart';
import 'package:erp_app/api_manager/error_response.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient(),
      super(const LoginInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
  }

  final ApiClient _apiClient;

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    emit(const LoginLoading());

    try {
      final response = await _apiClient.postData(
        ApiEndPoints.login,
        body:
            LoginRequest(
              loginId: event.loginId,
              password: event.password,
            ).toJson(),
      );

      // Check for API errors
      final apiError = ApiChecker.checkApi(response);
      if (apiError != null) {
        final errorResponse = ErrorResponse.fromResponse(
          response.body,
          response.statusCode,
        );
        final errorMessage = LoginErrorHandler.getLoginErrorMessage(
          errorResponse,
        );
        emit(LoginFailure(errorMessage));
        return;
      }

      // Validate response body
      if (response.body is! Map<String, dynamic>) {
        emit(const LoginFailure('Invalid login response.'));
        return;
      }

      final loginResponse = LoginResponse.fromJson(
        response.body as Map<String, dynamic>,
      );

      // Check if authenticated (has token)
      if (!loginResponse.isAuthenticated) {
        final errorResponse = ErrorResponse.fromResponse(
          response.body,
          response.statusCode,
        );
        final errorMessage = LoginErrorHandler.getLoginErrorMessage(
          errorResponse,
        );
        emit(LoginFailure(errorMessage));
        return;
      }

      // Save tokens and emit success
      await _apiClient.saveLoginTokens(
        token: loginResponse.token,
        refreshToken: loginResponse.refreshToken,
      );
      emit(
  LoginSuccess(
    loginResponse.message,
    roleName: loginResponse.role?.role.toUpperCase() ?? '',
  ),
);
    } catch (error) {
      // Client-side/unexpected error
      emit(const LoginFailure('Login failed. Please try again later.'));
    }
  }
}
