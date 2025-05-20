// lib/group/presentation/group_chat/group_chat_screen.dart

import 'package:devlink_mobile_app/core/component/app_image.dart';
import 'package:devlink_mobile_app/core/component/error_view.dart';
import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:devlink_mobile_app/group/domain/model/chat_message.dart';
import 'package:devlink_mobile_app/group/presentation/group_chat/group_chat_action.dart';
import 'package:devlink_mobile_app/group/presentation/group_chat/group_chat_state.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 그룹 채팅 화면 (순수 UI)
/// 상태와 액션을 외부에서 주입받아 렌더링만 담당
class GroupChatScreen extends StatefulWidget {
  final GroupChatState state;
  final void Function(GroupChatAction action) onAction;

  const GroupChatScreen({
    super.key,
    required this.state,
    required this.onAction,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // 스크롤 리스너 설정 - 상단에 도달하면 더 많은 메시지 로드
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  // 스크롤 리스너 - 상단에 도달하면 이전 메시지 로드
  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.minScrollExtent) {
      widget.onAction(const GroupChatAction.loadMoreMessages());
    }
  }

  // 새 메시지 전송
  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // 메시지 전송 액션 발생
    widget.onAction(GroupChatAction.sendMessage(message));

    // 입력 필드 비우기
    _messageController.clear();

    // UI 업데이트를 위해 약간 지연 후 스크롤 아래로 이동
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.state.groupName.isEmpty ? '그룹 채팅' : widget.state.groupName,
          style: AppTextStyles.heading6Bold,
        ),
        elevation: 0,
        backgroundColor: AppColorStyles.primary100,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 로딩 인디케이터 (더 많은 메시지 로드 중)
          if (widget.state.isLoadingMore)
            LinearProgressIndicator(
              backgroundColor: AppColorStyles.gray40,
              color: AppColorStyles.primary60,
              minHeight: 2,
            ),

          // 메시지 목록
          Expanded(child: _buildMessageList()),

          // 메시지 입력 영역
          _buildMessageInputField(),
        ],
      ),
    );
  }

  // group_chat_screen.dart 파일의 _buildMessageList 함수 수정

  Widget _buildMessageList() {
    return switch (widget.state.messages) {
      AsyncLoading() => const Center(child: CircularProgressIndicator()),

      AsyncError(:final error) => ErrorView(
        error: error,
        onRetry: () => widget.onAction(const GroupChatAction.loadMessages()),
      ),

      AsyncData(:final value) =>
        value.isEmpty
            ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 48,
                    color: AppColorStyles.gray60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '메시지가 없습니다.\n첫 메시지를 보내보세요!',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body1Regular.copyWith(
                      color: AppColorStyles.gray80,
                    ),
                  ),
                ],
              ),
            )
            : ListView.builder(
              controller: _scrollController,
              reverse: true, // 역순 배치 (최신 메시지가 아래쪽)
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: value.length,
              itemBuilder: (context, index) {
                final message = value[index];
                final isMe = message.senderId == widget.state.currentUserId;

                return _buildMessageItem(message, isMe);
              },
            ),
      // 모든 다른 경우를 처리하는 와일드카드 패턴
      _ => const Center(child: CircularProgressIndicator()),
    };
  }

  // 단일 메시지 아이템 위젯
  Widget _buildMessageItem(ChatMessage message, bool isMe) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상대방 메시지일 경우 프로필 이미지 표시
          if (!isMe) ...[
            AppImage.profile(imagePath: message.senderImage, size: 32),
            const SizedBox(width: 8),
          ],

          // 메시지 내용 + 메타데이터
          Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // 상대방 이름 (내 메시지에는 표시 안함)
              if (!isMe)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 2),
                  child: Text(
                    message.senderName,
                    style: AppTextStyles.captionRegular.copyWith(
                      color: AppColorStyles.gray100,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              // 메시지 내용
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color:
                      isMe
                          ? AppColorStyles.primary80.withOpacity(0.8)
                          : AppColorStyles.gray40,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  message.content,
                  style: AppTextStyles.body1Regular.copyWith(
                    color: isMe ? Colors.white : AppColorStyles.textPrimary,
                  ),
                ),
              ),

              // 타임스탬프
              Padding(
                padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                child: Text(
                  _formatTimestamp(message.timestamp),
                  style: AppTextStyles.captionRegular.copyWith(
                    color: AppColorStyles.gray80,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),

          // 내 메시지일 경우 여백 추가
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  // 메시지 입력 필드
  Widget _buildMessageInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // 확장 버튼 (이미지, 파일 첨부 등 - 구현 예정)
            IconButton(
              icon: Icon(
                Icons.add_circle_outline,
                color: AppColorStyles.gray100,
              ),
              onPressed: () {
                // 향후 확장: 이미지/파일 첨부 기능
              },
            ),

            // 텍스트 입력 필드
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: '메시지를 입력하세요',
                  hintStyle: AppTextStyles.body1Regular.copyWith(
                    color: AppColorStyles.gray60,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  filled: true,
                  fillColor: AppColorStyles.gray40.withOpacity(0.5),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),

            // 전송 버튼
            IconButton(
              icon: Icon(Icons.send, color: AppColorStyles.primary100),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  // 타임스탬프 포맷팅 (예: "오후 3:45")
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );

    final hour = timestamp.hour;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = hour < 12 ? '오전' : '오후';
    final displayHour = (hour <= 12 ? hour : hour - 12).toString();

    // 오늘 메시지는 시간만 표시
    if (messageDate == today) {
      return '$period $displayHour:$minute';
    }

    // 어제 메시지
    if (messageDate == today.subtract(const Duration(days: 1))) {
      return '어제 $period $displayHour:$minute';
    }

    // 그 외 날짜는 날짜와 시간 모두 표시
    return '${timestamp.month}/${timestamp.day} $period $displayHour:$minute';
  }
}
