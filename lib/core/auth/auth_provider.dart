// lib/core/auth/auth_provider.dart
import 'package:devlink_mobile_app/core/utils/privacy_mask_util.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/data/mapper/member_mapper.dart';
import '../../auth/domain/model/member.dart';
import '../../auth/module/auth_di.dart';
import '../utils/app_logger.dart';
import 'auth_state.dart';

part 'auth_provider.g.dart';

/// 인증 상태 스트림 Provider
/// 앱 전체에서 실시간 인증 상태 변화를 감지
@riverpod
Stream<AuthState> authState(Ref ref) {
  AppLogger.authInfo('인증 상태 스트림 Provider 초기화');

  final authDataSource = ref.watch(authDataSourceProvider);

  return authDataSource.authStateChanges
      .map((userData) {
        if (userData == null) {
          AppLogger.authInfo('사용자 로그아웃 상태 감지');
          return const AuthState.unauthenticated();
        }

        final member = userData.toMemberWithCalculatedStats();
        AppLogger.authInfo(
          '사용자 로그인 상태 감지: ${PrivacyMaskUtil.maskNickname(member.nickname)} (${PrivacyMaskUtil.maskEmail(member.email)})', // 변경
        );
        AppLogger.logState('AuthenticatedUser', {
          'userId': PrivacyMaskUtil.maskUserId(member.uid), // 변경
          'email': PrivacyMaskUtil.maskEmail(member.email), // 변경
          'nickname': PrivacyMaskUtil.maskNickname(member.nickname), // 변경
          'streakDays': member.streakDays,
          'totalFocusMinutes': member.focusStats?.totalMinutes ?? 0,
        });

        return AuthState.authenticated(member);
      })
      .handleError((error, stackTrace) {
        AppLogger.error('인증 상태 스트림 에러', error: error, stackTrace: stackTrace);
        // 에러 발생 시 로그아웃 상태로 처리
        return const AuthState.unauthenticated();
      });
}

/// 현재 인증 여부 Provider (편의용)
/// UI에서 간단하게 로그인 상태 확인용
@riverpod
bool isAuthenticated(Ref ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (state) {
      final isAuth = state.isAuthenticated;
      AppLogger.debug('인증 상태 확인: ${isAuth ? "로그인됨" : "로그아웃됨"}');
      return isAuth;
    },
    loading: () {
      AppLogger.debug('인증 상태 로딩 중');
      return false;
    },
    error: (error, stackTrace) {
      AppLogger.warning(
        '인증 상태 확인 중 에러 발생',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    },
  );
}

/// 현재 사용자 정보 Provider (편의용)
/// UI에서 사용자 정보가 필요할 때 사용
@riverpod
Member? currentUser(Ref ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (state) {
      final user = state.user;
      if (user != null) {
        AppLogger.debug('현재 사용자 정보 조회: ${user.nickname}');
        // 민감한 정보는 로깅하지 않음 (이메일 등)
      } else {
        AppLogger.debug('현재 사용자 없음');
      }
      return user;
    },
    loading: () {
      AppLogger.debug('사용자 정보 로딩 중');
      return null;
    },
    error: (error, stackTrace) {
      AppLogger.warning(
        '사용자 정보 조회 중 에러 발생',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    },
  );
}

/// 인증 상태 동기 확인 Provider
/// 라우터에서 리다이렉트 시 사용 (스트림이 아닌 한 번만 확인)
@riverpod
Future<AuthState> currentAuthState(Ref ref) async {
  AppLogger.authInfo('동기 인증 상태 확인 시작');
  final startTime = DateTime.now();

  final authDataSource = ref.watch(authDataSourceProvider);

  try {
    final userData = await authDataSource.getCurrentAuthState();

    final duration = DateTime.now().difference(startTime);
    AppLogger.logPerformance('동기 인증 상태 확인', duration);

    if (userData == null) {
      AppLogger.authInfo('동기 인증 확인 결과: 로그아웃 상태');
      return const AuthState.unauthenticated();
    }

    final member = userData.toMemberWithCalculatedStats();
    AppLogger.authInfo('동기 인증 확인 결과: 로그인 상태 (${member.nickname})');

    return AuthState.authenticated(member);
  } catch (e, st) {
    final duration = DateTime.now().difference(startTime);
    AppLogger.logPerformance('동기 인증 상태 확인 실패', duration);
    AppLogger.error('동기 인증 상태 확인 실패', error: e, stackTrace: st);

    // 에러 발생 시 안전하게 로그아웃 상태로 처리
    return const AuthState.unauthenticated();
  }
}

/// 사용자 세션 만료 감지 Provider
@riverpod
class SessionWatcher extends _$SessionWatcher {
  @override
  bool build() {
    // 인증 상태 변화 감지
    ref.listen(authStateProvider, (previous, current) {
      current.whenData((state) {
        // 로그인 -> 로그아웃 전환 감지
        if (previous?.value?.isAuthenticated == true &&
            !state.isAuthenticated) {
          AppLogger.authInfo('세션 만료 또는 강제 로그아웃 감지');
          _handleSessionExpired();
        }
        // 로그아웃 -> 로그인 전환 감지
        else if (previous?.value?.isAuthenticated == false &&
            state.isAuthenticated) {
          AppLogger.authInfo('새로운 로그인 세션 시작');
          _handleSessionStarted(state.user!);
        }
      });
    });

    return false;
  }

  void _handleSessionExpired() {
    AppLogger.logBox('세션 만료', '사용자 세션이 만료되었습니다');
    // 세션 만료 처리 로직
    // 예: 로그인 화면으로 리다이렉트, 캐시 클리어 등
  }

  void _handleSessionStarted(Member user) {
    AppLogger.logBox('세션 시작', '${user.nickname}님 환영합니다!');
    AppLogger.logState('NewSession', {
      'userId': user.uid,
      'loginTime': DateTime.now().toIso8601String(),
      'streakDays': user.streakDays,
    });
  }
}

/// 인증 관련 유틸리티 Provider들
@riverpod
class AuthUtils extends _$AuthUtils {
  @override
  void build() {
    // 초기화 로직 없음
  }

  /// 현재 사용자가 특정 권한을 가지고 있는지 확인
  bool hasPermission(String permission) {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      AppLogger.debug('권한 확인 실패: 로그인되지 않음');
      return false;
    }

    // 권한 확인 로직 (실제 구현 필요)
    // 예시: 관리자 권한, 프리미엄 사용자 등
    AppLogger.debug('권한 확인: $permission for ${user.nickname}');

    // 임시 구현
    return true;
  }

  /// 사용자 프로필 완성도 확인
  double getProfileCompleteness() {
    final user = ref.read(currentUserProvider);
    if (user == null) return 0.0;

    double completeness = 0.0;
    int totalFields = 5;
    int completedFields = 0;

    // ✅ 필수 필드 확인 (null 안전 접근)
    if (user.nickname.isNotEmpty) completedFields++;
    if (user.email.isNotEmpty) completedFields++;
    if (user.image.isNotEmpty) completedFields++;
    if (user.position?.isNotEmpty ?? false)
      completedFields++; // nullable String 처리
    if (user.description.isNotEmpty ?? false)
      completedFields++; // nullable String 처리

    completeness = completedFields / totalFields;

    AppLogger.debug(
      '프로필 완성도: ${(completeness * 100).toInt()}% ($completedFields/$totalFields)',
    );

    return completeness;
  }

  /// 사용자 활동 통계 로깅
  void logUserActivity(String activity) {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    AppLogger.logState('UserActivity', {
      'userId': user.uid,
      'activity': activity,
      'timestamp': DateTime.now().toIso8601String(),
      'streakDays': user.streakDays,
      // ✅ null 안전 접근
      'totalFocusMinutes': user.focusStats?.totalMinutes ?? 0,
      'position': user.position ?? '미설정',
    });
  }

  /// 사용자 통계 요약 로깅
  void logUserStats() {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    AppLogger.logState('UserStats', {
      'userId': user.uid,
      'nickname': user.nickname,
      'streakDays': user.streakDays,
      'totalFocusMinutes': user.focusStats?.totalMinutes ?? 0,
      'weeklyFocusMinutes':
          user.focusStats?.weeklyMinutes.values.fold(
            0,
            (sum, minutes) => sum + minutes,
          ) ??
          0,
      'joinedGroupsCount': user.joinedGroups.length ?? 0,
      'profileCompleteness': getProfileCompleteness(),
      'hasOnAir': user.onAir,
    });
  }

  /// 현재 사용자의 주간 활동 요약
  Map<String, dynamic> getWeeklyActivitySummary() {
    final user = ref.read(currentUserProvider);
    if (user == null) return {};

    final weeklyMinutes = user.focusStats?.weeklyMinutes ?? {};
    final totalWeeklyMinutes = weeklyMinutes.values.fold(
      0,
      (sum, minutes) => sum + minutes,
    );
    final activeDays =
        weeklyMinutes.values.where((minutes) => minutes > 0).length;

    final summary = {
      'totalWeeklyMinutes': totalWeeklyMinutes,
      'activeDays': activeDays,
      'dailyAverage':
          activeDays > 0 ? (totalWeeklyMinutes / activeDays).round() : 0,
      'streakDays': user.streakDays,
      'weeklyDetails': weeklyMinutes,
    };

    AppLogger.debug('주간 활동 요약: 총 $totalWeeklyMinutes분, $activeDays일 활동');

    return summary;
  }
}
