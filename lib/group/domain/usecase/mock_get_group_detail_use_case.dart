// lib/group/domain/usecase/mock_get_group_detail_use_case.dart
import 'package:devlink_mobile_app/group/domain/model/group.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class MockGetGroupDetailUseCase {
  MockGetGroupDetailUseCase();

  Future<AsyncValue<Group>> execute(String groupId) async {
    // 지연 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 500));

    // 수정된 Group 모델에 맞게 Mock 데이터 생성
    final mockGroup = Group(
      id: groupId,
      name: '출석부 테스트 그룹',
      description: '출석부 Mock 데이터용 그룹입니다.',
      imageUrl: null,
      createdAt: DateTime.now(),
      createdBy: 'user1', // 생성자 ID
      maxMemberCount: 10,
      hashTags: ['출석', '테스트'], // 해시태그는 이제 String 리스트
      memberCount: 3,
      isJoinedByCurrentUser: true, // 현재 사용자 참여 상태
    );

    return AsyncData(mockGroup);
  }
}
