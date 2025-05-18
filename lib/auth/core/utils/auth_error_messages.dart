// lib/auth/core/utils/auth_error_messages.dart

/// 인증 관련 모든 오류 메시지를 중앙에서 관리하는 상수 클래스
class AuthErrorMessages {
  AuthErrorMessages._(); // 인스턴스화 방지

  // 로그인 관련 오류 메시지
  static const String invalidCredentials = '이메일 또는 비밀번호가 일치하지 않습니다';
  static const String accountNotFound = '등록되지 않은 계정입니다';
  static const String accountDisabled = '계정이 비활성화되었습니다';
  static const String tooManyRequests = '너무 많은 시도가 있었습니다. 잠시 후 다시 시도해주세요';

  // 회원가입 관련 오류 메시지
  static const String emailAlreadyInUse = '이미 사용 중인 이메일입니다';
  static const String nicknameAlreadyInUse = '이미 사용 중인 닉네임입니다';
  static const String invalidEmail = '유효하지 않은 이메일 형식입니다';
  static const String weakPassword = '비밀번호는 8자 이상이어야 하며, 문자, 숫자, 특수문자를 포함해야 합니다';
  static const String passwordsDontMatch = '비밀번호가 일치하지 않습니다';
  static const String nicknameTooShort = '닉네임은 2자 이상이어야 합니다';
  static const String nicknameTooLong = '닉네임은 10자 이하여야 합니다';
  static const String nicknameInvalidCharacters = '닉네임은 한글, a-z, A-Z, 0-9만 사용 가능합니다';
  static const String termsNotAgreed = '필수 약관에 동의해주세요';

  // 비밀번호 재설정 관련 오류 메시지
  static const String passwordResetFailed = '비밀번호 재설정에 실패했습니다';
  static const String emailNotRegistered = '등록되지 않은 이메일입니다';
  static const String emailSendFailed = '이메일 전송에 실패했습니다';

  // 약관 관련 오류 메시지
  static const String termsLoadFailed = '약관 정보를 불러오는데 실패했습니다';
  static const String termsSaveFailed = '약관 동의 저장에 실패했습니다';

  // 네트워크 관련 오류 메시지
  static const String networkError = '인터넷 연결을 확인해주세요';
  static const String serverError = '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요';
  static const String timeout = '요청 시간이 초과되었습니다. 잠시 후 다시 시도해주세요';

  // 일반 오류 메시지
  static const String unknown = '알 수 없는 오류가 발생했습니다';
  static const String operationFailed = '작업을 완료할 수 없습니다';
}