import 'package:erp_app/Features/Profile/Bloc/change_password_event.dart';
import 'package:erp_app/Features/Profile/Bloc/change_password_state.dart';
import 'package:erp_app/api_manager/api_checker.dart';
import 'package:erp_app/api_manager/api_client.dart';
import 'package:erp_app/api_manager/api_endPoints.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChangePasswordBloc
    extends Bloc<ChangePasswordEvent, ChangePasswordState> {
  ChangePasswordBloc({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient(),
      super(const ChangePasswordInitial()) {
    on<ChangePasswordSubmitted>(_onSubmitted);
  }

  final ApiClient _apiClient;

  Future<void> _onSubmitted(
    ChangePasswordSubmitted event,
    Emitter<ChangePasswordState> emit,
  ) async {
    emit(const ChangePasswordLoading());

    try {
      final response = await _apiClient.postData(
        ApiEndPoints.changePassword,
        authenticated: true,
        body: {
          'currentPassword': event.currentPassword,
          'newPassword': event.newPassword,
        },
      );
      final error = ApiChecker.checkApi(response);
      if (error != null) {
        emit(ChangePasswordFailed(error));
        return;
      }
      emit(const ChangePasswordLoaded('Password changed successfully'));
    } catch (_) {
      emit(const ChangePasswordFailed('Unable to change password.'));
    }
  }
}
