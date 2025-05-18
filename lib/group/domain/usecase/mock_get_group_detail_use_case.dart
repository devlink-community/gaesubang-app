import 'package:devlink_mobile_app/auth/domain/model/member.dart';
import 'package:devlink_mobile_app/community/domain/model/hash_tag.dart';
import 'package:devlink_mobile_app/group/domain/model/group.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class MockGetGroupDetailUseCase {
  MockGetGroupDetailUseCase();

  Future<AsyncValue<Group>> execute(String groupId) async {
    // 지연 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 500));

    // MockAttendanceDataSourceImpl의 _mockData와 일치하는 그룹 반환
    final mockGroup = Group(
      id: groupId,
      name: '출석부 테스트 그룹',
      description: '출석부 Mock 데이터용 그룹입니다.',
      members: [
        const Member(
          id: 'user1', // MockAttendanceDataSourceImpl의 memberId와 일치
          email: 'user1@example.com',
          nickname: '사용자1',
          uid: 'uid1',
          onAir: true,
        ),
        const Member(
          id: 'user2',
          email: 'user2@example.com',
          nickname: '사용자2',
          uid: 'uid2',
          onAir: false,
        ),
        const Member(
          id: 'user3',
          email: 'user3@example.com',
          nickname: '사용자3',
          uid: 'uid3',
          onAir: true,
        ),
      ],
      hashTags: [
        HashTag(id: 'tag1', content: '출석'),
        HashTag(id: 'tag2', content: '테스트'),
      ],
      limitMemberCount: 10,
      owner: const Member(
        id: 'user1',
        email: 'user1@example.com',
        nickname: '사용자1',
        uid: 'uid1',
        onAir: true,
      ),
      imageUrl: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return AsyncData(mockGroup);
  }
}
