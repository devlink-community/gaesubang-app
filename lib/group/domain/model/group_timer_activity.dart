// lib/group/domain/model/group_timer_activity.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_timer_activity.freezed.dart';

@freezed
class GroupTimerActivity with _$GroupTimerActivity {
  const GroupTimerActivity({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.type,
    required this.timestamp,
    required this.groupId,
    this.metadata,
  });

  final String id;
  final String memberId;
  final String memberName;
  final String type; // "start", "end" 등 타이머 액션 타입
  final DateTime timestamp;
  final String groupId;
  final Map<String, dynamic>? metadata;
}
