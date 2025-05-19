import 'package:devlink_mobile_app/auth/data/data_source/auth_data_source.dart';
import 'package:devlink_mobile_app/auth/data/dto/timer_activity_dto.dart';
import 'package:devlink_mobile_app/auth/data/mapper/user_mapper.dart';
import 'package:devlink_mobile_app/auth/domain/model/member.dart';
import 'package:devlink_mobile_app/auth/domain/model/terms_agreement.dart';
import 'package:devlink_mobile_app/auth/domain/repository/auth_repository.dart';
import 'package:devlink_mobile_app/core/auth/auth_state.dart';
import 'package:devlink_mobile_app/core/config/app_config.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/core/utils/auth_error_messages.dart';
import 'package:devlink_mobile_app/core/utils/auth_exception_mapper.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
        // Mapper 사용하여 변환
        final termsAgreement = response.toTermsAgreement();
        return Result.success(termsAgreement);
      }

      // termsId가 있으면 해당 약관 정보 조회
      final response = await _authDataSource.getTermsInfo(termsId);
      if (response == null) {
        return const Result.success(null);
      }

      // Mapper 사용하여 변환
      final termsAgreement = response.toTermsAgreement();
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
      // Mapper 사용하여 TermsAgreement → Map 변환
      final termsData = terms.toUserDtoMap();

      final response = await _authDataSource.saveTermsAgreement(termsData);

      // Mapper 사용하여 Map → TermsAgreement 변환
      final savedTerms = response.toTermsAgreement();
      return Result.success(savedTerms);
    } catch (e, st) {
      debugPrint('약관 동의 저장 에러: $e');
      debugPrint('StackTrace: $st');
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
              .map((activityMap) => TimerActivityDto.fromJson(activityMap))
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
      final activityData = activity.toJson();

      await _authDataSource.saveTimerActivity(userId, activityData);
      return const Result.success(null);
    } catch (e, st) {
      return Result.error(AuthExceptionMapper.mapAuthException(e, st));
    }
  }

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

  // === 새로 추가된 인증 상태 관련 메서드 구현 ===

  @override
  Stream<AuthState> get authStateChanges {
    if (AppConfig.useMockAuth) {
      // Mock: 현재 로그인된 사용자가 있으면 인증된 상태로 스트림 반환
      return Stream.fromFuture(getCurrentUser()).asyncMap((result) {
        switch (result) {
          case Success(data: final member):
            return AuthState.authenticated(member);
          case Error():
            return const AuthState.unauthenticated();
        }
      });
    }

    // Firebase: 실제 인증 상태 변화 스트림
    return FirebaseAuth.instance.authStateChanges().asyncMap((
      firebaseUser,
    ) async {
      if (firebaseUser == null) {
        return const AuthState.unauthenticated();
      }

      try {
        // Firestore에서 완전한 사용자 정보 가져오기
        final userMap = await _authDataSource.fetchCurrentUser();
        if (userMap != null) {
          final member = userMap.toMember();
          return AuthState.authenticated(member);
        }
        return const AuthState.unauthenticated();
      } catch (e) {
        debugPrint('Auth state stream error: $e');
        return const AuthState.unauthenticated();
      }
    });
  }

  @override
  Future<AuthState> getCurrentAuthState() async {
    try {
      final result = await getCurrentUser();
      switch (result) {
        case Success(data: final member):
          return AuthState.authenticated(member);
        case Error():
          return const AuthState.unauthenticated();
      }
    } catch (e) {
      debugPrint('Get current auth state error: $e');
      return const AuthState.unauthenticated();
    }
  }
}
