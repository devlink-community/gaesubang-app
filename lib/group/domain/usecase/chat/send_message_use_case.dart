// lib/group/domain/usecase/send_message_use_case.dart
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/group/domain/model/chat_message.dart';
import 'package:devlink_mobile_app/group/domain/repository/group_chat_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SendMessageUseCase {
  final GroupChatRepository _repository;

  SendMessageUseCase({required GroupChatRepository repository})
    : _repository = repository;

  Future<AsyncValue<ChatMessage>> execute(String groupId, String content) async {
    final result = await _repository.sendMessage(groupId, content);

    return switch (result) {
      Success(:final data) => AsyncData(data),
      Error(:final failure) => AsyncError(
        failure,
        failure.stackTrace ?? StackTrace.current,
      ),
    };
  }
}