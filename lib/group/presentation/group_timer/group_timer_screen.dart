import 'package:devlink_mobile_app/group/presentation/group_timer/components/member_timer_item.dart';
import 'package:devlink_mobile_app/group/presentation/group_timer/components/timer_circle_progress.dart';
import 'package:devlink_mobile_app/group/presentation/group_timer/group_timer_action.dart';
import 'package:devlink_mobile_app/group/presentation/group_timer/group_timer_state.dart';
import 'package:flutter/material.dart';

class GroupTimerScreen extends StatelessWidget {
  const GroupTimerScreen({
    super.key,
    required this.state,
    required this.onAction,
  });

  final GroupTimerState state;
  final void Function(GroupTimerAction action) onAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(state.groupName),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {}, // 설정 화면으로 이동
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(), // 상단 정보 영역
          _buildTimerSection(), // 타이머 영역
          _buildMessage(), // 메시지 영역
          _buildHashTags(), // 해시태그 영역
          _buildMemberTimers(), // 멤버 타이머 영역
        ],
      ),
    );
  }

  // 상단 정보 영역 (참여자 수, 날짜)
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 참여자 수
          Row(
            children: [
              const Icon(Icons.person, size: 20),
              const SizedBox(width: 4),
              Text('${state.participantCount} / ${state.totalMemberCount}'),
            ],
          ),

          // 달력 아이콘
          IconButton(
            icon: const Icon(Icons.calendar_today, size: 20),
            onPressed: () => onAction(const GroupTimerAction.viewStatistics()),
          ),
        ],
      ),
    );
  }

  // 타이머 영역
  Widget _buildTimerSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TimerCircleProgress(
        elapsedSeconds: state.elapsedSeconds,
        isRunning: state.timerStatus == TimerStatus.running,
        onTap: () => onAction(const GroupTimerAction.toggleTimer()),
      ),
    );
  }

  // 메시지 영역
  Widget _buildMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        '안녕하세요. 저희는 소금빵을 먹으며 공부하는 소막입니다.\n'
        '다들 소금빵 좋아하시나요?\n'
        '한 줄이라도 코드를 나가주세요.',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14, color: Colors.black87),
      ),
    );
  }

  // 해시태그 영역
  Widget _buildHashTags() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        children:
            state.hashTags.map((tag) {
              return Text(
                '#$tag',
                style: const TextStyle(color: Colors.blue, fontSize: 14),
              );
            }).toList(),
      ),
    );
  }

  // 멤버 타이머 영역
  Widget _buildMemberTimers() {
    // 그리드 레이아웃으로 표시 (3열)
    return Expanded(
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // 3열 그리드
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8, // 자식 위젯의 가로/세로 비율
        ),
        itemCount: state.memberTimers.length,
        itemBuilder: (context, index) {
          final member = state.memberTimers[index];
          return MemberTimerItem(
            imageUrl: member.imageUrl,
            status: member.status,
            timeDisplay: member.timeDisplay,
          );
        },
      ),
    );
  }
}
