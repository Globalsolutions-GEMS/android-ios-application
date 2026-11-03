import 'package:erp_app/Features/Profile/Bloc/profile_event.dart';
import 'package:erp_app/Features/Profile/Bloc/profile_state.dart';
import 'package:erp_app/Features/Profile/model/profile_model.dart';
import 'package:erp_app/api_manager/api_checker.dart';
import 'package:erp_app/api_manager/api_client.dart';
import 'package:erp_app/api_manager/api_endPoints.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient(),
      super(const ProfileInitial()) {
    on<ProfileLoadRequested>(_onLoadRequested);
    on<ProfileUpdateRequested>(_onUpdateRequested);
    on<ProfilePhotoRemoveRequested>(_onPhotoRemoveRequested);
  }

  /// Message used by the screen to detect a successful photo removal.
  static const String photoRemovedMessage = 'Photo removed';

  final ApiClient _apiClient;

  Future<void> _onLoadRequested(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());

    try {
      final response = await _apiClient.getData(ApiEndPoints.getProfile);
      final error = ApiChecker.checkApi(response);
      if (error != null) {
        emit(ProfileFailure(error));
        return;
      }
      if (response.body is! Map<String, dynamic>) {
        emit(const ProfileFailure('Invalid profile response.'));
        return;
      }
      emit(
        ProfileLoaded(
          ProfileModel.fromJson(response.body as Map<String, dynamic>),
        ),
      );
    } catch (_) {
      emit(const ProfileFailure('Unable to load profile.'));
    }
  }

  Future<void> _onUpdateRequested(
    ProfileUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    final current = state;
    if (current is! ProfileDataState) return;
    final profile = current.profile;

    emit(ProfileSaving(profile));

    try {
      final response = await _apiClient.putData(
        '${ApiEndPoints.updateUser}/${profile.id}',
        body: profile.toUpdateJson(
          email: event.email,
          mobile: event.mobile,
          photoBase64: event.photoBase64,
        ),
      );
      final error = ApiChecker.checkApi(response);
      if (error != null) {
        emit(ProfileSaveFailure(profile, error));
        return;
      }
      final updated = response.body is Map<String, dynamic>
          ? ProfileModel.fromJson(response.body as Map<String, dynamic>)
          : profile;
      emit(ProfileSaveSuccess(updated, 'Profile updated successfully'));
    } catch (_) {
      emit(ProfileSaveFailure(profile, 'Unable to update profile.'));
    }
  }

  Future<void> _onPhotoRemoveRequested(
    ProfilePhotoRemoveRequested event,
    Emitter<ProfileState> emit,
  ) async {
    final current = state;
    if (current is! ProfileDataState) return;
    final profile = current.profile;

    emit(ProfileSaving(profile));

    try {
      final response = await _apiClient.deleteData(ApiEndPoints.deleteProfile);
      final error = ApiChecker.checkApi(response);
      if (error != null) {
        emit(ProfileSaveFailure(profile, error));
        return;
      }
      emit(ProfileSaveSuccess(profile.withoutPhoto(), photoRemovedMessage));
    } catch (_) {
      emit(ProfileSaveFailure(profile, 'Unable to remove photo.'));
    }
  }
}
