// lib/group/domain/usecase/mark_messages_as_read_use_case.dart
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/group/domain/repository/group_chat_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class MarkMessagesAsReadUseCase {
  final GroupChatRepository _repository;

  MarkMessagesAsReadUseCase({required GroupChatRepository repository})
    : _repository = repository;

  Future<AsyncValue<void>> execute(String groupId) async {
    final result = await _repository.markMessagesAsRead(groupId);

    return switch (result) {
      Success() => const AsyncData(null),
      Error(:final failure) => AsyncError(
        failure,
        failure.stackTrace ?? StackTrace.current,
      ),
    };
  }
}