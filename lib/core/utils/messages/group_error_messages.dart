// lib/core/utils/messages/group_error_messages.dart
/// 그룹 관련 에러 메시지 모음
class GroupErrorMessages {
  const GroupErrorMessages._(); // 인스턴스화 방지

  // 공통
  static const String loadFailed = '그룹 정보를 불러오는데 실패했습니다';
  static const String notFound = '그룹을 찾을 수 없습니다';
  static const String searchFailed = '그룹 검색 중 오류가 발생했습니다';

  // 그룹 생성/수정
  static const String createFailed = '그룹 생성에 실패했습니다';
  static const String updateFailed = '그룹 정보 수정에 실패했습니다';
  static const String invalidInput = '유효하지 않은 입력입니다';

  // 그룹 가입/탈퇴
  static const String joinFailed = '그룹 가입에 실패했습니다';
  static const String leaveFailed = '그룹 탈퇴에 실패했습니다';
  static const String alreadyJoined = '이미 가입한 그룹입니다';
  static const String notMember = '해당 그룹의 멤버가 아닙니다';
  static const String memberLimitReached = '그룹 최대 인원에 도달했습니다';
  static const String ownerCannotLeave = '그룹 소유자는 탈퇴할 수 없습니다';

  // 사용자 관련
  static const String userNotFound = '사용자를 찾을 수 없습니다';
  static const String unauthorized = '권한이 없습니다';

  // 이미지 관련
  static const String imageFailed = '이미지 업로드에 실패했습니다';
  static const String invalidImage = '유효하지 않은 이미지 파일입니다';
  static const String imageTooLarge = '이미지 크기가 너무 큽니다 (최대 5MB)';

  // 타이머 관련
  static const String operationFailed = '작업을 완료할 수 없습니다';
  static const String timerNotActive = '활성화된 타이머가 없습니다';
}
