class FetchUserContactRequest {
  const FetchUserContactRequest({
    required this.studentId,
  });

  final String studentId;

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
    };
  }
}

class ContactData {
  const ContactData({
    required this.loginId,
    required this.email,
    required this.mobile,
    required this.instituteName,
  });

  final String loginId;
  final String email;
  final String mobile;
  final String instituteName;

  factory ContactData.fromJson(Map<String, dynamic> json) {
    return ContactData(
      loginId: json['loginId'] as String? ?? '',
      email: json['email'] as String? ?? '',
      mobile: json['mobile']?.toString() ?? '',
      instituteName: json['instituteName'] as String? ?? '',
    );
  }
}

class FetchUserContactResponse {
  const FetchUserContactResponse({
    required this.statusCode,
    required this.message,
    this.workingDate = false,
    this.active = false,
    this.data,
  });

  final int statusCode;
  final String message;
  final bool workingDate;
  final bool active;
  final ContactData? data;

  factory FetchUserContactResponse.fromJson(Map<String, dynamic> json) {
    return FetchUserContactResponse(
      statusCode: (json['statusCode'] as num?)?.toInt() ?? 0,
      message: json['message'] as String? ?? '',
      workingDate: json['workingDate'] as bool? ?? false,
      active: json['active'] as bool? ?? false,
      data: json['data'] != null ? ContactData.fromJson(json['data'] as Map<String, dynamic>) : null,
    );
  }
}
