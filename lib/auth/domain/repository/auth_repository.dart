import 'package:devlink_mobile_app/auth/domain/model/member.dart';
import 'package:devlink_mobile_app/core/result/result.dart';

abstract interface class AuthRepository {
  /// 이메일, 비밀번호로 로그인
  Future<Result<Member>> login({
    required String email,
    required String password,
  });

  /// 이메일, 비밀번호, 닉네임으로 회원가입
  Future<Result<Member>> signup({
    required String email,
    required String password,
    required String nickname,
  });

  /// 현재 로그인된 유저 조회
  Future<Result<Member?>> getCurrentUser();

  /// 로그아웃
  Future<Result<void>> signOut();

  /// 회원탈퇴
  Future<Result<void>> deleteAccount();
}
