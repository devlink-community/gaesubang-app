// lib/core/utils/messages/storage_error_messages.dart
/// 스토리지 관련 에러 메시지 모음
class StorageErrorMessages {
  const StorageErrorMessages._(); // 인스턴스화 방지

  // 공통
  static const String unknownError = '알 수 없는 오류가 발생했습니다';
  static const String networkError = '인터넷 연결을 확인해주세요';
  static const String timeoutError = '요청 시간이 초과되었습니다';
  static const String serverError = '서버에 문제가 발생했습니다';

  // 업로드 관련
  static const String uploadFailed = '파일 업로드에 실패했습니다';
  static const String uploadCanceled = '업로드가 취소되었습니다';
  static const String invalidData = '잘못된 파일 데이터입니다';
  static const String invalidFileType = '지원하지 않는 파일 형식입니다';
  static const String fileTooLarge = '파일 크기가 너무 큽니다';
  static const String quotaExceeded = '스토리지 용량이 초과되었습니다';

  // 다운로드 관련
  static const String downloadFailed = '파일 다운로드에 실패했습니다';
  static const String fileNotFound = '파일을 찾을 수 없습니다';

  // 권한 관련
  static const String unauthorized = '파일 접근 권한이 없습니다';
  static const String permissionDenied = '권한이 거부되었습니다';

  // 삭제 관련
  static const String deleteFailed = '파일 삭제에 실패했습니다';
  static const String folderDeleteFailed = '폴더 삭제에 실패했습니다';

  // 이미지 관련
  static const String imageProcessingFailed = '이미지 처리에 실패했습니다';
  static const String imageCompressionFailed = '이미지 압축에 실패했습니다';
  static const String invalidImageFormat = '지원하지 않는 이미지 형식입니다';
  static const String imageTooLarge = '이미지 크기가 너무 큽니다 (최대 5MB)';

  // 기타
  static const String retryLater = '잠시 후 다시 시도해주세요';
  static const String contactSupport = '문제가 지속될 경우 고객센터에 문의해주세요';
}
