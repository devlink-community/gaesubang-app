import 'package:devlink_mobile_app/auth/domain/usecase/core/delete_account_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/core/signout_use_case.dart';
import 'package:devlink_mobile_app/auth/module/auth_di.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:upgrader/upgrader.dart';

import '../../core/utils/app_logger.dart';
import 'settings_action.dart';
import 'settings_state.dart';

part 'settings_notifier.g.dart';

@riverpod
class SettingsNotifier extends _$SettingsNotifier {
  late final SignoutUseCase _signoutUseCase;
  late final DeleteAccountUseCase _deleteAccountUseCase;

  @override
  SettingsState build() {
    _signoutUseCase = ref.watch(signoutUseCaseProvider);
    _deleteAccountUseCase = ref.watch(deleteAccountUseCaseProvider);

    AppLogger.info('SettingsNotifier 초기화 완료', tag: 'SettingsNotifier');

    // 앱 버전 정보 로드 (결과를 기다리지 않음)
    _loadAppVersion();

    return const SettingsState();
  }

  Future<void> onAction(SettingsAction action) async {
    AppLogger.debug(
      'SettingsAction 수신: ${action.runtimeType}',
      tag: 'SettingsNotifier',
    );

    switch (action) {
      case OnTapLogout():
        await _handleLogout();
      case OnTapDeleteAccount():
        await _handleDeleteAccount();
      // 화면 이동 액션들은 Root에서 처리됨
      case OnTapEditProfile():
      case OnTapChangePassword():
      case OnTapPrivacyPolicy():
      case OnTapOpenSourceLicenses():
      // URL 열기 액션들도 Root에서 처리됨
      case OpenUrlPrivacyPolicy():
      case OpenUrlAppInfo():
      case CheckAppVersion():
        AppLogger.debug(
          '액션이 Root에서 처리됨: ${action.runtimeType}',
          tag: 'SettingsNotifier',
        );
        break;
    }
  }

  Future<void> _handleLogout() async {
    final startTime = DateTime.now();
    AppLogger.info('로그아웃 처리 시작', tag: 'SettingsLogout');

    state = state.copyWith(logoutResult: const AsyncLoading());
    final asyncResult = await _signoutUseCase.execute();
    state = state.copyWith(logoutResult: asyncResult);

    final duration = DateTime.now().difference(startTime);

    asyncResult.when(
      data: (_) {
        AppLogger.logPerformance('로그아웃 성공', duration);
        AppLogger.info('로그아웃 완료', tag: 'SettingsLogout');
      },
      error: (error, stackTrace) {
        AppLogger.logPerformance('로그아웃 실패', duration);
        AppLogger.error(
          '로그아웃 실패',
          tag: 'SettingsLogout',
          error: error,
          stackTrace: stackTrace,
        );
      },
      loading: () {
        AppLogger.debug('로그아웃 여전히 로딩 중', tag: 'SettingsLogout');
      },
    );
  }

  Future<void> _handleDeleteAccount() async {
    final startTime = DateTime.now();
    AppLogger.info('계정 삭제 처리 시작', tag: 'SettingsDeleteAccount');

    state = state.copyWith(deleteAccountResult: const AsyncLoading());
    // 현재 로그인된 사용자의 이메일을 가져오는 로직이 필요합니다.
    // 임시로 'current@example.com'을 사용합니다.
    // 실제 구현에서는 getCurrentUser() 등을 통해 가져와야 합니다.
    final email = 'current@example.com'; // 실제 구현 필요

    AppLogger.warning(
      '임시 이메일 사용 중: $email (실제 구현 필요)',
      tag: 'SettingsDeleteAccount',
    );

    final asyncResult = await _deleteAccountUseCase.execute(email);
    state = state.copyWith(deleteAccountResult: asyncResult);

    final duration = DateTime.now().difference(startTime);

    asyncResult.when(
      data: (_) {
        AppLogger.logPerformance('계정 삭제 성공', duration);
        AppLogger.info('계정 삭제 완료', tag: 'SettingsDeleteAccount');
      },
      error: (error, stackTrace) {
        AppLogger.logPerformance('계정 삭제 실패', duration);
        AppLogger.error(
          '계정 삭제 실패',
          tag: 'SettingsDeleteAccount',
          error: error,
          stackTrace: stackTrace,
        );
      },
      loading: () {
        AppLogger.debug('계정 삭제 여전히 로딩 중', tag: 'SettingsDeleteAccount');
      },
    );
  }

  Future<void> _loadAppVersion() async {
    final startTime = DateTime.now();
    AppLogger.info('앱 버전 정보 로드 시작', tag: 'SettingsAppVersion');

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final appVersion = packageInfo.version;

      AppLogger.logState('앱 기본 정보', {
        'version': appVersion,
        'buildNumber': packageInfo.buildNumber,
        'packageName': packageInfo.packageName,
      });

      // Upgrader를 사용하여 최신 버전 확인
      final upgrader = Upgrader(
        durationUntilAlertAgain: const Duration(days: 1),
        debugLogging: true, // 디버그 로깅 활성화
        messages: UpgraderMessages(code: 'ko'), // 한국어 메시지 설정
      );

      AppLogger.debug('Upgrader 초기화 시작', tag: 'SettingsAppVersion');

      // 앱스토어 버전과 현재 버전 비교 (clearSavedSettings 호출 제거)
      await upgrader.initialize();
      final isUpdateAvailable = upgrader.isUpdateAvailable();

      AppLogger.logState('업데이트 확인 결과', {
        'currentVersion': appVersion,
        'isUpdateAvailable': isUpdateAvailable,
      });

      state = state.copyWith(
        appVersion: appVersion,
        isUpdateAvailable: isUpdateAvailable,
      );

      final duration = DateTime.now().difference(startTime);
      AppLogger.logPerformance('앱 버전 정보 로드 성공', duration);
      AppLogger.info('앱 버전 정보 로드 완료: v$appVersion', tag: 'SettingsAppVersion');
    } catch (e, stackTrace) {
      final duration = DateTime.now().difference(startTime);
      AppLogger.logPerformance('앱 버전 정보 로드 실패', duration);

      AppLogger.error(
        '앱 버전 정보 로드 실패',
        tag: 'SettingsAppVersion',
        error: e,
        stackTrace: stackTrace,
      );

      // 실패 시 기본 버전 정보만 표시
      state = state.copyWith(appVersion: '알 수 없음', isUpdateAvailable: false);

      AppLogger.warning('기본 버전 정보로 설정됨', tag: 'SettingsAppVersion');
    }
  }
}
