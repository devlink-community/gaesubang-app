import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_setting_action.freezed.dart';

@freezed
sealed class ProfileSettingAction with _$ProfileSettingAction {
  const factory ProfileSettingAction.onChangeNickname(String nickname) =
      OnChangeNickname;
  const factory ProfileSettingAction.onChangeMessage(String message) =
      OnChangeMessage;
  const factory ProfileSettingAction.onChangePosition(String position) =
      OnChangePosition;
  const factory ProfileSettingAction.onChangeSkills(String skills) =
      OnChangeSkills;
  const factory ProfileSettingAction.onPickImage(File image) = OnPickImage;
  const factory ProfileSettingAction.onSave() = OnSave;
}
