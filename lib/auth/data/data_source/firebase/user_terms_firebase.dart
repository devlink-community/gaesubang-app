// lib/auth/data/data_source/firebase/user_terms_firebase.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devlink_mobile_app/core/utils/api_call_logger.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/core/utils/auth_validator.dart';

/// Firebase 약관 관련 기능
class UserTermsFirebase {
  final FirebaseFirestore _firestore;

  UserTermsFirebase({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// 약관 동의 정보 저장
  Future<Map<String, dynamic>> saveTermsAgreement(
    Map<String, dynamic> termsData,
  ) async {
    return ApiCallDecorator.wrap(
      'UserTermsFirebase.saveTermsAgreement',
      () async {
        AppLogger.authInfo('Firebase 약관 동의 저장');
        AppLogger.logState('약관 동의 데이터', {
          'terms_id': termsData['id'],
          'service_agreed': termsData['isServiceTermsAgreed'],
          'privacy_agreed': termsData['isPrivacyPolicyAgreed'],
          'marketing_agreed': termsData['isMarketingAgreed'],
        });

        // 필수 약관 동의 여부 확인
        final isServiceTermsAgreed =
            termsData['isServiceTermsAgreed'] as bool? ?? false;
        final isPrivacyPolicyAgreed =
            termsData['isPrivacyPolicyAgreed'] as bool? ?? false;

        AuthValidator.validateRequiredTerms(
          isServiceTermsAgreed: isServiceTermsAgreed,
          isPrivacyPolicyAgreed: isPrivacyPolicyAgreed,
        );

        // 타임스탬프 추가
        termsData['agreedAt'] = Timestamp.now();
        termsData['id'] = 'terms_${DateTime.now().millisecondsSinceEpoch}';

        AppLogger.authInfo('Firebase 약관 동의 저장 완료: ${termsData['id']}');
        return termsData;
      },
      params: {'termsId': termsData['id']},
    );
  }

  /// 기본 약관 정보 조회
  Future<Map<String, dynamic>> fetchDefaultTermsInfo() async {
    return ApiCallDecorator.wrap(
      'UserTermsFirebase.fetchDefaultTermsInfo',
      () async {
        AppLogger.debug('Firebase 기본 약관 정보 조회');

        final termsInfo = {
          'id': 'terms_${DateTime.now().millisecondsSinceEpoch}',
          'isAllAgreed': false,
          'isServiceTermsAgreed': false,
          'isPrivacyPolicyAgreed': false,
          'isMarketingAgreed': false,
          'agreedAt': Timestamp.now(),
        };

        AppLogger.debug('Firebase 기본 약관 정보 생성 완료');
        return termsInfo;
      },
    );
  }

  /// 특정 약관 정보 조회
  Future<Map<String, dynamic>?> getTermsInfo(String termsId) async {
    return ApiCallDecorator.wrap('UserTermsFirebase.getTermsInfo', () async {
      AppLogger.debug('Firebase 특정 약관 정보 조회: $termsId');

      // 실제 구현에서는 Firestore의 terms 컬렉션에서 조회
      // 현재는 모의 데이터 반환
      final termsInfo = {
        'id': termsId,
        'isAllAgreed': true,
        'isServiceTermsAgreed': true,
        'isPrivacyPolicyAgreed': true,
        'isMarketingAgreed': false,
        'agreedAt': Timestamp.now(),
      };

      AppLogger.debug('Firebase 특정 약관 정보 반환 완료');
      return termsInfo;
    }, params: {'termsId': termsId});
  }

  /// 사용자의 약관 동의 정보 업데이트
  Future<void> updateUserTermsAgreement({
    required String userId,
    required Map<String, dynamic> termsData,
  }) async {
    return ApiCallDecorator.wrap(
      'UserTermsFirebase.updateUserTermsAgreement',
      () async {
        AppLogger.debug('사용자 약관 동의 정보 업데이트: $userId');

        try {
          // users 컬렉션의 사용자 문서에 약관 관련 필드 업데이트
          await _firestore.collection('users').doc(userId).update({
            'agreedTermId': termsData['id'],
            'isServiceTermsAgreed': termsData['isServiceTermsAgreed'] ?? false,
            'isPrivacyPolicyAgreed':
                termsData['isPrivacyPolicyAgreed'] ?? false,
            'isMarketingAgreed': termsData['isMarketingAgreed'] ?? false,
            'agreedAt': termsData['agreedAt'] ?? FieldValue.serverTimestamp(),
          });

          AppLogger.authInfo('사용자 약관 동의 정보 업데이트 완료');
        } catch (e, st) {
          AppLogger.error('약관 동의 정보 업데이트 실패', error: e, stackTrace: st);
          rethrow;
        }
      },
      params: {'userId': userId, 'termsId': termsData['id']},
    );
  }

  /// 약관 버전 목록 조회
  Future<List<Map<String, dynamic>>> fetchTermsVersions() async {
    return ApiCallDecorator.wrap(
      'UserTermsFirebase.fetchTermsVersions',
      () async {
        AppLogger.debug('약관 버전 목록 조회');

        try {
          // 실제로는 Firestore의 termsVersions 컬렉션에서 조회
          // 현재는 모의 데이터 반환
          final versions = [
            {
              'id': 'v2.3',
              'version': '2.3',
              'effectiveDate': '2024-12-01',
              'isActive': true,
            },
            {
              'id': 'v2.2',
              'version': '2.2',
              'effectiveDate': '2024-06-01',
              'isActive': false,
            },
          ];

          AppLogger.info('약관 버전 목록 조회 완료: ${versions.length}개');
          return versions;
        } catch (e, st) {
          AppLogger.error('약관 버전 목록 조회 실패', error: e, stackTrace: st);
          return [];
        }
      },
    );
  }

  /// 최신 약관 버전 가져오기
  Future<String> getLatestTermsVersion() async {
    return ApiCallDecorator.wrap(
      'UserTermsFirebase.getLatestTermsVersion',
      () async {
        AppLogger.debug('최신 약관 버전 조회');

        try {
          // 실제로는 Firestore에서 isActive가 true인 최신 버전 조회
          // 현재는 하드코딩된 값 반환
          const latestVersion = 'v2.3';

          AppLogger.info('최신 약관 버전: $latestVersion');
          return latestVersion;
        } catch (e, st) {
          AppLogger.error('최신 약관 버전 조회 실패', error: e, stackTrace: st);
          return 'v1.0'; // 기본값
        }
      },
    );
  }
}
