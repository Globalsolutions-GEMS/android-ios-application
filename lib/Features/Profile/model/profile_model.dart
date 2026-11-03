class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.name,
    required this.email,
    required this.loginId,
    required this.counter,
    this.mobile = '',
    this.role = '',
    this.instituteName = '',
    this.lastLogin = '',
    this.photoBase64,
    this.raw = const {},
  });

  final int id;
  final String name;
  final String email;
  final String loginId;
  final int counter;
  final String mobile;
  final String role;
  final String instituteName;
  final String lastLogin; // raw ISO string from the API
  final String? photoBase64; // userProfile (base64 image)
  final Map<String, dynamic> raw; // full user object from the API

  /// Copy of this profile with the photo cleared.
  ProfileModel withoutPhoto() => ProfileModel(
    id: id,
    name: name,
    email: email,
    loginId: loginId,
    counter: counter,
    mobile: mobile,
    role: role,
    instituteName: instituteName,
    lastLogin: lastLogin,
    photoBase64: null,
    raw: {...raw, 'userProfile': null},
  );

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    // Response may be wrapped in ourUsers or be the user itself
    final user = json['ourUsers'] is Map<String, dynamic>
        ? json['ourUsers'] as Map<String, dynamic>
        : json;
    final role = user['role'];
    final institute = user['institute'];

    return ProfileModel(
      id: (user['id'] as num?)?.toInt() ?? 0,
      name: (user['userName'] ?? user['username'] ?? '') as String,
      email: user['email'] as String? ?? '',
      loginId: user['loginId'] as String? ?? '',
      counter: (user['counter'] as num?)?.toInt() ?? 0,
      mobile: user['mobile']?.toString() ?? '',
      role: role is Map<String, dynamic>
          ? role['role'] as String? ?? ''
          : role as String? ?? '',
      instituteName: institute is Map<String, dynamic>
          ? institute['instituteName'] as String? ?? ''
          : '',
      lastLogin: user['lastLoginTime'] as String? ?? '',
      photoBase64: user['userProfile'] as String?,
      raw: user,
    );
  }

  /// Body for PUT /admin/update/{id} (same fields the web sends).
  Map<String, dynamic> toUpdateJson({
    required String email,
    required String mobile,
    String? photoBase64,
  }) => {
    'email': email,
    'userName': name,
    'fullName': '',
    'mobile': mobile,
    'counter': counter,
    'loginId': loginId,
    'workingDate': raw['workingDate'] ?? true,
    'active': raw['active'] ?? true,
    'id': id,
    'role': raw['role'],
    'userType': raw['userType'],
    'institute': raw['institute'],
    'userProfile': (photoBase64 == null || photoBase64.isEmpty)
        ? null
        : photoBase64,
  };
}
