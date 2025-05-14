import 'package:devlink_mobile_app/auth/domain/model/member.dart';
import 'package:devlink_mobile_app/community/domain/model/hash_tag.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:intl/intl.dart';

part 'group.freezed.dart';

@freezed
class Group with _$Group {
  const Group({
    required this.id,
    required this.name,
    required this.description,
    required this.members,
    required this.hashTags,
    required this.limitMemberCount,
    required this.owner,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  final String id;
  @override
  final String name;
  @override
  final String description;
  @override
  final List<Member> members;
  @override
  final List<HashTag> hashTags;
  @override
  final int limitMemberCount;
  @override
  final Member owner;
  @override
  final String? imageUrl;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  // 현재 그룹 멤버 수
  int get memberCount => members.length;

  // 새 멤버 참여 가능 여부 (memberCount < limitMemberCount)
  bool get isOpen => memberCount < limitMemberCount;

  // 현재 활동 중인 멤버 수 (타이머 활성 상태)
  // 참고: Member 클래스에 onAir 속성이 있다고 가정합니다
  int get activeMemberCount => members.where((member) => member.onAir).length;

  // 포맷된 생성일 문자열
  String get formattedCreatedDate {
    final dateFormat = DateFormat('yyyy.MM.dd');
    return dateFormat.format(createdAt);
  }

  // 해시태그를 '#태그1 #태그2' 형식으로 결합한 문자열
  String get hashTagsText {
    return hashTags.map((tag) => '#${tag.content}').join(' ');
  }
}
