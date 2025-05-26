// lib/home/presentation/home_screen_root.dart
import 'dart:async';

import 'package:devlink_mobile_app/core/utils/time_formatter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../ai_assistance/module/ai_client_di.dart';
import '../../auth/module/auth_di.dart';
import '../../core/utils/app_logger.dart';
import 'home_action.dart';
import 'home_notifier.dart';
import 'home_screen.dart';

class HomeScreenRoot extends ConsumerStatefulWidget {
  const HomeScreenRoot({super.key});

  @override
  ConsumerState<HomeScreenRoot> createState() => _HomeScreenRootState();
}

class _HomeScreenRootState extends ConsumerState<HomeScreenRoot> {
  String? userSkills;

  // 🆕 AI 초기화 상태 관리
  bool _isAIInitialized = false;
  bool _isAIInitializing = false;

  @override
  void initState() {
    super.initState();

    AppLogger.info('HomeScreenRoot 초기화 시작', tag: 'HomeInit');

    // 초기화 시점에 사용자 스킬 정보 로드
    _loadUserSkills();

    // 🆕 AI 서비스 사전 초기화 (백그라운드)
    _preInitializeAIServices();
  }

  /// 🆕 AI 서비스 사전 초기화 메서드
  Future<void> _preInitializeAIServices() async {
    if (_isAIInitializing || _isAIInitialized) {
      AppLogger.debug(
        'AI 서비스 이미 초기화 중이거나 완료됨 (초기화중: $_isAIInitializing, 완료: $_isAIInitialized)',
        tag: 'AIPreload',
      );
      return;
    }

    setState(() {
      _isAIInitializing = true;
    });

    AppLogger.info('AI 서비스 사전 초기화 시작 (백그라운드)', tag: 'AIPreload');

    final startTime = TimeFormatter.nowInSeoul();

    try {
      // 🔧 fire-and-forget 방식으로 백그라운드 초기화
      final firebaseAIClient = ref.read(firebaseAIClientProvider);

      // 초기화 상태 확인
      if (firebaseAIClient.isInitialized) {
        AppLogger.info('Firebase AI 클라이언트 이미 초기화됨', tag: 'AIPreload');

        setState(() {
          _isAIInitialized = true;
          _isAIInitializing = false;
        });
        return;
      }

      // 🆕 초기화 진행 중인지 확인
      if (firebaseAIClient.isInitializing) {
        AppLogger.info('Firebase AI 클라이언트 초기화 진행 중, 완료 대기', tag: 'AIPreload');

        // 다른 곳에서 초기화 중이면 완료까지 대기 (최대 10초)
        await _waitForInitialization(
          firebaseAIClient,
          const Duration(seconds: 10),
        );
      } else {
        // 새로 초기화 시작
        AppLogger.info('Firebase AI 클라이언트 새로 초기화 시작', tag: 'AIPreload');

        await firebaseAIClient.initialize();
      }

      final duration = TimeFormatter.nowInSeoul().difference(startTime);

      setState(() {
        _isAIInitialized = true;
        _isAIInitializing = false;
      });

      AppLogger.logPerformance('AI 서비스 사전 초기화 완료', duration);

      AppLogger.info(
        'AI 서비스 사전 초기화 성공 (${duration.inMilliseconds}ms)',
        tag: 'AIPreload',
      );

      // 🆕 초기화 완료 후 캐시 정리 실행
      _performInitialCacheCleanup();
    } catch (e) {
      final duration = TimeFormatter.nowInSeoul().difference(startTime);

      setState(() {
        _isAIInitializing = false;
        // _isAIInitialized는 false로 유지
      });

      AppLogger.logPerformance('AI 서비스 사전 초기화 실패', duration);

      AppLogger.error('AI 서비스 사전 초기화 실패', tag: 'AIPreload', error: e);

      // 🔧 초기화 실패해도 앱 사용에는 지장 없음 (첫 사용 시 다시 시도)
      AppLogger.info('AI 기능 첫 사용 시 다시 초기화 시도 예정', tag: 'AIPreload');
    }
  }

  /// 🆕 다른 곳에서 초기화 진행 중일 때 완료 대기
  Future<void> _waitForInitialization(
    dynamic firebaseAIClient,
    Duration timeout,
  ) async {
    final startTime = TimeFormatter.nowInSeoul();
    const checkInterval = Duration(milliseconds: 100);

    while (TimeFormatter.nowInSeoul().difference(startTime) < timeout) {
      if (firebaseAIClient.isInitialized) {
        AppLogger.info('Firebase AI 클라이언트 초기화 완료 대기 성공', tag: 'AIPreload');
        return;
      }

      if (!firebaseAIClient.isInitializing) {
        // 초기화가 중단된 경우
        throw StateError('Firebase AI 클라이언트 초기화가 예상치 못하게 중단됨');
      }

      await Future.delayed(checkInterval);
    }

    // 타임아웃 발생
    throw TimeoutException('Firebase AI 클라이언트 초기화 대기 타임아웃', timeout);
  }

  /// 🆕 초기화 완료 후 캐시 정리 실행
  void _performInitialCacheCleanup() {
    try {
      final cacheCleanup = ref.read(cacheCleanupProvider);
      cacheCleanup.cleanupOldCacheEntries();

      AppLogger.info('초기 캐시 정리 완료', tag: 'AIPreload');
    } catch (e) {
      AppLogger.error('초기 캐시 정리 실패', tag: 'AIPreload', error: e);
    }
  }

  /// 🆕 AI 초기화 상태 확인 메서드
  bool get isAIReady => _isAIInitialized;

  /// 🆕 AI 서비스 강제 초기화 메서드 (필요 시 UI에서 호출)
  Future<void> forceInitializeAI() async {
    if (_isAIInitializing) {
      AppLogger.debug('AI 강제 초기화 요청 무시 (이미 초기화 중)', tag: 'AIPreload');
      return;
    }

    AppLogger.info('AI 서비스 강제 초기화 시작', tag: 'AIPreload');

    // 상태 리셋
    setState(() {
      _isAIInitialized = false;
      _isAIInitializing = false;
    });

    // 강제 초기화 실행
    await _preInitializeAIServices();
  }

  Future<void> _loadUserSkills() async {
    final startTime = TimeFormatter.nowInSeoul();

    AppLogger.debug('사용자 스킬 정보 로드 시작', tag: 'HomeInit');

    try {
      final currentUserUseCase = ref.read(getCurrentUserUseCaseProvider);
      final userResult = await currentUserUseCase.execute();

      final duration = TimeFormatter.nowInSeoul().difference(startTime);

      userResult.when(
        data: (user) {
          setState(() {
            userSkills = user.skills;
          });

          AppLogger.logPerformance('사용자 스킬 정보 로드 완료', duration);
          AppLogger.info('사용자 스킬 정보 로드 완료: $userSkills', tag: 'HomeInit');
        },
        error: (error, stackTrace) {
          AppLogger.logPerformance('사용자 정보 로드 실패', duration);
          AppLogger.error(
            '사용자 정보 로드 실패',
            tag: 'HomeInit',
            error: error,
            stackTrace: stackTrace,
          );
        },
        loading: () {
          AppLogger.debug('사용자 정보 로딩 중...', tag: 'HomeInit');
        },
      );
    } catch (e) {
      final duration = TimeFormatter.nowInSeoul().difference(startTime);
      AppLogger.logPerformance('사용자 스킬 로드 예외', duration);
      AppLogger.error('사용자 스킬 로드 예외', tag: 'HomeInit', error: e);
    }
  }

  @override
  void dispose() {
    AppLogger.info('HomeScreenRoot 해제', tag: 'HomeInit');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeNotifier = ref.watch(homeNotifierProvider.notifier);
    final homeState = ref.watch(homeNotifierProvider);

    return HomeScreen(
      state: homeState,
      userSkills: userSkills, // 상태 변수에 저장된 스킬 정보 전달
      onAction: (action) async {
        AppLogger.debug(
          'HomeAction 수신: ${action.runtimeType}',
          tag: 'HomeAction',
        );

        switch (action) {
          case RefreshHome():
            AppLogger.info('홈화면 새로고침 시작', tag: 'HomeAction');

            await homeNotifier.onAction(action);
            _loadUserSkills(); // 새로고침 시 스킬 정보도 다시 로드

            // 🆕 새로고침 시 AI 상태도 확인하고 필요 시 재초기화
            if (!_isAIInitialized && !_isAIInitializing) {
              AppLogger.info('새로고침 시 AI 서비스 재초기화 시작', tag: 'HomeAction');
              unawaited(_preInitializeAIServices());
            }

            AppLogger.info('홈화면 새로고침 완료', tag: 'HomeAction');
            break;

          case OnTapGroup(:final groupId):
            AppLogger.info('그룹 페이지 이동: $groupId', tag: 'HomeAction');
            context.push('/group/$groupId');
            break;

          case OnTapPopularPost(:final postId):
            AppLogger.info('인기 게시글 페이지 이동: $postId', tag: 'HomeAction');
            context.push('/community/$postId');
            break;

          case OnTapSettings():
            AppLogger.info('설정 페이지 이동', tag: 'HomeAction');
            context.push('/settings');
            break;

          case OnTapNotification():
            AppLogger.info('알림 페이지 이동', tag: 'HomeAction');

            // 🆕 알림 페이지로 이동하고, 돌아왔을 때 알림 수 다시 로딩
            final result = await context.push('/notifications');

            // 알림 화면에서 돌아온 경우 (사용자가 알림을 읽었을 가능성)
            if (result != null || context.mounted) {
              AppLogger.info('알림 화면에서 돌아옴 - 홈 데이터 새로고침', tag: 'HomeAction');
              await homeNotifier.onAction(const HomeAction.refresh());
            }
            break;

          case OnTapCreateGroup():
            AppLogger.info('그룹 생성 페이지 이동', tag: 'HomeAction');
            context.push('/group/create');
            break;

          default:
            await homeNotifier.onAction(action);
            break;
        }
      },
    );
  }
}
