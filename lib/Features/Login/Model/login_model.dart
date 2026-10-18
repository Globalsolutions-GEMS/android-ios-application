class LoginRequest {
  const LoginRequest({required this.loginId, required this.password});

  final String loginId;
  final String password;

  Map<String, dynamic> toJson() => {
        'loginId': loginId,
        'password': password,
      };
}
class RoleModel {
  const RoleModel({required this.id, required this.role});

  final int id;
  final String role;

  factory RoleModel.fromJson(Map<String, dynamic> json) => RoleModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        role: json['role'] as String? ?? '',
      );
}
class LoginResponse {
  const LoginResponse({
    required this.statusCode,
    required this.message,
    required this.token,
    required this.refreshToken,
    this.role,
  });

  final int statusCode;
  final String message;
  final String token;
  final String refreshToken;
   final RoleModel? role;

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
        statusCode: (json['statusCode'] as num?)?.toInt() ?? 0,
        message: json['message'] as String? ?? '',
        token: json['token'] as String? ?? '',
        refreshToken: json['refreshToken'] as String? ?? '',
        role: json['role'] is Map<String, dynamic>
            ? RoleModel.fromJson(json['role'] as Map<String, dynamic>)
            : null,
        );

  // The web application treats a returned token as the successful-login signal.
  // Keep the mobile client compatible with that behaviour instead of requiring
  bool get isAuthenticated => token.isNotEmpty;
}
