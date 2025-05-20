// lib/group/presentation/group_chat/group_chat_notifier.dart 수정

import 'dart:async';
import 'package:devlink_mobile_app/group/domain/model/chat_message.dart';
import 'package:devlink_mobile_app/group/presentation/group_chat/group_chat_action.dart';
import 'package:devlink_mobile_app/group/presentation/group_chat/group_chat_state.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'group_chat_notifier.g.dart';

/// 그룹 채팅 Notifier 프로바이더
@riverpod
class GroupChatNotifier extends _$GroupChatNotifier {
  // 메시지 스트림 구독
  StreamSubscription<List<ChatMessage>>? _messagesSubscription;
  
  // 페이지 당 메시지 수
  static const int _messagesPerPage = 20;
  
  // Mock 고정 메시지 
  final List<ChatMessage> _mockMessages = [];
  
  // Mock 사용자 데이터
  final String _currentUserId = 'user1';
  final Map<String, String> _userNames = {
    'user1': '사용자1',
    'user2': '사용자2',
    'user3': '사용자3',
    'user4': '사용자4',
    'user5': '사용자5',
  };
  final Map<String, String> _userImages = {
    'user1': 'https://randomuser.me/api/portraits/men/1.jpg',
    'user2': 'https://randomuser.me/api/portraits/women/2.jpg',
    'user3': 'https://randomuser.me/api/portraits/men/3.jpg',
    'user4': 'https://randomuser.me/api/portraits/women/4.jpg',
    'user5': 'https://randomuser.me/api/portraits/men/5.jpg',
  };

  @override
  GroupChatState build() {
    ref.onDispose(() {
      // 화면 이탈 시 스트림 구독 해제
      _messagesSubscription?.cancel();
    });
    
    // Mock data initialization for development
    _initMockMessages();

    // 기본 상태 반환
    return const GroupChatState();
  }

  // Mock 메시지 초기화 (Firebase 연동 전까지 테스트용)
  void _initMockMessages() {
    // 다른 사용자 ID 목록 (현재 사용자 제외)
    final otherUserIds = _userNames.keys.where((id) => id != _currentUserId).toList();
    
    // Mock 메시지 생성 (최근 순으로 정렬됨)
    final now = DateTime.now();
    
    // 첫 번째 메시지 (5일 전)
    _mockMessages.add(ChatMessage(
      id: 'msg1',
      groupId: 'group_1',
      content: '안녕하세요! 그룹에 오신 것을 환영합니다.',
      senderId: otherUserIds[0],
      senderName: _userNames[otherUserIds[0]]!,
      senderImage: _userImages[otherUserIds[0]],
      timestamp: now.subtract(const Duration(days: 5, hours: 3)),
      isRead: true,
    ));
    
    // 두 번째 메시지 (3일 전)
    _mockMessages.add(ChatMessage(
      id: 'msg2', 
      groupId: 'group_1',
      content: '소금빵 팀 모두 반갑습니다! 개발 열심히 해봐요.',
      senderId: otherUserIds[1],
      senderName: _userNames[otherUserIds[1]]!,
      senderImage: _userImages[otherUserIds[1]],
      timestamp: now.subtract(const Duration(days: 3, hours: 5, minutes: 32)),
      isRead: true,
    ));
    
    // 세 번째 메시지 (2일 전 - 현재 사용자)
    _mockMessages.add(ChatMessage(
      id: 'msg3',
      groupId: 'group_1',
      content: '저도 반갑습니다! 함께 열심히 해보아요.',
      senderId: _currentUserId,
      senderName: _userNames[_currentUserId]!,
      senderImage: _userImages[_currentUserId],
      timestamp: now.subtract(const Duration(days: 2, hours: 1, minutes: 10)),
      isRead: true,
    ));
    
    // 네 번째 메시지 (1일 전)
    _mockMessages.add(ChatMessage(
      id: 'msg4',
      groupId: 'group_1',
      content: '오늘도 모두 화이팅입니다! 그룹 타이머 기능은 정말 좋네요.',
      senderId: otherUserIds[2],
      senderName: _userNames[otherUserIds[2]]!,
      senderImage: _userImages[otherUserIds[2]],
      timestamp: now.subtract(const Duration(days: 1, hours: 4, minutes: 23)),
      isRead: true,
    ));
    
    // 다섯 번째 메시지 (오늘 - 현재 사용자)
    _mockMessages.add(ChatMessage(
      id: 'msg5',
      groupId: 'group_1',
      content: '네, 정말 좋은 것 같습니다. 오늘 채팅 기능도 추가되어 더 좋아질 것 같아요!',
      senderId: _currentUserId,
      senderName: _userNames[_currentUserId]!,
      senderImage: _userImages[_currentUserId],
      timestamp: now.subtract(const Duration(hours: 3, minutes: 45)),
      isRead: true,
    ));
    
    // 최신 순으로 정렬
    _mockMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // 액션 처리
  Future<void> onAction(GroupChatAction action) async {
    switch (action) {
      case SetGroupId(:final groupId):
        _handleSetGroupId(groupId);
        
      case LoadMessages():
        await _handleLoadMessages();
        
      case LoadMoreMessages():
        await _handleLoadMoreMessages();
        
      case SendMessage(:final content):
        await _handleSendMessage(content);
        
      case DeleteMessage(:final messageId):
        await _handleDeleteMessage(messageId);
        
      case AttachImage(:final imagePath):
        await _handleAttachImage(imagePath);
    }
  }

  // 그룹 ID 설정 및 초기 데이터 로딩
  void _handleSetGroupId(String groupId) {
    // 그룹 ID 설정
    state = state.copyWith(
      groupId: groupId,
      currentUserId: _currentUserId,
    );
    
    // 그룹 정보 로딩 - Mock 데이터 사용
    _loadGroupInfo(groupId);
    
    // 메시지 로드
    _handleLoadMessages();
  }

  // 그룹 정보 로딩 (Mock)
  void _loadGroupInfo(String groupId) {
    // Mock 그룹 정보
    const mockGroupNames = {
      'group_0': '소금빵 스터디',
      'group_1': '개발자 그룹',
      'group_2': '플러터 마스터즈',
      'group_3': '코딩 모임',
    };
    
    // 그룹 정보 설정
    state = state.copyWith(
      groupName: mockGroupNames[groupId] ?? '그룹 채팅',
    );
  }

  // 메시지 로드
  Future<void> _handleLoadMessages() async {
    try {
      // 로딩 상태로 변경
      state = state.copyWith(
        messages: const AsyncValue.loading(),
      );
      
      // 실제 구현에서는 Firebase에서 데이터 가져오기
      // Mock 데이터 사용 (1초 지연)
      await Future.delayed(const Duration(seconds: 1));
      
      // 해당 그룹의 메시지만 필터링
      final groupMessages = _mockMessages
          .where((msg) => msg.groupId == state.groupId)
          .take(_messagesPerPage)
          .toList();
      
      // 상태 업데이트
      state = state.copyWith(
        messages: AsyncValue.data(groupMessages),
        lastMessageId: groupMessages.isEmpty ? null : groupMessages.last.id,
        hasReachedEnd: groupMessages.length < _messagesPerPage,
      );
    } catch (e) {
      // 에러 처리
      state = state.copyWith(
        messages: AsyncValue.error(e, StackTrace.current),
        errorMessage: '메시지를 불러오는 중 오류가 발생했습니다: $e',
      );
    }
  }

  // 추가 메시지 로드 (페이지네이션)
  Future<void> _handleLoadMoreMessages() async {
    // 이미 모든 메시지를 로드했거나 로딩 중이면 무시
    if (state.hasReachedEnd || state.isLoadingMore) return;
    
    try {
      // 로딩 상태로 변경
      state = state.copyWith(isLoadingMore: true);
      
      final currentMessages = state.messages.asData?.value ?? [];
      final lastMessageId = state.lastMessageId;
      
      // 마지막 메시지의 인덱스 찾기
      int lastIndex = -1;
      if (lastMessageId != null) {
        lastIndex = _mockMessages.indexWhere((msg) => msg.id == lastMessageId);
      }
      
      // 다음 페이지 메시지 가져오기
      if (lastIndex >= 0 && lastIndex + 1 < _mockMessages.length) {
        // 실제 구현에서는 Firebase에서 데이터 가져오기
        // Mock 데이터에서는 인덱스 기반으로 다음 페이지 가져오기
        await Future.delayed(const Duration(seconds: 1));
        
        final nextPageMessages = _mockMessages
            .skip(lastIndex + 1)
            .take(_messagesPerPage)
            .where((msg) => msg.groupId == state.groupId)
            .toList();
        
        // 새 메시지 목록 (기존 + 새로 로드한 메시지)
        final newMessages = [...currentMessages, ...nextPageMessages];
        
        // 상태 업데이트
        state = state.copyWith(
          messages: AsyncValue.data(newMessages),
          lastMessageId: nextPageMessages.isEmpty ? lastMessageId : nextPageMessages.last.id,
          hasReachedEnd: nextPageMessages.length < _messagesPerPage,
          isLoadingMore: false,
        );
      } else {
        // 더 이상 로드할 메시지가 없음
        state = state.copyWith(
          hasReachedEnd: true,
          isLoadingMore: false,
        );
      }
    } catch (e) {
      // 에러 처리
      state = state.copyWith(
        errorMessage: '추가 메시지를 불러오는 중 오류가 발생했습니다: $e',
        isLoadingMore: false,
      );
    }
  }

  // 메시지 전송
  Future<void> _handleSendMessage(String content) async {
    try {
      // 내용이 비어있으면 무시
      if (content.trim().isEmpty) return;
      
      // 전송 중 상태로 변경
      state = state.copyWith(isSending: true);
      
      // 새 메시지 생성
      final newMessage = ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        groupId: state.groupId,
        content: content,
        senderId: _currentUserId,
        senderName: _userNames[_currentUserId]!,
        senderImage: _userImages[_currentUserId],
        timestamp: DateTime.now(),
        isRead: false,
      );
      
      // Firebase 연동 시 여기서 Firestore에 저장
      // 현재는 Mock 데이터에 추가
      _mockMessages.insert(0, newMessage); // 리스트 맨 앞에 추가 (최신순)
      
      // 현재 메시지 목록에 추가
      final currentMessages = state.messages.asData?.value ?? [];
      final updatedMessages = [newMessage, ...currentMessages];
      
      // 상태 업데이트
      state = state.copyWith(
        messages: AsyncValue.data(updatedMessages),
        isSending: false,
      );
    } catch (e) {
      // 에러 처리
      state = state.copyWith(
        errorMessage: '메시지 전송 중 오류가 발생했습니다: $e',
        isSending: false,
      );
    }
  }

  // 메시지 삭제
  Future<void> _handleDeleteMessage(String messageId) async {
    try {
      // 현재 메시지 목록 가져오기
      final currentMessages = state.messages.asData?.value ?? [];
      
      // 삭제할 메시지 찾기
      final index = currentMessages.indexWhere((msg) => msg.id == messageId);
      if (index == -1) return; // 메시지를 찾지 못함
      
      // Firebase 연동 시 여기서 Firestore에서 삭제
      // 현재는 Mock 데이터에서 삭제
      _mockMessages.removeWhere((msg) => msg.id == messageId);
      
      // 현재 메시지 목록에서 삭제
      final updatedMessages = List<ChatMessage>.from(currentMessages)
        ..removeAt(index);
      
      // 상태 업데이트
      state = state.copyWith(
        messages: AsyncValue.data(updatedMessages),
      );
    } catch (e) {
      // 에러 처리
      state = state.copyWith(
        errorMessage: '메시지 삭제 중 오류가 발생했습니다: $e',
      );
    }
  }

  // 이미지 첨부 (향후 구현)
  Future<void> _handleAttachImage(String imagePath) async {
    // 이미지 첨부 기능은 향후 구현
    debugPrint('이미지 첨부 기능 구현 예정: $imagePath');
  }
}