import 'dart:io';

import 'package:devlink_mobile_app/edit_intro/presentation/edit_intro_action.dart';
import 'package:devlink_mobile_app/edit_intro/presentation/states/edit_intro_state.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/usecase/get_current_profile_usecase.dart';
import '../domain/usecase/update_profile_image_usecase.dart';
import '../domain/usecase/update_profile_usecase.dart';
import '../module/edit_intro_di.dart';

part 'edit_intro_notifier.g.dart';

@riverpod
class EditIntroNotifier extends _$EditIntroNotifier {
  late final GetCurrentProfileUseCase _getCurrentProfileUseCase;
  late final UpdateProfileUseCase _updateProfileUseCase;
  late final UpdateProfileImageUseCase _updateProfileImageUseCase;

  @override
  EditIntroState build() {
    _getCurrentProfileUseCase = ref.watch(getCurrentProfileUseCaseProvider);
    _updateProfileUseCase = ref.watch(updateProfileUseCaseProvider);
    _updateProfileImageUseCase = ref.watch(updateProfileImageUseCaseProvider);

    // 초기 상태 반환 및 프로필 로드 시작
    _loadProfile();

    return const EditIntroState();
  }

  // 나머지 메서드는 이전 코드와 동일...
  Future<void> _loadProfile() async {
    state = state.copyWith(isLoading: true, isError: false, errorMessage: null);

    try {
      final member = await _getCurrentProfileUseCase.execute();
      state = state.copyWith(isLoading: false, isSuccess: true, member: member);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isError: true,
        errorMessage: '프로필 정보를 불러올 수 없습니다.',
      );
    }
  }

  Future<void> onAction(EditIntroAction action) async {
    switch (action) {
      case OnChangeNickname(:final nickname):
        if (state.member != null) {
          final updatedMember = state.member!.copyWith(nickname: nickname);
          state = state.copyWith(member: updatedMember);
        }
        break;

      case OnChangeMessage(:final message):
        if (state.member != null) {
          final updatedMember = state.member!.copyWith(description: message);
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

  Future<void> _updateProfileImage(File image) async {
    state = state.copyWith(
      isImageUploading: true,
      isImageUploadError: false,
      imageUploadErrorMessage: null,
    );

    try {
      final xFile = XFile(image.path);
      final updatedMember = await _updateProfileImageUseCase.execute(xFile);
      state = state.copyWith(
        isImageUploading: false,
        isImageUploadSuccess: true,
        member: updatedMember,
      );
    } catch (e) {
      state = state.copyWith(
        isImageUploading: false,
        isImageUploadError: true,
        imageUploadErrorMessage: '프로필 이미지를 업데이트할 수 없습니다.',
      );
    }
  }

  Future<bool> _saveProfile() async {
    if (state.member == null) return false;

    state = state.copyWith(isLoading: true, isError: false, errorMessage: null);

    try {
      final updatedMember = await _updateProfileUseCase.execute(
        nickname: state.member!.nickname,
        intro: state.member!.description,
      );
      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        member: updatedMember,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isError: true,
        errorMessage: '프로필 정보를 수정할 수 없습니다.',
      );
      return false;
    }
  }
}
