import 'dart:async';

import 'package:devlink_mobile_app/auth/data/data_source/auth_data_source.dart';
import 'package:devlink_mobile_app/auth/data/dto/timer_activity_dto.dart';
import 'package:devlink_mobile_app/auth/data/mapper/user_mapper.dart';
import 'package:devlink_mobile_app/auth/domain/model/member.dart';
import 'package:devlink_mobile_app/auth/domain/model/terms_agreement.dart';
import 'package:devlink_mobile_app/auth/domain/repository/auth_repository.dart';
import 'package:devlink_mobile_app/core/auth/auth_state.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/core/utils/api_call_logger.dart';
import 'package:devlink_mobile_app/core/utils/exception_mappers/auth_exception_mapper.dart';
import 'package:devlink_mobile_app/core/utils/messages/auth_error_messages.dart';
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
    return ApiCallDecorator.wrap('AuthRepository.login', () async {
      try {
        final response = await _authDataSource.fetchLogin(
          email: email,
          password: password,
        );

        // 새로운 매퍼 사용: 타이머 활동까지 포함된 Member + FocusStats 변환
        final member = response.toMemberWithCalculatedStats();
        return Result.success(member);
      } catch (e, st) {
        debugPrint('Login error: $e');
        debugPrint('StackTrace: $st');
        return Result.error(AuthExceptionMapper.mapAuthException(e, st));
      }
    }, params: {'email': email});
  }

  @override
  Future<Result<Member>> signup({
    required String email,
    required String password,
    required String nickname,
    String? agreedTermsId,
  }) async {
    return ApiCallDecorator.wrap('AuthRepository.signup', () async {
      try {
        final response = await _authDataSource.createUser(
          email: email,
          password: password,
          nickname: nickname,
          agreedTermsId: agreedTermsId,
        );

        // 회원가입 시에도 통계까지 포함된 Member 반환
        final member = response.toMemberWithCalculatedStats();
        return Result.success(member);
      } catch (e, st) {
        return Result.error(AuthExceptionMapper.mapAuthException(e, st));
      }
    }, params: {'email': email, 'nickname': nickname});
  }

  @override
  Future<Result<Member>> getCurrentUser() async {
    return ApiCallDecorator.wrap('AuthRepository.getCurrentUser', () async {
      try {
        final response = await _authDataSource.fetchCurrentUser();
        if (response == null) {
          return Result.error(
            Failure(FailureType.unauthorized, AuthErrorMessages.noLoggedInUser),
          );
        }

        // 현재 사용자 조회 시 타이머 활동까지 포함된 Member + FocusStats 변환
        final member = response.toMemberWithCalculatedStats();
        return Result.success(member);
      } catch (e, st) {
        return Result.error(AuthExceptionMapper.mapAuthException(e, st));
      }
    });
  }

  @override
  Future<Result<void>> signOut() async {
    return ApiCallDecorator.wrap('AuthRepository.signOut', () async {
      try {
        await _authDataSource.signOut();
        return const Result.success(null);
      } catch (e, st) {
        return Result.error(AuthExceptionMapper.mapAuthException(e, st));
      }
    });
  }

  @override
  Future<Result<bool>> checkNicknameAvailability(String nickname) async {
    return ApiCallDecorator.wrap(
      'AuthRepository.checkNicknameAvailability',
      () async {
        try {
          final isAvailable = await _authDataSource.checkNicknameAvailability(
            nickname,
          );
          return Result.success(isAvailable);
        } catch (e, st) {
          return Result.error(AuthExceptionMapper.mapAuthException(e, st));
        }
      },
      params: {'nickname': nickname},
    );
  }

  @override
  Future<Result<bool>> checkEmailAvailability(String email) async {
    return ApiCallDecorator.wrap(
      'AuthRepository.checkEmailAvailability',
      () async {
        try {
          final isAvailable = await _authDataSource.checkEmailAvailability(
            email,
          );
          return Result.success(isAvailable);
        } catch (e, st) {
          return Result.error(AuthExceptionMapper.mapAuthException(e, st));
        }
      },
      params: {'email': email},
    );
  }

  @override
  Future<Result<void>> resetPassword(String email) async {
    return ApiCallDecorator.wrap('AuthRepository.resetPassword', () async {
      try {
        await _authDataSource.sendPasswordResetEmail(email);
        return const Result.success(null);
      } catch (e, st) {
        return Result.error(AuthExceptionMapper.mapAuthException(e, st));
      }
    }, params: {'email': email});
  }

  @override
  Future<Result<void>> deleteAccount(String email) async {
    return ApiCallDecorator.wrap('AuthRepository.deleteAccount', () async {
      try {
        await _authDataSource.deleteAccount(email);
        return const Result.success(null);
      } catch (e, st) {
        return Result.error(AuthExceptionMapper.mapAuthException(e, st));
      }
    }, params: {'email': email});
  }

  @override
  Future<Result<TermsAgreement?>> getTermsInfo(String? termsId) async {
    return ApiCallDecorator.wrap('AuthRepository.getTermsInfo', () async {
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
    }, params: {'termsId': termsId});
  }

  @override
  Future<Result<TermsAgreement>> saveTermsAgreement(
    TermsAgreement terms,
  ) async {
    return ApiCallDecorator.wrap('AuthRepository.saveTermsAgreement', () async {
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
    }, params: {'termsId': terms.id});
  }

  @override
  Future<Result<List<TimerActivityDto>>> getTimerActivities(
    String userId,
  ) async {
    return ApiCallDecorator.wrap('AuthRepository.getTimerActivities', () async {
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
    }, params: {'userId': userId});
  }

  @override
  Future<Result<void>> saveTimerActivity(
    String userId,
    TimerActivityDto activity,
  ) async {
    return ApiCallDecorator.wrap(
      'AuthRepository.saveTimerActivity',
      () async {
        try {
          final activityData = activity.toJson();

          await _authDataSource.saveTimerActivity(userId, activityData);
          return const Result.success(null);
        } catch (e, st) {
          return Result.error(AuthExceptionMapper.mapAuthException(e, st));
        }
      },
      params: {'userId': userId, 'activityType': activity.type},
    );
  }

  @override
  Future<Result<Member>> updateProfile({
    required String nickname,
    String? description,
    String? position,
    String? skills,
  }) async {
    return ApiCallDecorator.wrap('AuthRepository.updateProfile', () async {
      try {
        final response = await _authDataSource.updateUser(
          nickname: nickname,
          description: description,
          position: position,
          skills: skills,
        );

        // 프로필 업데이트 시에도 통계까지 포함된 Member 반환
        final member = response.toMemberWithCalculatedStats();
        return Result.success(member);
      } catch (e, st) {
        debugPrint('프로필 업데이트 에러: $e');
        debugPrint('StackTrace: $st');
        return Result.error(AuthExceptionMapper.mapAuthException(e, st));
      }
    }, params: {'nickname': nickname});
  }

  @override
  Future<Result<Member>> updateProfileImage(String imagePath) async {
    return ApiCallDecorator.wrap('AuthRepository.updateProfileImage', () async {
      try {
        final response = await _authDataSource.updateUserImage(imagePath);

        // 이미지 업데이트 시에도 통계까지 포함된 Member 반환
        final member = response.toMemberWithCalculatedStats();
        return Result.success(member);
      } catch (e, st) {
        debugPrint('프로필 이미지 업데이트 에러: $e');
        debugPrint('StackTrace: $st');
        return Result.error(AuthExceptionMapper.mapAuthException(e, st));
      }
    }, params: {'imagePath': imagePath});
  }

  // === 인증 상태 관련 메서드 구현 ===

  @override
  Stream<AuthState> get authStateChanges {
    return _authDataSource.authStateChanges.map((userData) {
      if (userData == null) {
        return const AuthState.unauthenticated();
      }

      final member = userData.toMemberWithCalculatedStats();
      return AuthState.authenticated(member);
    });
  }

  @override
  Future<AuthState> getCurrentAuthState() async {
    try {
      final userData = await _authDataSource.getCurrentAuthState();

      if (userData == null) {
        return const AuthState.unauthenticated();
      }

      final member = userData.toMemberWithCalculatedStats();
      return AuthState.authenticated(member);
    } catch (e) {
      debugPrint('Get current auth state error: $e');
      return const AuthState.unauthenticated();
    }
  }

  @override
  Future<Result<Member>> getUserProfile(String userId) async {
    try {
      final userDto = await _authDataSource.fetchUserProfile(userId);
      // UserDto를 Map으로 변환한 후 기존 mapper 사용
      final userMap = userDto.toJson();
      final member = userMap.toMember();
      return Result.success(member);
    } catch (e, st) {
      final failure = AuthExceptionMapper.mapAuthException(e, st);
      return Result.error(failure);
    }
  }
}
