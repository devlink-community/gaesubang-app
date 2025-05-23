// lib/group/presentation/group_create/group_create_action.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_create_action.freezed.dart';

@freezed
class GroupCreateAction with _$GroupCreateAction {
  const factory GroupCreateAction.nameChanged(String name) = NameChanged;
  const factory GroupCreateAction.descriptionChanged(String description) =
      DescriptionChanged;
  const factory GroupCreateAction.limitMemberCountChanged(int count) =
      LimitMemberCountChanged;
  const factory GroupCreateAction.hashTagAdded(String tag) = HashTagAdded;
  const factory GroupCreateAction.hashTagRemoved(String tag) = HashTagRemoved;
  const factory GroupCreateAction.imageUrlChanged(String? imageUrl) =
      ImageUrlChanged;
  const factory GroupCreateAction.memberInvited(String userId) = MemberInvited;
  const factory GroupCreateAction.memberRemoved(String userId) = MemberRemoved;
  const factory GroupCreateAction.submit() = Submit;
  const factory GroupCreateAction.cancel() = Cancel;
  const factory GroupCreateAction.selectImage() = SelectImage;
}
