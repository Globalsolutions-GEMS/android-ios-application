class Response {
  const Response({
    required this.body,
    required this.bodyString,
    required this.headers,
    required this.statusCode,
    required this.statusText,
  });

  final dynamic body;
  final String bodyString;
  final Map<String, String> headers;
  final int statusCode;
  final String statusText;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

class ApiChecker {
  ApiChecker._();

  static String? checkApi(Response response) {
    if (response.isSuccess) return null;

    // JSON error: {"message": "..."}
    if (response.body is Map<String, dynamic>) {
      final message = response.body['message'];
      if (message is String && message.isNotEmpty) return message;
    }

    // Plain text error from the server (for example 400 messages)
    final text = response.bodyString.trim();
    if (text.isNotEmpty && text.length <= 200 && !text.startsWith('<')) {
      return text;
    }

    return response.statusText.isNotEmpty
        ? response.statusText
        : 'Unable to complete the request.';
  }
}