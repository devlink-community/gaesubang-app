// lib/auth/domain/repository/auth_profile_repository.dart
import 'package:devlink_mobile_app/auth/domain/model/user.dart';
import 'package:devlink_mobile_app/core/result/result.dart';

/// 사용자 프로필 관리 Repository
abstract interface class AuthProfileRepository {
  /// 프로필 정보 업데이트
  Future<Result<User>> updateProfile({
    required String nickname,
    String? description,
    String? position,
    String? skills,
  });

  /// 프로필 이미지 업데이트
  Future<Result<User>> updateProfileImage(String imagePath);

  /// 사용자 프로필 조회 (다른 사용자)
  Future<Result<User>> getUserProfile(String userId);
}
