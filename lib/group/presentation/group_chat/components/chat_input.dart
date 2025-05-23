// lib/group/presentation/group_chat/components/chat_input.dart
import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:flutter/material.dart';

import '../../../../ai_assistance/module/group_chat_bot_service.dart';

class ChatInput extends StatelessWidget {
  const ChatInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onChanged,
    required this.onSend,
    this.activeBotType,
    this.onBotTypeSelected,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;

  // 🆕 봇 관련 프로퍼티들
  final BotType? activeBotType;
  final ValueChanged<BotType?>? onBotTypeSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🆕 봇 활성화 표시줄
            if (activeBotType != null) _buildBotStatusBar(),

            // 메인 입력 영역
            Row(
              children: [
                // 🆕 플러스 버튼 (봇 소환/해제)
                _buildPlusButton(context),
                const SizedBox(width: 8),

                // 메시지 입력 필드
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    maxLines: 3,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    decoration: InputDecoration(
                      hintText: _getHintText(),
                      hintStyle: TextStyle(color: AppColorStyles.gray60),
                      filled: true,
                      fillColor: AppColorStyles.gray40.withValues(alpha: 0.3),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      isDense: true,
                    ),
                    onChanged: onChanged,
                    onSubmitted: (_) => onSend(),
                  ),
                ),
                const SizedBox(width: 8),

                // 전송 버튼
                _buildSendButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 🆕 플러스 버튼 위젯
  Widget _buildPlusButton(BuildContext context) {
    return Material(
      color:
          activeBotType != null
              ? AppColorStyles.primary60
              : AppColorStyles.gray40,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: () => _showBotSelectionMenu(context),
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            activeBotType != null ? Icons.smart_toy : Icons.add,
            color: activeBotType != null ? Colors.white : AppColorStyles.gray80,
            size: 24,
          ),
        ),
      ),
    );
  }

  // 🆕 봇 선택 메뉴 표시
  void _showBotSelectionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _BotSelectionBottomSheet(
            activeBotType: activeBotType,
            onBotSelected: (botType) {
              Navigator.of(context).pop();
              onBotTypeSelected?.call(botType);
            },
            onBotDisabled: () {
              Navigator.of(context).pop();
              onBotTypeSelected?.call(null);
            },
          ),
    );
  }

  // 🆕 봇 상태 표시줄
  Widget _buildBotStatusBar() {
    if (activeBotType == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColorStyles.primary60.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColorStyles.primary60.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Text(
            activeBotType!.emoji,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${activeBotType!.displayName}가 대화에 참여 중',
              style: TextStyle(
                color: AppColorStyles.primary80,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          IconButton(
            onPressed: () => onBotTypeSelected?.call(null),
            icon: Icon(
              Icons.close,
              size: 18,
              color: AppColorStyles.primary80,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
        ],
      ),
    );
  }

  // 전송 버튼
  Widget _buildSendButton() {
    return Material(
      color: AppColorStyles.primary100,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: isLoading ? null : onSend,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child:
              isLoading
                  ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                  : const Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 24,
                  ),
        ),
      ),
    );
  }

  // 🆕 힌트 텍스트 생성
  String _getHintText() {
    if (activeBotType != null) {
      return '${activeBotType!.emoji} @${activeBotType!.displayName.replaceAll('AI ', '')} 멘션으로 질문하거나 일반 메시지를 입력하세요';
    }
    return '메시지를 입력하세요';
  }
}

// 🆕 봇 선택 바텀시트
class _BotSelectionBottomSheet extends StatelessWidget {
  const _BotSelectionBottomSheet({
    required this.activeBotType,
    required this.onBotSelected,
    required this.onBotDisabled,
  });

  final BotType? activeBotType;
  final ValueChanged<BotType> onBotSelected;
  final VoidCallback onBotDisabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들 바
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: AppColorStyles.gray40,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 헤더
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.smart_toy,
                  color: AppColorStyles.primary80,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'AI 챗봇 선택',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColorStyles.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // 봇 목록
          ...BotType.values.map((botType) => _buildBotOption(context, botType)),

          // 봇 비활성화 옵션
          if (activeBotType != null) ...[
            const Divider(height: 1),
            _buildDisableBotOption(context),
          ],

          // 하단 여백
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // 봇 옵션 아이템
  Widget _buildBotOption(BuildContext context, BotType botType) {
    final isSelected = activeBotType == botType;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColorStyles.primary60.withValues(alpha: 0.1)
                  : AppColorStyles.gray40.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          botType.emoji,
          style: const TextStyle(fontSize: 20),
        ),
      ),
      title: Text(
        botType.displayName,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color:
              isSelected
                  ? AppColorStyles.primary80
                  : AppColorStyles.textPrimary,
        ),
      ),
      subtitle: Text(
        botType.description,
        style: TextStyle(
          color: AppColorStyles.gray80,
          fontSize: 13,
        ),
      ),
      trailing:
          isSelected
              ? Icon(
                Icons.check_circle,
                color: AppColorStyles.primary80,
                size: 20,
              )
              : null,
      onTap: () => onBotSelected(botType),
    );
  }

  // 봇 비활성화 옵션
  Widget _buildDisableBotOption(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.power_settings_new,
          color: Colors.red,
          size: 20,
        ),
      ),
      title: const Text(
        '챗봇 비활성화',
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: Colors.red,
        ),
      ),
      subtitle: Text(
        '채팅에서 AI 봇을 제거합니다',
        style: TextStyle(
          color: AppColorStyles.gray80,
          fontSize: 13,
        ),
      ),
      onTap: onBotDisabled,
    );
  }
}
