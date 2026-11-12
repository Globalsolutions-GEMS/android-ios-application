sealed class ChangePasswordState {
  const ChangePasswordState();
}

class ChangePasswordInitial extends ChangePasswordState {
  const ChangePasswordInitial();
}

class ChangePasswordLoading extends ChangePasswordState {
  const ChangePasswordLoading();
}

class ChangePasswordLoaded extends ChangePasswordState {
  const ChangePasswordLoaded(this.message);

  final String message;
}

class ChangePasswordFailed extends ChangePasswordState {
  const ChangePasswordFailed(this.message);

  final String message;
}
