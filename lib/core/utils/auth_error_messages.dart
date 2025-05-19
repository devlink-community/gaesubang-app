// lib/core/utils/auth_error_messages.dart
class AuthErrorMessages {
  const AuthErrorMessages._();

  // === 로그인 관련 ===
  static const String loginFailed = '이메일 또는 비밀번호가 올바르지 않습니다';
  static const String userNotFound = '등록되지 않은 이메일입니다';
  static const String wrongPassword = '비밀번호가 올바르지 않습니다';
  static const String noLoggedInUser = '로그인이 필요합니다';

  // === 회원가입 관련 ===
  static const String emailAlreadyInUse = '이미 사용 중인 이메일입니다';
  static const String nicknameAlreadyInUse = '이미 사용 중인 닉네임입니다';
  static const String weakPassword = '비밀번호가 너무 단순합니다';
  static const String accountCreationFailed = '회원가입에 실패했습니다';

  // === 유효성 검사 관련 ===
  static const String invalidEmail = '유효하지 않은 이메일 형식입니다';
  static const String termsNotAgreed = '필수 약관에 동의해야 합니다';

  // 입력 필드 누락 메시지
  static const String emailRequired = '이메일을 입력해주세요';
  static const String nicknameRequired = '닉네임을 입력해주세요';
  static const String passwordRequired = '비밀번호를 입력해주세요';
  static const String passwordConfirmRequired = '비밀번호 확인을 입력해주세요';
  static const String termsRequired = '이용약관에 동의해주세요';

  // 길이 및 형식 검증 메시지
  static const String nicknameTooShort = '닉네임은 2자 이상이어야 합니다';
  static const String nicknameTooLong = '닉네임은 10자 이하여야 합니다';
  static const String nicknameInvalidFormat = '닉네임은 한글, 영문, 숫자만 사용 가능합니다';
  static const String passwordTooShort = '비밀번호는 8자 이상이어야 합니다';
  static const String passwordComplexity = '비밀번호는 대문자, 소문자, 숫자, 특수문자를 포함해야 합니다';
  static const String passwordMismatch = '비밀번호가 일치하지 않습니다';

  // === 중복 확인 관련 ===
  static const String nicknameCheckFailed = '닉네임 중복 확인 중 오류가 발생했습니다';
  static const String emailCheckFailed = '이메일 중복 확인 중 오류가 발생했습니다';
  static const String nicknameSuccess = '사용 가능한 닉네임입니다';
  static const String emailSuccess = '사용 가능한 이메일입니다';

  // === 폼 검증 관련 ===
  static const String formValidationFailed = '입력 정보를 확인해주세요';
  static const String duplicateCheckRequired = '닉네임 또는 이메일 중복을 확인해주세요';

  // === 약관 관련 ===
  static const String termsProcessFailed =
      '약관 동의 처리에 실패했습니다. 직접 약관 화면에서 동의해주세요';
  static const String termsProcessError =
      '약관 동의 처리 중 오류가 발생했습니다. 직접 약관 화면에서 동의해주세요';

  // === 비밀번호 재설정 관련 ===
  static const String passwordResetFailed = '비밀번호 재설정 이메일 전송에 실패했습니다';
  static const String passwordResetSuccess =
      '비밀번호 재설정 이메일이 발송되었습니다. 이메일을 확인해주세요';

  // === 시스템 관련 ===
  static const String networkError = '인터넷 연결을 확인해주세요';
  static const String timeoutError = '요청 시간이 초과되었습니다. 다시 시도해주세요';
  static const String serverError = '서버에 문제가 발생했습니다. 잠시 후 다시 시도해주세요';
  static const String unknownError = '알 수 없는 오류가 발생했습니다';

  // === 데이터 관련 ===
  static const String userDataNotFound = '사용자 정보를 찾을 수 없습니다';
  static const String dataLoadFailed = '데이터를 불러오는데 실패했습니다';
}
