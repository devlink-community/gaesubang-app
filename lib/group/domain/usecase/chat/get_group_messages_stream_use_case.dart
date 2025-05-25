// lib/group/domain/usecase/get_group_messages_stream_use_case.dart
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/group/domain/model/chat_message.dart';
import 'package:devlink_mobile_app/group/domain/repository/group_chat_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class GetGroupMessagesStreamUseCase {
  final GroupChatRepository _repository;

  GetGroupMessagesStreamUseCase({required GroupChatRepository repository})
    : _repository = repository;

  Stream<AsyncValue<List<ChatMessage>>> execute(String groupId) {
    return _repository.getGroupMessagesStream(groupId).map(
      (result) => switch (result) {
        Success(:final data) => AsyncData(data),
        Error(:final failure) => AsyncError(
          failure,
          failure.stackTrace ?? StackTrace.current,
        ),
      },
    );
  }
}