import 'package:erp_app/Features/Login/Model/login_model.dart';
import 'package:erp_app/api_manager/api_checker.dart';
import 'package:erp_app/api_manager/api_client.dart';
import 'package:erp_app/api_manager/api_endPoints.dart';
import 'package:flutter/foundation.dart';

class UserService {
  UserService._();

  static Future<LoginResponse> login({
    required String loginId,
    required String password,
  }) async {
    final apiClient = ApiClient();

    final response = await apiClient.postData(
      ApiEndPoints.login,
      body: LoginRequest(loginId: loginId, password: password).toJson(),
    );
    
    debugPrint('LOGIN RESPONSE: ${response.body}');

    final apiError = ApiChecker.checkApi(response);
    if (apiError != null) {
      throw Exception(apiError);
    }

    if (response.body is! Map<String, dynamic>) {
      throw Exception('Invalid login response.');
    }

    return LoginResponse.fromJson(response.body as Map<String, dynamic>);
  }
}
