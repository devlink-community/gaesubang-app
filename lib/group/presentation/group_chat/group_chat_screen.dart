// lib/group/presentation/group_chat/group_chat_screen.dart
import 'package:devlink_mobile_app/core/component/error_view.dart';
import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:devlink_mobile_app/group/domain/model/chat_message.dart';
import 'package:devlink_mobile_app/group/domain/model/group_member.dart';
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
  // GlobalKey 추가
  final _scaffoldKey = GlobalKey<ScaffoldState>();

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

    // 수정된 부분: 패턴 매칭 구문을 if-else로 변경
    final oldMessagesResult = oldWidget.state.messagesResult;
    final newMessagesResult = widget.state.messagesResult;

    if (newMessagesResult is AsyncData && oldMessagesResult is AsyncData) {
      final value = newMessagesResult.value;
      final oldValue = oldMessagesResult.value;

      if (value != null && oldValue != null && value.length > oldValue.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    }

    // 메시지 전송 후 텍스트 필드 비우기
    if (widget.state.currentMessage.isEmpty &&
        _textController.text.isNotEmpty) {
      _textController.clear();
    }
  }

  // 스크롤을 맨 아래로 이동
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.minScrollExtent,
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
      key: _scaffoldKey, // GlobalKey 추가
      appBar: AppBar(
        title: const Text('그룹 채팅'),
        centerTitle: true,
        actions: [
          // 드로어 열기 버튼 추가
          IconButton(
            icon: const Icon(Icons.people),
            tooltip: '그룹 멤버',
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer(); // GlobalKey로 접근
            },
          ),
        ],
      ),
      endDrawer: _buildMembersDrawer(), // 멤버 목록 드로어
      body: Column(
        children: [
          // 메시지 목록
          Expanded(child: _buildMessageList()),

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

  // 멤버 목록 드로어 위젯 - 개선된 버전
  Widget _buildMembersDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // 상단 헤더 부분 개선
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColorStyles.primary100, AppColorStyles.primary80],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: const Icon(
                            Icons.people,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '대화 참여자',
                                style: AppTextStyles.heading3Bold.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '현재 그룹 멤버 목록',
                                style: AppTextStyles.body1Regular.copyWith(
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // 멤버 수 표시 추가
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '총 ${_getMemberCount()} 명',
                        style: AppTextStyles.captionRegular.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 검색창 추가
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppColorStyles.background,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Icon(Icons.search, color: AppColorStyles.gray80, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '멤버 검색',
                    style: AppTextStyles.body2Regular.copyWith(
                      color: AppColorStyles.gray80,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 활성 멤버 섹션 추가
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '접속 중',
                  style: AppTextStyles.subtitle2Regular.copyWith(
                    color: AppColorStyles.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 24),
          // 멤버 목록
          Expanded(child: _buildMembersList()),
          // 하단 버튼 영역 추가
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
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
            child: ElevatedButton.icon(
              onPressed: () {
                // 그룹 채팅방 초대 기능 (미구현)
                _scaffoldKey.currentState?.closeEndDrawer();
                // TODO: 초대 기능 구현
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('멤버 초대 기능은 개발 예정입니다. 개발 해줘?'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.person_add),
              label: const Text('멤버 초대하기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorStyles.primary100,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 멤버 수 가져오기 헬퍼 메서드
  int _getMemberCount() {
    if (widget.state.groupMembersResult is AsyncData) {
      final AsyncData<List<GroupMember>> data =
          widget.state.groupMembersResult as AsyncData<List<GroupMember>>;
      return data.value.length;
    }
    return 0;
  }

  // 멤버 목록 위젯
  Widget _buildMembersList() {
    return switch (widget.state.groupMembersResult) {
      AsyncLoading() => const Center(child: CircularProgressIndicator()),
      AsyncError(:final error) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('멤버 목록을 불러오는데 실패했습니다'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed:
                  () =>
                      widget.onAction(const GroupChatAction.loadGroupMembers()),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
      AsyncData(:final value) =>
        value.isEmpty ? _buildEmptyMembersList() : _buildMembersListView(value),
      _ => const Center(child: Text('메시지를 불러올 수 없습니다')),
    };
  }

  // 멤버가 없을 때 표시할 위젯
  Widget _buildEmptyMembersList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_off, size: 64, color: AppColorStyles.gray60),
          const SizedBox(height: 16),
          Text(
            '멤버가 없습니다',
            style: AppTextStyles.subtitle1Medium.copyWith(
              color: AppColorStyles.gray80,
            ),
          ),
        ],
      ),
    );
  }

  // 멤버 목록 ListView - 개선된 버전
  Widget _buildMembersListView(List<GroupMember> members) {
    return ListView.builder(
      itemCount: members.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final member = members[index];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Container(
            decoration: BoxDecoration(
              color:
                  member.isActive
                      ? AppColorStyles.primary60.withOpacity(0.1)
                      : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              leading: Stack(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColorStyles.gray40,
                    backgroundImage:
                        member.profileUrl != null &&
                                member.profileUrl!.isNotEmpty
                            ? NetworkImage(member.profileUrl!)
                            : null,
                    child:
                        member.profileUrl == null || member.profileUrl!.isEmpty
                            ? Icon(
                              Icons.person,
                              color: AppColorStyles.gray80,
                              size: 22,
                            )
                            : null,
                  ),
                  if (member.isActive)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              title: Text(
                member.userName,
                style: AppTextStyles.subtitle1Medium,
              ),
              subtitle: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color:
                          member.isOwner
                              ? AppColorStyles.primary100.withOpacity(0.1)
                              : AppColorStyles.gray40,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      member.isOwner ? '방장' : '멤버',
                      style: AppTextStyles.captionRegular.copyWith(
                        color:
                            member.isOwner
                                ? AppColorStyles.primary100
                                : AppColorStyles.gray80,
                        fontWeight:
                            member.isOwner
                                ? FontWeight.bold
                                : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (member.isActive)
                    Container(
                      margin: const EdgeInsets.only(left: 6, top: 2),
                      child: Text(
                        '활동 중',
                        style: AppTextStyles.captionRegular.copyWith(
                          color: Colors.green,
                        ),
                      ),
                    ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: AppColorStyles.gray80),
                itemBuilder:
                    (context) => [
                      const PopupMenuItem<String>(
                        value: 'message',
                        child: Row(
                          children: [
                            Icon(Icons.message, size: 18),
                            SizedBox(width: 8),
                            Text('메시지 보내기'),
                          ],
                        ),
                      ),
                      if (member.isOwner == false)
                        const PopupMenuItem<String>(
                          value: 'promote',
                          child: Row(
                            children: [
                              Icon(Icons.upgrade, size: 18),
                              SizedBox(width: 8),
                              Text('방장 위임하기'),
                            ],
                          ),
                        ),
                      if (member.isOwner == false)
                        const PopupMenuItem<String>(
                          value: 'remove',
                          child: Row(
                            children: [
                              Icon(
                                Icons.remove_circle,
                                size: 18,
                                color: Colors.red,
                              ),
                              SizedBox(width: 8),
                              Text(
                                '멤버 내보내기',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                    ],
                onSelected: (String value) {
                  // 액션 처리 (미구현)
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // 메시지 목록 위젯
  Widget _buildMessageList() {
    return switch (widget.state.messagesResult) {
      AsyncLoading() => const Center(child: CircularProgressIndicator()),
      AsyncError(:final error) => ErrorView(
        error: error,
        onRetry:
            () => widget.onAction(
              GroupChatAction.loadMessages(widget.state.groupId),
            ),
      ),
      AsyncData(:final value) =>
        value.isEmpty ? _buildEmptyMessages() : _buildMessages(value),
      _ => const Center(child: Text('메시지를 불러올 수 없습니다')),
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
        final bool isMe =
            message.senderId == widget.state.currentUserId; // 실제 사용자 ID로 대체 필요

        // 날짜 구분선 표시 로직
        final showDateDivider =
            index == messages.length - 1 ||
            _shouldShowDateDivider(
              messages[index],
              index < messages.length - 1 ? messages[index + 1] : null,
            );

        return Column(
          children: [
            if (showDateDivider) _buildDateDivider(message.timestamp),
            ChatBubble(message: message, isMe: isMe),
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
            child: Divider(color: AppColorStyles.gray40, thickness: 1),
          ),
        ],
      ),
    );
  }
}
