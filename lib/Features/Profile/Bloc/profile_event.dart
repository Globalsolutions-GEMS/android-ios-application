sealed class ProfileEvent {
  const ProfileEvent();
}

class ProfileLoadRequested extends ProfileEvent {
  const ProfileLoadRequested();
}

class ProfileUpdateRequested extends ProfileEvent {
  const ProfileUpdateRequested({
    required this.email,
    required this.mobile,
    this.photoBase64,
  });

  final String email;
  final String mobile;
  final String? photoBase64; // current photo, sent back as-is
}

class ProfilePhotoRemoveRequested extends ProfileEvent {
  const ProfilePhotoRemoveRequested();
}
