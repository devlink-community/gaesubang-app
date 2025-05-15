import 'dart:math';
import 'package:devlink_mobile_app/auth/data/dto/profile_dto.dart';
import 'package:devlink_mobile_app/auth/data/dto/user_dto.dart';
import 'package:devlink_mobile_app/community/data/dto/hash_tag_dto.dart';
import 'package:devlink_mobile_app/community/data/dto/member_dto.dart';
import 'package:devlink_mobile_app/group/data/dto/group_dto.dart';
import 'package:intl/intl.dart';
import 'group_data_source.dart';

class MockGroupDataSourceImpl implements GroupDataSource {
  final Random _random = Random();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  // 기본 사용자 목록 (제공된 초기화 데이터와 일치)
  final List<Map<String, dynamic>> _defaultUsers = [
    {
      'user': UserDto(
        id: 'user1',
        email: 'test1@example.com'.toLowerCase(),
        nickname: '사용자1',
        uid: 'uid1',
      ),
      'profile': ProfileDto(userId: 'user1', image: '', onAir: false),
      'password': 'password123',
    },
    {
      'user': UserDto(
        id: 'user2',
        email: 'test2@example.com'.toLowerCase(),
        nickname: '사용자2',
        uid: 'uid2',
      ),
      'profile': ProfileDto(userId: 'user2', image: '', onAir: true),
      'password': 'password123',
    },
    {
      'user': UserDto(
        id: 'user3',
        email: 'test3@example.com'.toLowerCase(),
        nickname: '사용자3',
        uid: 'uid3',
      ),
      'profile': ProfileDto(userId: 'user3', image: '', onAir: false),
      'password': 'password123',
    },
    {
      'user': UserDto(
        id: 'user4',
        email: 'test4@example.com'.toLowerCase(),
        nickname: '사용자4',
        uid: 'uid4',
      ),
      'profile': ProfileDto(userId: 'user4', image: '', onAir: true),
      'password': 'password123',
    },
    {
      'user': UserDto(
        id: 'user5',
        email: 'test5@example.com'.toLowerCase(),
        nickname: '사용자5',
        uid: 'uid5',
      ),
      'profile': ProfileDto(userId: 'user5', image: '', onAir: false),
      'password': 'password123',
    },
    {
      'user': UserDto(
        id: 'user6',
        email: 'admin@example.com'.toLowerCase(),
        nickname: '관리자',
        uid: 'uid6',
      ),
      'profile': ProfileDto(userId: 'user6', image: '', onAir: true),
      'password': 'admin123',
    },
    {
      'user': UserDto(
        id: 'user7',
        email: 'developer@example.com'.toLowerCase(),
        nickname: '개발자',
        uid: 'uid7',
      ),
      'profile': ProfileDto(userId: 'user7', image: '', onAir: true),
      'password': 'dev123',
    },
  ];

  // UserDto에서 MemberDto로 변환하는 헬퍼 메서드
  MemberDto _userToMember(UserDto user, ProfileDto profile) {
    return MemberDto(
      id: user.id,
      email: user.email,
      nickname: user.nickname,
      uid: user.uid,
      image: profile.image,
      onAir: profile.onAir,
    );
  }

  // 랜덤하게 사용자를 선택
  Map<String, dynamic> _getRandomUser() {
    final index = _random.nextInt(_defaultUsers.length);
    return _defaultUsers[index];
  }

  @override
  Future<List<GroupDto>> fetchGroupList() async {
    await Future.delayed(const Duration(milliseconds: 500));

    return List.generate(15, (i) {
      // 랜덤 멤버 수 (소유자 포함)
      final memberCount = _random.nextInt(5) + 1; // 1~5명의 멤버
      final limitMemberCount =
          memberCount + _random.nextInt(5) + 2; // 현재 멤버 수 + 2~6명 여유

      // 임의의 생성일과 수정일 생성
      final now = DateTime.now();
      final createdDate = now.subtract(
        Duration(days: _random.nextInt(90)),
      ); // 최대 90일 전
      final updatedDate = createdDate.add(
        Duration(days: _random.nextInt(30)),
      ); // 생성일 이후 최대 30일 후

      // 그룹 소유자 - 실제 기본 사용자 중 하나를 선택
      final ownerData = _defaultUsers[i % _defaultUsers.length]; // 순환하며 선택
      final ownerUser = ownerData['user'] as UserDto;
      final ownerProfile = ownerData['profile'] as ProfileDto;
      final owner = _userToMember(ownerUser, ownerProfile);

      // 멤버 목록 생성 (소유자 포함)
      final members = <MemberDto>[owner];

      // 소유자를 제외한 추가 멤버 (기본 사용자 풀에서 선택)
      final availableUsers = List<Map<String, dynamic>>.from(_defaultUsers);
      availableUsers.removeWhere(
        (userData) => userData['user'].id == owner.id,
      ); // 소유자 제외

      // 랜덤하게 추가 멤버 선택
      availableUsers.shuffle(_random);
      for (int j = 0; j < min(memberCount - 1, availableUsers.length); j++) {
        final userData = availableUsers[j];
        final user = userData['user'] as UserDto;
        final profile = userData['profile'] as ProfileDto;
        members.add(_userToMember(user, profile));
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

      // 그룹명 생성 - 일관성 있게
      String groupName;
      if (i % 3 == 0) {
        groupName = '${owner.nickname}의 스터디 그룹';
      } else if (i % 3 == 1) {
        groupName = '${owner.nickname}의 프로젝트';
      } else {
        groupName = '${owner.nickname}의 모임';
      }

      return GroupDto(
        id: 'group_$i',
        name: groupName,
        description:
            '${owner.nickname}님이 만든 ${hashTags.map((tag) => tag.content).join(', ')} 그룹입니다. 현재 ${members.length}명이 활동 중입니다!',
        members: members,
        hashTags: hashTags,
        limitMemberCount: limitMemberCount,
        owner: owner,
        imageUrl: 'assets/images/group_${(i % 5) + 1}.png', // 5개의 기본 이미지 순환
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

    return originalGroup; // 동일한 객체 반환 (더 이상 새 객체 생성하지 않음)
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
    final now = DateTime.now();

    // 새 그룹 DTO 생성
    return GroupDto(
      id: newId,
      name: groupDto.name,
      description: groupDto.description,
      members: groupDto.members,
      hashTags: groupDto.hashTags,
      limitMemberCount: groupDto.limitMemberCount,
      owner: groupDto.owner,
      imageUrl: groupDto.imageUrl,
      createdAt: _dateFormat.format(now),
      updatedAt: _dateFormat.format(now),
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
