abstract class ResetPasswordEvent {
  const ResetPasswordEvent();
}

class ResetPasswordSubmitted extends ResetPasswordEvent {
  const ResetPasswordSubmitted({
    required this.newPassword,
    required this.confirmNewPassword,
    required this.otp,
    this.email,
    this.mobile,
    this.studentId,
  });

  final String newPassword;
  final String confirmNewPassword;
  final String otp;
  final String? email;
  final String? mobile;
  final String? studentId;
}
