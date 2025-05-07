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
        title: const Text('프로필'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed:
                () => onAction(const GroupTimerAction.navigateToSettings()),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildUserProfile(), // 사용자 프로필 영역
          _buildTimerSection(), // 타이머 영역
          _buildMessage(), // 메시지 영역
          _buildHashTags(), // 해시태그 영역
          _buildMemberTimers(), // 멤버 타이머 영역
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: '채팅'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: '그룹'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: '알림'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '프로필'),
        ],
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
      ),
    );
  }

  // 사용자 프로필 영역 (이미지, 이름, 활동일 표시)
  Widget _buildUserProfile() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              // 프로필 이미지
              CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(
                  state.memberTimers.isNotEmpty
                      ? state.memberTimers[0].imageUrl
                      : '',
                ),
                backgroundColor: Colors.grey[200],
              ),
              const SizedBox(width: 16),
              // 이름 및 활동 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.groupName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.local_fire_department,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '1 Day',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // 달력 버튼
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed:
                    () =>
                        onAction(const GroupTimerAction.navigateToAttendance()),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('안녕하세요.', style: TextStyle(fontSize: 14)),
          const Divider(),
        ],
      ),
    );
  }

  // 타이머 영역 - 주간 활동 그래프
  Widget _buildTimerSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // 두 개의 버튼 (예: 출석부, 타이머)
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: Colors.grey),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(''),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: Colors.grey),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(''),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 주간 활동 그래프
          SizedBox(
            height: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildActivityBar('월', 0.3, true),
                _buildActivityBar('화', 0.7, true),
                _buildActivityBar('수', 0.2, true),
                _buildActivityBar('목', 0.5, true),
                _buildActivityBar('금', 0.8, true),
                _buildActivityBar('토', 0.3, true),
                _buildActivityBar('일', 0.6, true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 주간 활동 막대 그래프 아이템
  Widget _buildActivityBar(String day, double progress, bool isActive) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // 활동 막대
        Container(
          width: 16,
          height: 100 * progress,
          decoration: BoxDecoration(
            color: isActive ? Colors.blue : Colors.blue.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        // 요일 표시
        Text(day, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  // 메시지 영역
  Widget _buildMessage() {
    return const SizedBox.shrink(); // 제거
  }

  // 해시태그 영역
  Widget _buildHashTags() {
    return const SizedBox.shrink(); // 제거
  }

  // 멤버 타이머 영역 - 기존과 동일하게 유지
  Widget _buildMemberTimers() {
    return const SizedBox.shrink(); // 여기선 필요없음
  }
}
