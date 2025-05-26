// lib/auth/data/data_source/firebase/user_profile_firebase.dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devlink_mobile_app/core/utils/api_call_logger.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/core/utils/auth_validator.dart';
import 'package:devlink_mobile_app/core/utils/messages/auth_error_messages.dart';
import 'package:devlink_mobile_app/core/utils/privacy_mask_util.dart';
import 'package:devlink_mobile_app/core/utils/time_formatter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../dto/user_dto.dart';

/// Firebase 사용자 프로필 관련 기능
class UserProfileFirebase {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  UserProfileFirebase({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// 새 사용자 프로필 생성 (회원가입 시)
  Future<void> createUserProfile({
    required String userId,
    required String email,
    required String nickname,
    required Map<String, dynamic> termsMap, // Map 형태로 변경
  }) async {
    return ApiCallDecorator.wrap(
      'UserProfileFirebase.createUserProfile',
      () async {
        AppLogger.debug('Firestore 사용자 프로필 생성 시작');

        try {
          // 프로필 데이터 준비
          final userData = {
            'uid': userId,
            'email': email.toLowerCase(),
            'nickname': nickname,
            'image': '',
            'description': '',
            'onAir': false,
            'position': '',
            'skills': '',
            'streakDays': 0,
            'created_at': FieldValue.serverTimestamp(),
            'updated_at': FieldValue.serverTimestamp(),
            // 약관 동의 정보 추가
            'isServiceTermsAgreed': termsMap['isServiceTermsAgreed'] ?? false,
            'isPrivacyPolicyAgreed': termsMap['isPrivacyPolicyAgreed'] ?? false,
            'isMarketingAgreed': termsMap['isMarketingAgreed'] ?? false,
            'agreedAt': termsMap['agreedAt'] ?? FieldValue.serverTimestamp(),
            // 추가 필드는 필요에 따라 설정
          };

          // Firestore에 저장
          await _usersCollection.doc(userId).set(userData);

          AppLogger.debug('Firestore 사용자 프로필 생성 완료');
        } catch (e, st) {
          AppLogger.error('Firestore 사용자 프로필 생성 실패', error: e, stackTrace: st);
          rethrow;
        }
      },
      params: {'userId': userId},
    );
  }

  /// 사용자 프로필 조회
  Future<Map<String, dynamic>?> fetchUserProfile(String userId) async {
    return ApiCallDecorator.wrap(
      'UserProfileFirebase.fetchUserProfile',
      () async {
        AppLogger.debug('Firebase 사용자 프로필 조회: $userId');

        final docSnapshot = await _usersCollection.doc(userId).get();

        if (!docSnapshot.exists) {
          AppLogger.warning('Firebase 사용자 문서 없음: $userId');
          return null;
        }

        final userData = docSnapshot.data()!;
        userData['uid'] = docSnapshot.id; // 문서 ID를 uid로 설정

        AppLogger.authInfo('Firebase 사용자 프로필 조회 성공');
        AppLogger.logState('조회된 프로필 정보', {
          'uid': userId,
          'nickname': userData['nickname'] ?? '',
          'email': userData['email'] ?? '',
          'position': userData['position'] ?? '',
          'streak_days': userData['streakDays'] ?? 0,
        });

        return userData;
      },
      params: {'userId': PrivacyMaskUtil.maskUserId(userId)},
    );
  }

  /// 사용자 프로필 업데이트
  Future<void> updateUserProfile({
    required String userId,
    required String nickname,
    String? description,
    String? position,
    String? skills,
  }) async {
    return ApiCallDecorator.wrap(
      'UserProfileFirebase.updateUserProfile',
      () async {
        AppLogger.logBanner('Firebase 사용자 프로필 업데이트 시작');

        AppLogger.logState('Firebase 프로필 업데이트 요청', {
          'uid': userId,
          'nickname': nickname,
          'description_length': description?.length ?? 0,
          'position': position ?? 'null',
          'skills_length': skills?.length ?? 0,
        });

        // 닉네임 유효성 검사
        AuthValidator.validateNicknameFormat(nickname);

        AppLogger.logStep(1, 4, '현재 닉네임과 비교');
        // 현재 닉네임과 다른 경우에만 중복 확인
        final currentUserDoc = await _usersCollection.doc(userId).get();
        final currentNickname = currentUserDoc.data()?['nickname'] as String?;

        if (currentNickname != nickname) {
          AppLogger.logStep(2, 4, '닉네임 중복 확인');
          // AuthCoreFirebase의 checkNicknameAvailability를 사용해야 함
          // 여기서는 직접 구현
          final query =
              await _usersCollection
                  .where('nickname', isEqualTo: nickname)
                  .limit(1)
                  .get();

          if (query.docs.isNotEmpty) {
            AppLogger.warning('프로필 업데이트 - 닉네임 중복: $nickname');
            throw Exception(AuthErrorMessages.nicknameAlreadyInUse);
          }
          AppLogger.debug('닉네임 중복 확인 통과');
        } else {
          AppLogger.debug('닉네임 변경 없음 - 중복 확인 건너뜀');
        }

        AppLogger.logStep(3, 4, 'Firestore 프로필 업데이트');
        // Firestore에 사용자 정보 업데이트
        final updateData = {
          'nickname': nickname,
          'description': description ?? '',
          'position': position ?? '',
          'skills': skills ?? '',
        };

        await _usersCollection.doc(userId).update(updateData);

        // Firebase Auth displayName도 업데이트
        final currentUser = _auth.currentUser;
        if (currentUser != null && currentUser.uid == userId) {
          await currentUser.updateDisplayName(nickname);
          await currentUser.reload();
        }

        // 추가된 부분: 그룹 멤버 정보 업데이트
        AppLogger.logStep(4, 4, '그룹 멤버 정보 업데이트');
        await _updateUserGroupMembersInfo(
          userId: userId,
          nickname: nickname,
          profileUrl: currentUser?.photoURL,
        );

        AppLogger.authInfo('Firebase 프로필 정보 업데이트 완료: $nickname');
      },
      params: {
        'userId': PrivacyMaskUtil.maskUserId(userId),
        'nickname': PrivacyMaskUtil.maskNickname(nickname),
      },
    );
  }

  /// 프로필 이미지 업데이트
  Future<String> updateProfileImage({
    required String userId,
    required String imagePath,
  }) async {
    return ApiCallDecorator.wrap(
      'UserProfileFirebase.updateProfileImage',
      () async {
        AppLogger.logBanner('Firebase 프로필 이미지 업데이트 시작');

        AppLogger.logState('Firebase 이미지 업데이트 요청', {
          'uid': userId,
          'image_path': imagePath,
          'path_length': imagePath.length,
        });

        try {
          AppLogger.logStep(1, 7, '이미지 파일 검증');
          final File imageFile = File(imagePath);
          if (!await imageFile.exists()) {
            AppLogger.error('이미지 파일을 찾을 수 없음: $imagePath');
            throw Exception('이미지 파일을 찾을 수 없습니다');
          }

          AppLogger.logStep(2, 7, '이미지 바이트 읽기');
          final Uint8List imageBytes = await imageFile.readAsBytes();

          AppLogger.logState('Firebase 업로드할 이미지 정보', {
            'file_size_kb': imageBytes.length ~/ 1024,
            'file_size_bytes': imageBytes.length,
            'is_compressed': true,
          });

          AppLogger.logStep(3, 7, 'Firebase Storage 경로 설정');
          final String fileName =
              'profile_${TimeFormatter.nowInSeoul().millisecondsSinceEpoch}.jpg';
          final String storagePath = 'users/$userId/$fileName';
          final Reference storageRef = _storage.ref().child(storagePath);

          AppLogger.logStep(4, 7, '기존 프로필 이미지 삭제');
          await _deleteExistingProfileImage(userId);

          AppLogger.logStep(5, 7, 'Firebase Storage 업로드');
          final UploadTask uploadTask = storageRef.putData(
            imageBytes,
            SettableMetadata(
              contentType: 'image/jpeg',
              customMetadata: {
                'userId': userId,
                'uploadedAt': TimeFormatter.nowInSeoul().toIso8601String(),
                'originalPath': imagePath,
                'compressedByUseCase': 'true',
              },
            ),
          );

          final TaskSnapshot snapshot = await uploadTask;
          final String downloadUrl = await snapshot.ref.getDownloadURL();

          AppLogger.authInfo('Firebase Storage 이미지 업로드 완료: $downloadUrl');

          AppLogger.logStep(6, 7, 'Firestore 이미지 URL 업데이트');
          await _usersCollection.doc(userId).update({'image': downloadUrl});

          // Firebase Auth photoURL도 업데이트
          final currentUser = _auth.currentUser;
          if (currentUser != null && currentUser.uid == userId) {
            await currentUser.updatePhotoURL(downloadUrl);
            await currentUser.reload();
          }

          // 추가된 부분: 그룹 멤버 프로필 이미지 업데이트
          AppLogger.logStep(7, 7, '그룹 멤버 프로필 이미지 업데이트');
          await _updateUserGroupMembersInfo(
            userId: userId,
            nickname: currentUser?.displayName ?? '',
            profileUrl: downloadUrl,
          );

          AppLogger.authInfo('Firebase 프로필 이미지 업데이트 완료');
          return downloadUrl;
        } catch (e, stackTrace) {
          AppLogger.error(
            'Firebase 프로필 이미지 업데이트 실패',
            error: e,
            stackTrace: stackTrace,
          );

          if (e.toString().contains('network')) {
            throw Exception('네트워크 연결을 확인해주세요');
          } else if (e.toString().contains('permission')) {
            throw Exception('이미지 업로드 권한이 없습니다');
          } else if (e.toString().contains('quota')) {
            throw Exception('저장 공간이 부족합니다');
          } else if (e.toString().contains('file_size')) {
            throw Exception('이미지 파일이 너무 큽니다');
          } else {
            throw Exception('이미지 업로드에 실패했습니다');
          }
        }
      },
      params: {
        'userId': PrivacyMaskUtil.maskUserId(userId),
        'imagePath': imagePath,
      },
    );
  }

  /// 기존 프로필 이미지 삭제
  Future<void> _deleteExistingProfileImage(String userId) async {
    try {
      AppLogger.debug('기존 프로필 이미지 삭제 시도: $userId');

      final currentUserDoc = await _usersCollection.doc(userId).get();
      final currentImageUrl = currentUserDoc.data()?['image'] as String?;

      if (currentImageUrl != null &&
          currentImageUrl.isNotEmpty &&
          currentImageUrl.contains('firebase')) {
        final Reference oldImageRef = _storage.refFromURL(currentImageUrl);
        await oldImageRef.delete();
        AppLogger.authInfo('기존 프로필 이미지 삭제 완료');
      } else {
        AppLogger.debug('삭제할 기존 이미지 없음');
      }
    } catch (e, st) {
      AppLogger.warning('기존 이미지 삭제 실패 (무시함)', error: e, stackTrace: st);
    }
  }

  /// 특정 사용자 프로필 조회 (다른 사용자) - Summary 정보 포함
  Future<UserDto> fetchOtherUserProfile(String userId) async {
    return ApiCallDecorator.wrap(
      'UserProfileFirebase.fetchOtherUserProfile',
      () async {
        AppLogger.debug('Firebase 다른 사용자 프로필 조회: $userId');

        try {
          // 1. 기본 사용자 프로필 정보 조회
          final docSnapshot = await _usersCollection.doc(userId).get();

          if (!docSnapshot.exists) {
            AppLogger.warning('Firebase 사용자 문서 없음: $userId');
            throw Exception('사용자를 찾을 수 없습니다');
          }

          final userData = docSnapshot.data()!;
          userData['uid'] = docSnapshot.id;

          // 2. Summary 정보 조회 (추가)
          try {
            final summaryDoc =
                await _usersCollection
                    .doc(userId)
                    .collection('summary')
                    .doc('current')
                    .get();

            if (summaryDoc.exists) {
              userData['summary'] = summaryDoc.data();
            }
          } catch (summaryError) {
            AppLogger.warning(
              'Summary 정보 조회 실패 (무시)',
              error: summaryError,
            );
            // Summary 조회 실패는 무시하고 기본 프로필 정보만 반환
          }

          AppLogger.authInfo('Firebase 사용자 프로필 조회 성공: $userId');
          AppLogger.logState('조회된 사용자 프로필', {
            'uid': userId,
            'nickname': userData['nickname'] ?? '',
            'email': userData['email'] ?? '',
            'position': userData['position'] ?? '',
            'has_summary': userData.containsKey('summary'),
          });

          return UserDto.fromJson(userData);
        } catch (e, st) {
          AppLogger.error('Firebase 사용자 프로필 조회 오류', error: e, stackTrace: st);
          throw Exception('사용자 프로필을 불러오는데 실패했습니다');
        }
      },
      params: {'userId': PrivacyMaskUtil.maskUserId(userId)},
    );
  }

  /// 사용자가 속한 모든 그룹의 멤버 정보 업데이트 (최적화 버전)
  Future<void> _updateUserGroupMembersInfo({
    required String userId,
    required String nickname,
    String? profileUrl,
  }) async {
    try {
      AppLogger.debug('사용자 그룹 멤버 정보 업데이트 시작: $userId');

      // 1. 사용자 문서에서 joingroup 필드 조회
      final userDocRef = _usersCollection.doc(userId);
      final userJoinGroupSnapshot = await userDocRef.get();

      if (!userJoinGroupSnapshot.exists) {
        AppLogger.warning('사용자 문서를 찾을 수 없음: $userId');
        return;
      }

      final userData = userJoinGroupSnapshot.data()!;
      final joinGroups = userData['joingroup'] as List<dynamic>? ?? [];

      if (joinGroups.isEmpty) {
        AppLogger.debug('사용자가 속한 그룹이 없음: $userId');
        return;
      }

      // 2. 업데이트할 데이터 준비
      final updateData = {
        'userName': nickname,
      };

      // 프로필 이미지가 있는 경우 함께 업데이트
      if (profileUrl != null) {
        updateData['profileUrl'] = profileUrl;
      }

      // 3. 배치 처리 준비
      var batch = _firestore.batch();
      int groupCount = 0;
      int batchCount = 0;
      const int batchLimit = 450; // Firestore 배치 제한(500)보다 약간 낮게 설정

      // 4. 그룹 목록을 처리하면서 여러 배치로 나누어 처리
      for (final groupInfo in joinGroups) {
        if (groupInfo is! Map<String, dynamic>) continue;

        final groupId = groupInfo['group_id'] as String?;
        if (groupId == null || groupId.isEmpty) continue;

        // 해당 그룹의 멤버 문서 참조 가져오기
        final memberRef = _firestore
            .collection('groups')
            .doc(groupId)
            .collection('members')
            .doc(userId);

        // 문서 존재 확인 없이 업데이트 시도 (효율성 개선)
        // 만약 문서가 없으면 업데이트는 무시됨
        batch.update(memberRef, updateData);
        groupCount++;
        batchCount++;

        // 배치 크기 제한에 도달하면 커밋하고 새 배치 시작
        if (batchCount >= batchLimit) {
          await batch.commit();
          AppLogger.info('그룹 멤버 정보 배치 업데이트 완료: $batchCount개');
          batch = _firestore.batch(); // 새 배치 생성
          batchCount = 0;
        }
      }

      // 5. 남은 배치 처리
      if (batchCount > 0) {
        await batch.commit();
        AppLogger.info('사용자 그룹 멤버 정보 업데이트 완료: $groupCount개 그룹');
      } else if (groupCount > 0) {
        AppLogger.info('모든 그룹 멤버 정보 배치 업데이트 완료: $groupCount개 그룹');
      } else {
        AppLogger.debug('업데이트할 그룹 멤버 정보 없음');
      }
    } catch (e, st) {
      AppLogger.error(
        '그룹 멤버 정보 업데이트 실패',
        error: e,
        stackTrace: st,
      );
    }
  }
}
