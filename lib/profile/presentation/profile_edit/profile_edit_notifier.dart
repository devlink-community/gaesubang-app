import 'dart:io';

import 'package:devlink_mobile_app/auth/domain/usecase/check_nickname_availability_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/get_current_user_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/update_profile_image_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/update_profile_use_case.dart';
import 'package:devlink_mobile_app/auth/module/auth_di.dart';
import 'package:devlink_mobile_app/core/utils/auth_validator.dart';
import 'package:devlink_mobile_app/profile/presentation/profile_edit/profile_edit_action.dart';
import 'package:devlink_mobile_app/profile/presentation/profile_edit/profile_edit_state.dart';
import 'package:devlink_mobile_app/profile/presentation/profile_refresh_state.dart'; // 추가
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_edit_notifier.g.dart';

@riverpod
class ProfileEditNotifier extends _$ProfileEditNotifier {
  late final GetCurrentUserUseCase _getCurrentUserUseCase;
  late final UpdateProfileUseCase _updateProfileUseCase;
  late final UpdateProfileImageUseCase _updateProfileImageUseCase;
  late final CheckNicknameAvailabilityUseCase _checkNicknameUseCase;

  @override
  ProfileEditState build() {
    _getCurrentUserUseCase = ref.watch(getCurrentUserUseCaseProvider);
    _updateProfileUseCase = ref.watch(updateProfileUseCaseProvider);
    _updateProfileImageUseCase = ref.watch(updateProfileImageUseCaseProvider);
    _checkNicknameUseCase = ref.watch(checkNicknameAvailabilityUseCaseProvider);

    return const ProfileEditState();
  }

  Future<void> onAction(ProfileEditAction action) async {
    switch (action) {
      case LoadProfile():
        await _loadProfile();
        break;

      case OnChangeNickname(:final nickname):
        _updateEditingProfile(
          (profile) => profile.copyWith(nickname: nickname),
        );
        _clearFieldError('nickname');
        break;

      case OnChangeDescription(:final description):
        _updateEditingProfile(
          (profile) => profile.copyWith(description: description),
        );
        break;

      case OnChangePosition(:final position):
        _updateEditingProfile(
          (profile) => profile.copyWith(position: position),
        );
        break;

      case OnChangeSkills(:final skills):
        _updateEditingProfile((profile) => profile.copyWith(skills: skills));
        break;

      case CheckNicknameAvailability(:final nickname):
        await _checkNicknameAvailability(nickname);
        break;

      case PickImage():
        await _pickImage();
        break;

      case OnChangeImage(:final imageFile):
        await _updateProfileImage(imageFile);
        break;

      case ValidateForm():
        _validateForm();
        break;

      case SaveProfile():
        await _saveProfile();
        break;

      case ClearErrors():
        _clearErrors();
        break;
    }
  }

  /// 프로필 로드
  Future<void> _loadProfile() async {
    state = state.copyWith(profileState: const AsyncLoading());

    try {
      final result = await _getCurrentUserUseCase.execute();

      if (result case AsyncData(:final value)) {
        state = state.copyWith(
          profileState: AsyncData(value),
          editingProfile: value,
        );
      } else if (result case AsyncError(:final error, :final stackTrace)) {
        state = state.copyWith(profileState: AsyncError(error, stackTrace));
      }
    } catch (e, st) {
      state = state.copyWith(profileState: AsyncError(e, st));
    }
  }

  /// 편집 중인 프로필 업데이트
  void _updateEditingProfile(Function(dynamic) updater) {
    final currentProfile = state.editingProfile;
    if (currentProfile != null) {
      final updatedProfile = updater(currentProfile);
      state = state.copyWith(editingProfile: updatedProfile);
    }
  }

  /// 특정 필드 에러 제거
  void _clearFieldError(String field) {
    final updatedErrors = Map<String, String>.from(state.validationErrors);
    updatedErrors.remove(field);
    state = state.copyWith(validationErrors: updatedErrors);
  }

  /// 모든 에러 초기화
  void _clearErrors() {
    state = state.copyWith(
      validationErrors: {},
      saveState: const AsyncData(null),
      nicknameCheckState: const AsyncData(null),
    );
  }

  /// 닉네임 중복 확인
  Future<void> _checkNicknameAvailability(String nickname) async {
    // 현재 사용자의 닉네임과 같으면 중복 확인하지 않음
    if (state.profileState case AsyncData(:final value)) {
      if (value.nickname == nickname) {
        state = state.copyWith(nicknameCheckState: const AsyncData(true));
        return;
      }
    }

    state = state.copyWith(nicknameCheckState: const AsyncLoading());

    try {
      final result = await _checkNicknameUseCase.execute(nickname);

      if (result case AsyncData(:final value)) {
        state = state.copyWith(nicknameCheckState: AsyncData(value));

        // 닉네임이 중복이면 에러 메시지 추가
        if (!value) {
          final updatedErrors = Map<String, String>.from(
            state.validationErrors,
          );
          updatedErrors['nickname'] = '이미 사용 중인 닉네임입니다';
          state = state.copyWith(validationErrors: updatedErrors);
        }
      } else if (result case AsyncError(:final error, :final stackTrace)) {
        state = state.copyWith(
          nicknameCheckState: AsyncError(error, stackTrace),
        );
      }
    } catch (e, st) {
      state = state.copyWith(nicknameCheckState: AsyncError(e, st));
    }
  }

  /// 이미지 선택
  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        await _updateProfileImage(File(image.path));
      }
    } catch (e) {
      debugPrint('이미지 선택 실패: $e');
    }
  }

  /// 프로필 이미지 업데이트
  Future<void> _updateProfileImage(File imageFile) async {
    try {
      final result = await _updateProfileImageUseCase.execute(imageFile.path);

      if (result case AsyncData(:final value)) {
        // 성공 시 편집 중인 프로필과 로드된 프로필 모두 업데이트
        state = state.copyWith(
          profileState: AsyncData(value),
          editingProfile: value,
        );

        // ✅ 핵심: 이미지 업데이트 성공 시 프로필 갱신 상태 마크
        ref.read(profileRefreshStateProvider.notifier).markForRefresh();

        debugPrint(
          '✅ ProfileEditNotifier: 이미지 업데이트 성공 및 갱신 상태 마크: ${value.image}',
        );
      } else if (result case AsyncError(:final error)) {
        debugPrint('❌ ProfileEditNotifier: 이미지 업데이트 실패: $error');
      }
    } catch (e) {
      debugPrint('❌ ProfileEditNotifier: 이미지 업데이트 예외: $e');
    }
  }

  /// 폼 검증
  void _validateForm() {
    final profile = state.editingProfile;
    if (profile == null) return;

    final Map<String, String> errors = {};

    // 닉네임 검증
    final nicknameError = AuthValidator.validateNickname(profile.nickname);
    if (nicknameError != null) {
      errors['nickname'] = nicknameError;
    }

    // 닉네임 중복 확인 여부 검증
    if (state.profileState case AsyncData(:final value)) {
      final originalProfile = value; // ✅ 올바른 문법
      final isNicknameChanged = originalProfile.nickname != profile.nickname;

      if (isNicknameChanged) {
        // 닉네임이 변경된 경우에만 중복 확인 필요
        if (state.nicknameCheckState case AsyncData(:final value)) {
          final isAvailable = value; // ✅ 올바른 문법
          if (isAvailable == false) {
            errors['nickname'] = '이미 사용 중인 닉네임입니다';
          }
          // isAvailable == true이면 통과
        } else {
          // 중복 확인을 아직 하지 않은 경우
          errors['nickname'] = '닉네임 중복 확인이 필요합니다';
        }
      }
      // 닉네임이 변경되지 않았으면 중복 확인 생략
    }

    state = state.copyWith(validationErrors: errors);

    // 디버깅 로그 추가
    if (errors.isNotEmpty) {
      debugPrint('❌ ProfileEditNotifier: 폼 검증 실패 - $errors');
    } else {
      debugPrint('✅ ProfileEditNotifier: 폼 검증 통과');
    }
  }

  /// 프로필 저장
  Future<void> _saveProfile() async {
    final profile = state.editingProfile;
    if (profile == null) return;

    // 저장 전 폼 검증
    _validateForm();
    if (state.hasValidationErrors) {
      return;
    }

    state = state.copyWith(saveState: const AsyncLoading());

    try {
      final result = await _updateProfileUseCase.execute(
        nickname: profile.nickname,
        description: profile.description,
        position: profile.position,
        skills: profile.skills,
      );

      if (result case AsyncData(:final value)) {
        state = state.copyWith(
          saveState: const AsyncData(true),
          profileState: AsyncData(value),
          editingProfile: value,
        );

        // ✅ 핵심: 프로필 저장 성공 시 프로필 갱신 상태 마크
        ref.read(profileRefreshStateProvider.notifier).markForRefresh();

        debugPrint(
          '✅ ProfileEditNotifier: 프로필 저장 성공 및 갱신 상태 마크: ${value.nickname}',
        );
      } else if (result case AsyncError(:final error, :final stackTrace)) {
        state = state.copyWith(saveState: AsyncError(error, stackTrace));
        debugPrint('❌ ProfileEditNotifier: 프로필 저장 실패: $error');
      }
    } catch (e, st) {
      state = state.copyWith(saveState: AsyncError(e, st));
      debugPrint('❌ ProfileEditNotifier: 프로필 저장 예외: $e');
    }
  }

  /// 편의 메서드: 프로필 로드 (외부에서 호출 가능)
  Future<void> loadProfile() async {
    await onAction(const ProfileEditAction.loadProfile());
  }

  /// 편의 메서드: 특정 닉네임이 변경되었는지 확인
  bool get isNicknameChanged {
    if (state.profileState case AsyncData(:final value)) {
      return value.nickname != state.editingProfile?.nickname;
    }
    return false;
  }

  /// 편의 메서드: 프로필이 변경되었는지 확인
  bool get hasChanges {
    if (state.profileState case AsyncData(:final value)) {
      final editingProfile = state.editingProfile;
      if (editingProfile == null) return false;

      return value.nickname != editingProfile.nickname ||
          value.description != editingProfile.description ||
          value.position != editingProfile.position ||
          value.skills != editingProfile.skills ||
          value.image != editingProfile.image;
    }
    return false;
  }
}
