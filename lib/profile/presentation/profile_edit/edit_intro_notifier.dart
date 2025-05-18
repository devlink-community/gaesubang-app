import 'dart:io';

import 'package:devlink_mobile_app/profile/domain/use_case/get_current_profile_usecase.dart';
import 'package:devlink_mobile_app/profile/domain/use_case/update_profile_image_usecase.dart';
import 'package:devlink_mobile_app/profile/domain/use_case/update_profile_usecase.dart';
import 'package:devlink_mobile_app/profile/module/edit_intro_di.dart';
import 'package:devlink_mobile_app/profile/presentation/profile_edit/edit_intro_action.dart';
import 'package:devlink_mobile_app/profile/presentation/profile_edit/edit_intro_state.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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

    // 초기 상태만 반환하고, 프로필 로드는 별도 메서드로 분리
    return const EditIntroState();
  }

  // 프로필 로드를 public 메서드로 변경하여 외부에서 호출 가능하게 함
  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, isError: false, errorMessage: null);

    try {
      final result = await _getCurrentProfileUseCase.execute();

      if (result is AsyncData) {
        // 성공적으로 데이터를 받은 경우
        debugPrint(
          '프로필 로드 성공: ${result.value?.nickname}, ${result.value?.description}',
        );

        state = state.copyWith(
          isLoading: false,
          isSuccess: true,
          member: result.value,
        );
      } else if (result is AsyncError) {
        // 에러가 발생한 경우
        debugPrint('프로필 로드 실패: ${result.error}');

        state = state.copyWith(
          isLoading: false,
          isError: true,
          errorMessage: result.error.toString(),
        );
      }
    } catch (e) {
      // 예외 처리
      debugPrint('프로필 로드 예외: $e');

      state = state.copyWith(
        isLoading: false,
        isError: true,
        errorMessage: '프로필을 불러오는 데 실패했습니다: ${e.toString()}',
      );
    }
  }

  Future<void> onAction(EditIntroAction action) async {
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
      final xFile = XFile(image.path);
      debugPrint('이미지 업로드 시작: ${xFile.path}');

      final result = await _updateProfileImageUseCase.execute(xFile);

      // 이미지 업로드 결과 처리 - AsyncValue에 따라 분기
      if (result.hasValue) {
        debugPrint('이미지 업로드 성공: ${result.value!.image}');

        state = state.copyWith(
          isImageUploading: false,
          isImageUploadSuccess: true,
          member: result.value,
        );
      } else if (result.hasError) {
        debugPrint('이미지 업로드 실패: ${result.error}');

        state = state.copyWith(
          isImageUploading: false,
          isImageUploadError: true,
          imageUploadErrorMessage: result.error.toString(),
        );
      }
    } catch (e) {
      debugPrint('이미지 업로드 예외: $e');

      state = state.copyWith(
        isImageUploading: false,
        isImageUploadError: true,
        imageUploadErrorMessage: '프로필 이미지를 업데이트할 수 없습니다: ${e.toString()}',
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

    // 디버그 로그 추가
    debugPrint(
      '프로필 저장 시작: ${state.member!.nickname}, ${state.member!.description}, ${state.member!.position}, ${state.member!.skills}',
    );

    try {
      final result = await _updateProfileUseCase.execute(
        nickname: state.member!.nickname,
        intro: state.member!.description,
        position: state.member!.position,
        skills: state.member!.skills,
      );

      // 저장 결과 처리 - AsyncValue에 따라 분기
      if (result.hasValue) {
        // 성공 시 디버그 로그 추가
        debugPrint(
          '프로필 저장 성공: ${result.value!.nickname}, ${result.value!.description}, ${result.value!.position}, ${result.value!.skills}',
        );

        state = state.copyWith(
          isLoading: false,
          isSuccess: true,
          member: result.value,
        );
        return true;
      } else if (result.hasError) {
        // 실패 시 디버그 로그 추가
        debugPrint('프로필 저장 실패: ${result.error}');

        state = state.copyWith(
          isLoading: false,
          isError: true,
          errorMessage: result.error.toString(),
        );
        return false;
      }
      return false;
    } catch (e) {
      // 예외 발생 시 디버그 로그 추가
      debugPrint('프로필 저장 예외: $e');

      state = state.copyWith(
        isLoading: false,
        isError: true,
        errorMessage: '프로필 정보를 수정할 수 없습니다: ${e.toString()}',
      );
      return false;
    }
  }
}
