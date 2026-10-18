class ResetPasswordRequest {
  const ResetPasswordRequest({
    required this.otp,
    required this.newPassword,
    this.email,
    this.mobile,
    this.studentId,
  });

  final String otp;
  final String newPassword;
  final String? email;
  final String? mobile;
  final String? studentId;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'otp': otp,
      'newPassword': newPassword,
    };

    if (email != null) json['email'] = email;
    if (mobile != null) json['mobile'] = mobile;
    if (studentId != null) json['studentId'] = studentId;

    return json;
  }
}

class ResetPasswordResponse {
  const ResetPasswordResponse({
    required this.statusCode,
    required this.message,
    this.workingDate = false,
    this.active = false,
  });

  final int statusCode;
  final String message;
  final bool workingDate;
  final bool active;

  factory ResetPasswordResponse.fromJson(Map<String, dynamic> json) {
    return ResetPasswordResponse(
      statusCode: (json['statusCode'] as num?)?.toInt() ?? 0,
      message: json['message'] as String? ?? '',
      workingDate: json['workingDate'] as bool? ?? false,
      active: json['active'] as bool? ?? false,
    );
  }
}
