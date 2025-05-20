// lib/group/domain/model/group_member_location.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_member_location.freezed.dart';

@freezed
class GroupMemberLocation with _$GroupMemberLocation {
  const GroupMemberLocation({
    required this.memberId,
    required this.nickname,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    this.lastUpdated,
    this.isOnline = false,
  });

  final String memberId;
  final String nickname;
  final String imageUrl;
  final double latitude;
  final double longitude;
  final DateTime? lastUpdated;
  final bool isOnline; // 실시간 접속 여부 표시
}
