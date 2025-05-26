import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/core/utils/time_formatter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FCMTokenService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  // 토큰 갱신 리스너 중복 방지를 위한 StreamSubscription
  StreamSubscription<String>? _tokenRefreshSubscription;

  // 리스너가 이미 설정되었는지 확인하는 플래그
  bool _isTokenRefreshListenerSetup = false;

  /// 현재 디바이스의 FCM 토큰을 사용자에게 등록
  Future<void> registerDeviceToken(String userId) async {
    try {
      AppLogger.logBanner('FCM 토큰 등록 시작');
      AppLogger.info('사용자 ID: $userId', tag: 'FCMTokenService');

      // ✅ iOS 전용: APNs 토큰 확인 (새로 추가된 부분)
      if (Platform.isIOS) {
        final apnsReady = await _verifyAPNsReadiness();
        if (!apnsReady) {
          AppLogger.error('APNs 토큰이 준비되지 않아 등록을 중단합니다', tag: 'FCMTokenService');
          throw Exception('APNs 토큰이 준비되지 않았습니다.');
        }
      }

      // 1. FCM 토큰 가져오기 (기존 코드 유지)
      final token = await _messaging.getToken();
      if (token == null) {
        AppLogger.error('FCM 토큰을 가져올 수 없습니다', tag: 'FCMTokenService');
        throw Exception('FCM 토큰을 가져올 수 없습니다.');
      }

      AppLogger.info(
        'FCM 토큰 획득: ${token.substring(0, 20)}...',
        tag: 'FCMTokenService',
      );

      // 2. 디바이스 정보 가져오기 (기존 코드 유지)
      final deviceId = await _getDeviceId();
      final platform = Platform.isIOS ? 'ios' : 'android';

      AppLogger.logState('디바이스 정보', {
        'deviceId': deviceId,
        'platform': platform,
      });

      // 3. 기존 토큰 문서 확인 (동일 디바이스) (기존 코드 유지)
      final existingTokenQuery =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('private')
              .doc('fcmTokens')
              .collection('tokens')
              .where('deviceId', isEqualTo: deviceId)
              .limit(1)
              .get();

      // 4. 토큰 데이터 구성 (기존 코드 유지)
      final tokenData = {
        'token': token,
        'deviceId': deviceId,
        'platform': platform,
        'lastUsed': FieldValue.serverTimestamp(),
        'appVersion': await _getAppVersion(),
        'deviceModel': await _getDeviceModel(),
      };

      // 5. 기존 토큰 업데이트 또는 새 토큰 생성 (기존 코드 유지)
      if (existingTokenQuery.docs.isNotEmpty) {
        // 기존 토큰 업데이트
        final existingDoc = existingTokenQuery.docs.first;
        final existingToken = existingDoc.data()['token'] as String?;

        if (existingToken != token) {
          AppLogger.info('토큰이 변경됨 - 업데이트 진행', tag: 'FCMTokenService');
          await existingDoc.reference.update(tokenData);
          AppLogger.info('기존 FCM 토큰 업데이트 완료', tag: 'FCMTokenService');
        } else {
          AppLogger.debug('토큰이 동일함 - lastUsed만 업데이트', tag: 'FCMTokenService');
          await existingDoc.reference.update({
            'lastUsed': FieldValue.serverTimestamp(),
          });
        }
      } else {
        // 새 토큰 추가
        tokenData['createdAt'] = FieldValue.serverTimestamp();
        final docRef = await _firestore
            .collection('users')
            .doc(userId)
            .collection('private')
            .doc('fcmTokens')
            .collection('tokens')
            .add(tokenData);
        AppLogger.info('새 FCM 토큰 등록 완료: ${docRef.id}', tag: 'FCMTokenService');
      }

      // 6. 토큰 갱신 리스너 설정 (중복 방지) (기존 코드 유지)
      _setupTokenRefreshListenerIfNeeded(userId);

      // 7. 등록 성공 검증 (기존 코드 유지)
      await _verifyTokenRegistration(userId, token);

      AppLogger.logBanner('FCM 토큰 등록 완료');
    } catch (e, stackTrace) {
      AppLogger.severe(
        'FCM 토큰 등록 실패',
        tag: 'FCMTokenService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<bool> _verifyAPNsReadiness() async {
    AppLogger.info('iOS APNs 준비 상태 확인 시작', tag: 'FCMTokenService');

    try {
      // APNs 토큰 확인
      final apnsToken = await _messaging.getAPNSToken();

      if (apnsToken != null) {
        AppLogger.info('APNs 토큰 확인됨', tag: 'FCMTokenService');
        return true;
      }

      // APNs 토큰이 없으면 잠시 대기 후 재시도
      AppLogger.warning('APNs 토큰이 없음 - 2초 대기 후 재시도', tag: 'FCMTokenService');
      await Future.delayed(const Duration(seconds: 2));

      final retryToken = await _messaging.getAPNSToken();
      if (retryToken != null) {
        AppLogger.info('APNs 토큰 재시도 성공', tag: 'FCMTokenService');
        return true;
      } else {
        AppLogger.error('APNs 토큰 재시도 실패', tag: 'FCMTokenService');
        return false;
      }
    } catch (e) {
      AppLogger.error('APNs 준비 상태 확인 중 오류', tag: 'FCMTokenService', error: e);
      return false;
    }
  }

  /// 토큰 갱신 리스너 설정 (중복 방지)
  void _setupTokenRefreshListenerIfNeeded(String userId) {
    // 이미 리스너가 설정되어 있으면 스킵
    if (_isTokenRefreshListenerSetup) {
      AppLogger.debug('토큰 갱신 리스너 이미 설정됨 - 스킵', tag: 'FCMTokenService');
      return;
    }

    AppLogger.logBanner('토큰 갱신 리스너 설정 시작');

    try {
      // 기존 구독이 있다면 취소
      _tokenRefreshSubscription?.cancel();

      // 새 구독 설정
      _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((
        newToken,
      ) async {
        AppLogger.logBox(
          'FCM 토큰 갱신 감지',
          '새 토큰: ${newToken.substring(0, 20)}...',
        );

        try {
          await registerDeviceToken(userId);
          AppLogger.info('토큰 갱신 등록 완료', tag: 'FCMTokenService');
        } catch (e) {
          AppLogger.error('토큰 갱신 등록 실패', tag: 'FCMTokenService', error: e);
        }
      });

      _isTokenRefreshListenerSetup = true;
      AppLogger.info('토큰 갱신 리스너 설정 완료', tag: 'FCMTokenService');
    } catch (e) {
      AppLogger.error('토큰 갱신 리스너 설정 실패', tag: 'FCMTokenService', error: e);
    }
  }

  /// 토큰 등록 검증
  Future<void> _verifyTokenRegistration(String userId, String token) async {
    try {
      final deviceId = await _getDeviceId();
      final tokenQuery =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('private')
              .doc('fcmTokens')
              .collection('tokens')
              .where('deviceId', isEqualTo: deviceId)
              .where('token', isEqualTo: token)
              .limit(1)
              .get();

      if (tokenQuery.docs.isNotEmpty) {
        AppLogger.info('토큰 등록 검증 성공', tag: 'FCMTokenService');
      } else {
        AppLogger.error('토큰 등록 검증 실패', tag: 'FCMTokenService');
        throw Exception('토큰 등록 검증에 실패했습니다.');
      }
    } catch (e) {
      AppLogger.error('토큰 등록 검증 중 오류', tag: 'FCMTokenService', error: e);
    }
  }

  /// 디바이스 고유 ID 가져오기
  Future<String> _getDeviceId() async {
    try {
      if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ??
            'unknown_ios_${TimeFormatter.nowInSeoul().millisecondsSinceEpoch}';
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.id;
      } else {
        return 'unknown_platform_${TimeFormatter.nowInSeoul().millisecondsSinceEpoch}';
      }
    } catch (e) {
<<<<<<< HEAD
      AppLogger.error(
        '디바이스 ID 가져오기 실패',
        tag: 'FCMTokenService',
        error: e,
      );
      return 'fallback_${TimeFormatter.nowInSeoul().millisecondsSinceEpoch}';
=======
      AppLogger.error('디바이스 ID 가져오기 실패', tag: 'FCMTokenService', error: e);
      return 'fallback_${DateTime.now().millisecondsSinceEpoch}';
>>>>>>> cca5021 (fix: token ios 추가 사항 반영 완료)
    }
  }

  /// 앱 버전 가져오기
  Future<String> _getAppVersion() async {
    try {
      // package_info_plus 사용 시
      // final packageInfo = await PackageInfo.fromPlatform();
      // return packageInfo.version;
      return '1.0.0'; // 임시값
    } catch (e) {
      AppLogger.error('앱 버전 가져오기 실패', tag: 'FCMTokenService', error: e);
      return 'unknown';
    }
  }

  /// 디바이스 모델 가져오기
  Future<String> _getDeviceModel() async {
    try {
      if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.model;
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return '${androidInfo.brand} ${androidInfo.model}';
      } else {
        return 'Unknown';
      }
    } catch (e) {
      AppLogger.error('디바이스 모델 가져오기 실패', tag: 'FCMTokenService', error: e);
      return 'Unknown';
    }
  }

  /// 특정 사용자의 모든 활성 토큰 가져오기
  Future<List<String>> getUserActiveTokens(String userId) async {
    try {
      AppLogger.logBox('사용자 활성 토큰 조회', '사용자 ID: $userId');

      final thirtyDaysAgo = Timestamp.fromDate(
        TimeFormatter.nowInSeoul().subtract(const Duration(days: 30)),
      );

      final snapshot =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('private')
              .doc('fcmTokens')
              .collection('tokens')
              .where('lastUsed', isGreaterThan: thirtyDaysAgo)
              .get();

      final tokens =
          snapshot.docs
              .map((doc) => doc.data()['token'] as String?)
              .where((token) => token != null)
              .cast<String>()
              .toList();

      AppLogger.info('활성 토큰 ${tokens.length}개 조회됨', tag: 'FCMTokenService');

      // 각 토큰의 정보도 로그로 출력 (디버깅용)
      for (int i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        final data = doc.data();
        AppLogger.debug(
          '토큰 ${i + 1}: 플랫폼=${data['platform']}, 디바이스=${data['deviceModel']}',
          tag: 'FCMTokenService',
        );
      }

      return tokens;
    } catch (e) {
      AppLogger.error('사용자 토큰 조회 실패', tag: 'FCMTokenService', error: e);
      return [];
    }
  }

  /// 현재 디바이스의 토큰 제거 (로그아웃 시 사용)
  Future<void> removeCurrentDeviceToken(String userId) async {
    try {
      AppLogger.logBox('현재 디바이스 FCM 토큰 제거 시작', '사용자 ID: $userId');

      final deviceId = await _getDeviceId();
      AppLogger.info('디바이스 ID: $deviceId', tag: 'FCMTokenService');

      final tokenQuery =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('private')
              .doc('fcmTokens')
              .collection('tokens')
              .where('deviceId', isEqualTo: deviceId)
              .get();

      if (tokenQuery.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in tokenQuery.docs) {
          batch.delete(doc.reference);
          AppLogger.debug('삭제 대상 토큰: ${doc.id}', tag: 'FCMTokenService');
        }
        await batch.commit();
        AppLogger.info(
          '현재 디바이스 FCM 토큰 ${tokenQuery.docs.length}개 제거 완료',
          tag: 'FCMTokenService',
        );
      } else {
        AppLogger.info('제거할 토큰이 없습니다', tag: 'FCMTokenService');
      }
    } catch (e) {
      AppLogger.error('FCM 토큰 제거 실패', tag: 'FCMTokenService', error: e);
      rethrow;
    }
  }

  /// 사용자의 모든 토큰 제거 (계정 삭제 시 사용)
  Future<void> removeAllUserTokens(String userId) async {
    try {
      AppLogger.logBox('사용자 모든 FCM 토큰 제거 시작', '사용자 ID: $userId');

      final tokensCollection = _firestore
          .collection('users')
          .doc(userId)
          .collection('private')
          .doc('fcmTokens')
          .collection('tokens');

      final snapshot = await tokensCollection.get();

      if (snapshot.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }

        // fcmTokens 문서도 삭제
        batch.delete(
          _firestore
              .collection('users')
              .doc(userId)
              .collection('private')
              .doc('fcmTokens'),
        );

        await batch.commit();
        AppLogger.info(
          '사용자 모든 FCM 토큰 ${snapshot.docs.length}개 제거 완료',
          tag: 'FCMTokenService',
        );
      } else {
        AppLogger.info('제거할 토큰이 없습니다', tag: 'FCMTokenService');
      }
    } catch (e) {
      AppLogger.error('모든 FCM 토큰 제거 실패', tag: 'FCMTokenService', error: e);
      rethrow;
    }
  }

  /// 만료된 토큰 정리 (주기적 실행 권장)
  Future<void> cleanupExpiredTokens(
    String userId, {
    int expiredDays = 90,
  }) async {
    try {
      AppLogger.logBox(
        '만료된 FCM 토큰 정리 시작',
        '사용자 ID: $userId, 만료 기준: $expiredDays일',
      );

      final expiredDate = TimeFormatter.nowInSeoul().subtract(
        Duration(days: expiredDays),
      );
      final expiredTimestamp = Timestamp.fromDate(expiredDate);

      final expiredTokens =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('private')
              .doc('fcmTokens')
              .collection('tokens')
              .where('lastUsed', isLessThan: expiredTimestamp)
              .get();

      if (expiredTokens.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in expiredTokens.docs) {
          batch.delete(doc.reference);
          AppLogger.debug('만료된 토큰 삭제: ${doc.id}', tag: 'FCMTokenService');
        }
        await batch.commit();
        AppLogger.info(
          '만료된 FCM 토큰 ${expiredTokens.docs.length}개 정리 완료',
          tag: 'FCMTokenService',
        );
      } else {
        AppLogger.info('정리할 만료된 토큰이 없습니다', tag: 'FCMTokenService');
      }
    } catch (e) {
      AppLogger.error('만료된 토큰 정리 실패', tag: 'FCMTokenService', error: e);
    }
  }

  /// 현재 디바이스의 FCM 토큰 가져오기
  Future<String?> getCurrentDeviceToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        AppLogger.info(
          '현재 디바이스 토큰: ${token.substring(0, 20)}...',
          tag: 'FCMTokenService',
        );
      } else {
        AppLogger.warning('현재 디바이스 토큰: null', tag: 'FCMTokenService');
      }
      return token;
    } catch (e) {
      AppLogger.error('현재 디바이스 토큰 가져오기 실패', tag: 'FCMTokenService', error: e);
      return null;
    }
  }

  /// 토큰 사용 시간 업데이트 (앱이 포그라운드로 돌아올 때 사용)
  Future<void> updateTokenLastUsed(String userId) async {
    try {
      AppLogger.info('토큰 사용 시간 업데이트', tag: 'FCMTokenService');

      final deviceId = await _getDeviceId();

      final tokenQuery =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('private')
              .doc('fcmTokens')
              .collection('tokens')
              .where('deviceId', isEqualTo: deviceId)
              .limit(1)
              .get();

      if (tokenQuery.docs.isNotEmpty) {
        await tokenQuery.docs.first.reference.update({
          'lastUsed': FieldValue.serverTimestamp(),
        });
        AppLogger.info('토큰 사용 시간 업데이트 완료', tag: 'FCMTokenService');
      } else {
        AppLogger.warning('업데이트할 토큰을 찾을 수 없습니다', tag: 'FCMTokenService');
      }
    } catch (e) {
      AppLogger.error('토큰 사용 시간 업데이트 실패', tag: 'FCMTokenService', error: e);
    }
  }

  /// 디바이스별 토큰 정보 조회 (디버그용)
  Future<Map<String, dynamic>?> getDeviceTokenInfo(String userId) async {
    try {
      AppLogger.info('디바이스 토큰 정보 조회', tag: 'FCMTokenService');

      final deviceId = await _getDeviceId();

      final tokenQuery =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('private')
              .doc('fcmTokens')
              .collection('tokens')
              .where('deviceId', isEqualTo: deviceId)
              .limit(1)
              .get();

      if (tokenQuery.docs.isNotEmpty) {
        final data = tokenQuery.docs.first.data();
        final tokenInfo = {
          'token': data['token'],
          'deviceId': data['deviceId'],
          'platform': data['platform'],
          'deviceModel': data['deviceModel'],
          'appVersion': data['appVersion'],
          'createdAt': data['createdAt'],
          'lastUsed': data['lastUsed'],
        };

        AppLogger.info('토큰 정보 조회 성공', tag: 'FCMTokenService');
        AppLogger.logState('토큰 정보', {
          'platform': tokenInfo['platform'],
          'deviceModel': tokenInfo['deviceModel'],
        });

        return tokenInfo;
      }

      AppLogger.warning('토큰 정보를 찾을 수 없습니다', tag: 'FCMTokenService');
      return null;
    } catch (e) {
      AppLogger.error('디바이스 토큰 정보 조회 실패', tag: 'FCMTokenService', error: e);
      return null;
    }
  }

  /// FCM 권한 상태 확인
  Future<bool> hasNotificationPermission() async {
    try {
      final settings = await _messaging.getNotificationSettings();
      final hasPermission =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      AppLogger.logState('FCM 권한 상태', {
        'authorizationStatus': settings.authorizationStatus.toString(),
        'hasPermission': hasPermission,
      });

      return hasPermission;
    } catch (e) {
      AppLogger.error('FCM 권한 상태 확인 실패', tag: 'FCMTokenService', error: e);
      return false;
    }
  }

  /// FCM 권한 요청
  Future<bool> requestNotificationPermission() async {
    try {
      AppLogger.info('FCM 권한 요청', tag: 'FCMTokenService');

      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      final isAuthorized =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      AppLogger.logState('FCM 권한 요청 결과', {
        'authorizationStatus': settings.authorizationStatus.toString(),
        'isAuthorized': isAuthorized,
      });

      return isAuthorized;
    } catch (e) {
      AppLogger.error('FCM 권한 요청 실패', tag: 'FCMTokenService', error: e);
      return false;
    }
  }

  /// FCM 토큰 서비스 전체 상태 진단 (디버그용)
  Future<void> diagnoseService(String userId) async {
    AppLogger.logBanner('FCM 토큰 서비스 진단 시작');

    try {
      // 1. 권한 상태
      final hasPermission = await hasNotificationPermission();
      AppLogger.info('1. 권한 상태: $hasPermission', tag: 'FCMDiagnosis');

      // 2. 현재 토큰
      final currentToken = await getCurrentDeviceToken();
      AppLogger.info(
        '2. 현재 토큰: ${currentToken != null ? "있음" : "없음"}',
        tag: 'FCMDiagnosis',
      );

      // 3. 저장된 토큰 정보
      final tokenInfo = await getDeviceTokenInfo(userId);
      AppLogger.info(
        '3. 저장된 토큰: ${tokenInfo != null ? "있음" : "없음"}',
        tag: 'FCMDiagnosis',
      );

      // 4. 활성 토큰 수
      final activeTokens = await getUserActiveTokens(userId);
      AppLogger.info(
        '4. 활성 토큰 수: ${activeTokens.length}개',
        tag: 'FCMDiagnosis',
      );

      // 5. 리스너 상태
      AppLogger.info(
        '5. 토큰 갱신 리스너 설정됨: $_isTokenRefreshListenerSetup',
<<<<<<< HEAD
        tag: 'FCMDiagnosis',
      );
    } catch (e) {
      AppLogger.error(
        '진단 중 오류 발생',
=======
>>>>>>> cca5021 (fix: token ios 추가 사항 반영 완료)
        tag: 'FCMDiagnosis',
      );
    } catch (e) {
      AppLogger.error('진단 중 오류 발생', tag: 'FCMDiagnosis', error: e);
    }

    AppLogger.logBanner('FCM 토큰 서비스 진단 완료');
  }

  /// 서비스 정리 (메모리 누수 방지)
  void dispose() {
    AppLogger.info('FCMTokenService 정리 시작', tag: 'FCMTokenService');

    // 토큰 갱신 리스너 구독 취소
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;

    // 플래그 초기화
    _isTokenRefreshListenerSetup = false;

    AppLogger.info('FCMTokenService 정리 완료', tag: 'FCMTokenService');
  }
}
