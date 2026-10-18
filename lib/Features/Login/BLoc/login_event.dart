sealed class LoginEvent {
  const LoginEvent();
}

class LoginSubmitted extends LoginEvent {
  const LoginSubmitted({required this.loginId, required this.password});

  final String loginId;
  final String password;
}
