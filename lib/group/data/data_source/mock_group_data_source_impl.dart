import 'dart:math';

import 'package:devlink_mobile_app/auth/data/dto/profile_dto_old.dart';
import 'package:devlink_mobile_app/auth/data/dto/user_dto_old.dart';
import 'package:devlink_mobile_app/community/data/dto/hash_tag_dto_old.dart';
import 'package:devlink_mobile_app/community/data/dto/member_dto_old.dart';
import 'package:devlink_mobile_app/group/data/dto/group_dto_old.dart';
import 'package:intl/intl.dart';

import 'group_data_source.dart';

class MockGroupDataSourceImpl implements GroupDataSource {
  final Random _random = Random();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  // 메모리에 그룹 데이터 저장 (실제 DB 역할)
  final List<GroupDto> _groups = [];
  bool _initialized = false;

  // DiceBear API 기반 이미지 URL 생성 함수
  String _generateDiceBearUrl() {
    // 개발/코딩/기술 테마에 적합한 스타일 선택
    final styles = [
      'bottts', // 로봇형 아바타
      'pixel-art', // 픽셀 아트 스타일
      'identicon', // GitHub 스타일 아이덴티콘
      'shapes', // 기하학적 모양
      'initials', // 이니셜 기반 (그룹 이름의 첫 글자)
    ];
    final style = styles[_random.nextInt(styles.length)];

    // 랜덤 시드 값 생성 (그룹마다 다른 이미지가 나오도록)
    final seed =
        DateTime.now().millisecondsSinceEpoch.toString() +
        _random.nextInt(10000).toString();

    // DiceBear API URL 생성
    return 'https://api.dicebear.com/7.x/$style/png?seed=$seed&size=200';
  }

  // 기본 사용자 목록 (제공된 초기화 데이터와 일치)
  final List<Map<String, dynamic>> _defaultUsers = [
    {
      'user': UserDto(
        id: 'user1',
        email: 'test1@example.com'.toLowerCase(),
        nickname: '사용자1',
        uid: 'uid1',
      ),
      'profile': ProfileDto(
        userId: 'user1',
        image: 'https://randomuser.me/api/portraits/men/1.jpg',
        onAir: false,
      ),
      'password': 'password123',
    },
    {
      'user': UserDto(
        id: 'user2',
        email: 'test2@example.com'.toLowerCase(),
        nickname: '사용자2',
        uid: 'uid2',
      ),
      'profile': ProfileDto(
        userId: 'user2',
        image: 'https://randomuser.me/api/portraits/women/2.jpg',
        onAir: true,
      ),
      'password': 'password123',
    },
    {
      'user': UserDto(
        id: 'user3',
        email: 'test3@example.com'.toLowerCase(),
        nickname: '사용자3',
        uid: 'uid3',
      ),
      'profile': ProfileDto(
        userId: 'user3',
        image: 'https://randomuser.me/api/portraits/men/3.jpg',
        onAir: false,
      ),
      'password': 'password123',
    },
    {
      'user': UserDto(
        id: 'user4',
        email: 'test4@example.com'.toLowerCase(),
        nickname: '사용자4',
        uid: 'uid4',
      ),
      'profile': ProfileDto(
        userId: 'user4',
        image: 'https://randomuser.me/api/portraits/women/4.jpg',
        onAir: true,
      ),
      'password': 'password123',
    },
    {
      'user': UserDto(
        id: 'user5',
        email: 'test5@example.com'.toLowerCase(),
        nickname: '사용자5',
        uid: 'uid5',
      ),
      'profile': ProfileDto(
        userId: 'user5',
        image: 'https://randomuser.me/api/portraits/men/5.jpg',
        onAir: false,
      ),
      'password': 'password123',
    },
    {
      'user': UserDto(
        id: 'user6',
        email: 'admin@example.com'.toLowerCase(),
        nickname: '관리자',
        uid: 'uid6',
      ),
      'profile': ProfileDto(
        userId: 'user6',
        image: 'https://randomuser.me/api/portraits/women/6.jpg',
        onAir: true,
      ),
      'password': 'admin123',
    },
    {
      'user': UserDto(
        id: 'user7',
        email: 'developer@example.com'.toLowerCase(),
        nickname: '개발자',
        uid: 'uid7',
      ),
      'profile': ProfileDto(
        userId: 'user7',
        image: 'https://randomuser.me/api/portraits/men/7.jpg',
        onAir: true,
      ),
      'password': 'dev123',
    },
  ];

  // Mock 데이터 초기화
  Future<void> _initializeIfNeeded() async {
    if (_initialized) return;

    // 초기 15개 그룹 생성 및 저장
    _groups.addAll(
      List.generate(15, (i) {
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

        // DiceBear API로 그룹 이미지 URL 생성
        final imageUrl = _generateDiceBearUrl();

        return GroupDto(
          id: 'group_$i',
          name: groupName,
          description:
              '${owner.nickname}님이 만든 ${hashTags.map((tag) => tag.content).join(', ')} 그룹입니다. 현재 ${members.length}명이 활동 중입니다!',
          members: members,
          hashTags: hashTags,
          limitMemberCount: limitMemberCount,
          owner: owner,
          imageUrl: imageUrl,
          // DiceBear API 이미지 URL 사용
          createdAt: _dateFormat.format(createdDate),
          updatedAt: _dateFormat.format(updatedDate),
        );
      }),
    );

    _initialized = true;
  }

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

  @override
  Future<List<GroupDto>> fetchGroupList() async {
    await Future.delayed(const Duration(milliseconds: 500));
    await _initializeIfNeeded();

    // 모든 그룹의 목록을 반환 (새로 생성된 그룹 포함)
    return List.from(_groups); // 복사본 반환
  }

  @override
  Future<List<GroupDto>> fetchUserJoinedGroups(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    await _initializeIfNeeded();

    // 사용자가 멤버로 포함된 그룹만 필터링
    final userGroups =
        _groups
            .where(
              (group) =>
                  group.members?.any((member) => member.id == userId) ?? false,
            )
            .toList();

    print(
      '🔍 User $userId joined groups: ${userGroups.length} out of ${_groups.length}',
    );

    return userGroups;
  }

  @override
  Future<GroupDto> fetchGroupDetail(String groupId) async {
    await Future.delayed(const Duration(milliseconds: 700));
    await _initializeIfNeeded();

    print('🔍 Searching for group with ID: $groupId');
    print('🔍 Available group IDs: ${_groups.map((g) => g.id).join(', ')}');

    // 저장된 그룹 목록에서 ID로 검색
    final group = _groups.firstWhere(
      (group) => group.id == groupId,
      orElse: () {
        print('❌ Group not found with ID: $groupId');
        throw Exception('그룹을 찾을 수 없습니다: $groupId');
      },
    );

    print('✅ Found group: ${group.id}, name: ${group.name}');

    return group;
  }

  @override
  Future<void> fetchJoinGroup(String groupId) async {
    // 가입 성공 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 800));
    await _initializeIfNeeded();

    // 그룹 존재 확인
    final groupIndex = _groups.indexWhere((g) => g.id == groupId);
    if (groupIndex == -1) {
      throw Exception('참여할 그룹을 찾을 수 없습니다: $groupId');
    }

    // 랜덤으로 실패 케이스 발생 (10% 확률)
    if (_random.nextInt(10) == 0) {
      throw Exception('그룹 참여 중 오류가 발생했습니다');
    }

    // 여기서 사용자를 그룹에 추가하는 로직 구현 가능
    // (현재는 간단한 성공만 시뮬레이션)
  }

  @override
  Future<GroupDto> fetchCreateGroup(GroupDto groupDto) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    await _initializeIfNeeded();

    // 새 ID 부여
    final newId = 'group_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    // DiceBear API로 그룹 이미지 URL 생성
    final imageUrl = _generateDiceBearUrl();

    // 새 그룹 DTO 생성
    final createdGroup = GroupDto(
      id: newId,
      name: groupDto.name,
      description: groupDto.description,
      members: groupDto.members ?? [],
      // null 방지
      hashTags: groupDto.hashTags ?? [],
      // null 방지
      limitMemberCount: groupDto.limitMemberCount?.toInt() ?? 10,
      // 기본값 제공
      owner: groupDto.owner,
      imageUrl: imageUrl,
      // DiceBear API로 생성된 이미지 URL
      createdAt: _dateFormat.format(now),
      updatedAt: _dateFormat.format(now),
    );

    // 생성된 그룹을 메모리에 저장
    _groups.add(createdGroup);

    print(
      '🔍 Group created and added to memory: ${createdGroup.id}, name: ${createdGroup.name}',
    );
    print('🔍 Total groups in memory: ${_groups.length}');

    return createdGroup;
  }

  @override
  Future<void> fetchUpdateGroup(GroupDto groupDto) async {
    await Future.delayed(const Duration(milliseconds: 800));
    await _initializeIfNeeded();

    // 업데이트 실패 케이스 (5% 확률)
    if (_random.nextInt(20) == 0) {
      throw Exception('그룹 정보 업데이트 중 오류가 발생했습니다');
    }

    // 기존 그룹 찾기
    final index = _groups.indexWhere((g) => g.id == groupDto.id);
    if (index >= 0) {
      // 그룹 업데이트
      _groups[index] = groupDto;
      print('🔍 Group updated: ${groupDto.id}, name: ${groupDto.name}');
    } else {
      throw Exception('업데이트할 그룹을 찾을 수 없습니다: ${groupDto.id}');
    }
  }

  @override
  Future<void> fetchLeaveGroup(String groupId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    await _initializeIfNeeded();

    // 그룹 존재 확인
    final groupIndex = _groups.indexWhere((g) => g.id == groupId);
    if (groupIndex == -1) {
      throw Exception('탈퇴할 그룹을 찾을 수 없습니다: $groupId');
    }

    // 탈퇴 실패 케이스 (5% 확률)
    if (_random.nextInt(20) == 0) {
      throw Exception('그룹 탈퇴 중 오류가 발생했습니다');
    }

    // 여기서 사용자를 그룹에서 제거하는 로직 구현 가능
    // (현재는 간단한 성공만 시뮬레이션)
    print('🔍 Left group: $groupId');
  }

  Future<List<GroupDto>> searchGroups(String query) async {
    await Future.delayed(const Duration(milliseconds: 500));
    await _initializeIfNeeded();

    // 쿼리 전처리 (소문자로 변환하여 대소문자 구분 없게)
    final queryLower = query.toLowerCase();

    // 이름, 설명, 해시태그에서 검색어 포함 여부 확인
    final filtered =
        _groups.where((group) {
          // 이름에서 검색
          if ((group.name ?? '').toLowerCase().contains(queryLower)) {
            return true;
          }

          // 설명에서 검색
          if ((group.description ?? '').toLowerCase().contains(queryLower)) {
            return true;
          }

          // 해시태그에서 검색
          if (group.hashTags?.any(
                (tag) => (tag.content ?? '').toLowerCase().contains(queryLower),
              ) ??
              false) {
            return true;
          }

          return false;
        }).toList();

    return filtered;
  }
}
