import 'dart:async';
import 'dart:convert';

import 'package:erp_app/api_manager/api_checker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;

    // This is the development machine's Wi-Fi address for physical Android devices.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
       return 'http://192.168.31.114:8080';
    }
    return 'http://localhost:8080';
  }

  static const Duration _timeout = Duration(seconds: 10);

  final http.Client _client;

  Future<Response> postData(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl$path'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body ?? const <String, dynamic>{}),
          )
          .timeout(_timeout);
      return _toResponse(response);
    } on TimeoutException {
      return _networkFailure('Request timed out. Please try again.');
    } on http.ClientException catch (error) {
      return _networkFailure('Unable to reach the server: ${error.message}');
    } catch (error) {
      return _networkFailure('Login request failed: $error');
    }
  }

  Response _toResponse(http.Response response) {
    dynamic body = response.body;
    try {
      body = jsonDecode(response.body);
    } on FormatException {
      // Keep non-JSON error bodies available to the caller.
    }
    return Response(
      body: body,
      bodyString: response.body,
      headers: response.headers,
      statusCode: response.statusCode,
      statusText: response.reasonPhrase ?? '',
    );
  }

  Response _networkFailure(String message) => Response(
        body: {'message': message},
        bodyString: message,
        headers: const {},
        statusCode: 1,
        statusText: message,
      );

  Future<void> saveLoginTokens({
    required String token,
    required String refreshToken,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('auth_token', token);
    await preferences.setString('refresh_token', refreshToken);
  }

}
