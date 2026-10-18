abstract class VerifyOtpState {
  const VerifyOtpState();
}

class VerifyOtpInitial extends VerifyOtpState {
  const VerifyOtpInitial();
}

class VerifyOtpLoading extends VerifyOtpState {
  const VerifyOtpLoading();
}

class VerifyOtpSuccess extends VerifyOtpState {
  const VerifyOtpSuccess();
}

class VerifyOtpFailure extends VerifyOtpState {
  const VerifyOtpFailure(this.message);

  final String message;
}
