import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_edit_action.freezed.dart';

@freezed
sealed class ProfileEditAction with _$ProfileEditAction {
  /// 프로필 로드 시작
  const factory ProfileEditAction.loadProfile() = LoadProfile;

  /// 닉네임 변경
  const factory ProfileEditAction.onChangeNickname(String nickname) =
      OnChangeNickname;

  /// 소개글 변경
  const factory ProfileEditAction.onChangeDescription(String description) =
      OnChangeDescription;

  /// 직무 변경
  const factory ProfileEditAction.onChangePosition(String position) =
      OnChangePosition;

  /// 스킬 변경
  const factory ProfileEditAction.onChangeSkills(String skills) =
      OnChangeSkills;

  /// 닉네임 중복 확인
  const factory ProfileEditAction.checkNicknameAvailability(String nickname) =
      CheckNicknameAvailability;

  /// 프로필 이미지 선택
  const factory ProfileEditAction.pickImage() = PickImage;

  /// 프로필 이미지 변경 (파일 선택 후)
  const factory ProfileEditAction.onChangeImage(File imageFile) = OnChangeImage;

  /// 폼 검증
  const factory ProfileEditAction.validateForm() = ValidateForm;

  /// 프로필 저장
  const factory ProfileEditAction.saveProfile() = SaveProfile;

  /// 에러 초기화
  const factory ProfileEditAction.clearErrors() = ClearErrors;
}
