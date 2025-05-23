import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_member_location.freezed.dart';

@freezed
class GroupMemberLocation with _$GroupMemberLocation {
  const GroupMemberLocation({
    required this.userId,
    required this.nickname,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    this.lastUpdated,
    this.isOnline = false,
  });

  @override
  final String userId;
  @override
  final String nickname;
  @override
  final String imageUrl;
  @override
  final double latitude;
  @override
  final double longitude;
  @override
  final DateTime? lastUpdated;
  @override
  final bool isOnline; // 실시간 접속 여부 표시
}
