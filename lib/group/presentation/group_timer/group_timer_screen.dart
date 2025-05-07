import 'package:devlink_mobile_app/group/domain/model/timer_session.dart';
import 'package:devlink_mobile_app/group/presentation/group_timer/components/timer_circle_progress.dart';
import 'package:devlink_mobile_app/group/presentation/group_timer/group_timer_action.dart';
import 'package:devlink_mobile_app/group/presentation/group_timer/group_timer_state.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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
        title: const Text('집중 타이머'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => onAction(const GroupTimerAction.viewStatistics()),
            tooltip: '통계 보기',
          ),
        ],
      ),
      body: Column(children: [_buildTimerSection(), _buildSessionList()]),
    );
  }

  // 타이머 섹션
  Widget _buildTimerSection() {
    return Expanded(
      flex: 3,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 그룹명 표시
            Text(
              '${state.groupId} 그룹',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // 타이머 원형 프로그레스
            TimerCircleProgress(
              elapsedSeconds: state.elapsedSeconds,
              totalSeconds: 60 * 25, // 25분 (포모도로 기본)
              radius: 120,
              strokeWidth: 15,
            ),
            const SizedBox(height: 30),

            // 타이머 컨트롤 버튼들
            _buildTimerControls(),

            // 에러 메시지 (있는 경우)
            if (state.errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  state.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 타이머 컨트롤 버튼들
  Widget _buildTimerControls() {
    // 타이머 상태에 따라 다른 버튼 표시
    switch (state.timerStatus) {
      case TimerStatus.initial:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildControlButton(
              label: '시작',
              icon: Icons.play_arrow,
              color: Colors.green,
              onPressed: () => onAction(const GroupTimerAction.startTimer()),
            ),
          ],
        );

      case TimerStatus.running:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildControlButton(
              label: '일시정지',
              icon: Icons.pause,
              color: Colors.orange,
              onPressed: () => onAction(const GroupTimerAction.pauseTimer()),
            ),
            const SizedBox(width: 20),
            _buildControlButton(
              label: '종료',
              icon: Icons.stop,
              color: Colors.red,
              onPressed: () => onAction(const GroupTimerAction.stopTimer()),
            ),
          ],
        );

      case TimerStatus.paused:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildControlButton(
              label: '재개',
              icon: Icons.play_arrow,
              color: Colors.green,
              onPressed: () => onAction(const GroupTimerAction.resumeTimer()),
            ),
            const SizedBox(width: 20),
            _buildControlButton(
              label: '종료',
              icon: Icons.stop,
              color: Colors.red,
              onPressed: () => onAction(const GroupTimerAction.stopTimer()),
            ),
          ],
        );

      case TimerStatus.completed:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildControlButton(
              label: '새로 시작',
              icon: Icons.refresh,
              color: Colors.blue,
              onPressed: () {
                onAction(const GroupTimerAction.resetTimer());
                onAction(const GroupTimerAction.startTimer());
              },
            ),
          ],
        );
    }
  }

  // 컨트롤 버튼 위젯
  Widget _buildControlButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  // 세션 목록 섹션
  Widget _buildSessionList() {
    return Expanded(
      flex: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '최근 집중 기록',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed:
                      () => onAction(const GroupTimerAction.refreshSessions()),
                  tooltip: '새로고침',
                ),
              ],
            ),
          ),
          Expanded(child: _buildSessionListContent()),
        ],
      ),
    );
  }

  // 세션 목록 내용
  Widget _buildSessionListContent() {
    switch (state.sessions) {
      case AsyncLoading():
        return const Center(child: CircularProgressIndicator());

      case AsyncError(:final error):
        return Center(child: Text('세션 목록을 불러올 수 없습니다: $error'));

      case AsyncData(:final value):
        if (value.isEmpty) {
          return const Center(child: Text('아직 집중 기록이 없습니다'));
        }

        return ListView.builder(
          itemCount: value.length,
          itemBuilder: (context, index) {
            final session = value[index];
            return _buildSessionItem(session);
          },
        );
    }

    // 기본 반환값 추가
    return const SizedBox.shrink();
  }

  // 개별 세션 아이템
  Widget _buildSessionItem(TimerSession session) {
    final duration = Duration(seconds: session.duration);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    final formattedDate = _formatDate(session.startTime);
    final formattedDuration = '$minutes분 ${seconds}초';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.timer)),
        title: Text(formattedDuration),
        subtitle: Text(formattedDate),
        trailing:
            session.isCompleted
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.pending, color: Colors.orange),
      ),
    );
  }

  // 날짜 포맷팅 헬퍼
  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (date == today) {
      return '오늘 ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }

    return '${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
