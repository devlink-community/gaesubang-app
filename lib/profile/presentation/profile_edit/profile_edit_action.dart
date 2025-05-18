import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_edit_action.freezed.dart';

@freezed
sealed class ProfileEditAction with _$ProfileEditAction {
  const factory ProfileEditAction.onChangeNickname(String nickname) =
      OnChangeNickname;
  const factory ProfileEditAction.onChangeMessage(String message) =
      OnChangeMessage;
  const factory ProfileEditAction.onChangePosition(String position) =
      OnChangePosition;
  const factory ProfileEditAction.onChangeSkills(String skills) =
      OnChangeSkills;
  const factory ProfileEditAction.onPickImage(File image) = OnPickImage;
  const factory ProfileEditAction.onSave() = OnSave;
}
