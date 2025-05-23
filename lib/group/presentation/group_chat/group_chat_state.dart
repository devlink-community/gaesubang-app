// lib/group/presentation/group_chat/group_chat_state.dart
import 'package:devlink_mobile_app/group/domain/model/chat_message.dart';
import 'package:devlink_mobile_app/group/domain/model/group_member.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

part 'group_chat_state.freezed.dart';

@freezed
class GroupChatState with _$GroupChatState {
  const GroupChatState({
    // 그룹 ID
    this.groupId = '',

    // 메시지 목록
    this.messagesResult = const AsyncValue.loading(),

    // 메시지 전송 상태
    this.sendingStatus = const AsyncValue.data(null),

    // 현재 입력 메시지
    this.currentMessage = '',

    // 오류 메시지
    this.errorMessage,

    // 그룹 멤버 목록
    this.groupMembersResult = const AsyncValue.loading(),

    // 현재 사용자 ID
    this.currentUserId = '',

    // 🆕 멤버 검색 관련 상태
    this.memberSearchQuery = '',
    this.isSearchingMembers = false,
  });

  final String groupId;
  final AsyncValue<List<ChatMessage>> messagesResult;
  final AsyncValue<void> sendingStatus;
  final String currentMessage;
  final String? errorMessage;
  final AsyncValue<List<GroupMember>> groupMembersResult;
  final String currentUserId;

  // 🆕 멤버 검색 관련 필드
  final String memberSearchQuery;
  final bool isSearchingMembers;

  // 🆕 필터링된 멤버 목록을 반환하는 getter
  List<GroupMember> get filteredMembers {
    if (groupMembersResult case AsyncData(:final value)) {
      if (memberSearchQuery.isEmpty) {
        return value;
      }

      final query = memberSearchQuery.toLowerCase();
      return value.where((member) {
        return member.userName.toLowerCase().contains(query);
      }).toList();
    }
    return [];
  }
}
