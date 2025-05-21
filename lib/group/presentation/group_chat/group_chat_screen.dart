// lib/group/presentation/group_chat/group_chat_screen.dart
import 'package:devlink_mobile_app/core/component/error_view.dart';
import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:devlink_mobile_app/group/domain/model/chat_message.dart';
import 'package:devlink_mobile_app/group/presentation/group_chat/components/chat_bubble.dart';
import 'package:devlink_mobile_app/group/presentation/group_chat/components/chat_input.dart';
import 'package:devlink_mobile_app/group/presentation/group_chat/group_chat_action.dart';
import 'package:devlink_mobile_app/group/presentation/group_chat/group_chat_state.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class GroupChatScreen extends StatefulWidget {
  const GroupChatScreen({
    super.key,
    required this.state,
    required this.onAction,
  });

  final GroupChatState state;
  final void Function(GroupChatAction action) onAction;

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  // 스크롤 컨트롤러
  late ScrollController _scrollController;

  // 메시지 입력 컨트롤러
  late TextEditingController _textController;

  // 포커스 노드
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _textController = TextEditingController();
    _focusNode = FocusNode();

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        // 키보드가 나타날 때 스크롤 맨 아래로
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(GroupChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 새 메시지가 추가되었을 때 스크롤 맨 아래로
    if (widget.state.messagesResult case AsyncData(:final value)) {
      if (oldWidget.state.messagesResult case AsyncData(:final oldValue)) {
        if (value != null && oldValue != null && value.length > oldValue.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      }
    }

    // 메시지 전송 후 텍스트 필드 비우기
    if (widget.state.currentMessage.isEmpty && _textController.text.isNotEmpty) {
      _textController.clear();
    }
  }

  // 스크롤을 맨 아래로 이동
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // 메시지 전송 처리
  void _handleSendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    widget.onAction(GroupChatAction.sendMessage(text));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('그룹 채팅'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 메시지 목록
          Expanded(
            child: _buildMessageList(),
          ),

          // 입력 영역
          ChatInput(
            controller: _textController,
            focusNode: _focusNode,
            isLoading: widget.state.sendingStatus is AsyncLoading,
            onChanged: (value) {
              widget.onAction(GroupChatAction.messageChanged(value));
            },
            onSend: _handleSendMessage,
          ),
        ],
      ),
    );
  }

  // 메시지 목록 위젯
  Widget _buildMessageList() {
    return switch (widget.state.messagesResult) {
      AsyncLoading() => const Center(child: CircularProgressIndicator()),
      AsyncError(:final error) => ErrorView(
          error: error,
          onRetry: () => widget.onAction(
            GroupChatAction.loadMessages(widget.state.groupId),
          ),
        ),
      AsyncData(:final value) => value == null || value.isEmpty
          ? _buildEmptyMessages()
          : _buildMessages(value),
    };
  }

  // 메시지가 없을 때 표시할 위젯
  Widget _buildEmptyMessages() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: AppColorStyles.gray60,
          ),
          const SizedBox(height: 16),
          Text(
            '채팅 메시지가 없습니다',
            style: AppTextStyles.subtitle1Medium.copyWith(
              color: AppColorStyles.gray80,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '첫 메시지를 보내보세요!',
            style: AppTextStyles.body1Regular.copyWith(
              color: AppColorStyles.gray60,
            ),
          ),
        ],
      ),
    );
  }

  // 메시지 목록 구현
  Widget _buildMessages(List<ChatMessage> messages) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      reverse: true, // 최신 메시지가 아래에 표시되도록 역순 배치
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final bool isMe = message.senderId == 'currentUserId'; // 실제 사용자 ID로 대체 필요

        // 날짜 구분선 표시 로직
        final showDateDivider = index == messages.length - 1 || 
            _shouldShowDateDivider(messages[index], index < messages.length - 1 ? messages[index + 1] : null);

        return Column(
          children: [
            if (showDateDivider) _buildDateDivider(message.timestamp),
            ChatBubble(
              message: message,
              isMe: isMe,
            ),
          ],
        );
      },
    );
  }

  // 날짜 변경 여부 확인
  bool _shouldShowDateDivider(ChatMessage current, ChatMessage? previous) {
    if (previous == null) return true;
    
    final currentDate = DateTime(
      current.timestamp.year,
      current.timestamp.month,
      current.timestamp.day,
    );
    
    final previousDate = DateTime(
      previous.timestamp.year,
      previous.timestamp.month,
      previous.timestamp.day,
    );
    
    return currentDate != previousDate;
  }

  // 날짜 구분선 위젯
  Widget _buildDateDivider(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );
    
    String dateText;
    if (messageDate == today) {
      dateText = '오늘';
    } else if (messageDate == yesterday) {
      dateText = '어제';
    } else {
      dateText = '${timestamp.year}년 ${timestamp.month}월 ${timestamp.day}일';
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(
            child: Divider(
              color: AppColorStyles.gray40,
              thickness: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              dateText,
              style: AppTextStyles.captionRegular.copyWith(
                color: AppColorStyles.gray60,
              ),
            ),
          ),
          const Expanded(
            child: Divider(
              color: AppColorStyles.gray40,
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }
}