// lib/auth/domain/usecase/validate_email_use_case.dart
class ValidateEmailUseCase {
  Future<String?> execute(String email) async {
    if (email.isEmpty) {
      return '이메일을 입력해주세요';
    }

    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      return '유효한 이메일 형식이 아닙니다';
    }

    return null; // 유효한 경우
  }
}