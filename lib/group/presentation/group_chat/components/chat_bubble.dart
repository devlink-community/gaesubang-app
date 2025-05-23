// lib/group/presentation/group_chat/components/chat_bubble.dart
import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:devlink_mobile_app/group/domain/model/chat_message.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  final ChatMessage message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    // 🆕 봇 메시지 여부 확인
    final isBotMessage = _isBotMessage(message.senderId);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: _getMainAxisAlignment(isBotMessage),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상대방 메시지일 때만 프로필 이미지 표시
          if (!isMe && !isBotMessage) ...[
            _buildUserAvatar(),
            const SizedBox(width: 8),
          ],

          // 🆕 봇 메시지일 때 봇 아바타 표시
          if (isBotMessage) ...[
            _buildBotAvatar(),
            const SizedBox(width: 8),
          ],

          // 메시지 컨테이너
          Flexible(
            child: Column(
              crossAxisAlignment: _getCrossAxisAlignment(isBotMessage),
              children: [
                // 🆕 봇 이름 또는 상대방 이름 표시
                if (!isMe || isBotMessage) _buildSenderName(isBotMessage),

                // 메시지 내용 및 시간
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isMe && !isBotMessage) _buildTimeStamp(),

                    // 메시지 내용
                    Flexible(
                      child: _buildMessageContainer(isBotMessage),
                    ),

                    if (!isMe || isBotMessage) _buildTimeStamp(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🆕 메인 축 정렬 결정
  MainAxisAlignment _getMainAxisAlignment(bool isBotMessage) {
    if (isBotMessage) return MainAxisAlignment.start;
    return isMe ? MainAxisAlignment.end : MainAxisAlignment.start;
  }

  // 🆕 교차 축 정렬 결정
  CrossAxisAlignment _getCrossAxisAlignment(bool isBotMessage) {
    if (isBotMessage) return CrossAxisAlignment.start;
    return isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
  }

  // 🆕 봇 메시지 여부 확인
  bool _isBotMessage(String senderId) {
    return senderId.startsWith('bot_');
  }

  // 기존 사용자 아바타
  Widget _buildUserAvatar() {
    return CircleAvatar(
      radius: 16,
      backgroundColor: AppColorStyles.gray40,
      backgroundImage:
          message.senderImage != null && message.senderImage!.isNotEmpty
              ? NetworkImage(message.senderImage!)
              : null,
      child:
          message.senderImage == null || message.senderImage!.isEmpty
              ? Icon(
                Icons.person,
                size: 16,
                color: AppColorStyles.gray80,
              )
              : null,
    );
  }

  // 🆕 봇 아바타
  Widget _buildBotAvatar() {
    final botEmoji = _getBotEmoji(message.senderId);

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColorStyles.primary60,
            AppColorStyles.primary100,
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColorStyles.primary60.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          botEmoji,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  // 🆕 봇 이모지 가져오기
  String _getBotEmoji(String senderId) {
    switch (senderId) {
      case 'bot_assistant':
        return '🤖';
      case 'bot_researcher':
        return '🔍';
      case 'bot_counselor':
        return '💬';
      default:
        return '🤖';
    }
  }

  // 🆕 발신자 이름 표시
  Widget _buildSenderName(bool isBotMessage) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isBotMessage) ...[
            // 🆕 봇 배지
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColorStyles.primary60,
                    AppColorStyles.primary80,
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'AI',
                style: AppTextStyles.captionRegular.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            message.senderName,
            style: AppTextStyles.captionRegular.copyWith(
              fontWeight: FontWeight.bold,
              color:
                  isBotMessage
                      ? AppColorStyles.primary80
                      : AppColorStyles.gray100,
            ),
          ),
        ],
      ),
    );
  }

  // 🆕 메시지 컨테이너 (봇 메시지 스타일 추가)
  Widget _buildMessageContainer(bool isBotMessage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _getMessageBackgroundColor(isBotMessage),
        gradient: isBotMessage ? _getBotMessageGradient() : null,
        borderRadius: _getMessageBorderRadius(isBotMessage),
        border:
            isBotMessage
                ? Border.all(
                  color: AppColorStyles.primary60.withValues(alpha: 0.3),
                  width: 1,
                )
                : null,
        boxShadow:
            isBotMessage
                ? [
                  BoxShadow(
                    color: AppColorStyles.primary60.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
                : null,
      ),
      child: _buildMessageContent(isBotMessage),
    );
  }

  // 🆕 메시지 배경색 결정
  Color _getMessageBackgroundColor(bool isBotMessage) {
    if (isBotMessage) return Colors.transparent; // 그라데이션 사용
    return isMe ? AppColorStyles.primary60 : AppColorStyles.gray40;
  }

  // 🆕 봇 메시지 그라데이션
  LinearGradient? _getBotMessageGradient() {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white,
        AppColorStyles.primary60.withValues(alpha: 0.05),
      ],
    );
  }

  // 🆕 메시지 테두리 반경
  BorderRadius _getMessageBorderRadius(bool isBotMessage) {
    if (isBotMessage) {
      return BorderRadius.circular(16).copyWith(
        bottomLeft: const Radius.circular(4),
      );
    }

    return BorderRadius.circular(16).copyWith(
      bottomLeft: !isMe ? const Radius.circular(4) : null,
      bottomRight: isMe ? const Radius.circular(4) : null,
    );
  }

  // 🆕 메시지 내용 (봇 메시지 스타일링 추가)
  Widget _buildMessageContent(bool isBotMessage) {
    if (isBotMessage) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 봇 메시지 내용
          Text(
            message.content,
            style: AppTextStyles.body1Regular.copyWith(
              color: AppColorStyles.textPrimary,
              height: 1.4,
            ),
          ),

          // 🆕 봇 메시지 하단 정보
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome,
                size: 12,
                color: AppColorStyles.primary80.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 4),
              Text(
                'AI 응답',
                style: AppTextStyles.captionRegular.copyWith(
                  color: AppColorStyles.primary80.withValues(alpha: 0.8),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      );
    }

    // 일반 메시지
    return Text(
      message.content,
      style: AppTextStyles.body1Regular.copyWith(
        color: isMe ? Colors.white : AppColorStyles.textPrimary,
      ),
    );
  }

  // 시간 표시 위젯 (기존과 동일)
  Widget _buildTimeStamp() {
    final timeFormat = DateFormat('HH:mm');
    final formattedTime = timeFormat.format(message.timestamp);

    return Padding(
      padding: EdgeInsets.only(
        left: (isMe && !_isBotMessage(message.senderId)) ? 4 : 0,
        right: (!isMe || _isBotMessage(message.senderId)) ? 4 : 0,
        bottom: 4,
      ),
      child: Text(
        formattedTime,
        style: TextStyle(
          fontSize: 10,
          color: AppColorStyles.gray60,
        ),
      ),
    );
  }
}
