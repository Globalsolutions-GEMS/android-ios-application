sealed class LoginState {
  const LoginState();
}

class LoginInitial extends LoginState {
  const LoginInitial();
}

class LoginLoading extends LoginState {
  const LoginLoading();
}

class LoginSuccess extends LoginState {
  const LoginSuccess(this.message, {this.roleName = ''});

  final String message;
  final String roleName; // e.g. "ADMIN", "STUDENT"
}

class LoginFailure extends LoginState {
  const LoginFailure(this.message);

  final String message;
}
