import 'dart:async';

import 'package:devlink_mobile_app/auth/data/data_source/auth_data_source.dart';
import 'package:devlink_mobile_app/auth/data/dto/timer_activity_dto.dart';
import 'package:devlink_mobile_app/auth/data/mapper/user_mapper.dart';
import 'package:devlink_mobile_app/auth/domain/model/member.dart';
import 'package:devlink_mobile_app/auth/domain/model/terms_agreement.dart';
import 'package:devlink_mobile_app/auth/domain/repository/auth_repository.dart';
import 'package:devlink_mobile_app/core/auth/auth_state.dart';
import 'package:devlink_mobile_app/core/config/app_config.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/core/utils/api_call_logger.dart';
import 'package:devlink_mobile_app/core/utils/exception_mappers/auth_exception_mapper.dart';
import 'package:devlink_mobile_app/core/utils/messages/auth_error_messages.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/core/utils/privacy_mask_util.dart';
import 'package:devlink_mobile_app/notification/service/fcm_token_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource _authDataSource;
  final FCMTokenService _fcmTokenService;

  AuthRepositoryImpl({
    required AuthDataSource authDataSource,
    required FCMTokenService fcmTokenService,
  }) : _authDataSource = authDataSource,
       _fcmTokenService = fcmTokenService {
    AppLogger.authInfo('AuthRepositoryImpl 초기화 완료');
  }

  // === Mock 스트림 최적화를 위한 Static 변수들 ===
  static StreamController<AuthState>? _mockController;
  static AuthState? _cachedAuthState;
  static bool _hasInitialized = false;

  // === Firebase 스트림 최적화를 위한 Static 변수들 ===
  static Member? _cachedMember;
  static String? _lastFirebaseUserId;

  /// Mock 스트림 컨트롤러 초기화
  static void _initializeMockStream() {
    if (_mockController == null || _mockController!.isClosed) {
      _mockController = StreamController<AuthState>.broadcast();
      _hasInitialized = false;

      AppLogger.debug('AuthRepository: Mock 스트림 컨트롤러 초기화됨');
    }
  }

  /// Mock 환경에서 초기 상태 설정
  Future<void> _setInitialMockState() async {
    if (_hasInitialized) return;

    AppLogger.logStep(1, 2, 'Mock 초기 상태 설정 중');
    final startTime = DateTime.now();

    try {
      final result = await getCurrentUser();
      final duration = DateTime.now().difference(startTime);

      switch (result) {
        case Success(data: final member):
          _cachedAuthState = AuthState.authenticated(member);
          AppLogger.authInfo('Mock 초기 상태: 인증됨 (${member.nickname})');
        case Error():
          _cachedAuthState = const AuthState.unauthenticated();
          AppLogger.authInfo('Mock 초기 상태: 비인증');
      }

      _hasInitialized = true;
      _mockController?.add(_cachedAuthState!);

      AppLogger.logStep(2, 2, 'Mock 초기 상태 설정 완료');
      AppLogger.logPerformance('Mock 초기 상태 설정', duration);
    } catch (e, st) {
      AppLogger.error('Mock 초기 상태 설정 에러', error: e, stackTrace: st);
      _cachedAuthState = const AuthState.unauthenticated();
      _hasInitialized = true;
      _mockController?.add(_cachedAuthState!);
    }
  }

  /// Mock 환경에서 인증 상태 업데이트
  static void _updateMockAuthState(AuthState newState) {
    if (_mockController == null || _mockController!.isClosed) {
      AppLogger.warning('Mock 컨트롤러가 닫혀있어 상태 업데이트 건너뜀');
      return;
    }

    // 상태가 실제로 변경된 경우에만 업데이트
    if (_cachedAuthState != newState) {
      _cachedAuthState = newState;
      _mockController!.add(newState);

      final stateType = newState.isAuthenticated ? '인증됨' : '비인증';
      AppLogger.authInfo('Mock 상태 업데이트됨: $stateType');

      if (newState.isAuthenticated && newState.user != null) {
        AppLogger.logState('Mock 인증 사용자', {
          'user_id': newState.user!.uid,
          'nickname': newState.user!.nickname,
          'email': newState.user!.email,
        });
      }
    }
  }

  /// Firebase 사용자 정보 캐시 업데이트
  void _updateFirebaseCache(Member member, String userId) {
    _cachedMember = member;
    _lastFirebaseUserId = userId;

    AppLogger.debug('Firebase 캐시 업데이트됨: ${member.nickname}');
    AppLogger.logState('Firebase 캐시 정보', {
      'user_id': userId,
      'nickname': member.nickname,
      'streak_days': member.streakDays,
      'total_focus_minutes': member.focusStats?.totalMinutes ?? 0,
    });
  }

  /// Firebase 캐시 초기화
  void _clearFirebaseCache() {
    final hadCache = _cachedMember != null;
    _cachedMember = null;
    _lastFirebaseUserId = null;

    if (hadCache) {
      AppLogger.debug('Firebase 캐시 초기화됨');
    }
  }

  @override
  Future<Result<Member>> login({
    required String email,
    required String password,
  }) async {
    return ApiCallDecorator.wrap('AuthRepository.login', () async {
      AppLogger.logBanner('로그인 시작');
      final startTime = DateTime.now();

      AppLogger.logState('로그인 요청 정보', {
        'email': PrivacyMaskUtil.maskEmail(email), // 변경
        'password_length': password.length,
        'auth_environment': AppConfig.useMockAuth ? 'mock' : 'firebase',
      });

      try {
        AppLogger.logStep(1, 3, '인증 데이터 소스 호출');
        final response = await _authDataSource.fetchLogin(
          email: email,
          password: password,
        );

        AppLogger.logStep(2, 3, '사용자 데이터 변환');
        // 새로운 매퍼 사용: 타이머 활동까지 포함된 Member + FocusStats 변환
        final member = response.toMemberWithCalculatedStats();

        AppLogger.logStep(3, 3, '로그인 후처리');
        // 로그인 성공 시 FCM 토큰 등록 추가
        await _handleLoginSuccess(member);

        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('전체 로그인 프로세스', duration);

        AppLogger.logBox(
          '로그인 성공',
          '사용자: ${member.nickname}\n이메일: ${member.email}\n소요시간: ${duration.inSeconds}초',
        );

        return Result.success(member);
      } catch (e, st) {
        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('로그인 실패', duration);

        AppLogger.error('로그인 에러', error: e, stackTrace: st);
        AppLogger.logState('로그인 실패 상세', {
          'email': email,
          'error_type': e.runtimeType.toString(),
          'duration_ms': duration.inMilliseconds,
        });

        // 로그인 실패 시 상태 업데이트
        if (AppConfig.useMockAuth) {
          _updateMockAuthState(const AuthState.unauthenticated());
        }

        return Result.error(AuthExceptionMapper.mapAuthException(e, st));
      }
    }, params: {'email': email});
  }

  /// 로그인 성공 시 FCM 토큰 등록 및 상태 업데이트
  Future<void> _handleLoginSuccess(Member member) async {
    AppLogger.logStep(1, 2, '로그인 후처리 시작');

    try {
      // 1. 상태 업데이트 (즉시 처리)
      if (AppConfig.useMockAuth) {
        _updateMockAuthState(AuthState.authenticated(member));
      } else {
        _updateFirebaseCache(member, member.uid);
      }

      AppLogger.logStep(2, 2, 'FCM 토큰 등록 (백그라운드)');
      // 2. FCM 토큰 등록 (fire-and-forget 패턴 - 로그인 완료를 지연시키지 않음)
      registerFCMToken(member.uid)
          .then((fcmResult) {
            switch (fcmResult) {
              case Success():
                AppLogger.authInfo('FCM 토큰 등록 성공 (백그라운드)');
              case Error(:final failure):
                AppLogger.warning(
                  'FCM 토큰 등록 실패 (로그인은 계속 진행)',
                  error: failure.message,
                );
            }
          })
          .catchError((e) {
            AppLogger.warning('FCM 토큰 등록 중 예외 발생 (로그인은 계속 진행)', error: e);
          });

      AppLogger.authInfo('로그인 성공 처리 완료 (FCM 등록은 백그라운드에서 진행)');
    } catch (e, st) {
      AppLogger.error('로그인 후 처리 중 오류 발생', error: e, stackTrace: st);
      // FCM 등록 실패는 로그인 자체를 실패시키지 않음
    }
  }

  @override
  Future<Result<Member>> signup({
    required String email,
    required String password,
    required String nickname,
    String? agreedTermsId,
  }) async {
    return ApiCallDecorator.wrap('AuthRepository.signup', () async {
      AppLogger.logBanner('회원가입 시작');
      final startTime = DateTime.now();

      AppLogger.logState('회원가입 요청 정보', {
        'email': PrivacyMaskUtil.maskEmail(email), // 변경
        'nickname': PrivacyMaskUtil.maskNickname(nickname), // 변경
        'password_length': password.length,
        'agreed_terms_id': agreedTermsId,
        'auth_environment': AppConfig.useMockAuth ? 'mock' : 'firebase',
      });

      try {
        AppLogger.logStep(1, 2, '회원가입 API 호출');
        final response = await _authDataSource.createUser(
          email: email,
          password: password,
          nickname: nickname,
          agreedTermsId: agreedTermsId,
        );

        AppLogger.logStep(2, 2, '회원가입 후처리');
        // 회원가입 시에도 통계까지 포함된 Member 반환
        final member = response.toMemberWithCalculatedStats();

        // 회원가입 성공 시 자동 로그인 상태로 설정 및 FCM 토큰 등록
        await _handleLoginSuccess(member);

        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('전체 회원가입 프로세스', duration);

        AppLogger.logBox(
          '회원가입 성공',
          '사용자: ${member.nickname}\n이메일: ${member.email}\n소요시간: ${duration.inSeconds}초',
        );

        return Result.success(member);
      } catch (e, st) {
        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('회원가입 실패', duration);

        AppLogger.error('회원가입 에러', error: e, stackTrace: st);
        AppLogger.logState('회원가입 실패 상세', {
          'email': email,
          'nickname': nickname,
          'error_type': e.runtimeType.toString(),
          'duration_ms': duration.inMilliseconds,
        });

        return Result.error(AuthExceptionMapper.mapAuthException(e, st));
      }
    }, params: {'email': email, 'nickname': nickname});
  }

  @override
  Future<Result<Member>> getCurrentUser() async {
    return ApiCallDecorator.wrap('AuthRepository.getCurrentUser', () async {
      AppLogger.debug('현재 사용자 조회 시작');

      try {
        final response = await _authDataSource.fetchCurrentUser();
        if (response == null) {
          AppLogger.debug('현재 사용자 없음 - 비인증 상태');
          return Result.error(
            Failure(FailureType.unauthorized, AuthErrorMessages.noLoggedInUser),
          );
        }

        // 현재 사용자 조회 시 타이머 활동까지 포함된 Member + FocusStats 변환
        final member = response.toMemberWithCalculatedStats();

        AppLogger.authInfo('현재 사용자 조회 성공: ${member.nickname}');
        AppLogger.logState('현재 사용자 정보', {
          'user_id': PrivacyMaskUtil.maskUserId(member.uid), // 변경
          'nickname': PrivacyMaskUtil.maskNickname(member.nickname), // 변경
          'streak_days': member.streakDays,
          'total_focus_minutes': member.focusStats?.totalMinutes ?? 0,
        });

        // Firebase 환경에서 캐시 업데이트
        if (!AppConfig.useMockAuth) {
          _updateFirebaseCache(member, member.uid);
        }

        return Result.success(member);
      } catch (e, st) {
        AppLogger.error('현재 사용자 조회 에러', error: e, stackTrace: st);
        return Result.error(AuthExceptionMapper.mapAuthException(e, st));
      }
    });
  }

  @override
  Future<Result<void>> signOut() async {
    return ApiCallDecorator.wrap('AuthRepository.signOut', () async {
      AppLogger.logBanner('로그아웃 시작');
      final startTime = DateTime.now();

      try {
        AppLogger.logStep(1, 4, '현재 사용자 ID 확인');
        // 1. 현재 사용자 ID 가져오기 (FCM 토큰 해제용)
        String? currentUserId;
        if (AppConfig.useMockAuth &&
            _cachedAuthState?.isAuthenticated == true) {
          currentUserId = _cachedAuthState!.user?.uid;
        } else if (!AppConfig.useMockAuth && _cachedMember != null) {
          currentUserId = _cachedMember!.uid;
        }

        AppLogger.logState('로그아웃 대상 사용자', {
          'user_id': currentUserId,
          'auth_environment': AppConfig.useMockAuth ? 'mock' : 'firebase',
        });

        AppLogger.logStep(2, 4, '실제 로그아웃 처리');
        // 2. 실제 로그아웃 처리
        await _authDataSource.signOut();

        AppLogger.logStep(3, 4, 'FCM 토큰 해제 (백그라운드)');
        // 3. FCM 토큰 해제 (백그라운드에서 처리)
        if (currentUserId != null) {
          final fcmResult = await unregisterCurrentDeviceFCMToken(
            currentUserId,
          );
          if (fcmResult is Error) {
            AppLogger.warning(
              'FCM 토큰 해제 실패 (로그아웃은 계속 진행)',
              error: fcmResult.failure.message,
            );
          } else {
            AppLogger.authInfo('FCM 토큰 해제 성공');
          }
        }

        AppLogger.logStep(4, 4, '로그아웃 상태 업데이트');
        // 4. 상태 업데이트
        if (AppConfig.useMockAuth) {
          _updateMockAuthState(const AuthState.unauthenticated());
        } else {
          _clearFirebaseCache();
        }

        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('전체 로그아웃 프로세스', duration);
        AppLogger.logBox('로그아웃 완료', '소요시간: ${duration.inMilliseconds}ms');

        return const Result.success(null);
      } catch (e, st) {
        AppLogger.error('로그아웃 에러', error: e, stackTrace: st);
        return Result.error(AuthExceptionMapper.mapAuthException(e, st));
      }
    });
  }

  @override
  Future<Result<bool>> checkNicknameAvailability(String nickname) async {
    return ApiCallDecorator.wrap(
      'AuthRepository.checkNicknameAvailability',
      () async {
        AppLogger.debug('닉네임 중복 확인: $nickname');

        try {
          final isAvailable = await _authDataSource.checkNicknameAvailability(
            nickname,
          );

          AppLogger.authInfo(
            '닉네임 중복 확인 결과: $nickname -> ${isAvailable ? "사용가능" : "사용불가"}',
          );
          return Result.success(isAvailable);
        } catch (e, st) {
          AppLogger.error('닉네임 중복 확인 에러', error: e, stackTrace: st);
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
        AppLogger.debug('이메일 중복 확인: $email');

        try {
          final isAvailable = await _authDataSource.checkEmailAvailability(
            email,
          );

          AppLogger.authInfo(
            '이메일 중복 확인 결과: $email -> ${isAvailable ? "사용가능" : "사용불가"}',
          );
          return Result.success(isAvailable);
        } catch (e, st) {
          AppLogger.error('이메일 중복 확인 에러', error: e, stackTrace: st);
          return Result.error(AuthExceptionMapper.mapAuthException(e, st));
        }
      },
      params: {'email': email},
    );
  }

  @override
  Future<Result<void>> resetPassword(String email) async {
    return ApiCallDecorator.wrap('AuthRepository.resetPassword', () async {
      AppLogger.authInfo('비밀번호 재설정 이메일 전송: $email');

      try {
        await _authDataSource.sendPasswordResetEmail(email);
        AppLogger.authInfo('비밀번호 재설정 이메일 전송 성공');
        return const Result.success(null);
      } catch (e, st) {
        AppLogger.error('비밀번호 재설정 에러', error: e, stackTrace: st);
        return Result.error(AuthExceptionMapper.mapAuthException(e, st));
      }
    }, params: {'email': email});
  }

  @override
  Future<Result<void>> deleteAccount(String email) async {
    return ApiCallDecorator.wrap('AuthRepository.deleteAccount', () async {
      AppLogger.logBanner('계정 삭제 시작');
      final startTime = DateTime.now();

      try {
        AppLogger.logStep(1, 4, '삭제 대상 사용자 ID 확인');
        // 1. 현재 사용자 ID 가져오기 (FCM 토큰 제거용)
        String? currentUserId;
        if (AppConfig.useMockAuth &&
            _cachedAuthState?.isAuthenticated == true) {
          currentUserId = _cachedAuthState!.user?.uid;
        } else if (!AppConfig.useMockAuth && _cachedMember != null) {
          currentUserId = _cachedMember!.uid;
        }

        AppLogger.logState('계정 삭제 대상', {
          'email': email,
          'user_id': currentUserId,
        });

        AppLogger.logStep(2, 4, '모든 FCM 토큰 제거');
        // 2. 모든 FCM 토큰 제거 (계정 삭제 전에 먼저 처리)
        if (currentUserId != null) {
          final fcmResult = await removeAllFCMTokens(currentUserId);
          if (fcmResult is Error) {
            AppLogger.warning(
              'FCM 토큰 제거 실패 (계정 삭제는 계속 진행)',
              error: fcmResult.failure.message,
            );
          } else {
            AppLogger.authInfo('모든 FCM 토큰 제거 성공');
          }
        }

        AppLogger.logStep(3, 4, '실제 계정 삭제');
        // 3. 실제 계정 삭제
        await _authDataSource.deleteAccount(email);

        AppLogger.logStep(4, 4, '계정 삭제 상태 업데이트');
        // 4. 상태 업데이트
        if (AppConfig.useMockAuth) {
          _updateMockAuthState(const AuthState.unauthenticated());
        } else {
          _clearFirebaseCache();
        }

        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('전체 계정 삭제 프로세스', duration);
        AppLogger.logBox(
          '계정 삭제 완료',
          '이메일: $email\n소요시간: ${duration.inSeconds}초',
        );

        return const Result.success(null);
      } catch (e, st) {
        AppLogger.error('계정 삭제 에러', error: e, stackTrace: st);
        return Result.error(AuthExceptionMapper.mapAuthException(e, st));
      }
    }, params: {'email': email});
  }

  @override
  Future<Result<TermsAgreement?>> getTermsInfo(String? termsId) async {
    return ApiCallDecorator.wrap('AuthRepository.getTermsInfo', () async {
      AppLogger.debug('약관 정보 조회: ${termsId ?? "기본 약관"}');

      try {
        // termsId가 없으면 기본 약관 정보 반환
        if (termsId == null) {
          final response = await _authDataSource.fetchTermsInfo();
          // Mapper 사용하여 변환
          final termsAgreement = response.toTermsAgreement();
          AppLogger.authInfo('기본 약관 정보 조회 성공');
          return Result.success(termsAgreement);
        }

        // termsId가 있으면 해당 약관 정보 조회
        final response = await _authDataSource.getTermsInfo(termsId);
        if (response == null) {
          AppLogger.warning('약관 정보 없음: $termsId');
          return const Result.success(null);
        }

        // Mapper 사용하여 변환
        final termsAgreement = response.toTermsAgreement();
        AppLogger.authInfo('약관 정보 조회 성공: $termsId');
        return Result.success(termsAgreement);
      } catch (e, st) {
        AppLogger.error('약관 정보 조회 에러', error: e, stackTrace: st);
        return Result.error(AuthExceptionMapper.mapAuthException(e, st));
      }
    }, params: {'termsId': termsId});
  }

  @override
  Future<Result<TermsAgreement>> saveTermsAgreement(
    TermsAgreement terms,
  ) async {
    return ApiCallDecorator.wrap('AuthRepository.saveTermsAgreement', () async {
      AppLogger.authInfo('약관 동의 저장: ${terms.id}');
      AppLogger.logState('약관 동의 정보', {
        'terms_id': terms.id,
        'all_agreed': terms.isAllAgreed,
        'service_agreed': terms.isServiceTermsAgreed,
        'privacy_agreed': terms.isPrivacyPolicyAgreed,
        'marketing_agreed': terms.isMarketingAgreed,
      });

      try {
        // Mapper 사용하여 TermsAgreement → Map 변환
        final termsData = terms.toUserDtoMap();

        final response = await _authDataSource.saveTermsAgreement(termsData);

        // Mapper 사용하여 Map → TermsAgreement 변환
        final savedTerms = response.toTermsAgreement();
        AppLogger.authInfo('약관 동의 저장 성공: ${savedTerms.id}');
        return Result.success(savedTerms);
      } catch (e, st) {
        AppLogger.error('약관 동의 저장 에러', error: e, stackTrace: st);
        AppLogger.logState('약관 저장 실패 상세', {
          'terms_id': terms.id,
          'error_type': e.runtimeType.toString(),
        });
        return Result.error(AuthExceptionMapper.mapAuthException(e, st));
      }
    }, params: {'termsId': terms.id});
  }

  @override
  Future<Result<List<TimerActivityDto>>> getTimerActivities(
    String userId,
  ) async {
    return ApiCallDecorator.wrap('AuthRepository.getTimerActivities', () async {
      AppLogger.debug('타이머 활동 조회: $userId');

      try {
        final response = await _authDataSource.fetchTimerActivities(userId);

        final activities =
            response
                .map((activityMap) => TimerActivityDto.fromJson(activityMap))
                .toList();

        AppLogger.authInfo('타이머 활동 조회 성공: ${activities.length}개');
        return Result.success(activities);
      } catch (e, st) {
        AppLogger.error('타이머 활동 조회 에러', error: e, stackTrace: st);
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
        AppLogger.debug('타이머 활동 저장: $userId, 타입: ${activity.type}');
        AppLogger.logState('타이머 활동 저장 정보', {
          'user_id': userId,
          'activity_type': activity.type,
          'activity_id': activity.id,
          'timestamp': activity.timestamp?.toIso8601String(),
        });

        try {
          final activityData = activity.toJson();

          await _authDataSource.saveTimerActivity(userId, activityData);
          AppLogger.authInfo('타이머 활동 저장 성공');
          return const Result.success(null);
        } catch (e, st) {
          AppLogger.error('타이머 활동 저장 에러', error: e, stackTrace: st);
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
      AppLogger.authInfo('프로필 업데이트: $nickname');
      AppLogger.logState('프로필 업데이트 정보', {
        'nickname': nickname,
        'description_length': description?.length ?? 0,
        'position': position ?? 'null',
        'skills_length': skills?.length ?? 0,
      });

      try {
        final response = await _authDataSource.updateUser(
          nickname: nickname,
          description: description,
          position: position,
          skills: skills,
        );

        // 프로필 업데이트 시에도 통계까지 포함된 Member 반환
        final member = response.toMemberWithCalculatedStats();

        AppLogger.authInfo('프로필 업데이트 성공: ${member.nickname}');
        AppLogger.logState('업데이트된 프로필', {
          'user_id': member.uid,
          'nickname': member.nickname,
          'description': member.description ?? 'null',
          'position': member.position ?? 'null',
        });

        // 프로필 업데이트 시 캐시 및 상태 업데이트
        if (AppConfig.useMockAuth) {
          _updateMockAuthState(AuthState.authenticated(member));
        } else {
          _updateFirebaseCache(member, member.uid);
        }

        return Result.success(member);
      } catch (e, st) {
        AppLogger.error('프로필 업데이트 에러', error: e, stackTrace: st);
        AppLogger.logState('프로필 업데이트 실패 상세', {
          'nickname': nickname,
          'error_type': e.runtimeType.toString(),
        });
        return Result.error(AuthExceptionMapper.mapAuthException(e, st));
      }
    }, params: {'nickname': nickname});
  }

  @override
  Future<Result<Member>> updateProfileImage(String imagePath) async {
    return ApiCallDecorator.wrap('AuthRepository.updateProfileImage', () async {
      AppLogger.authInfo('프로필 이미지 업데이트 시작');
      AppLogger.logState('프로필 이미지 업데이트 정보', {
        'image_path': imagePath,
        'file_exists': imagePath.isNotEmpty,
      });

      try {
        final response = await _authDataSource.updateUserImage(imagePath);

        // 이미지 업데이트 시에도 통계까지 포함된 Member 반환
        final member = response.toMemberWithCalculatedStats();

        AppLogger.authInfo('프로필 이미지 업데이트 성공');
        AppLogger.logState('업데이트된 이미지 정보', {
          'user_id': member.uid,
          'image_url_length': member.image.length,
          'has_image': member.image.isNotEmpty,
        });

        // 프로필 이미지 업데이트 시 캐시 및 상태 업데이트
        if (AppConfig.useMockAuth) {
          _updateMockAuthState(AuthState.authenticated(member));
        } else {
          _updateFirebaseCache(member, member.uid);
        }

        return Result.success(member);
      } catch (e, st) {
        AppLogger.error('프로필 이미지 업데이트 에러', error: e, stackTrace: st);
        AppLogger.logState('프로필 이미지 업데이트 실패 상세', {
          'image_path': imagePath,
          'error_type': e.runtimeType.toString(),
        });
        return Result.error(AuthExceptionMapper.mapAuthException(e, st));
      }
    }, params: {'imagePath': imagePath});
  }

  // === 🚀 최적화된 인증 상태 관련 메서드 구현 ===

  @override
  Stream<AuthState> get authStateChanges {
    AppLogger.debug('AuthRepository.authStateChanges: Stream 구독 시작');

    if (AppConfig.useMockAuth) {
      AppLogger.debug('Mock 환경: BroadcastStream 사용');
      // Mock: 최적화된 BroadcastStream 사용
      _initializeMockStream();

      // 초기 상태 설정 (한 번만)
      if (!_hasInitialized) {
        _setInitialMockState();
      }

      return _mockController!.stream;
    }

    AppLogger.debug('Firebase 환경: 캐싱 최적화된 스트림 사용');
    // Firebase: 캐싱 최적화된 스트림
    return FirebaseAuth.instance.authStateChanges().asyncMap((
      firebaseUser,
    ) async {
      if (firebaseUser == null) {
        AppLogger.authInfo('Firebase 인증 상태 변경: 사용자 로그아웃됨');
        _clearFirebaseCache();
        return const AuthState.unauthenticated();
      }

      try {
        // 캐시된 사용자와 동일한 경우 API 호출 생략
        if (_lastFirebaseUserId == firebaseUser.uid && _cachedMember != null) {
          AppLogger.debug(
            'Firebase 캐시된 사용자 정보 사용: ${_cachedMember!.nickname}',
          );
          return AuthState.authenticated(_cachedMember!);
        }

        AppLogger.authInfo(
          'Firebase 새로운 사용자 감지: ${firebaseUser.uid}',
        );

        // 새로운 사용자이거나 캐시가 없는 경우에만 API 호출
        final userMap = await _authDataSource.fetchCurrentUser();
        if (userMap != null) {
          final member = userMap.toMemberWithCalculatedStats();
          _updateFirebaseCache(member, firebaseUser.uid);
          AppLogger.authInfo('Firebase 사용자 정보 업데이트 완료');
          return AuthState.authenticated(member);
        }

        AppLogger.warning('Firebase 사용자 정보 조회 실패');
        _clearFirebaseCache();
        return const AuthState.unauthenticated();
      } catch (e, st) {
        AppLogger.error('Firebase 인증 상태 스트림 에러', error: e, stackTrace: st);
        _clearFirebaseCache();
        return const AuthState.unauthenticated();
      }
    });
  }

  @override
  Future<AuthState> getCurrentAuthState() async {
    return ApiCallDecorator.wrap(
      'AuthRepository.getCurrentAuthState',
      () async {
        AppLogger.debug('현재 인증 상태 확인 시작');

        // Mock 환경에서 캐시된 상태 활용
        if (AppConfig.useMockAuth && _cachedAuthState != null) {
          AppLogger.debug('Mock 캐시 사용');
          return _cachedAuthState!;
        }

        // Firebase 환경에서 캐시된 상태 활용
        if (!AppConfig.useMockAuth && _cachedMember != null) {
          AppLogger.debug('Firebase 캐시 사용');
          return AuthState.authenticated(_cachedMember!);
        }

        AppLogger.debug('캐시 없음 - API 호출');
        // 캐시가 없는 경우에만 API 호출
        try {
          final result = await getCurrentUser();
          switch (result) {
            case Success(data: final member):
              AppLogger.authInfo('현재 인증 상태: 인증됨 (${member.nickname})');
              return AuthState.authenticated(member);
            case Error():
              AppLogger.authInfo('현재 인증 상태: 비인증');
              return const AuthState.unauthenticated();
          }
        } catch (e, st) {
          AppLogger.error('현재 인증 상태 확인 에러', error: e, stackTrace: st);
          return const AuthState.unauthenticated();
        }
      },
    );
  }

  // === FCM 토큰 관리 메서드 구현 ===

  @override
  Future<Result<void>> registerFCMToken(String userId) async {
    return ApiCallDecorator.wrap('AuthRepository.registerFCMToken', () async {
      AppLogger.debug('FCM 토큰 등록 시작: $userId');

      try {
        await _fcmTokenService.registerDeviceToken(userId);
        AppLogger.authInfo('FCM 토큰 등록 성공');
        return const Result.success(null);
      } catch (e, st) {
        AppLogger.error('FCM 토큰 등록 실패', error: e, stackTrace: st);
        return Result.error(
          Failure(
            FailureType.network,
            'FCM 토큰 등록에 실패했습니다',
            cause: e,
            stackTrace: st,
          ),
        );
      }
    }, params: {'userId': userId});
  }

  @override
  Future<Result<void>> unregisterCurrentDeviceFCMToken(String userId) async {
    return ApiCallDecorator.wrap(
      'AuthRepository.unregisterCurrentDeviceFCMToken',
      () async {
        AppLogger.debug('현재 기기 FCM 토큰 해제: $userId');

        try {
          await _fcmTokenService.removeCurrentDeviceToken(userId);
          AppLogger.authInfo('현재 기기 FCM 토큰 해제 성공');
          return const Result.success(null);
        } catch (e, st) {
          AppLogger.error('FCM 토큰 해제 실패', error: e, stackTrace: st);
          return Result.error(
            Failure(
              FailureType.network,
              'FCM 토큰 해제에 실패했습니다',
              cause: e,
              stackTrace: st,
            ),
          );
        }
      },
      params: {'userId': userId},
    );
  }

  @override
  Future<Result<void>> removeAllFCMTokens(String userId) async {
    return ApiCallDecorator.wrap('AuthRepository.removeAllFCMTokens', () async {
      AppLogger.debug('모든 FCM 토큰 제거: $userId');

      try {
        await _fcmTokenService.removeAllUserTokens(userId);
        AppLogger.authInfo('모든 FCM 토큰 제거 성공');
        return const Result.success(null);
      } catch (e, st) {
        AppLogger.error('모든 FCM 토큰 제거 실패', error: e, stackTrace: st);
        return Result.error(
          Failure(
            FailureType.network,
            '모든 FCM 토큰 제거에 실패했습니다',
            cause: e,
            stackTrace: st,
          ),
        );
      }
    }, params: {'userId': userId});
  }

  /// 리소스 정리 메서드 (필요시 호출)
  static void dispose() {
    AppLogger.debug('AuthRepository: 리소스 정리 중');

    _mockController?.close();
    _mockController = null;
    _cachedAuthState = null;
    _hasInitialized = false;
    _cachedMember = null;
    _lastFirebaseUserId = null;

    AppLogger.debug('AuthRepository: 리소스 정리 완료');
  }

  @override
  Future<Result<Member>> getUserProfile(String userId) async {
    AppLogger.debug('사용자 프로필 조회: $userId');

    try {
      final userDto = await _authDataSource.fetchUserProfile(userId);
      // UserDto를 Map으로 변환한 후 기존 mapper 사용
      final userMap = userDto.toJson();
      final member = userMap.toMember();

      AppLogger.authInfo('사용자 프로필 조회 성공: ${member.nickname}');
      AppLogger.logState('조회된 프로필 정보', {
        'user_id': userId,
        'nickname': member.nickname,
        'email': member.email,
        'streak_days': member.streakDays,
      });

      return Result.success(member);
    } catch (e, st) {
      AppLogger.error('사용자 프로필 조회 에러', error: e, stackTrace: st);
      final failure = AuthExceptionMapper.mapAuthException(e, st);
      return Result.error(failure);
    }
  }
}
