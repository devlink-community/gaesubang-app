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

    return const EditIntroState();
  }

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, isError: false, errorMessage: null);

    final memberResult = await _getCurrentProfileUseCase.execute();

    memberResult.when(
      data: (member) {
        state = state.copyWith(
          isLoading: false,
          isSuccess: true,
          member: member,
        );
      },
      error: (error, stackTrace) {
        state = state.copyWith(
          isLoading: false,
          isError: true,
          errorMessage: '프로필 정보를 불러올 수 없습니다.',
        );
      },
      loading: () {
        // 이미 위에서 loading 상태로 설정했으므로 여기서는 추가 작업 없음
      },
    );
  }

  Future<void> onAction(EditIntroAction action) async {
    switch (action) {
      case OnChangeNickname(:final nickname):
        _handleChangeNickname(nickname);
      case OnChangeMessage(:final message):
        _handleChangeMessage(message);
      case OnPickImage(:final image):
        await _updateProfileImage(image);
      case OnSave():
        await _saveProfile();
    }
  }

  void _handleChangeNickname(String nickname) {
    if (state.member != null) {
      final updatedMember = state.member!.copyWith(nickname: nickname);
      state = state.copyWith(member: updatedMember);
    }
  }

  void _handleChangeMessage(String message) {
    if (state.member != null) {
      final updatedMember = state.member!.copyWith(description: message);
      state = state.copyWith(member: updatedMember);
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
      final updatedMemberResult = await _updateProfileImageUseCase.execute(
        xFile,
      );

      updatedMemberResult.when(
        data: (updatedMember) {
          state = state.copyWith(
            isImageUploading: false,
            isImageUploadSuccess: true,
            member: updatedMember,
          );
        },
        error: (error, stackTrace) {
          state = state.copyWith(
            isImageUploading: false,
            isImageUploadError: true,
            imageUploadErrorMessage: '프로필 이미지를 업데이트할 수 없습니다.',
          );
        },
        loading: () {
          // 이미 로딩 상태로 설정했으므로 추가 작업 없음
        },
      );
    } catch (e) {
      state = state.copyWith(
        isImageUploading: false,
        isImageUploadError: true,
        imageUploadErrorMessage: '프로필 이미지를 업데이트할 수 없습니다.',
      );
    }
  }

  Future<void> _saveProfile() async {
    if (state.member == null) return;

    state = state.copyWith(isLoading: true, isError: false, errorMessage: null);

    try {
      final updatedMemberResult = await _updateProfileUseCase.execute(
        nickname: state.member!.nickname,
        intro: state.member!.description,
      );

      updatedMemberResult.when(
        data: (updatedMember) {
          state = state.copyWith(
            isLoading: false,
            isSuccess: true,
            member: updatedMember,
          );
        },
        error: (error, stackTrace) {
          state = state.copyWith(
            isLoading: false,
            isError: true,
            errorMessage: '프로필 정보를 수정할 수 없습니다.',
          );
        },
        loading: () {
          // 이미 로딩 상태로 설정했으므로 추가 작업 없음
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isError: true,
        errorMessage: '프로필 정보를 수정할 수 없습니다.',
      );
    }
  }
}
