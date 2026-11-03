class LoginRequest {
  const LoginRequest({required this.loginId, required this.password});

  final String loginId;
  final String password;

  Map<String, dynamic> toJson() => {'loginId': loginId, 'password': password};
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

class InstituteModel {
  const InstituteModel({
    this.id,
    this.societyName,
    this.instituteName,
    this.instituteCode,
    this.instituteAddress,
    this.principalName,
    this.principalMobile,
    this.principalEmail,
    this.instituteLogo,
  });

  final int? id;
  final String? societyName;
  final String? instituteName;
  final String? instituteCode;
  final String? instituteAddress;
  final String? principalName;
  final int? principalMobile;
  final String? principalEmail;
  final String? instituteLogo;

  factory InstituteModel.fromJson(Map<String, dynamic> json) => InstituteModel(
    id: (json['id'] as num?)?.toInt(),
    societyName: json['societyName'] as String?,
    instituteName: json['instituteName'] as String?,
    instituteCode: json['instituteCode'] as String?,
    instituteAddress: json['instituteAddress'] as String?,
    principalName: json['principalName'] as String?,
    principalMobile: (json['principalMobile'] as num?)?.toInt(),
    principalEmail: json['principalEmail'] as String?,
    instituteLogo: json['instituteLogo'] as String?,
  );
}

class LoginResponse {
  const LoginResponse({
    required this.statusCode,
    required this.message,
    required this.token,
    required this.refreshToken,
    this.role,
    this.userId,
    this.userName,
    this.lastLoginTime,
    this.institute,
  });

  final int statusCode;
  final String message;
  final String token;
  final String refreshToken;
  final RoleModel? role;
  final int? userId; // ourUsers.id from the login response
  final String? userName; // ourUsers.userName or userName from root
  final String?
  lastLoginTime; // ourUsers.lastLoginTime or lastLoginTime from root
  final InstituteModel? institute; // ourUsers.institute or institute from root

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    try {
      return LoginResponse(
        statusCode: (json['statusCode'] as num?)?.toInt() ?? 0,
        message: json['message'] as String? ?? '',
        token: json['token'] as String? ?? '',
        refreshToken: json['refreshToken'] as String? ?? '',
        role:
            json['role'] is Map<String, dynamic>
                ? RoleModel.fromJson(json['role'] as Map<String, dynamic>)
                : null,
        userId: _readUserId(json),
        userName: _readUserName(json),
        lastLoginTime: _readLastLoginTime(json),
        institute: _readInstitute(json),
      );
    } catch (e) {
      print('Error parsing LoginResponse: $e');
      print('JSON: $json');
      rethrow;
    }
  }

  static int? _readUserId(Map<String, dynamic> json) {
    final user = json['ourUsers'];
    final raw = user is Map<String, dynamic> ? user['id'] : json['userId'];
    return raw is num ? raw.toInt() : null;
  }

  static String? _readUserName(Map<String, dynamic> json) {
    final user = json['ourUsers'];
    if (user is Map<String, dynamic>) {
      return user['userName'] as String? ?? json['userName'] as String?;
    }
    return json['userName'] as String?;
  }

  static String? _readLastLoginTime(Map<String, dynamic> json) {
    final user = json['ourUsers'];
    if (user is Map<String, dynamic>) {
      return user['lastLoginTime'] as String? ??
          json['lastLoginTime'] as String?;
    }
    return json['lastLoginTime'] as String?;
  }

  static InstituteModel? _readInstitute(Map<String, dynamic> json) {
    final user = json['ourUsers'];
    if (user is Map<String, dynamic> &&
        user['institute'] is Map<String, dynamic>) {
      return InstituteModel.fromJson(user['institute'] as Map<String, dynamic>);
    }
    if (json['institute'] is Map<String, dynamic>) {
      return InstituteModel.fromJson(json['institute'] as Map<String, dynamic>);
    }
    return null;
  }

  // The web application treats a returned token as the successful-login signal.
  // Keep the mobile client compatible with that behaviour instead of requiring
  bool get isAuthenticated => token.isNotEmpty;
}
