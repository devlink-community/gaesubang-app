// lib/group/presentation/group_detail/components/timer_display.dart
import 'package:devlink_mobile_app/group/presentation/group_detail/group_detail_state.dart';
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

  // 🔧 통일된 시간 포맷팅 메서드
  String _formatTime(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    // 🔧 항상 HH:MM:SS 형식으로 표시
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isRunning = timerStatus == TimerStatus.running;
    final isStopped = timerStatus == TimerStatus.stop;

    // 컴팩트 모드(상단 플로팅) 또는 일반 모드에 따라 스타일 변경
    if (isCompact) {
      return _buildCompactTimer(isRunning, isStopped);
    } else {
      return _buildFullTimer(isRunning, isStopped);
    }
  }

  // 작은 타이머 디스플레이 (상단 플로팅용)
  Widget _buildCompactTimer(bool isRunning, bool isStopped) {
    // 상태에 따른 배경색 결정
    final backgroundColor =
        isStopped
            ? const Color(0xFF9E9E9E) // 회색 (정지 상태)
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
            _formatTime(elapsedSeconds), // 🔧 통일된 포맷 사용
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          _buildControlButton(isRunning, isStopped, size: 36, iconSize: 18),
        ],
      ),
    );
  }

  // 큰 타이머 디스플레이 (메인 화면용)
  Widget _buildFullTimer(bool isRunning, bool isStopped) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 16, bottom: 24),
      decoration: BoxDecoration(color: Colors.transparent),
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
            _formatTime(elapsedSeconds), // 🔧 통일된 포맷 사용
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
          _buildControlButton(isRunning, isStopped, size: 64, iconSize: 32),
        ],
      ),
    );
  }

  // 컨트롤 버튼 (재생/일시정지)
  Widget _buildControlButton(
    bool isRunning,
    bool isStopped, {
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
          isStopped
              ? Icons
                  .play_arrow // 정지 상태일 때 재생 아이콘
              : isRunning
              ? Icons
                  .pause // 실행 중일 때 일시 정지 아이콘
              : Icons.play_arrow, // 일시 정지 상태일 때 재생 아이콘
          color:
              isStopped
                  ? const Color(0xFF9E9E9E) // 회색 (정지 상태)
                  : const Color(0xFF8080FF), // 파란색
          size: iconSize,
        ),
      ),
    );
  }
}
