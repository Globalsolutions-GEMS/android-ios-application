class ForgotPasswordRequest {
  const ForgotPasswordRequest({
    this.email,
    this.mobile,
    this.studentId,
    this.loginId,
  });

  final String? email;
  final String? mobile;
  final String? studentId;
  final String? loginId;

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'mobile': mobile,
      'studentId': studentId,
      'loginId': loginId,
    };
  }
}

class ForgotPasswordResponse {
  const ForgotPasswordResponse({
    required this.statusCode,
    required this.message,
    this.workingDate = false,
    this.active = false,
    this.maskedEmail,
    this.maskedMobile,
  });

  final int statusCode;
  final String message;
  final bool workingDate;
  final bool active;
  final String? maskedEmail;
  final String? maskedMobile;

  factory ForgotPasswordResponse.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordResponse(
      statusCode: (json['statusCode'] as num?)?.toInt() ?? 0,
      message: json['message'] as String? ?? '',
      workingDate: json['workingDate'] as bool? ?? false,
      active: json['active'] as bool? ?? false,
      maskedEmail: json['maskedEmail'] as String?,
      maskedMobile: json['maskedMobile'] as String?,
    );
  }
}
