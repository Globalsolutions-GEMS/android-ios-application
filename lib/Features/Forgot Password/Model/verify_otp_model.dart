class VerifyOtpRequest {
  const VerifyOtpRequest({
    required this.otp,
    this.email,
    this.mobile,
    this.studentId,
    this.instituteId,
  });

  final String otp;
  final String? email;
  final String? mobile;
  final String? studentId;
  final String? instituteId;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'otp': otp,
    };

    if (studentId != null) {
      json['studentId'] = studentId;
      json['instituteId'] = instituteId;
    } else {
      json['instituteId'] = instituteId;
      if (email != null) json['email'] = email;
      if (mobile != null) json['mobile'] = mobile;
    }

    return json;
  }
}

class VerifyOtpResponse {
  const VerifyOtpResponse({
    required this.statusCode,
    required this.message,
  });

  final int statusCode;
  final String message;

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    return VerifyOtpResponse(
      statusCode: (json['statusCode'] as num?)?.toInt() ?? 0,
      message: json['message'] as String? ?? '',
    );
  }
}
