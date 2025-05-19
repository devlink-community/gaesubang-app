import 'package:devlink_mobile_app/auth/data/data_source/auth_data_source.dart';
import 'package:devlink_mobile_app/auth/data/dto/timer_activity_dto.dart';
import 'package:devlink_mobile_app/auth/data/mapper/user_mapper.dart';
import 'package:devlink_mobile_app/auth/domain/model/member.dart';
import 'package:devlink_mobile_app/auth/domain/model/terms_agreement.dart';
import 'package:devlink_mobile_app/auth/domain/repository/auth_repository.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/core/utils/auth_error_messages.dart';
import 'package:devlink_mobile_app/core/utils/auth_exception_mapper.dart';
import 'package:flutter/foundation.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource _authDataSource;

  AuthRepositoryImpl({required AuthDataSource authDataSource})
    : _authDataSource = authDataSource;

  @override
  Future<Result<Member>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _authDataSource.fetchLogin(
        email: email,
        password: password,
      );

      // Map을 직접 Member로 변환
      final member = response.toMember();

      return Result.success(member);
    } catch (e, st) {
      debugPrint('Login error: $e');
      debugPrint('StackTrace: $st');
      return Result.error(AuthExceptionMapper.mapAuthException(e, st));
    }
  }

  @override
  Future<Result<Member>> signup({
    required String email,
    required String password,
    required String nickname,
    String? agreedTermsId,
  }) async {
    try {
      final response = await _authDataSource.createUser(
        email: email,
        password: password,
        nickname: nickname,
        agreedTermsId: agreedTermsId,
      );

      // Map을 직접 Member로 변환
      final member = response.toMember();

      return Result.success(member);
    } catch (e, st) {
      return Result.error(AuthExceptionMapper.mapAuthException(e, st));
    }
  }

  @override
  Future<Result<Member>> getCurrentUser() async {
    try {
      final response = await _authDataSource.fetchCurrentUser();
      if (response == null) {
        return Result.error(
          Failure(FailureType.unauthorized, AuthErrorMessages.noLoggedInUser),
        );
      }

      // Map을 직접 Member로 변환
      final member = response.toMember();

      return Result.success(member);
    } catch (e, st) {
      return Result.error(AuthExceptionMapper.mapAuthException(e, st));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _authDataSource.signOut();
      return const Result.success(null);
    } catch (e, st) {
      return Result.error(AuthExceptionMapper.mapAuthException(e, st));
    }
  }

  @override
  Future<Result<bool>> checkNicknameAvailability(String nickname) async {
    try {
      final isAvailable = await _authDataSource.checkNicknameAvailability(
        nickname,
      );
      return Result.success(isAvailable);
    } catch (e, st) {
      return Result.error(AuthExceptionMapper.mapAuthException(e, st));
    }
  }

  @override
  Future<Result<bool>> checkEmailAvailability(String email) async {
    try {
      final isAvailable = await _authDataSource.checkEmailAvailability(email);
      return Result.success(isAvailable);
    } catch (e, st) {
      return Result.error(AuthExceptionMapper.mapAuthException(e, st));
    }
  }

  @override
  Future<Result<void>> resetPassword(String email) async {
    try {
      await _authDataSource.sendPasswordResetEmail(email);
      return const Result.success(null);
    } catch (e, st) {
      return Result.error(AuthExceptionMapper.mapAuthException(e, st));
    }
  }

  @override
  Future<Result<void>> deleteAccount(String email) async {
    try {
      await _authDataSource.deleteAccount(email);
      return const Result.success(null);
    } catch (e, st) {
      return Result.error(AuthExceptionMapper.mapAuthException(e, st));
    }
  }

  @override
  Future<Result<TermsAgreement?>> getTermsInfo(String? termsId) async {
    try {
      // termsId가 없으면 기본 약관 정보 반환
      if (termsId == null) {
        final response = await _authDataSource.fetchTermsInfo();
        final termsAgreement = TermsAgreement(
          id: response['id'] as String,
          isAllAgreed: response['isAllAgreed'] as bool? ?? false,
          isServiceTermsAgreed:
              response['isServiceTermsAgreed'] as bool? ?? false,
          isPrivacyPolicyAgreed:
              response['isPrivacyPolicyAgreed'] as bool? ?? false,
          isMarketingAgreed: response['isMarketingAgreed'] as bool? ?? false,
        );
        return Result.success(termsAgreement);
      }

      // termsId가 있으면 해당 약관 정보 조회
      final response = await _authDataSource.getTermsInfo(termsId);
      if (response == null) {
        return const Result.success(null);
      }

      final termsAgreement = TermsAgreement(
        id: response['id'] as String,
        isAllAgreed: response['isAllAgreed'] as bool? ?? false,
        isServiceTermsAgreed:
            response['isServiceTermsAgreed'] as bool? ?? false,
        isPrivacyPolicyAgreed:
            response['isPrivacyPolicyAgreed'] as bool? ?? false,
        isMarketingAgreed: response['isMarketingAgreed'] as bool? ?? false,
        agreedAt:
            response['agreedAt'] != null
                ? DateTime.parse(response['agreedAt'] as String)
                : null,
      );
      return Result.success(termsAgreement);
    } catch (e, st) {
      return Result.error(AuthExceptionMapper.mapAuthException(e, st));
    }
  }

  @override
  Future<Result<TermsAgreement>> saveTermsAgreement(
    TermsAgreement terms,
  ) async {
    try {
      final Map<String, dynamic> termsData = {
        'id': terms.id,
        'isAllAgreed': terms.isAllAgreed,
        'isServiceTermsAgreed': terms.isServiceTermsAgreed,
        'isPrivacyPolicyAgreed': terms.isPrivacyPolicyAgreed,
        'isMarketingAgreed': terms.isMarketingAgreed,
        'agreedAt':
            terms.agreedAt?.toIso8601String() ??
            DateTime.now().toIso8601String(),
      };

      final response = await _authDataSource.saveTermsAgreement(termsData);

      return Result.success(
        TermsAgreement(
          id: response['id'] as String,
          isAllAgreed: response['isAllAgreed'] as bool,
          isServiceTermsAgreed: response['isServiceTermsAgreed'] as bool,
          isPrivacyPolicyAgreed: response['isPrivacyPolicyAgreed'] as bool,
          isMarketingAgreed: response['isMarketingAgreed'] as bool,
          agreedAt:
              response['agreedAt'] != null
                  ? DateTime.parse(response['agreedAt'] as String)
                  : null,
        ),
      );
    } catch (e, st) {
      return Result.error(AuthExceptionMapper.mapAuthException(e, st));
    }
  }

  @override
  Future<Result<List<TimerActivityDto>>> getTimerActivities(
    String userId,
  ) async {
    try {
      final response = await _authDataSource.fetchTimerActivities(userId);

      final activities =
          response
              .map(
                (activityMap) => TimerActivityDto(
                  id: activityMap['id'] as String?,
                  memberId: activityMap['memberId'] as String?,
                  type: activityMap['type'] as String?,
                  timestamp: activityMap['timestamp'] as DateTime?,
                  metadata: activityMap['metadata'] as Map<String, dynamic>?,
                ),
              )
              .toList();

      return Result.success(activities);
    } catch (e, st) {
      return Result.error(AuthExceptionMapper.mapAuthException(e, st));
    }
  }

  @override
  Future<Result<void>> saveTimerActivity(
    String userId,
    TimerActivityDto activity,
  ) async {
    try {
      final activityData = {
        'id': activity.id,
        'memberId': activity.memberId,
        'type': activity.type,
        'timestamp': activity.timestamp,
        'metadata': activity.metadata,
      };

      await _authDataSource.saveTimerActivity(userId, activityData);
      return const Result.success(null);
    } catch (e, st) {
      return Result.error(AuthExceptionMapper.mapAuthException(e, st));
    }
  }
  // lib/auth/data/repository_impl/auth_repository_impl.dart의 끝부분에 추가

  @override
  Future<Result<Member>> updateProfile({
    required String nickname,
    String? description,
    String? position,
    String? skills,
  }) async {
    try {
      final response = await _authDataSource.updateUser(
        nickname: nickname,
        description: description,
        position: position,
        skills: skills,
      );

      // Map을 직접 Member로 변환
      final member = response.toMember();

      return Result.success(member);
    } catch (e, st) {
      debugPrint('프로필 업데이트 에러: $e');
      debugPrint('StackTrace: $st');
      return Result.error(AuthExceptionMapper.mapAuthException(e, st));
    }
  }

  @override
  Future<Result<Member>> updateProfileImage(String imagePath) async {
    try {
      final response = await _authDataSource.updateUserImage(imagePath);

      // Map을 직접 Member로 변환
      final member = response.toMember();

      return Result.success(member);
    } catch (e, st) {
      debugPrint('프로필 이미지 업데이트 에러: $e');
      debugPrint('StackTrace: $st');
      return Result.error(AuthExceptionMapper.mapAuthException(e, st));
    }
  }
}
