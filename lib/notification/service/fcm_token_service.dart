import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FCMTokenService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// 현재 디바이스의 FCM 토큰을 사용자에게 등록
  Future<void> registerDeviceToken(String userId) async {
    try {
      debugPrint('FCM 토큰 등록 시작: $userId');

      // 1. FCM 토큰 가져오기
      final token = await _messaging.getToken();
      if (token == null) {
        debugPrint('FCM 토큰을 가져올 수 없습니다.');
        return;
      }

      debugPrint('FCM 토큰 획득: ${token.substring(0, 20)}...');

      // 2. 디바이스 정보 가져오기
      final deviceId = await _getDeviceId();
      final platform = Platform.isIOS ? 'ios' : 'android';

      debugPrint('디바이스 ID: $deviceId, 플랫폼: $platform');

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
      };

      // 5. 기존 토큰 업데이트 또는 새 토큰 생성
      if (existingTokenQuery.docs.isNotEmpty) {
        // 기존 토큰 업데이트
        final existingDoc = existingTokenQuery.docs.first;
        await existingDoc.reference.update(tokenData);
        debugPrint('기존 FCM 토큰 업데이트 완료');
      } else {
        // 새 토큰 추가
        tokenData['createdAt'] = FieldValue.serverTimestamp();
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('private')
            .doc('fcmTokens')
            .collection('tokens')
            .add(tokenData);
        debugPrint('새 FCM 토큰 등록 완료');
      }

      // 6. 토큰 갱신 리스너 설정
      _setupTokenRefreshListener(userId);
    } catch (e, stackTrace) {
      debugPrint('FCM 토큰 등록 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
    }
  }

  /// 토큰 갱신 리스너 설정
  void _setupTokenRefreshListener(String userId) {
    _messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('FCM 토큰 갱신됨: ${newToken.substring(0, 20)}...');
      await registerDeviceToken(userId);
    });
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

  /// 특정 사용자의 모든 활성 토큰 가져오기
  Future<List<String>> getUserActiveTokens(String userId) async {
    try {
      final snapshot =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('private')
              .doc('fcmTokens')
              .collection('tokens')
              .where(
                'lastUsed',
                isGreaterThan: Timestamp.fromDate(
                  DateTime.now().subtract(
                    const Duration(days: 30),
                  ), // 30일 이내 사용
                ),
              )
              .get();

      final tokens =
          snapshot.docs
              .map((doc) => doc.data()['token'] as String?)
              .where((token) => token != null)
              .cast<String>()
              .toList();

      debugPrint('사용자 $userId의 활성 토큰 ${tokens.length}개 조회됨');
      return tokens;
    } catch (e) {
      debugPrint('사용자 토큰 조회 실패: $e');
      return [];
    }
  }

  /// 현재 디바이스의 토큰 제거 (로그아웃 시 사용)
  Future<void> removeCurrentDeviceToken(String userId) async {
    try {
      debugPrint('현재 디바이스 FCM 토큰 제거 시작: $userId');

      final deviceId = await _getDeviceId();

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
        }
        await batch.commit();
        debugPrint('현재 디바이스 FCM 토큰 ${tokenQuery.docs.length}개 제거 완료');
      } else {
        debugPrint('제거할 토큰이 없습니다.');
      }
    } catch (e) {
      debugPrint('FCM 토큰 제거 실패: $e');
    }
  }

  /// 사용자의 모든 토큰 제거 (계정 삭제 시 사용)
  Future<void> removeAllUserTokens(String userId) async {
    try {
      debugPrint('사용자 모든 FCM 토큰 제거 시작: $userId');

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
        await batch.commit();
        debugPrint('사용자 모든 FCM 토큰 ${snapshot.docs.length}개 제거 완료');
      }
    } catch (e) {
      debugPrint('모든 FCM 토큰 제거 실패: $e');
    }
  }

  /// 만료된 토큰 정리 (주기적 실행 권장)
  Future<void> cleanupExpiredTokens(
    String userId, {
    int expiredDays = 90,
  }) async {
    try {
      debugPrint('만료된 FCM 토큰 정리 시작: $userId');

      final expiredDate = DateTime.now().subtract(Duration(days: expiredDays));

      final expiredTokens =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('private')
              .doc('fcmTokens')
              .collection('tokens')
              .where('lastUsed', isLessThan: Timestamp.fromDate(expiredDate))
              .get();

      if (expiredTokens.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in expiredTokens.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        debugPrint('만료된 FCM 토큰 ${expiredTokens.docs.length}개 정리 완료');
      } else {
        debugPrint('정리할 만료된 토큰이 없습니다.');
      }
    } catch (e) {
      debugPrint('만료된 토큰 정리 실패: $e');
    }
  }

  /// 현재 디바이스의 FCM 토큰 가져오기
  Future<String?> getCurrentDeviceToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('현재 디바이스 토큰 가져오기 실패: $e');
      return null;
    }
  }

  /// 토큰 사용 시간 업데이트 (앱이 포그라운드로 돌아올 때 사용)
  Future<void> updateTokenLastUsed(String userId) async {
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
              .limit(1)
              .get();

      if (tokenQuery.docs.isNotEmpty) {
        await tokenQuery.docs.first.reference.update({
          'lastUsed': FieldValue.serverTimestamp(),
        });
        debugPrint('토큰 사용 시간 업데이트 완료');
      }
    } catch (e) {
      debugPrint('토큰 사용 시간 업데이트 실패: $e');
    }
  }

  /// 디바이스별 토큰 정보 조회 (디버그용)
  Future<Map<String, dynamic>?> getDeviceTokenInfo(String userId) async {
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
              .limit(1)
              .get();

      if (tokenQuery.docs.isNotEmpty) {
        final data = tokenQuery.docs.first.data();
        return {
          'token': data['token'],
          'deviceId': data['deviceId'],
          'platform': data['platform'],
          'createdAt': data['createdAt'],
          'lastUsed': data['lastUsed'],
        };
      }

      return null;
    } catch (e) {
      debugPrint('디바이스 토큰 정보 조회 실패: $e');
      return null;
    }
  }

  /// FCM 권한 상태 확인
  Future<bool> hasNotificationPermission() async {
    try {
      final settings = await _messaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      debugPrint('FCM 권한 상태 확인 실패: $e');
      return false;
    }
  }

  /// FCM 권한 요청
  Future<bool> requestNotificationPermission() async {
    try {
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
      return isAuthorized;
    } catch (e) {
      debugPrint('FCM 권한 요청 실패: $e');
      return false;
    }
  }
}
