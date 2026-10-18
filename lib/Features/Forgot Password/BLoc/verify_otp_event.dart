abstract class VerifyOtpEvent {
  const VerifyOtpEvent();
}

class VerifyOtpSubmitted extends VerifyOtpEvent {
  const VerifyOtpSubmitted({
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
}

class ResendOtp extends VerifyOtpEvent {
  const ResendOtp({
    this.email,
    this.mobile,
    this.studentId,
  });

  final String? email;
  final String? mobile;
  final String? studentId;
}
