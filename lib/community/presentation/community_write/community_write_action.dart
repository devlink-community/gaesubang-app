// lib/community/presentation/community_write/community_write_action.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart' show Uint8List;

part 'community_write_action.freezed.dart';

@freezed
sealed class CommunityWriteAction with _$CommunityWriteAction {
  const factory CommunityWriteAction.titleChanged(String title) = TitleChanged;
  const factory CommunityWriteAction.contentChanged(String content) = ContentChanged;
  const factory CommunityWriteAction.tagAdded(String tag) = TagAdded;
  const factory CommunityWriteAction.tagRemoved(String tag) = TagRemoved;
  const factory CommunityWriteAction.imageAdded(Uint8List bytes) = ImageAdded;
  const factory CommunityWriteAction.imageRemoved(int index) = ImageRemoved;
  const factory CommunityWriteAction.submit() = Submit;
  const factory CommunityWriteAction.navigateBack(String postId) = NavigateBack;
}