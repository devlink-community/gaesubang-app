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
    this.elapsedMinutes = 0, // 경과 시간 (분 단위)
  });

  final String id;
  final String userId;
  final String userName;
  final String? profileUrl;
  final String role; // "owner", "member"
  final DateTime joinedAt;

  // 추가된 필드
  final bool isActive; // 활동 상태 (활성/비활성)
  final DateTime? timerStartTime; // 현재 타이머 상태 (시작된 시간)
  final int elapsedMinutes; // 경과 시간 (분 단위)

  // 관리자 여부 확인 헬퍼 메서드
  bool get isOwner => role == "owner";

  // 경과 시간 문자열 포맷 (HH:MM:SS)
  String get elapsedTimeFormat {
    // 초 단위로 변환
    final seconds = elapsedMinutes * 60;

    // 시, 분, 초 계산
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    // HH:MM:SS 형식으로 반환
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // 현재 시간 기준 업데이트된 GroupMember 반환
  GroupMember updateElapsedTime() {
    if (!isActive || timerStartTime == null) {
      return this;
    }

    // 시작 시간부터 현재까지의 경과 시간 계산
    final now = DateTime.now();
    final diff = now.difference(timerStartTime!);
    final newElapsedMinutes = diff.inMinutes;

    return copyWith(elapsedMinutes: newElapsedMinutes);
  }
}
