class ErrorResponse {
  const ErrorResponse({
    required this.statusCode,
    required this.message,
    this.body,
  });

  final int statusCode;
  final String message;
  final dynamic body;

  factory ErrorResponse.fromResponse(dynamic response, int statusCode) {
    String message = '';
    dynamic body = response;

    if (response is Map<String, dynamic>) {
      message = response['message'] as String? ?? '';
      body = response;
    } else if (response is String) {
      message = response;
    }

    return ErrorResponse(statusCode: statusCode, message: message, body: body);
  }
}

class LoginErrorHandler {
  LoginErrorHandler._();

  static String getLoginErrorMessage(ErrorResponse error) {
    final statusCode = error.statusCode;
    final message = error.message.toLowerCase();

    // User does not exist (404)
    if (statusCode == 404) {
      return 'User not found. Please check your login ID.';
    }

    // Account inactive/disabled (401 with specific message)
    if (statusCode == 401 &&
        (message.contains('inactive') || message.contains('disabled'))) {
      return 'Your login has been disabled. Please contact the administrative office for assistance.';
    }

    // Credentials invalid (401)
    if (statusCode == 401) {
      return 'Invalid login ID or password.';
    }

    // Incorrect password (500)
    if (statusCode == 500 && message.contains('password')) {
      return 'Incorrect password. Please try again.';
    }

    // Network error (statusCode 1 from ApiClient)
    if (statusCode == 1) {
      return 'Network error. Please check your connection.';
    }

    // Other server/API failure - use backend message if available
    if (error.message.isNotEmpty) {
      return error.message;
    }

    // Default error message
    return 'Login failed. Please try again.';
  }
}
