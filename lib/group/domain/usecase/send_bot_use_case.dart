// lib/group/domain/usecase/send_bot_message_use_case.dart
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/group/domain/model/chat_message.dart';
import 'package:devlink_mobile_app/group/domain/repository/group_chat_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SendBotMessageUseCase {
  final GroupChatRepository _repository;

  SendBotMessageUseCase({required GroupChatRepository repository})
    : _repository = repository;

  Future<AsyncValue<ChatMessage>> execute(
    String groupId,
    String content,
    String botId,
    String botName,
  ) async {
    final result = await _repository.sendBotMessage(
      groupId,
      content,
      botId,
      botName,
    );

    return switch (result) {
      Success(:final data) => AsyncData(data),
      Error(:final failure) => AsyncError(
        failure,
        failure.stackTrace ?? StackTrace.current,
      ),
    };
  }
}
