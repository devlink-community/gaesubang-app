// lib/group/data/repository_impl/group_chat_repository_impl.dart
import 'dart:async';
import 'dart:convert';

import 'package:devlink_mobile_app/core/auth/auth_provider.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/group/data/data_source/group_chat_data_source.dart';
import 'package:devlink_mobile_app/group/data/dto/group_chat_message_dto.dart';
import 'package:devlink_mobile_app/group/data/mapper/group_chat_message_mapper.dart';
import 'package:devlink_mobile_app/group/domain/model/chat_message.dart';
import 'package:devlink_mobile_app/group/domain/repository/group_chat_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class GroupChatRepositoryImpl implements GroupChatRepository {
  final GroupChatDataSource _dataSource;
  final Ref _ref;

  GroupChatRepositoryImpl({
    required GroupChatDataSource dataSource,
    required Ref ref,
  }) : _dataSource = dataSource,
       _ref = ref;

  @override
  Future<Result<List<ChatMessage>>> getGroupMessages(
    String groupId, {
    int limit = 50,
  }) async {
    try {
      final messagesData = await _dataSource.fetchGroupMessages(
        groupId,
        limit: limit,
      );

      // Map<String, dynamic> → GroupChatMessageDto → ChatMessage 변환
      final messageDtos =
          messagesData
              .map((data) => GroupChatMessageDto.fromJson(data))
              .toList();
      final messages = messageDtos.toModelList();

      return Result.success(messages);
    } catch (e, st) {
      return Result.error(
        Failure(
          FailureType.server,
          '채팅 메시지를 불러오는데 실패했습니다',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<ChatMessage>> sendMessage(
    String groupId,
    String content,
  ) async {
    try {
      // 현재 사용자 정보 가져오기
      final currentUser = _ref.read(currentUserProvider);
      if (currentUser == null) {
        return Result.error(
          const Failure(FailureType.unauthorized, '로그인이 필요합니다'),
        );
      }

      // 메시지 크기 검증 (1KB 제한)
      final bytes = utf8.encode(content);
      if (bytes.length > 1024) {
        return Result.error(
          const Failure(FailureType.validation, '메시지 크기가 1KB를 초과합니다'),
        );
      }

      // 메시지 전송
      final messageData = await _dataSource.sendMessage(
        groupId,
        content,
        currentUser.id,
        currentUser.nickname,
        currentUser.image,
      );

      // 변환 및 반환
      final messageDto = GroupChatMessageDto.fromJson(messageData);
      final message = messageDto.toModel();

      return Result.success(message);
    } catch (e, st) {
      return Result.error(
        Failure(FailureType.server, '메시지 전송에 실패했습니다', cause: e, stackTrace: st),
      );
    }
  }

  @override
  Stream<Result<List<ChatMessage>>> getGroupMessagesStream(String groupId) {
    return _dataSource
        .streamGroupMessages(groupId)
        .map((messagesData) {
          try {
            // 데이터 변환
            final messageDtos =
                messagesData
                    .map((data) => GroupChatMessageDto.fromJson(data))
                    .toList();
            final messages = messageDtos.toModelList();

            // 스트림으로 Success 결과 반환
            return Result<List<ChatMessage>>.success(messages);
          } catch (e, st) {
            // 스트림으로 Error 결과 반환
            return Result<List<ChatMessage>>.error(
              Failure(
                FailureType.server,
                '채팅 메시지 처리 중 오류가 발생했습니다',
                cause: e,
                stackTrace: st,
              ),
            );
          }
        })
        .transform(
          StreamTransformer<
            Result<List<ChatMessage>>,
            Result<List<ChatMessage>>
          >.fromHandlers(
            handleError: (error, stackTrace, sink) {
              sink.add(
                Result.error(
                  Failure(
                    FailureType.server,
                    '채팅 스트림 구독 중 오류가 발생했습니다',
                    cause: error,
                    stackTrace: stackTrace,
                  ),
                ),
              );
            },
          ),
        );
  }

  @override
  Future<Result<void>> markMessagesAsRead(String groupId) async {
    try {
      // 현재 사용자 정보 가져오기
      final currentUser = _ref.read(currentUserProvider);
      if (currentUser == null) {
        return Result.error(
          const Failure(FailureType.unauthorized, '로그인이 필요합니다'),
        );
      }

      // 읽음 처리
      await _dataSource.markMessagesAsRead(groupId, currentUser.id);

      return const Result.success(null);
    } catch (e, st) {
      return Result.error(
        Failure(
          FailureType.server,
          '메시지 읽음 처리에 실패했습니다',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<ChatMessage>> sendBotMessage(
    String groupId,
    String content,
    String botId,
    String botName,
  ) async {
    try {
      // 메시지 크기 검증 (1KB 제한)
      final bytes = utf8.encode(content);
      if (bytes.length > 1024) {
        return Result.error(
          const Failure(FailureType.validation, '메시지 크기가 1KB를 초과합니다'),
        );
      }

      // 🔧 봇 메시지 직접 전송 (현재 사용자 정보 사용 안 함)
      final messageData = await _dataSource.sendMessage(
        groupId,
        content,
        botId, // 🔧 봇 ID 직접 전달
        botName, // 🔧 봇 이름 직접 전달
        null, // 봇은 이미지 없음
      );

      // 변환 및 반환
      final messageDto = GroupChatMessageDto.fromJson(messageData);
      final message = messageDto.toModel();

      return Result.success(message);
    } catch (e, st) {
      return Result.error(
        Failure(
          FailureType.server,
          '봇 메시지 전송에 실패했습니다',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }
}
