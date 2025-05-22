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
import 'package:devlink_mobile_app/notification/service/fcm_token_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource _authDataSource;
  final FCMTokenService _fcmTokenService;

  AuthRepositoryImpl({
    required AuthDataSource authDataSource,
    required FCMTokenService fcmTokenService,
  }) : _authDataSource = authDataSource,
       _fcmTokenService = fcmTokenService;

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

      if (AppConfig.enableVerboseLogging) {
        debugPrint('AuthRepository: Mock 스트림 컨트롤러 초기화됨');
      }
    }
  }

  /// Mock 환경에서 초기 상태 설정
  Future<void> _setInitialMockState() async {
    if (_hasInitialized) return;

    try {
      if (AppConfig.enableVerboseLogging) {
        debugPrint('AuthRepository: Mock 초기 상태 설정 중...');
      }

      final result = await getCurrentUser();
      switch (result) {
        case Success(data: final member):
          _cachedAuthState = AuthState.authenticated(member);
          if (AppConfig.enableVerboseLogging) {
            debugPrint('AuthRepository: Mock 초기 상태 - 인증됨 (${member.nickname})');
          }
        case Error():
          _cachedAuthState = const AuthState.unauthenticated();
          if (AppConfig.enableVerboseLogging) {
            debugPrint('AuthRepository: Mock 초기 상태 - 비인증');
          }
      }

      _hasInitialized = true;
      _mockController?.add(_cachedAuthState!);
    } catch (e) {
      if (AppConfig.enableVerboseLogging) {
        debugPrint('AuthRepository: Mock 초기 상태 설정 에러 - $e');
      }
      _cachedAuthState = const AuthState.unauthenticated();
      _hasInitialized = true;
      _mockController?.add(_cachedAuthState!);
    }
  }

  /// Mock 환경에서 인증 상태 업데이트
  static void _updateMockAuthState(AuthState newState) {
    if (_mockController == null || _mockController!.isClosed) {
      if (AppConfig.enableVerboseLogging) {
        debugPrint('AuthRepository: Mock 컨트롤러가 닫혀있어 상태 업데이트 건너뜀');
      }
      return;
    }

    // 상태가 실제로 변경된 경우에만 업데이트
    if (_cachedAuthState != newState) {
      _cachedAuthState = newState;
      _mockController!.add(newState);

      if (AppConfig.enableVerboseLogging) {
        final stateType = newState.isAuthenticated ? '인증됨' : '비인증';
        debugPrint('AuthRepository: Mock 상태 업데이트됨 - $stateType');
      }
    }
  }

  /// Firebase 사용자 정보 캐시 업데이트
  void _updateFirebaseCache(Member member, String userId) {
    _cachedMember = member;
    _lastFirebaseUserId = userId;

    if (AppConfig.enableVerboseLogging) {
      debugPrint('AuthRepository: Firebase 캐시 업데이트됨 - ${member.nickname}');
    }
  }

  /// Firebase 캐시 초기화
  void _clearFirebaseCache() {
    _cachedMember = null;
    _lastFirebaseUserId = null;

    if (AppConfig.enableVerboseLogging) {
      debugPrint('AuthRepository: Firebase 캐시 초기화됨');
    }
  }

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

        // ✅ 로그인 성공 시 FCM 토큰 등록 추가
        await _handleLoginSuccess(member);

        return Result.success(member);
      } catch (e, st) {
        debugPrint('Login error: $e');
        debugPrint('StackTrace: $st');

        // ✅ 로그인 실패 시 상태 업데이트
        if (AppConfig.useMockAuth) {
          _updateMockAuthState(const AuthState.unauthenticated());
        }

        return Result.error(AuthExceptionMapper.mapAuthException(e, st));
      }
    }, params: {'email': email});
  }

  /// 로그인 성공 시 FCM 토큰 등록 및 상태 업데이트
  Future<void> _handleLoginSuccess(Member member) async {
    try {
      // 1. 상태 업데이트 (즉시 처리)
      if (AppConfig.useMockAuth) {
        _updateMockAuthState(AuthState.authenticated(member));
      } else {
        _updateFirebaseCache(member, member.uid);
      }

      // 2. FCM 토큰 등록 (fire-and-forget 패턴 - 로그인 완료를 지연시키지 않음)
      registerFCMToken(member.uid)
          .then((fcmResult) {
            switch (fcmResult) {
              case Success():
                debugPrint('✅ FCM 토큰 등록 성공 (백그라운드)');
              case Error(:final failure):
                debugPrint('⚠️ FCM 토큰 등록 실패 (로그인은 계속 진행): ${failure.message}');
            }
          })
          .catchError((e) {
            debugPrint('⚠️ FCM 토큰 등록 중 예외 발생 (로그인은 계속 진행): $e');
          });

      debugPrint('✅ 로그인 성공 처리 완료 (FCM 등록은 백그라운드에서 진행)');
    } catch (e) {
      debugPrint('❌ 로그인 후 처리 중 오류 발생: $e');
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
      try {
        final response = await _authDataSource.createUser(
          email: email,
          password: password,
          nickname: nickname,
          agreedTermsId: agreedTermsId,
        );

        // 회원가입 시에도 통계까지 포함된 Member 반환
        final member = response.toMemberWithCalculatedStats();

        // ✅ 회원가입 성공 시 자동 로그인 상태로 설정 및 FCM 토큰 등록
        await _handleLoginSuccess(member);

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

        // ✅ Firebase 환경에서 캐시 업데이트
        if (!AppConfig.useMockAuth) {
          _updateFirebaseCache(member, member.uid);
        }

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
        // 1. 현재 사용자 ID 가져오기 (FCM 토큰 해제용)
        String? currentUserId;
        if (AppConfig.useMockAuth &&
            _cachedAuthState?.isAuthenticated == true) {
          currentUserId = _cachedAuthState!.user?.uid;
        } else if (!AppConfig.useMockAuth && _cachedMember != null) {
          currentUserId = _cachedMember!.uid;
        }

        // 2. 실제 로그아웃 처리
        await _authDataSource.signOut();

        // 3. FCM 토큰 해제 (백그라운드에서 처리)
        if (currentUserId != null) {
          final fcmResult = await unregisterCurrentDeviceFCMToken(
            currentUserId,
          );
          if (fcmResult is Error) {
            debugPrint(
              'FCM 토큰 해제 실패 (로그아웃은 계속 진행): ${fcmResult.failure.message}',
            );
          } else {
            debugPrint('FCM 토큰 해제 성공');
          }
        }

        // 4. 상태 업데이트
        if (AppConfig.useMockAuth) {
          _updateMockAuthState(const AuthState.unauthenticated());
        } else {
          _clearFirebaseCache();
        }

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
        // 1. 현재 사용자 ID 가져오기 (FCM 토큰 제거용)
        String? currentUserId;
        if (AppConfig.useMockAuth &&
            _cachedAuthState?.isAuthenticated == true) {
          currentUserId = _cachedAuthState!.user?.uid;
        } else if (!AppConfig.useMockAuth && _cachedMember != null) {
          currentUserId = _cachedMember!.uid;
        }

        // 2. 모든 FCM 토큰 제거 (계정 삭제 전에 먼저 처리)
        if (currentUserId != null) {
          final fcmResult = await removeAllFCMTokens(currentUserId);
          if (fcmResult is Error) {
            debugPrint(
              'FCM 토큰 제거 실패 (계정 삭제는 계속 진행): ${fcmResult.failure.message}',
            );
          } else {
            debugPrint('모든 FCM 토큰 제거 성공');
          }
        }

        // 3. 실제 계정 삭제
        await _authDataSource.deleteAccount(email);

        // 4. 상태 업데이트
        if (AppConfig.useMockAuth) {
          _updateMockAuthState(const AuthState.unauthenticated());
        } else {
          _clearFirebaseCache();
        }

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

        // ✅ 프로필 업데이트 시 캐시 및 상태 업데이트
        if (AppConfig.useMockAuth) {
          _updateMockAuthState(AuthState.authenticated(member));
        } else {
          _updateFirebaseCache(member, member.uid);
        }

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

        // ✅ 프로필 이미지 업데이트 시 캐시 및 상태 업데이트
        if (AppConfig.useMockAuth) {
          _updateMockAuthState(AuthState.authenticated(member));
        } else {
          _updateFirebaseCache(member, member.uid);
        }

        return Result.success(member);
      } catch (e, st) {
        debugPrint('프로필 이미지 업데이트 에러: $e');
        debugPrint('StackTrace: $st');
        return Result.error(AuthExceptionMapper.mapAuthException(e, st));
      }
    }, params: {'imagePath': imagePath});
  }

  // === 🚀 최적화된 인증 상태 관련 메서드 구현 ===

  @override
  Stream<AuthState> get authStateChanges {
    // 로깅은 스트림에서 제외 (너무 빈번한 호출 방지)
    if (AppConfig.enableVerboseLogging) {
      debugPrint('AuthRepository.authStateChanges: Stream 구독 시작');
    }

    if (AppConfig.useMockAuth) {
      // ✅ Mock: 최적화된 BroadcastStream 사용
      _initializeMockStream();

      // 초기 상태 설정 (한 번만)
      if (!_hasInitialized) {
        _setInitialMockState();
      }

      return _mockController!.stream;
    }

    // ✅ Firebase: 캐싱 최적화된 스트림
    return FirebaseAuth.instance.authStateChanges().asyncMap((
      firebaseUser,
    ) async {
      if (firebaseUser == null) {
        if (AppConfig.enableVerboseLogging) {
          debugPrint('AuthRepository.authStateChanges: 사용자 로그아웃됨');
        }
        _clearFirebaseCache();
        return const AuthState.unauthenticated();
      }

      try {
        // ✅ 캐시된 사용자와 동일한 경우 API 호출 생략
        if (_lastFirebaseUserId == firebaseUser.uid && _cachedMember != null) {
          if (AppConfig.enableVerboseLogging) {
            debugPrint(
              'AuthRepository.authStateChanges: 캐시된 사용자 정보 사용 - ${_cachedMember!.nickname}',
            );
          }
          return AuthState.authenticated(_cachedMember!);
        }

        if (AppConfig.enableVerboseLogging) {
          debugPrint(
            'AuthRepository.authStateChanges: 새로운 Firebase 사용자 감지 - ${firebaseUser.uid}',
          );
        }

        // 새로운 사용자이거나 캐시가 없는 경우에만 API 호출
        final userMap = await _authDataSource.fetchCurrentUser();
        if (userMap != null) {
          final member = userMap.toMemberWithCalculatedStats();
          _updateFirebaseCache(member, firebaseUser.uid);
          return AuthState.authenticated(member);
        }
        _clearFirebaseCache();
        return const AuthState.unauthenticated();
      } catch (e) {
        debugPrint('Auth state stream error: $e');
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
        // ✅ Mock 환경에서 캐시된 상태 활용
        if (AppConfig.useMockAuth && _cachedAuthState != null) {
          if (AppConfig.enableVerboseLogging) {
            debugPrint('AuthRepository.getCurrentAuthState: Mock 캐시 사용');
          }
          return _cachedAuthState!;
        }

        // ✅ Firebase 환경에서 캐시된 상태 활용
        if (!AppConfig.useMockAuth && _cachedMember != null) {
          if (AppConfig.enableVerboseLogging) {
            debugPrint('AuthRepository.getCurrentAuthState: Firebase 캐시 사용');
          }
          return AuthState.authenticated(_cachedMember!);
        }

        // 캐시가 없는 경우에만 API 호출
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
      },
    );
  }

  // === FCM 토큰 관리 메서드 구현 ===

  @override
  Future<Result<void>> registerFCMToken(String userId) async {
    return ApiCallDecorator.wrap('AuthRepository.registerFCMToken', () async {
      try {
        await _fcmTokenService.registerDeviceToken(userId);
        return const Result.success(null);
      } catch (e, st) {
        debugPrint('FCM 토큰 등록 실패: $e');
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
        try {
          await _fcmTokenService.removeCurrentDeviceToken(userId);
          return const Result.success(null);
        } catch (e, st) {
          debugPrint('FCM 토큰 해제 실패: $e');
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
      try {
        await _fcmTokenService.removeAllUserTokens(userId);
        return const Result.success(null);
      } catch (e, st) {
        debugPrint('모든 FCM 토큰 제거 실패: $e');
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
    if (AppConfig.enableVerboseLogging) {
      debugPrint('AuthRepository: 리소스 정리 중...');
    }

    _mockController?.close();
    _mockController = null;
    _cachedAuthState = null;
    _hasInitialized = false;
    _cachedMember = null;
    _lastFirebaseUserId = null;
  }
}
