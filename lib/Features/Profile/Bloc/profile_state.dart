import 'package:erp_app/Features/Profile/model/profile_model.dart';

sealed class ProfileState {
  const ProfileState();
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileFailure extends ProfileState {
  const ProfileFailure(this.message);

  final String message;
}

/// States that carry the loaded profile.
sealed class ProfileDataState extends ProfileState {
  const ProfileDataState(this.profile);

  final ProfileModel profile;
}

class ProfileLoaded extends ProfileDataState {
  const ProfileLoaded(super.profile);
}

class ProfileSaving extends ProfileDataState {
  const ProfileSaving(super.profile);
}

class ProfileSaveSuccess extends ProfileDataState {
  const ProfileSaveSuccess(super.profile, this.message);

  final String message;
}

class ProfileSaveFailure extends ProfileDataState {
  const ProfileSaveFailure(super.profile, this.message);

  final String message;
}