import 'dart:math';
import 'package:devlink_mobile_app/community/data/dto/hash_tag_dto.dart';
import 'package:devlink_mobile_app/community/data/dto/member_dto.dart';
import 'package:devlink_mobile_app/group/data/dto/group_dto.dart';
import 'package:intl/intl.dart';
import 'group_data_source.dart';

class MockGroupDataSourceImpl implements GroupDataSource {
  final Random _random = Random();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  @override
  Future<List<GroupDto>> fetchGroupList() async {
    await Future.delayed(const Duration(milliseconds: 500));

    return List.generate(15, (i) {
      final memberCount = _random.nextInt(10) + 1;
      final limitMemberCount = memberCount + _random.nextInt(10) + 5;

      // 임의의 생성일과 수정일 생성
      final now = DateTime.now();
      final createdDate = now.subtract(
        Duration(days: _random.nextInt(90)),
      ); // 최대 90일 전
      final updatedDate = createdDate.add(
        Duration(days: _random.nextInt(30)),
      ); // 생성일 이후 최대 30일 후

      // 그룹 소유자 생성
      final owner = MemberDto(
        id: 'owner_$i',
        email: 'owner$i@example.com',
        nickname: '그룹장$i',
        uid: 'uid_owner_$i',
        image: '',
        onAir: i % 3 == 0, // 일부만 온라인 상태
      );

      // 멤버 목록 생성 (소유자 포함)
      final members = [owner];
      for (int j = 1; j < memberCount; j++) {
        members.add(
          MemberDto(
            id: 'member_${i}_$j',
            email: 'member$j@example.com',
            nickname: '멤버$j',
            uid: 'uid_member_${i}_$j',
            image: '',
            onAir: j % 4 == 0, // 일부만 온라인 상태
          ),
        );
      }

      // 해시태그 생성
      final hashTags = [
        HashTagDto(id: 'tag_${i}_1', content: '주제${i % 5 + 1}'),
        HashTagDto(id: 'tag_${i}_2', content: '그룹$i'),
      ];

      // 그룹 주제에 따라 추가 태그
      if (i % 3 == 0) {
        hashTags.add(HashTagDto(id: 'tag_${i}_3', content: '스터디'));
      } else if (i % 3 == 1) {
        hashTags.add(HashTagDto(id: 'tag_${i}_3', content: '프로젝트'));
      } else {
        hashTags.add(HashTagDto(id: 'tag_${i}_3', content: '취미'));
      }

      return GroupDto(
        id: 'group_$i',
        name: '목 그룹 ${i + 1}',
        description: '이것은 테스트용 목 그룹 ${i + 1}입니다. 다양한 사용자와 함께 활동해보세요!',
        members: members,
        hashTags: hashTags,
        limitMemberCount: limitMemberCount,
        owner: owner,
        imageUrl: 'assets/images/group_${i + 1}.png',
        createdAt: _dateFormat.format(createdDate),
        updatedAt: _dateFormat.format(updatedDate),
      );
    });
  }

  @override
  Future<GroupDto> fetchGroupDetail(String groupId) async {
    await Future.delayed(const Duration(milliseconds: 700));

    // 목록에서 ID로 그룹을 찾음
    final groups = await fetchGroupList();
    final originalGroup = groups.firstWhere(
      (group) => group.id == groupId,
      orElse: () => throw Exception('그룹을 찾을 수 없습니다'),
    );

    return GroupDto(
      id: originalGroup.id,
      name: originalGroup.name,
      description: originalGroup.description,
      members: originalGroup.members,
      hashTags: originalGroup.hashTags,
      limitMemberCount: originalGroup.limitMemberCount,
      owner: originalGroup.owner,
      imageUrl: originalGroup.imageUrl,
    );
  }

  @override
  Future<void> fetchJoinGroup(String groupId) async {
    // 가입 성공 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 800));

    // 랜덤으로 실패 케이스 발생 (10% 확률)
    if (_random.nextInt(10) == 0) {
      throw Exception('그룹 참여 중 오류가 발생했습니다');
    }
  }

  @override
  Future<GroupDto> fetchCreateGroup(GroupDto groupDto) async {
    await Future.delayed(const Duration(milliseconds: 1000));

    // 새 ID 부여
    final newId = 'group_${DateTime.now().millisecondsSinceEpoch}';

    // 새 그룹 DTO 생성 (ID만 변경)
    return GroupDto(
      id: newId,
      name: groupDto.name,
      description: groupDto.description,
      members: groupDto.members,
      hashTags: groupDto.hashTags,
      limitMemberCount: groupDto.limitMemberCount,
      owner: groupDto.owner,
      imageUrl: groupDto.imageUrl,
    );
  }

  @override
  Future<void> fetchUpdateGroup(GroupDto groupDto) async {
    await Future.delayed(const Duration(milliseconds: 800));

    // 업데이트 실패 케이스 (5% 확률)
    if (_random.nextInt(20) == 0) {
      throw Exception('그룹 정보 업데이트 중 오류가 발생했습니다');
    }
  }

  @override
  Future<void> fetchLeaveGroup(String groupId) async {
    await Future.delayed(const Duration(milliseconds: 600));

    // 탈퇴 실패 케이스 (5% 확률)
    if (_random.nextInt(20) == 0) {
      throw Exception('그룹 탈퇴 중 오류가 발생했습니다');
    }
  }
}
