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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상대방 메시지일 때만 프로필 이미지 표시
          if (!isMe) ...[
            _buildAvatar(),
            const SizedBox(width: 8),
          ],

          // 메시지 컨테이너
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // 상대방 메시지일 때만 이름 표시
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 2),
                    child: Text(
                      message.senderName,
                      style: AppTextStyles.captionRegular.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColorStyles.gray100,
                      ),
                    ),
                  ),

                // 메시지 내용 및 시간
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isMe) _buildTimeStamp(),
                    
                    // 메시지 내용
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? AppColorStyles.primary60 : AppColorStyles.gray40,
                          borderRadius: BorderRadius.circular(16).copyWith(
                            bottomLeft: !isMe ? const Radius.circular(4) : null,
                            bottomRight: isMe ? const Radius.circular(4) : null,
                          ),
                        ),
                        child: Text(
                          message.content,
                          style: AppTextStyles.body1Regular.copyWith(
                            color: isMe ? Colors.white : AppColorStyles.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    
                    if (!isMe) _buildTimeStamp(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 프로필 이미지 위젯
  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 16,
      backgroundColor: AppColorStyles.gray40,
      backgroundImage: message.senderImage != null && message.senderImage!.isNotEmpty
          ? NetworkImage(message.senderImage!)
          : null,
      child: message.senderImage == null || message.senderImage!.isEmpty
          ? Icon(
              Icons.person,
              size: 16,
              color: AppColorStyles.gray80,
            )
          : null,
    );
  }

  // 시간 표시 위젯
  Widget _buildTimeStamp() {
    final timeFormat = DateFormat('HH:mm');
    final formattedTime = timeFormat.format(message.timestamp);
    
    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? 4 : 0,
        right: isMe ? 0 : 4,
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