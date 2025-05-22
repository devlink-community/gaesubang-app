// lib/group/domain/model/group_member.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_member.freezed.dart';

@freezed
class GroupMember with _$GroupMember {
  const GroupMember({
    required this.id,
    required this.userId,
    required this.userName,
    this.profileUrl,
    required this.role,
    required this.joinedAt,
    this.isActive = false, // 활동 상태 (활성/비활성)
    this.timerStartTime, // 현재 타이머 상태 (시작된 시간)
    this.elapsedMinutes = 0, // 경과 시간 (분 단위) - 기존 호환성 유지
    this.elapsedSeconds = 0, // 🔧 새로 추가: 경과 시간 (초 단위)
  });

  final String id;
  final String userId;
  final String userName;
  final String? profileUrl;
  final String role; // "owner", "member"
  final DateTime joinedAt;

  // 기존 필드들
  final bool isActive; // 활동 상태 (활성/비활성)
  final DateTime? timerStartTime; // 현재 타이머 상태 (시작된 시간)
  final int elapsedMinutes; // 경과 시간 (분 단위) - 기존 호환성 유지

  // 🔧 새로 추가된 필드
  final int elapsedSeconds; // 경과 시간 (초 단위)

  // 관리자 여부 확인 헬퍼 메서드
  bool get isOwner => role == "owner";

  // 🔧 개선된 경과 시간 문자열 포맷 (초 단위 기반)
  String get elapsedTimeFormat {
    // elapsedSeconds 우선 사용, 없으면 elapsedMinutes * 60 사용 (하위 호환성)
    final totalSeconds =
        elapsedSeconds > 0 ? elapsedSeconds : elapsedMinutes * 60;

    // 시, 분, 초 계산
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    // HH:MM:SS 형식으로 반환
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // 🔧 현재 시간 기준 업데이트된 GroupMember 반환 (초 단위 기반)
  GroupMember updateElapsedTime() {
    if (!isActive || timerStartTime == null) {
      return this;
    }

    // 시작 시간부터 현재까지의 경과 시간 계산 (초 단위)
    final now = DateTime.now();
    final diff = now.difference(timerStartTime!);
    final newElapsedSeconds = diff.inSeconds;

    return copyWith(
      elapsedSeconds: newElapsedSeconds,
      elapsedMinutes: (newElapsedSeconds / 60).floor(), // 호환성을 위해 분 단위도 업데이트
    );
  }

  // 🔧 실시간 경과 시간을 초 단위로 계산하는 헬퍼 메서드
  int get currentElapsedSeconds {
    if (!isActive || timerStartTime == null) {
      return elapsedSeconds;
    }

    // 현재 시간 기준으로 실시간 계산
    final now = DateTime.now();
    final diff = now.difference(timerStartTime!);
    return diff.inSeconds;
  }

  // 🔧 실시간 경과 시간을 포맷된 문자열로 반환
  String get currentElapsedTimeFormat {
    final totalSeconds = currentElapsedSeconds;

    // 시, 분, 초 계산
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    // HH:MM:SS 형식으로 반환
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
