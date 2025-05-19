import 'dart:io';

import 'package:devlink_mobile_app/auth/domain/usecase/get_current_user_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/update_profile_image_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/update_profile_use_case.dart';
import 'package:devlink_mobile_app/auth/module/auth_di.dart';
import 'package:devlink_mobile_app/core/utils/profile_error_messages.dart';
import 'package:devlink_mobile_app/profile/presentation/profile_edit/profile_edit_action.dart';
import 'package:devlink_mobile_app/profile/presentation/profile_edit/profile_edit_state.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_edit_notifier.g.dart';

@riverpod
class ProfileEditNotifier extends _$ProfileEditNotifier {
  late final GetCurrentUserUseCase _getCurrentUserUseCase;
  late final UpdateProfileUseCase _updateProfileUseCase;
  late final UpdateProfileImageUseCase _updateProfileImageUseCase;

  @override
  ProfileEditState build() {
    _getCurrentUserUseCase = ref.watch(getCurrentUserUseCaseProvider);
    _updateProfileUseCase = ref.watch(updateProfileUseCaseProvider);
    _updateProfileImageUseCase = ref.watch(updateProfileImageUseCaseProvider);

    return const ProfileEditState();
  }

  // 프로필 로드를 public 메서드로 변경하여 외부에서 호출 가능하게 함
  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, isError: false, errorMessage: null);

    try {
      final result = await _getCurrentUserUseCase.execute();

      if (result is AsyncData) {
        debugPrint(
          '프로필 로드 성공: ${result.value?.nickname}, ${result.value?.description}',
        );

        state = state.copyWith(
          isLoading: false,
          isSuccess: true,
          member: result.value,
        );
      } else if (result is AsyncError) {
        debugPrint('프로필 로드 실패: ${result.error}');

        state = state.copyWith(
          isLoading: false,
          isError: true,
          errorMessage: ProfileErrorMessages.profileLoadFailed,
        );
      }
    } catch (e) {
      debugPrint('프로필 로드 예외: $e');

      state = state.copyWith(
        isLoading: false,
        isError: true,
        errorMessage: ProfileErrorMessages.profileLoadFailed,
      );
    }
  }

  Future<void> onAction(ProfileEditAction action) async {
    switch (action) {
      case OnChangeNickname(:final nickname):
        if (state.member != null) {
          debugPrint('닉네임 변경: $nickname');
          final updatedMember = state.member!.copyWith(nickname: nickname);
          state = state.copyWith(member: updatedMember);
        }
        break;

      case OnChangeMessage(:final message):
        if (state.member != null) {
          debugPrint('소개글 변경: $message');
          final updatedMember = state.member!.copyWith(description: message);
          state = state.copyWith(member: updatedMember);
        }
        break;

      case OnChangePosition(:final position):
        if (state.member != null) {
          debugPrint('직무 변경: $position');
          final updatedMember = state.member!.copyWith(position: position);
          state = state.copyWith(member: updatedMember);
        }
        break;

      case OnChangeSkills(:final skills):
        if (state.member != null) {
          debugPrint('스킬 변경: $skills');
          final updatedMember = state.member!.copyWith(skills: skills);
          state = state.copyWith(member: updatedMember);
        }
        break;

      case OnPickImage(:final image):
        await _updateProfileImage(image);
        break;

      case OnSave():
        await _saveProfile();
        break;
    }
  }

  Future<void> updateProfileImage(XFile image) async {
    await _updateProfileImage(File(image.path));
  }

  Future<void> _updateProfileImage(File image) async {
    state = state.copyWith(
      isImageUploading: true,
      isImageUploadError: false,
      imageUploadErrorMessage: null,
    );

    try {
      debugPrint('이미지 업로드 시작: ${image.path}');

      final result = await _updateProfileImageUseCase.execute(image.path);

      if (result is AsyncData && result.value != null) {
        state = state.copyWith(
          isImageUploading: false,
          isImageUploadSuccess: true,
          member: result.value,
        );
        debugPrint('이미지 업로드 성공: ${result.value!.image}');
      } else {
        state = state.copyWith(
          isImageUploading: false,
          isImageUploadError: true,
          imageUploadErrorMessage: ProfileErrorMessages.imageUploadFailed,
        );
        debugPrint('이미지 업로드 실패: ${result.error}');
      }
    } catch (e) {
      debugPrint('이미지 업로드 예외: $e');

      state = state.copyWith(
        isImageUploading: false,
        isImageUploadError: true,
        imageUploadErrorMessage: ProfileErrorMessages.imageUpdateFailed,
      );
    }
  }

  Future<bool> updateProfile({required String nickname, String? intro}) async {
    final updated = state.member?.copyWith(
      nickname: nickname,
      description: intro ?? state.member?.description ?? '',
    );

    if (updated != null) {
      state = state.copyWith(member: updated);
    }

    return await _saveProfile();
  }

  Future<bool> _saveProfile() async {
    if (state.member == null) return false;

    state = state.copyWith(isLoading: true, isError: false, errorMessage: null);

    debugPrint(
      '프로필 저장 시작: ${state.member!.nickname}, ${state.member!.description}, ${state.member!.position}, ${state.member!.skills}',
    );

    try {
      final result = await _updateProfileUseCase.execute(
        nickname: state.member!.nickname,
        description: state.member!.description,
        position: state.member!.position,
        skills: state.member!.skills,
      );

      if (result is AsyncData && result.value != null) {
        state = state.copyWith(
          isLoading: false,
          isSuccess: true,
          member: result.value,
        );
        debugPrint('프로필 저장 성공: ${result.value!.nickname}');
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          isError: true,
          errorMessage: ProfileErrorMessages.profileUpdateFailed,
        );
        debugPrint('프로필 저장 실패: ${result.error}');
        return false;
      }
    } catch (e) {
      debugPrint('프로필 저장 예외: $e');

      state = state.copyWith(
        isLoading: false,
        isError: true,
        errorMessage: ProfileErrorMessages.profileUpdateFailed,
      );
      return false;
    }
  }
}
