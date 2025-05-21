// lib/group/domain/usecase/get_group_messages_use_case.dart
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/group/domain/model/chat_message.dart';
import 'package:devlink_mobile_app/group/domain/repository/group_chat_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class GetGroupMessagesUseCase {
  final GroupChatRepository _repository;

  GetGroupMessagesUseCase({required GroupChatRepository repository})
    : _repository = repository;

  Future<AsyncValue<List<ChatMessage>>> execute(String groupId, {int limit = 50}) async {
    final result = await _repository.getGroupMessages(groupId, limit: limit);

    return switch (result) {
      Success(:final data) => AsyncData(data),
      Error(:final failure) => AsyncError(
        failure,
        failure.stackTrace ?? StackTrace.current,
      ),
    };
  }
}