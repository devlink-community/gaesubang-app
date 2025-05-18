import 'package:devlink_mobile_app/group/presentation/group_timer/group_timer_state.dart';
import 'package:flutter/material.dart';

class TimerDisplay extends StatelessWidget {
  final int elapsedSeconds;
  final TimerStatus timerStatus;
  final VoidCallback onToggle;
  final bool isCompact;

  const TimerDisplay({
    super.key,
    required this.elapsedSeconds,
    required this.timerStatus,
    required this.onToggle,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isRunning = timerStatus == TimerStatus.running;
    final isCompleted = timerStatus == TimerStatus.completed;

    final hours = elapsedSeconds ~/ 3600;
    final minutes = (elapsedSeconds % 3600) ~/ 60;
    final seconds = elapsedSeconds % 60;

    // 컴팩트 모드(상단 플로팅) 또는 일반 모드에 따라 스타일 변경
    if (isCompact) {
      return _buildCompactTimer(
        hours,
        minutes,
        seconds,
        isRunning,
        isCompleted,
      );
    } else {
      return _buildFullTimer(hours, minutes, seconds, isRunning, isCompleted);
    }
  }

  // 작은 타이머 디스플레이 (상단 플로팅용)
  // 작은 타이머 디스플레이 (상단 플로팅용)
  Widget _buildCompactTimer(
    int hours,
    int minutes,
    int seconds,
    bool isRunning,
    bool isCompleted,
  ) {
    final timeText =
        '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    // 완료 상태이면 다른 색상 사용
    final backgroundColor =
        isCompleted
            ? const Color(0xFF9E9E9E) // 회색 (완료 상태)
            : isRunning
            ? const Color(0xFF8080FF) // 파란색 (실행 중)
            : const Color(0xFFCDCDFF); // 연한 파란색 (일시 정지)

    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text(
            '집중 시간',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            timeText,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          _buildControlButton(isRunning, isCompleted, size: 36, iconSize: 18),
        ],
      ),
    );
  }

  // 큰 타이머 디스플레이 (메인 화면용)
  // 큰 타이머 디스플레이 (메인 화면용)
  Widget _buildFullTimer(
    int hours,
    int minutes,
    int seconds,
    bool isRunning,
    bool isCompleted,
  ) {
    // 배경색 결정
    final backgroundColor =
        isCompleted
            ? const Color(0xFF9E9E9E) // 회색 (완료 상태)
            : isRunning
            ? const Color(0xFF8080FF) // 파란색 (실행 중)
            : const Color(0xFFCDCDFF); // 연한 파란색 (일시 정지)

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 16, bottom: 24),
      decoration: BoxDecoration(color: backgroundColor),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '집중 시간',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // 디지털 시간 표시
          Text(
            '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: const TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
              shadows: [
                Shadow(
                  color: Color(0x40000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 재생/일시정지 버튼
          _buildControlButton(isRunning, isCompleted, size: 64, iconSize: 32),
        ],
      ),
    );
  }

  // 컨트롤 버튼 (재생/일시정지)
  // 컨트롤 버튼 (재생/일시정지)
  Widget _buildControlButton(
    bool isRunning,
    bool isCompleted, {
    required double size,
    required double iconSize,
  }) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: size / 6.4,
              spreadRadius: size / 64,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          isCompleted
              ? Icons
                  .replay // 완료 상태일 때 재시작 아이콘
              : isRunning
              ? Icons
                  .pause // 실행 중일 때 일시 정지 아이콘
              : Icons.play_arrow, // 일시 정지 상태일 때 재생 아이콘
          color:
              isCompleted
                  ? const Color(0xFF9E9E9E) // 회색 (완료 상태)
                  : const Color(0xFF8080FF), // 파란색
          size: iconSize,
        ),
      ),
    );
  }
}
