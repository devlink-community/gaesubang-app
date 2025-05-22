import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

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
      debugPrint('=== FCM 토큰 등록 시작 ===');
      debugPrint('사용자 ID: $userId');

      // 1. FCM 토큰 가져오기
      final token = await _messaging.getToken();
      if (token == null) {
        debugPrint('❌ FCM 토큰을 가져올 수 없습니다.');
        throw Exception('FCM 토큰을 가져올 수 없습니다.');
      }

      debugPrint('✅ FCM 토큰 획득: ${token.substring(0, 20)}...');

      // 2. 디바이스 정보 가져오기
      final deviceId = await _getDeviceId();
      final platform = Platform.isIOS ? 'ios' : 'android';

      debugPrint('디바이스 ID: $deviceId');
      debugPrint('플랫폼: $platform');

      // 3. 기존 토큰 문서 확인 (동일 디바이스)
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

      // 4. 토큰 데이터 구성
      final tokenData = {
        'token': token,
        'deviceId': deviceId,
        'platform': platform,
        'lastUsed': FieldValue.serverTimestamp(),
        'appVersion': await _getAppVersion(),
        'deviceModel': await _getDeviceModel(),
      };

      // 5. 기존 토큰 업데이트 또는 새 토큰 생성
      if (existingTokenQuery.docs.isNotEmpty) {
        // 기존 토큰 업데이트
        final existingDoc = existingTokenQuery.docs.first;
        final existingToken = existingDoc.data()['token'] as String?;

        if (existingToken != token) {
          debugPrint('토큰이 변경됨 - 업데이트 진행');
          await existingDoc.reference.update(tokenData);
          debugPrint('✅ 기존 FCM 토큰 업데이트 완료');
        } else {
          debugPrint('토큰이 동일함 - lastUsed만 업데이트');
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
        debugPrint('✅ 새 FCM 토큰 등록 완료: ${docRef.id}');
      }

      // 6. 토큰 갱신 리스너 설정 (중복 방지)
      _setupTokenRefreshListenerIfNeeded(userId);

      // 7. 등록 성공 검증
      await _verifyTokenRegistration(userId, token);

      debugPrint('=== FCM 토큰 등록 완료 ===');
    } catch (e, stackTrace) {
      debugPrint('❌ FCM 토큰 등록 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  /// 토큰 갱신 리스너 설정 (중복 방지)
  void _setupTokenRefreshListenerIfNeeded(String userId) {
    // 이미 리스너가 설정되어 있으면 스킵
    if (_isTokenRefreshListenerSetup) {
      debugPrint('토큰 갱신 리스너 이미 설정됨 - 스킵');
      return;
    }

    debugPrint('=== 토큰 갱신 리스너 설정 시작 ===');

    try {
      // 기존 구독이 있다면 취소
      _tokenRefreshSubscription?.cancel();

      // 새 구독 설정
      _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((
        newToken,
      ) async {
        debugPrint('=== FCM 토큰 갱신 감지 ===');
        debugPrint('새 토큰: ${newToken.substring(0, 20)}...');

        try {
          await registerDeviceToken(userId);
          debugPrint('✅ 토큰 갱신 등록 완료');
        } catch (e) {
          debugPrint('❌ 토큰 갱신 등록 실패: $e');
        }
      });

      _isTokenRefreshListenerSetup = true;
      debugPrint('✅ 토큰 갱신 리스너 설정 완료');
    } catch (e) {
      debugPrint('❌ 토큰 갱신 리스너 설정 실패: $e');
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
        debugPrint('✅ 토큰 등록 검증 성공');
      } else {
        debugPrint('❌ 토큰 등록 검증 실패');
        throw Exception('토큰 등록 검증에 실패했습니다.');
      }
    } catch (e) {
      debugPrint('토큰 등록 검증 중 오류: $e');
    }
  }

  /// 디바이스 고유 ID 가져오기
  Future<String> _getDeviceId() async {
    try {
      if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ??
            'unknown_ios_${DateTime.now().millisecondsSinceEpoch}';
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.id;
      } else {
        return 'unknown_platform_${DateTime.now().millisecondsSinceEpoch}';
      }
    } catch (e) {
      debugPrint('디바이스 ID 가져오기 실패: $e');
      return 'fallback_${DateTime.now().millisecondsSinceEpoch}';
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
      debugPrint('앱 버전 가져오기 실패: $e');
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
      debugPrint('디바이스 모델 가져오기 실패: $e');
      return 'Unknown';
    }
  }

  /// 특정 사용자의 모든 활성 토큰 가져오기
  Future<List<String>> getUserActiveTokens(String userId) async {
    try {
      debugPrint('=== 사용자 활성 토큰 조회 ===');
      debugPrint('사용자 ID: $userId');

      final thirtyDaysAgo = Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 30)),
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

      debugPrint('✅ 활성 토큰 ${tokens.length}개 조회됨');

      // 각 토큰의 정보도 로그로 출력 (디버깅용)
      for (int i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        final data = doc.data();
        debugPrint(
          '토큰 ${i + 1}: 플랫폼=${data['platform']}, 디바이스=${data['deviceModel']}',
        );
      }

      return tokens;
    } catch (e) {
      debugPrint('❌ 사용자 토큰 조회 실패: $e');
      return [];
    }
  }

  /// 현재 디바이스의 토큰 제거 (로그아웃 시 사용)
  Future<void> removeCurrentDeviceToken(String userId) async {
    try {
      debugPrint('=== 현재 디바이스 FCM 토큰 제거 시작 ===');
      debugPrint('사용자 ID: $userId');

      final deviceId = await _getDeviceId();
      debugPrint('디바이스 ID: $deviceId');

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
          debugPrint('삭제 대상 토큰: ${doc.id}');
        }
        await batch.commit();
        debugPrint('✅ 현재 디바이스 FCM 토큰 ${tokenQuery.docs.length}개 제거 완료');
      } else {
        debugPrint('제거할 토큰이 없습니다.');
      }
    } catch (e) {
      debugPrint('❌ FCM 토큰 제거 실패: $e');
      rethrow;
    }
  }

  /// 사용자의 모든 토큰 제거 (계정 삭제 시 사용)
  Future<void> removeAllUserTokens(String userId) async {
    try {
      debugPrint('=== 사용자 모든 FCM 토큰 제거 시작 ===');
      debugPrint('사용자 ID: $userId');

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
        debugPrint('✅ 사용자 모든 FCM 토큰 ${snapshot.docs.length}개 제거 완료');
      } else {
        debugPrint('제거할 토큰이 없습니다.');
      }
    } catch (e) {
      debugPrint('❌ 모든 FCM 토큰 제거 실패: $e');
      rethrow;
    }
  }

  /// 만료된 토큰 정리 (주기적 실행 권장)
  Future<void> cleanupExpiredTokens(
    String userId, {
    int expiredDays = 90,
  }) async {
    try {
      debugPrint('=== 만료된 FCM 토큰 정리 시작 ===');
      debugPrint('사용자 ID: $userId, 만료 기준: $expiredDays일');

      final expiredDate = DateTime.now().subtract(Duration(days: expiredDays));
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
          debugPrint('만료된 토큰 삭제: ${doc.id}');
        }
        await batch.commit();
        debugPrint('✅ 만료된 FCM 토큰 ${expiredTokens.docs.length}개 정리 완료');
      } else {
        debugPrint('정리할 만료된 토큰이 없습니다.');
      }
    } catch (e) {
      debugPrint('❌ 만료된 토큰 정리 실패: $e');
    }
  }

  /// 현재 디바이스의 FCM 토큰 가져오기
  Future<String?> getCurrentDeviceToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        debugPrint('현재 디바이스 토큰: ${token.substring(0, 20)}...');
      } else {
        debugPrint('현재 디바이스 토큰: null');
      }
      return token;
    } catch (e) {
      debugPrint('❌ 현재 디바이스 토큰 가져오기 실패: $e');
      return null;
    }
  }

  /// 토큰 사용 시간 업데이트 (앱이 포그라운드로 돌아올 때 사용)
  Future<void> updateTokenLastUsed(String userId) async {
    try {
      debugPrint('=== 토큰 사용 시간 업데이트 ===');

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
        debugPrint('✅ 토큰 사용 시간 업데이트 완료');
      } else {
        debugPrint('⚠️ 업데이트할 토큰을 찾을 수 없습니다.');
      }
    } catch (e) {
      debugPrint('❌ 토큰 사용 시간 업데이트 실패: $e');
    }
  }

  /// 디바이스별 토큰 정보 조회 (디버그용)
  Future<Map<String, dynamic>?> getDeviceTokenInfo(String userId) async {
    try {
      debugPrint('=== 디바이스 토큰 정보 조회 ===');

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

        debugPrint('✅ 토큰 정보 조회 성공');
        debugPrint('플랫폼: ${tokenInfo['platform']}');
        debugPrint('디바이스: ${tokenInfo['deviceModel']}');

        return tokenInfo;
      }

      debugPrint('토큰 정보를 찾을 수 없습니다.');
      return null;
    } catch (e) {
      debugPrint('❌ 디바이스 토큰 정보 조회 실패: $e');
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

      debugPrint('FCM 권한 상태: ${settings.authorizationStatus} ($hasPermission)');
      return hasPermission;
    } catch (e) {
      debugPrint('❌ FCM 권한 상태 확인 실패: $e');
      return false;
    }
  }

  /// FCM 권한 요청
  Future<bool> requestNotificationPermission() async {
    try {
      debugPrint('=== FCM 권한 요청 ===');

      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      final isAuthorized =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      debugPrint('FCM 권한 요청 결과: ${settings.authorizationStatus}');
      debugPrint('권한 승인됨: $isAuthorized');

      return isAuthorized;
    } catch (e) {
      debugPrint('❌ FCM 권한 요청 실패: $e');
      return false;
    }
  }

  /// FCM 토큰 서비스 전체 상태 진단 (디버그용)
  Future<void> diagnoseService(String userId) async {
    debugPrint('=== FCM 토큰 서비스 진단 시작 ===');

    try {
      // 1. 권한 상태
      final hasPermission = await hasNotificationPermission();
      debugPrint('1. 권한 상태: $hasPermission');

      // 2. 현재 토큰
      final currentToken = await getCurrentDeviceToken();
      debugPrint('2. 현재 토큰: ${currentToken != null ? "있음" : "없음"}');

      // 3. 저장된 토큰 정보
      final tokenInfo = await getDeviceTokenInfo(userId);
      debugPrint('3. 저장된 토큰: ${tokenInfo != null ? "있음" : "없음"}');

      // 4. 활성 토큰 수
      final activeTokens = await getUserActiveTokens(userId);
      debugPrint('4. 활성 토큰 수: ${activeTokens.length}개');

      // 5. 리스너 상태
      debugPrint('5. 토큰 갱신 리스너 설정됨: $_isTokenRefreshListenerSetup');
    } catch (e) {
      debugPrint('❌ 진단 중 오류 발생: $e');
    }

    debugPrint('=== FCM 토큰 서비스 진단 완료 ===');
  }

  /// 서비스 정리 (메모리 누수 방지)
  void dispose() {
    debugPrint('=== FCMTokenService 정리 시작 ===');

    // 토큰 갱신 리스너 구독 취소
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;

    // 플래그 초기화
    _isTokenRefreshListenerSetup = false;

    debugPrint('✅ FCMTokenService 정리 완료');
  }
}
