// lib/core/utils/profile_error_messages.dart
class ProfileErrorMessages {
  const ProfileErrorMessages._();

  // === 프로필 로드 관련 ===
  static const String profileLoadFailed = '프로필을 불러오는데 실패했습니다';
  static const String profileDataNotFound = '프로필 정보를 찾을 수 없습니다';

  // === 프로필 업데이트 관련 ===
  static const String profileUpdateFailed = '프로필 저장에 실패했습니다';
  static const String profileUpdateSuccess = '프로필이 성공적으로 저장되었습니다';

  // === 프로필 이미지 관련 ===
  static const String imageUploadFailed = '이미지 업로드에 실패했습니다';
  static const String imageUploadSuccess = '프로필 이미지가 성공적으로 업데이트되었습니다';
  static const String imageUpdateFailed = '프로필 이미지를 업데이트할 수 없습니다';
  static const String imageLoadFailed = '이미지를 불러올 수 없습니다';

  // === 입력 유효성 관련 ===
  static const String nicknameUpdateRequired = '닉네임을 입력해주세요';
  static const String profileDataIncomplete = '필수 정보를 모두 입력해주세요';

  // === 시스템 관련 ===
  static const String networkErrorProfile = '네트워크 연결을 확인하고 다시 시도해주세요';
  static const String timeoutErrorProfile = '시간이 초과되었습니다. 다시 시도해주세요';
  static const String serverErrorProfile = '서버에 문제가 발생했습니다. 잠시 후 다시 시도해주세요';
  static const String unknownErrorProfile = '알 수 없는 오류가 발생했습니다';

  // === 기타 ===
  static const String noChangesToSave = '변경된 내용이 없습니다';
  static const String unsupportedImageFormat = '지원되지 않는 이미지 형식입니다';
}
