abstract class ForgotPasswordEvent {
  const ForgotPasswordEvent();
}

class ForgotPasswordSubmitted extends ForgotPasswordEvent {
  const ForgotPasswordSubmitted({
    required this.methodIndex,
    required this.inputValue,
  });

  final int methodIndex; // 0 = Email, 1 = Mobile, 2 = Student ID
  final String inputValue;
}
