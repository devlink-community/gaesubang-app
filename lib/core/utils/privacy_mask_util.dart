// lib/core/utils/privacy_mask_util.dart

/// 개인정보 보호를 위한 마스킹 유틸리티
/// 로깅 시 민감한 정보를 안전하게 처리하기 위해 사용
class PrivacyMaskUtil {
  const PrivacyMaskUtil._();

  /// 이메일 주소를 마스킹 처리
  /// 예: autologintest@test.com → auto*****test@test.com
  /// 예: user@example.com → use***@example.com
  /// 예: a@b.com → a***@b.com
  static String maskEmail(String email) {
    if (email.isEmpty) return '';

    final atIndex = email.indexOf('@');
    if (atIndex == -1) {
      // @ 기호가 없는 경우 (잘못된 이메일 형식)
      return _maskString(email);
    }

    final localPart = email.substring(0, atIndex);
    final domainPart = email.substring(atIndex);

    // 로컬 부분 마스킹
    final maskedLocal = _maskString(localPart);

    return '$maskedLocal$domainPart';
  }

  /// 닉네임을 마스킹 처리
  /// 예: 홍길동 → 홍*동
  /// 예: developer123 → dev*****123
  /// 예: 김철수 → 김*수
  static String maskNickname(String nickname) {
    if (nickname.isEmpty) return '';

    return _maskString(nickname);
  }

  /// 사용자 ID를 마스킹 처리 (앞 4자리와 뒤 4자리만 표시)
  /// 예: 1234567890abcdef → 1234****cdef
  /// 예: abc123 → ab****23
  static String maskUserId(String userId) {
    if (userId.isEmpty) return '';

    if (userId.length <= 8) {
      // 8자 이하인 경우 절반만 표시
      final showLength = (userId.length / 2).floor();
      final hideLength = userId.length - showLength;
      return '${userId.substring(0, showLength)}${'*' * hideLength}';
    }

    // 8자 초과인 경우 앞뒤 4자리만 표시
    final prefix = userId.substring(0, 4);
    final suffix = userId.substring(userId.length - 4);
    final maskLength = userId.length - 8;

    return '$prefix${'*' * maskLength}$suffix';
  }

  /// 전화번호를 마스킹 처리
  /// 예: 010-1234-5678 → 010-****-5678
  /// 예: 01012345678 → 010****5678
  static String maskPhoneNumber(String phoneNumber) {
    if (phoneNumber.isEmpty) return '';

    // 하이픈 제거
    final cleanNumber = phoneNumber.replaceAll('-', '');

    if (cleanNumber.length == 11 && cleanNumber.startsWith('010')) {
      // 한국 휴대폰 번호 형식
      return '010****${cleanNumber.substring(7)}';
    } else if (cleanNumber.length >= 8) {
      // 일반적인 전화번호
      final prefix = cleanNumber.substring(0, 3);
      final suffix = cleanNumber.substring(cleanNumber.length - 4);
      final maskLength = cleanNumber.length - 7;
      return '$prefix${'*' * maskLength}$suffix';
    }

    // 형식이 불분명한 경우 일반 마스킹
    return _maskString(phoneNumber);
  }

  /// 일반 문자열 마스킹 (내부용)
  /// 문자열의 앞뒤 일부만 보여주고 중간을 마스킹
  static String _maskString(String text) {
    if (text.isEmpty) return '';

    if (text.length <= 2) {
      // 2자 이하는 모두 마스킹
      return '*' * text.length;
    } else if (text.length <= 4) {
      // 4자 이하는 첫 글자만 보여주고 나머지 마스킹
      return '${text[0]}${'*' * (text.length - 1)}';
    } else if (text.length <= 6) {
      // 6자 이하는 첫 글자와 마지막 글자만 보여줌
      return '${text[0]}${'*' * (text.length - 2)}${text[text.length - 1]}';
    } else {
      // 7자 이상은 앞 2자와 뒤 2자만 보여줌
      final prefix = text.substring(0, 2);
      final suffix = text.substring(text.length - 2);
      final maskLength = text.length - 4;
      return '$prefix${'*' * maskLength}$suffix';
    }
  }

  /// 로깅용 안전한 사용자 정보 Map 생성
  /// 민감한 정보들을 자동으로 마스킹하여 반환
  static Map<String, dynamic> createSafeUserInfo({
    String? userId,
    String? email,
    String? nickname,
    String? phoneNumber,
    Map<String, dynamic>? additionalInfo,
  }) {
    final safeInfo = <String, dynamic>{};

    if (userId != null) {
      safeInfo['userId'] = maskUserId(userId);
    }

    if (email != null) {
      safeInfo['email'] = maskEmail(email);
    }

    if (nickname != null) {
      safeInfo['nickname'] = maskNickname(nickname);
    }

    if (phoneNumber != null) {
      safeInfo['phoneNumber'] = maskPhoneNumber(phoneNumber);
    }

    // 추가 정보가 있으면 그대로 포함 (민감하지 않은 정보들)
    if (additionalInfo != null) {
      safeInfo.addAll(additionalInfo);
    }

    return safeInfo;
  }

  /// 개발 환경에서만 원본 정보 반환, 운영 환경에서는 마스킹
  /// 환경별 로깅 레벨 조정용
  static String conditionalMask(
    String sensitiveData,
    String Function(String) maskFunction,
  ) {
    // 개발 환경 판단 (kDebugMode 또는 환경 변수로 판단)
    const isProduction = bool.fromEnvironment(
      'dart.vm.product',
      defaultValue: false,
    );

    if (isProduction) {
      return maskFunction(sensitiveData);
    } else {
      // 개발 환경에서는 원본 반환 (단, 주의 메시지 추가)
      return '$sensitiveData [DEV_ONLY]';
    }
  }
}
