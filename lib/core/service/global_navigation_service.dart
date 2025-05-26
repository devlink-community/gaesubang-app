import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';

/// 글로벌 네비게이션을 담당하는 싱글톤 서비스
/// 앱의 어느 곳에서든 네비게이션을 수행할 수 있도록 함
class GlobalNavigationService {
  static final GlobalNavigationService _instance =
      GlobalNavigationService._internal();
  factory GlobalNavigationService() => _instance;
  GlobalNavigationService._internal();

  // Global Navigator Key
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // GoRouter 인스턴스 저장
  GoRouter? _goRouter;

  /// GoRouter 인스턴스를 등록
  void setRouter(GoRouter router) {
    _goRouter = router;
    AppLogger.info('GoRouter 인스턴스 등록 완료', tag: 'GlobalNavigation');
  }

  /// 현재 BuildContext 가져오기
  BuildContext? get currentContext => navigatorKey.currentContext;

  /// GoRouter 인스턴스 가져오기
  GoRouter? get router => _goRouter;

  /// 특정 경로로 이동 (push)
  Future<void> pushTo(String path, {Object? extra}) async {
    try {
      AppLogger.info('네비게이션 push: $path', tag: 'GlobalNavigation');

      if (_goRouter != null) {
        _goRouter!.push(path, extra: extra);
      } else if (currentContext != null) {
        GoRouter.of(currentContext!).push(path, extra: extra);
      } else {
        AppLogger.error(
          '네비게이션 실패: Router와 Context 모두 없음',
          tag: 'GlobalNavigation',
        );
      }
    } catch (e) {
      AppLogger.error('네비게이션 push 실패', tag: 'GlobalNavigation', error: e);
    }
  }

  /// 특정 경로로 이동 (go - 스택 교체)
  Future<void> goTo(String path, {Object? extra}) async {
    try {
      AppLogger.info('네비게이션 go: $path', tag: 'GlobalNavigation');

      if (_goRouter != null) {
        _goRouter!.go(path, extra: extra);
      } else if (currentContext != null) {
        GoRouter.of(currentContext!).go(path, extra: extra);
      } else {
        AppLogger.error(
          '네비게이션 실패: Router와 Context 모두 없음',
          tag: 'GlobalNavigation',
        );
      }
    } catch (e) {
      AppLogger.error('네비게이션 go 실패', tag: 'GlobalNavigation', error: e);
    }
  }

  /// 알림 타입별 네비게이션 처리
  Future<void> handleNotificationNavigation({
    required String type,
    required String targetId,
    String? senderId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      AppLogger.info('알림 네비게이션 처리 시작', tag: 'NotificationNavigation');
      AppLogger.logState('알림 정보', {
        'type': type,
        'targetId': targetId,
        'senderId': senderId,
        'additionalData': additionalData?.toString(),
      });

      String targetPath;

      switch (type) {
        case 'like':
        case 'comment':
          // 게시글 상세로 이동
          targetPath = '/community/$targetId';
          AppLogger.info(
            '게시글 상세로 이동: $targetPath',
            tag: 'NotificationNavigation',
          );
          break;

        case 'follow':
          // 사용자 프로필로 이동
          if (senderId != null) {
            targetPath = '/user/$senderId/profile';
            AppLogger.info(
              '사용자 프로필로 이동: $targetPath',
              tag: 'NotificationNavigation',
            );
          } else {
            AppLogger.warning(
              'follow 알림에 senderId가 없음',
              tag: 'NotificationNavigation',
            );
            return;
          }
          break;

        case 'mention':
          // 멘션된 게시글로 이동
          targetPath = '/community/$targetId';
          AppLogger.info(
            '멘션 게시글로 이동: $targetPath',
            tag: 'NotificationNavigation',
          );
          break;

        case 'group_invite':
          // 그룹 상세로 이동
          targetPath = '/group/$targetId';
          AppLogger.info(
            '그룹 상세로 이동: $targetPath',
            tag: 'NotificationNavigation',
          );
          break;

        case 'group_chat':
          // 그룹 채팅으로 이동
          targetPath = '/group/$targetId/chat';
          AppLogger.info(
            '그룹 채팅으로 이동: $targetPath',
            tag: 'NotificationNavigation',
          );
          break;

        default:
          AppLogger.warning(
            '알 수 없는 알림 타입: $type',
            tag: 'NotificationNavigation',
          );
          // 기본적으로 알림 목록으로 이동
          targetPath = '/notifications';
          break;
      }

      // 네비게이션 실행
      await pushTo(targetPath);

      AppLogger.info(
        '알림 네비게이션 처리 완료: $targetPath',
        tag: 'NotificationNavigation',
      );
    } catch (e) {
      AppLogger.error(
        '알림 네비게이션 처리 실패',
        tag: 'NotificationNavigation',
        error: e,
      );

      // 실패 시 알림 목록으로 대체 이동
      try {
        await pushTo('/notifications');
      } catch (fallbackError) {
        AppLogger.error(
          '대체 네비게이션도 실패',
          tag: 'NotificationNavigation',
          error: fallbackError,
        );
      }
    }
  }

  /// 앱 상태에 따른 스마트 네비게이션
  /// 앱이 백그라운드에서 포그라운드로 올 때 적절한 네비게이션 수행
  Future<void> handleAppStateNavigation({
    required String type,
    required String targetId,
    String? senderId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      AppLogger.info('앱 상태 기반 네비게이션 시작', tag: 'AppStateNavigation');

      // 현재 앱이 완전히 로드되었는지 확인
      if (currentContext == null && _goRouter == null) {
        AppLogger.warning(
          '앱이 아직 완전히 로드되지 않음 - 네비게이션 지연',
          tag: 'AppStateNavigation',
        );

        // 잠시 대기 후 재시도
        await Future.delayed(const Duration(milliseconds: 1000));

        if (currentContext == null && _goRouter == null) {
          AppLogger.error('앱 로딩 대기 후에도 네비게이션 불가', tag: 'AppStateNavigation');
          return;
        }
      }

      // 먼저 홈으로 이동하여 앱 상태를 안정화
      await goTo('/home');

      // 잠시 대기 후 목표 위치로 이동
      await Future.delayed(const Duration(milliseconds: 500));

      // 실제 네비게이션 수행
      await handleNotificationNavigation(
        type: type,
        targetId: targetId,
        senderId: senderId,
        additionalData: additionalData,
      );

      AppLogger.info('앱 상태 기반 네비게이션 완료', tag: 'AppStateNavigation');
    } catch (e) {
      AppLogger.error('앱 상태 기반 네비게이션 실패', tag: 'AppStateNavigation', error: e);
    }
  }

  /// 딥링크 처리
  Future<void> handleDeepLink(String deepLink) async {
    try {
      AppLogger.info('딥링크 처리: $deepLink', tag: 'DeepLink');

      // 딥링크 파싱 및 적절한 경로로 변환
      final uri = Uri.tryParse(deepLink);
      if (uri == null) {
        AppLogger.error('잘못된 딥링크 형식: $deepLink', tag: 'DeepLink');
        return;
      }

      String targetPath = uri.path;

      // 쿼리 파라미터가 있으면 처리
      if (uri.hasQuery) {
        // 필요에 따라 쿼리 파라미터 처리 로직 추가
        AppLogger.debug('딥링크 쿼리 파라미터: ${uri.queryParameters}', tag: 'DeepLink');
      }

      await pushTo(targetPath);

      AppLogger.info('딥링크 처리 완료: $targetPath', tag: 'DeepLink');
    } catch (e) {
      AppLogger.error('딥링크 처리 실패', tag: 'DeepLink', error: e);
    }
  }

  /// 네비게이션 서비스 진단 (디버그용)
  void diagnose() {
    AppLogger.logBanner('글로벌 네비게이션 서비스 진단');

    AppLogger.logState('네비게이션 상태', {
      'navigatorKey.currentContext': currentContext != null ? '사용 가능' : '없음',
      'goRouter': _goRouter != null ? '등록됨' : '미등록',
      '현재 라우트':
          _goRouter?.routerDelegate.currentConfiguration.matches.isNotEmpty ==
                  true
              ? _goRouter!
                  .routerDelegate
                  .currentConfiguration
                  .matches
                  .last
                  .matchedLocation
              : '알 수 없음',
    });
  }

  /// 서비스 정리
  void dispose() {
    AppLogger.info('GlobalNavigationService 정리', tag: 'GlobalNavigation');
    _goRouter = null;
  }
}
