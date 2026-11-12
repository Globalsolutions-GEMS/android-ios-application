import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:erp_app/api_manager/api_checker.dart';
import 'package:erp_app/api_manager/api_endPoints.dart';
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
      // return 'http://192.168.31.114:8080';
      return 'http://192.168.31.56:8081';
    }
    return 'http://localhost:8080';
  }

  static const Duration _timeout = Duration(seconds: 10);

  final http.Client _client;

  Future<Response> postData(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) async {
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};

      if (authenticated) {
        final preferences = await SharedPreferences.getInstance();
        final token = preferences.getString('auth_token') ?? '';

        if (token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
      }

      final response = await _client
          .post(
            Uri.parse('$baseUrl$path'),
            headers: headers,
            body: jsonEncode(body ?? const <String, dynamic>{}),
          )
          .timeout(_timeout);

      return _toResponse(response);
    } on TimeoutException {
      return _networkFailure('Request timed out. Please try again.');
    } on http.ClientException catch (error) {
      return _networkFailure('Unable to reach the server: ${error.message}');
    } catch (error) {
      return _networkFailure('Request failed: $error');
    }
  }

  /// Authenticated GET. Sends the saved login token as a Bearer header.
  /// Dashboard endpoints return whole-institute lists, so the timeout is longer
  /// than the one used for login.
  Future<Response> getData(
    String path, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final token = preferences.getString('auth_token') ?? '';
      final response = await _client
          .get(
            Uri.parse('$baseUrl$path'),
            headers: {
              'Content-Type': 'application/json',
              if (token.isNotEmpty) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(timeout);
      return _toResponse(response);
    } on TimeoutException {
      return _networkFailure('Request timed out. Please try again.');
    } on http.ClientException catch (error) {
      return _networkFailure('Unable to reach the server: ${error.message}');
    } catch (error) {
      return _networkFailure('Request failed: $error');
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
    int? userId,
    String? userName,
    String? lastLoginTime,
    String? instituteName,
    String? instituteAddress,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('auth_token', token);
    await preferences.setString('refresh_token', refreshToken);
    if (userId != null) {
      await preferences.setInt('user_id', userId);
    }
    if (userName != null) {
      await preferences.setString('user_name', userName);
    }
    if (lastLoginTime != null) {
      await preferences.setString('last_login_time', lastLoginTime);
    }
    if (instituteName != null) {
      await preferences.setString('institute_name', instituteName);
    }
    if (instituteAddress != null) {
      await preferences.setString('institute_address', instituteAddress);
    }
  }

  /// Authenticated PUT. Sends the saved login token as a Bearer header.
  Future<Response> putData(String path, {Map<String, dynamic>? body}) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final token = preferences.getString('auth_token') ?? '';
      final response = await _client
          .put(
            Uri.parse('$baseUrl$path'),
            headers: {
              'Content-Type': 'application/json',
              if (token.isNotEmpty) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body ?? const <String, dynamic>{}),
          )
          .timeout(const Duration(seconds: 30));
      return _toResponse(response);
    } on TimeoutException {
      return _networkFailure('Request timed out. Please try again.');
    } on http.ClientException catch (error) {
      return _networkFailure('Unable to reach the server: ${error.message}');
    } catch (error) {
      return _networkFailure('Request failed: $error');
    }
  }

  /// Authenticated POST. Sends the saved login token as a Bearer header.
  Future<Response> postAuthData(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final token = preferences.getString('auth_token') ?? '';
      final response = await _client
          .post(
            Uri.parse('$baseUrl$path'),
            headers: {
              'Content-Type': 'application/json',
              if (token.isNotEmpty) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body ?? const <String, dynamic>{}),
          )
          .timeout(const Duration(seconds: 30));
      return _toResponse(response);
    } on TimeoutException {
      return _networkFailure('Request timed out. Please try again.');
    } on http.ClientException catch (error) {
      return _networkFailure('Unable to reach the server: ${error.message}');
    } catch (error) {
      return _networkFailure('Request failed: $error');
    }
  }

  /// Authenticated DELETE. Sends the saved login token as a Bearer header.
  Future<Response> deleteData(String path) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final token = preferences.getString('auth_token') ?? '';
      final response = await _client
          .delete(
            Uri.parse('$baseUrl$path'),
            headers: {
              'Content-Type': 'application/json',
              if (token.isNotEmpty) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 30));
      return _toResponse(response);
    } on TimeoutException {
      return _networkFailure('Request timed out. Please try again.');
    } on http.ClientException catch (error) {
      return _networkFailure('Unable to reach the server: ${error.message}');
    } catch (error) {
      return _networkFailure('Request failed: $error');
    }
  }

  /// Upload profile image using multipart/form-data
  Future<Response> uploadProfileImage(File imageFile) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final token = preferences.getString('auth_token') ?? '';

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl${ApiEndPoints.changeProfile}'),
      );

      // Add authorization header
      if (token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add the file
      final file = await http.MultipartFile.fromPath('file', imageFile.path);
      request.files.add(file);

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );

      final response = await http.Response.fromStream(streamedResponse);
      return _toResponse(response);
    } on TimeoutException {
      return _networkFailure('Request timed out. Please try again.');
    } on http.ClientException catch (error) {
      return _networkFailure('Unable to reach the server: ${error.message}');
    } catch (error) {
      return _networkFailure('Upload failed: $error');
    }
  }
}
