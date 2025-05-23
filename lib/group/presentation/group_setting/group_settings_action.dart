// lib/group/presentation/group_settings/group_settings_action.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_settings_action.freezed.dart';

@freezed
class GroupSettingsAction with _$GroupSettingsAction {
  const factory GroupSettingsAction.nameChanged(String name) = NameChanged;
  const factory GroupSettingsAction.descriptionChanged(String description) =
  DescriptionChanged;
  const factory GroupSettingsAction.limitMemberCountChanged(int count) =
  LimitMemberCountChanged;
  const factory GroupSettingsAction.imageUrlChanged(String? imageUrl) =
  ImageUrlChanged;
  const factory GroupSettingsAction.hashTagAdded(String tag) = HashTagAdded;
  const factory GroupSettingsAction.hashTagRemoved(String tag) = HashTagRemoved;
  const factory GroupSettingsAction.toggleEditMode() = ToggleEditMode;
  const factory GroupSettingsAction.save() = Save;
  const factory GroupSettingsAction.leaveGroup() = LeaveGroup;
  const factory GroupSettingsAction.selectImage() = SelectImage;
  const factory GroupSettingsAction.refresh() = Refresh; // 수동 새로고침 액션

  // 🔧 새로 추가: 멤버 페이지네이션 관련 액션들
  const factory GroupSettingsAction.loadMoreMembers() = LoadMoreMembers;
  const factory GroupSettingsAction.retryLoadMembers() = RetryLoadMembers;
  const factory GroupSettingsAction.resetMemberPagination() = ResetMemberPagination;
}