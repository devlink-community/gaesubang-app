// lib/group/data/data_source/group_firebase_data_source.dart
import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devlink_mobile_app/core/utils/api_call_logger.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/core/utils/messages/auth_error_messages.dart';
import 'package:devlink_mobile_app/core/utils/messages/group_error_messages.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';

import 'group_data_source.dart';

class GroupFirebaseDataSource implements GroupDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  // 가입 그룹 캐싱을 위한 변수들
  Set<String>? _cachedJoinedGroups;
  String? _lastUserId;

  // 🔧 멤버 정보 캐싱을 위한 변수들
  List<Map<String, dynamic>>? _cachedGroupMembers;
  String? _lastGroupId; // 마지막 조회한 그룹 ID (기존 변수 활용)

  // 🔧 새로 추가: 멤버 변경 감지를 위한 스트림 구독
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _memberChangeSubscription;

  GroupFirebaseDataSource({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
    required FirebaseAuth auth,
  }) : _firestore = firestore,
       _storage = storage,
       _auth = auth {
    // FirebaseAuth 상태 변화 감지하여 캐시 관리
    _auth.authStateChanges().listen((user) {
      if (user?.uid != _lastUserId) {
        // 사용자가 바뀌면 모든 캐시 초기화
        _cachedJoinedGroups = null;
        _cachedGroupMembers = null;
        _lastUserId = user?.uid;
        _lastGroupId = null;

        // 🔧 멤버 변경 감지 구독도 해제
        _stopMemberChangeDetection();
      }
    });
  }

  // Collection 참조들
  CollectionReference<Map<String, dynamic>> get _groupsCollection =>
      _firestore.collection('groups');

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  // 🔧 새로 추가: 멤버 변경 감지 시작
  void _startMemberChangeDetection(String groupId) {
    // 이미 같은 그룹을 감지 중이면 무시
    if (_lastGroupId == groupId && _memberChangeSubscription != null) {
      AppLogger.debug(
        'Already detecting member changes for group: $groupId',
        tag: 'GroupFirebaseDataSource',
      );
      return;
    }

    // 이전 구독 해제
    _stopMemberChangeDetection();

    AppLogger.info(
      'Starting member change detection for group: $groupId',
      tag: 'GroupFirebaseDataSource',
    );

    // 새 그룹의 멤버 변경 감지 시작
    _memberChangeSubscription = _groupsCollection
        .doc(groupId)
        .collection('members')
        .snapshots()
        .listen(
          (snapshot) {
            AppLogger.debug(
              'Member change detected in group: $groupId',
              tag: 'GroupFirebaseDataSource',
            );
            AppLogger.debug(
              'Member count: ${snapshot.docs.length}',
              tag: 'GroupFirebaseDataSource',
            );

            // 🔧 _lastGroupId가 현재 그룹과 일치할 때만 캐시 무효화
            if (_lastGroupId == groupId && _cachedGroupMembers != null) {
              AppLogger.info(
                'Invalidating member cache due to member change',
                tag: 'GroupFirebaseDataSource',
              );
              _cachedGroupMembers = null;
              // _lastGroupId는 유지 (감지 중인 그룹 정보로 계속 사용)
            }
          },
          onError: (error) {
            AppLogger.error(
              'Error in member change detection',
              tag: 'GroupFirebaseDataSource',
              error: error,
            );
          },
        );
  }

  // 🔧 새로 추가: 멤버 변경 감지 중지
  void _stopMemberChangeDetection() {
    if (_memberChangeSubscription != null) {
      AppLogger.info(
        'Stopping member change detection for group: $_lastGroupId',
        tag: 'GroupFirebaseDataSource',
      );
      _memberChangeSubscription?.cancel();
      _memberChangeSubscription = null;
    }
  }

  // 🔧 새로 추가: 리소스 정리 메서드
  void dispose() {
    AppLogger.info(
      'Disposing GroupFirebaseDataSource',
      tag: 'GroupFirebaseDataSource',
    );
    _stopMemberChangeDetection();
  }

  // 🔧 새로 추가: Firebase Storage URL에서 이미지 삭제하는 헬퍼 메서드
  Future<void> _deleteImageFromStorage(String imageUrl) async {
    try {
      if (imageUrl.isEmpty || !imageUrl.startsWith('http')) {
        AppLogger.info(
          'Invalid image URL, skipping deletion: $imageUrl',
          tag: 'GroupFirebaseDataSource',
        );
        return;
      }

      // Firebase Storage URL에서 파일 참조 생성
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      AppLogger.info(
        'Successfully deleted image from storage: $imageUrl',
        tag: 'GroupFirebaseDataSource',
      );
    } catch (e) {
      if (e.toString().contains('object-not-found')) {
        AppLogger.info(
          'Image already deleted or not found: $imageUrl',
          tag: 'GroupFirebaseDataSource',
        );
      } else {
        AppLogger.error(
          'Failed to delete image from storage',
          tag: 'GroupFirebaseDataSource',
          error: e,
        );
        // 삭제 실패는 로그만 남기고 예외를 던지지 않음 (그룹 업데이트는 계속 진행)
      }
    }
  }

  // 🔧 새로 추가: 그룹 폴더 전체 삭제하는 헬퍼 메서드
  Future<void> _deleteGroupFolder(String groupId) async {
    try {
      final folderRef = _storage.ref().child('groups/$groupId');

      // 폴더 내 모든 파일 목록 가져오기
      final result = await folderRef.listAll();

      // 각 파일 삭제
      final deleteFutures = result.items.map((item) => item.delete());
      await Future.wait(deleteFutures);

      AppLogger.info(
        'Successfully deleted group folder: groups/$groupId',
        tag: 'GroupFirebaseDataSource',
      );
    } catch (e) {
      AppLogger.error(
        'Failed to delete group folder',
        tag: 'GroupFirebaseDataSource',
        error: e,
      );
    }
  }

  // 현재 사용자 확인 헬퍼 메서드
  String _getCurrentUserId() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception(AuthErrorMessages.noLoggedInUser);
    }
    return user.uid;
  }

  // 현재 사용자 정보 가져오기 헬퍼 메서드
  Future<Map<String, String>> _getCurrentUserInfo() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception(AuthErrorMessages.noLoggedInUser);
    }

    final userId = user.uid;
    final userName = user.displayName ?? '';
    final profileUrl = user.photoURL ?? '';

    return {
      'userId': userId,
      'userName': userName,
      'profileUrl': profileUrl,
    };
  }

  // 현재 사용자의 가입 그룹 ID 목록 가져오기 (캐싱 적용)
  Future<Set<String>> _getCurrentUserJoinedGroupIds() async {
    try {
      final userId = _getCurrentUserId();
      AppLogger.debug(
        'Checking joined groups for user: $userId',
        tag: 'GroupFirebaseDataSource',
      );

      // 캐시 확인
      if (_cachedJoinedGroups != null && _lastUserId == userId) {
        AppLogger.debug(
          'Using cached joined groups: $_cachedJoinedGroups',
          tag: 'GroupFirebaseDataSource',
        );
        return _cachedJoinedGroups!;
      }

      // Firestore에서 사용자 문서 조회
      final userDoc = await _usersCollection.doc(userId).get();
      AppLogger.debug(
        'User document exists: ${userDoc.exists}',
        tag: 'GroupFirebaseDataSource',
      );

      if (!userDoc.exists) {
        AppLogger.debug(
          'User document not found, returning empty set',
          tag: 'GroupFirebaseDataSource',
        );
        _cachedJoinedGroups = {};
        _lastUserId = userId;
        return {};
      }

      final userData = userDoc.data()!;
      AppLogger.debug(
        'User document data: $userData',
        tag: 'GroupFirebaseDataSource',
      );

      if (!userData.containsKey('joingroup')) {
        AppLogger.debug(
          'No joingroup field found, returning empty set',
          tag: 'GroupFirebaseDataSource',
        );
        _cachedJoinedGroups = {};
        _lastUserId = userId;
        return {};
      }

      final joinGroups = userData['joingroup'] as List<dynamic>;
      AppLogger.debug(
        'Raw joingroup data: $joinGroups',
        tag: 'GroupFirebaseDataSource',
      );

      final joinedGroupIds =
          joinGroups
              .map((group) {
                AppLogger.debug(
                  'Processing group: $group',
                  tag: 'GroupFirebaseDataSource',
                );
                return group['group_id'] as String?;
              })
              .where((id) => id != null)
              .cast<String>()
              .toSet();

      AppLogger.debug(
        'Extracted joined group IDs: $joinedGroupIds',
        tag: 'GroupFirebaseDataSource',
      );

      // 캐시 업데이트
      _cachedJoinedGroups = joinedGroupIds;
      _lastUserId = userId;

      return joinedGroupIds;
    } catch (e, st) {
      AppLogger.error(
        'Error getting joined groups',
        tag: 'GroupFirebaseDataSource',
        error: e,
        stackTrace: st,
      );
      return {};
    }
  }

  // 🔧 그룹 ID 변경 시 멤버 캐시 무효화 (기존 메서드 수정)
  void _invalidateMemberCacheIfNeeded(String newGroupId) {
    if (_lastGroupId != null && _lastGroupId != newGroupId) {
      AppLogger.info(
        'Group ID changed ($_lastGroupId → $newGroupId), invalidating member cache',
        tag: 'GroupFirebaseDataSource',
      );
      _cachedGroupMembers = null;
      _lastGroupId = null;
      // 🔧 기존 멤버 감지도 중지
      _stopMemberChangeDetection();
    }
  }

  // 🔧 멤버 정보 캐시 무효화 (기존 메서드 수정)
  void _invalidateMemberCache(String groupId) {
    if (_lastGroupId == groupId) {
      AppLogger.info(
        'Invalidating member cache for group: $groupId',
        tag: 'GroupFirebaseDataSource',
      );
      _cachedGroupMembers = null;
      _lastGroupId = null;
      // 🔧 멤버 감지도 중지 (멤버 정보가 변경되었으므로)
      _stopMemberChangeDetection();
    }
  }

  // 그룹 멤버 목록 조회 (내부 헬퍼 메서드)
  Future<List<String>> _getGroupMemberUserIds(String groupId) async {
    try {
      // 🔧 멤버 정보 캐시 확인
      List<Map<String, dynamic>> members;

      if (_cachedGroupMembers != null && _lastGroupId == groupId) {
        AppLogger.debug(
          'Using cached group members for memberUserIds',
          tag: 'GroupFirebaseDataSource',
        );
        members = _cachedGroupMembers!;
      } else {
        final membersSnapshot =
            await _groupsCollection.doc(groupId).collection('members').get();

        members =
            membersSnapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList();
      }

      return members
          .map((member) => member['userId'] as String?)
          .where((userId) => userId != null)
          .cast<String>()
          .toList();
    } catch (e) {
      AppLogger.error(
        '그룹 멤버 조회 오류',
        tag: 'GroupFirebaseDataSource',
        error: e,
      );
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchGroupList() async {
    return ApiCallDecorator.wrap('GroupFirebase.fetchGroupList', () async {
      try {
        // 1. 그룹 목록 조회
        final querySnapshot =
            await _groupsCollection
                .orderBy('createdAt', descending: true)
                .get();

        if (querySnapshot.docs.isEmpty) {
          AppLogger.debug(
            'No groups found in Firestore',
            tag: 'GroupFirebaseDataSource',
          );
          return [];
        }

        AppLogger.info(
          'Found ${querySnapshot.docs.length} groups in Firestore',
          tag: 'GroupFirebaseDataSource',
        );

        // 2. 현재 사용자의 가입 그룹 ID 목록 조회
        final joinedGroupIds = await _getCurrentUserJoinedGroupIds();

        // 3. 그룹 데이터 변환 및 멤버십 상태 설정
        final groups =
            querySnapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;

              final groupId = doc.id;
              final isJoined = joinedGroupIds.contains(groupId);

              // 가입 여부 설정
              data['isJoinedByCurrentUser'] = isJoined;

              return data;
            }).toList();

        return groups;
      } catch (e) {
        AppLogger.error(
          'Error in fetchGroupList',
          tag: 'GroupFirebaseDataSource',
          error: e,
        );
        throw Exception(GroupErrorMessages.loadFailed);
      }
    });
  }

  @override
  Future<Map<String, dynamic>> fetchGroupDetail(String groupId) async {
    return ApiCallDecorator.wrap('GroupFirebase.fetchGroupDetail', () async {
      try {
        // 🔧 그룹 ID 변경 감지
        _invalidateMemberCacheIfNeeded(groupId);

        // 1. 그룹 문서 조회
        final docSnapshot = await _groupsCollection.doc(groupId).get();

        // ✅ 비즈니스 로직 검증: 그룹 존재 여부
        if (!docSnapshot.exists) {
          throw Exception(GroupErrorMessages.notFound);
        }

        // 2. 기본 그룹 데이터
        final data = docSnapshot.data()!;
        data['id'] = docSnapshot.id;

        // 3. 현재 사용자의 가입 여부 확인
        final joinedGroupIds = await _getCurrentUserJoinedGroupIds();
        data['isJoinedByCurrentUser'] = joinedGroupIds.contains(groupId);

        return data;
      } catch (e, st) {
        // ✅ 예외 구분 처리
        if (e is Exception &&
            e.toString().contains(GroupErrorMessages.notFound)) {
          // 비즈니스 로직 검증 실패: 의미 있는 예외 그대로 전달
          AppLogger.error(
            '그룹 상세 비즈니스 로직 오류',
            tag: 'GroupFirebaseDataSource',
            error: e,
          );
          rethrow;
        } else {
          // Firebase 통신 오류: 원본 예외 정보 보존
          AppLogger.error(
            '그룹 상세 Firebase 통신 오류',
            tag: 'GroupFirebaseDataSource',
            error: e,
            stackTrace: st,
          );
          rethrow;
        }
      }
    }, params: {'groupId': groupId});
  }

  @override
  Future<void> fetchJoinGroup(String groupId) async {
    return ApiCallDecorator.wrap('GroupFirebase.fetchJoinGroup', () async {
      try {
        // 현재 사용자 정보 가져오기
        final userInfo = await _getCurrentUserInfo();
        final userId = userInfo['userId']!;
        final userName = userInfo['userName']!;
        final profileUrl = userInfo['profileUrl']!;

        // 트랜잭션을 사용하여 멤버 추가 및 카운터 업데이트
        return _firestore.runTransaction((transaction) async {
          // 1. 그룹 문서 조회
          final groupDoc = await transaction.get(
            _groupsCollection.doc(groupId),
          );

          if (!groupDoc.exists) {
            throw Exception(GroupErrorMessages.notFound);
          }

          // 2. 현재 멤버 수 확인
          final data = groupDoc.data()!;
          final currentMemberCount = data['memberCount'] as int? ?? 0;
          final maxMemberCount = data['maxMemberCount'] as int? ?? 10;

          // 3. 멤버 수 제한 확인
          if (currentMemberCount >= maxMemberCount) {
            throw Exception(GroupErrorMessages.memberLimitReached);
          }

          // 4. 멤버 추가
          transaction.set(
            _groupsCollection.doc(groupId).collection('members').doc(userId),
            {
              'userId': userId,
              'userName': userName,
              'profileUrl': profileUrl,
              'role': 'member',
              'joinedAt': FieldValue.serverTimestamp(),
            },
          );

          // 5. 멤버 수 증가
          transaction.update(_groupsCollection.doc(groupId), {
            'memberCount': currentMemberCount + 1,
          });

          // 6. 사용자 문서에 가입 그룹 정보 추가
          transaction.update(_usersCollection.doc(userId), {
            'joingroup': FieldValue.arrayUnion([
              {
                'group_id': groupId,
                'group_name': data['name'] ?? '',
                'group_image': data['imageUrl'] ?? '',
              },
            ]),
          });

          // 7. 캐시 무효화 (가입 그룹 정보와 멤버 정보가 변경되었으므로)
          _cachedJoinedGroups = null;
          _invalidateMemberCache(groupId); // 🔧 멤버 캐시 무효화 (감지도 중지됨)
        });
      } catch (e, st) {
        // ✅ 예외 구분 처리
        if (e is Exception &&
            (e.toString().contains(GroupErrorMessages.notFound) ||
                e.toString().contains(GroupErrorMessages.memberLimitReached))) {
          // 비즈니스 로직 검증 실패: 의미 있는 예외 그대로 전달
          AppLogger.error(
            '그룹 가입 비즈니스 로직 오류',
            tag: 'GroupFirebaseDataSource',
            error: e,
          );
          rethrow;
        } else {
          // Firebase 통신 오류: 원본 예외 정보 보존
          AppLogger.error(
            '그룹 가입 Firebase 통신 오류',
            tag: 'GroupFirebaseDataSource',
            error: e,
            stackTrace: st,
          );
          rethrow;
        }
      }
    }, params: {'groupId': groupId});
  }

  @override
  Future<Map<String, dynamic>> fetchCreateGroup(
    Map<String, dynamic> groupData,
  ) async {
    return ApiCallDecorator.wrap('GroupFirebase.fetchCreateGroup', () async {
      try {
        // 현재 사용자 정보 가져오기
        final userInfo = await _getCurrentUserInfo();
        final ownerId = userInfo['userId']!;
        final ownerNickname = userInfo['userName']!;
        final ownerProfileUrl = userInfo['profileUrl']!;

        // 새 그룹 ID 생성
        final groupRef = _groupsCollection.doc();
        final groupId = groupRef.id;

        // 타임스탬프 생성
        final now = FieldValue.serverTimestamp();

        // 그룹 데이터 준비
        final finalGroupData = {
          ...groupData,
          'createdAt': now,
          'updatedAt': now,
          'ownerId': ownerId,
          'ownerNickname': ownerNickname,
          'ownerProfileImage': ownerProfileUrl,
          'memberCount': 1, // 처음에는 생성자만 멤버
        };

        // 트랜잭션을 사용하여 그룹 생성 및 멤버 추가
        await _firestore.runTransaction((transaction) async {
          // 1. 그룹 문서 생성
          transaction.set(groupRef, finalGroupData);

          // 2. 소유자(방장) 멤버 추가
          transaction.set(groupRef.collection('members').doc(ownerId), {
            'userId': ownerId,
            'userName': ownerNickname,
            'profileUrl': ownerProfileUrl,
            'role': 'owner',
            'joinedAt': now,
          });

          // 3. 사용자 문서에 가입 그룹 정보 추가
          transaction.update(_usersCollection.doc(ownerId), {
            'joingroup': FieldValue.arrayUnion([
              {
                'group_id': groupId,
                'group_name': groupData['name'] ?? '',
                'group_image': groupData['imageUrl'] ?? '',
              },
            ]),
          });

          // 4. 캐시 무효화 (가입 그룹 정보가 변경되었으므로)
          _cachedJoinedGroups = null;
          // 🔧 새 그룹이므로 멤버 캐시는 무효화할 필요 없음
        });

        // 생성된 그룹 정보 반환을 위한 준비
        final createdGroupDoc = await groupRef.get();
        if (!createdGroupDoc.exists) {
          throw Exception(GroupErrorMessages.createFailed);
        }

        // 생성된 그룹 데이터 반환
        final createdData = createdGroupDoc.data()!;
        createdData['id'] = groupId;
        createdData['isJoinedByCurrentUser'] = true; // 생성자는 항상 가입됨

        return createdData;
      } catch (e) {
        AppLogger.error(
          '그룹 생성 오류',
          tag: 'GroupFirebaseDataSource',
          error: e,
        );
        throw Exception(GroupErrorMessages.createFailed);
      }
    });
  }

  @override
  Future<void> fetchUpdateGroup(
    String groupId,
    Map<String, dynamic> updateData,
  ) async {
    return ApiCallDecorator.wrap('GroupFirebase.fetchUpdateGroup', () async {
      try {
        // 🔧 이미지 업데이트 시 기존 이미지 삭제 처리
        if (updateData.containsKey('imageUrl')) {
          // 기존 그룹 정보 조회
          final groupDoc = await _groupsCollection.doc(groupId).get();
          if (groupDoc.exists) {
            final currentData = groupDoc.data()!;
            final currentImageUrl = currentData['imageUrl'] as String?;

            // 기존 이미지가 있고, 새 이미지와 다른 경우 기존 이미지 삭제
            if (currentImageUrl != null &&
                currentImageUrl.isNotEmpty &&
                currentImageUrl != updateData['imageUrl']) {
              AppLogger.info(
                'Deleting previous group image: $currentImageUrl',
                tag: 'GroupFirebaseDataSource',
              );
              await _deleteImageFromStorage(currentImageUrl);
            }
          }
        }

        // 업데이트 필드 준비
        final updates = {...updateData};

        // id, createdAt, createdBy, memberCount는 수정 불가
        updates.remove('id');
        updates.remove('createdAt');
        updates.remove('createdBy');
        updates.remove('memberCount');

        // 업데이트 시간 추가
        updates['updatedAt'] = FieldValue.serverTimestamp();

        // 그룹 이름이나 이미지가 변경되는 경우에만 멤버 정보 업데이트 필요
        final nameChanged = updates.containsKey('name');
        final imageUrlChanged = updates.containsKey('imageUrl');

        if (nameChanged || imageUrlChanged) {
          // WriteBatch 생성
          final batch = _firestore.batch();

          // 그룹 문서 업데이트
          batch.update(_groupsCollection.doc(groupId), updates);

          // 멤버 목록 조회
          final membersSnapshot =
              await _groupsCollection.doc(groupId).collection('members').get();

          // 각 멤버의 사용자 문서에서 joingroup 배열 업데이트
          for (final memberDoc in membersSnapshot.docs) {
            final userId = memberDoc.data()['userId'] as String?;
            if (userId == null) continue;

            // 사용자 문서 참조
            final userRef = _usersCollection.doc(userId);

            // 현재 그룹 정보 조회
            final userDoc = await userRef.get();
            if (!userDoc.exists || !userDoc.data()!.containsKey('joingroup')) {
              continue;
            }

            final joingroups = userDoc.data()!['joingroup'] as List<dynamic>;

            // 현재 그룹 정보 찾기
            for (int i = 0; i < joingroups.length; i++) {
              final groupInfo = joingroups[i] as Map<String, dynamic>;

              if (groupInfo['group_id'] == groupId) {
                // 새 그룹 정보 생성
                final updatedGroupInfo = {
                  'group_id': groupId,
                  'group_name':
                      nameChanged ? updates['name'] : groupInfo['group_name'],
                  'group_image':
                      imageUrlChanged
                          ? updates['imageUrl']
                          : groupInfo['group_image'],
                };

                // 기존 그룹 정보 제거 후 새 정보 추가
                batch.update(userRef, {
                  'joingroup': FieldValue.arrayRemove([groupInfo]),
                });

                batch.update(userRef, {
                  'joingroup': FieldValue.arrayUnion([updatedGroupInfo]),
                });

                break;
              }
            }
          }

          // 모든 작업을 한 번에 커밋
          await batch.commit();
        } else {
          // 그룹 이름/이미지가 변경되지 않았으면 그룹 문서만 업데이트
          await _groupsCollection.doc(groupId).update(updates);
        }

        // 🔧 그룹 정보 변경 시 멤버 캐시 무효화 (멤버 정보에 그룹명 등이 포함될 수 있음)
        if (nameChanged || imageUrlChanged) {
          _invalidateMemberCache(groupId);
        }
      } catch (e) {
        AppLogger.error(
          '그룹 업데이트 오류',
          tag: 'GroupFirebaseDataSource',
          error: e,
        );
        throw Exception(GroupErrorMessages.updateFailed);
      }
    }, params: {'groupId': groupId});
  }

  @override
  Future<void> fetchLeaveGroup(String groupId) async {
    return ApiCallDecorator.wrap('GroupFirebase.fetchLeaveGroup', () async {
      try {
        final userId = _getCurrentUserId();

        // 트랜잭션을 사용하여 멤버 제거 및 카운터 업데이트
        return _firestore.runTransaction((transaction) async {
          // 🔥 1단계: 모든 읽기 작업을 먼저 수행
          final groupDoc = await transaction.get(
            _groupsCollection.doc(groupId),
          );
          final memberDoc = await transaction.get(
            _groupsCollection.doc(groupId).collection('members').doc(userId),
          );
          final userDoc = await transaction.get(_usersCollection.doc(userId));

          // 🔥 2단계: 읽기 완료 후 검증 로직
          if (!groupDoc.exists) {
            throw Exception(GroupErrorMessages.notFound);
          }

          // ✅ 비즈니스 로직 검증: 멤버 여부 확인
          if (!memberDoc.exists) {
            throw Exception(GroupErrorMessages.notMember);
          }

          // 소유자 확인 (소유자는 탈퇴 불가)
          final memberData = memberDoc.data()!;

          // ✅ 비즈니스 로직 검증: 소유자 탈퇴 방지
          if (memberData['role'] == 'owner') {
            throw Exception(GroupErrorMessages.ownerCannotLeave);
          }

          // 현재 멤버 수 확인
          final groupData = groupDoc.data()!;
          final currentMemberCount = groupData['memberCount'] as int? ?? 0;

          // 🔥 3단계: 모든 쓰기 작업을 나중에 수행
          // 멤버 제거
          transaction.delete(
            _groupsCollection.doc(groupId).collection('members').doc(userId),
          );

          // 멤버 수 감소
          transaction.update(_groupsCollection.doc(groupId), {
            'memberCount': currentMemberCount > 0 ? currentMemberCount - 1 : 0,
          });

          // 사용자 문서에서 가입 그룹 정보 제거
          if (userDoc.exists && userDoc.data()!.containsKey('joingroup')) {
            final joingroups = userDoc.data()!['joingroup'] as List<dynamic>;

            // 그룹 ID로 항목 찾기
            for (final joingroup in joingroups) {
              if (joingroup['group_id'] == groupId) {
                // 그룹 정보 제거
                transaction.update(_usersCollection.doc(userId), {
                  'joingroup': FieldValue.arrayRemove([joingroup]),
                });
                break;
              }
            }
          }

          // 캐시 무효화 (가입 그룹 정보와 멤버 정보가 변경되었으므로)
          _cachedJoinedGroups = null;
          _invalidateMemberCache(groupId); // 🔧 멤버 캐시 무효화 (감지도 중지됨)
        });
      } catch (e, st) {
        // ✅ 예외 구분 처리
        if (e is Exception &&
            (e.toString().contains(GroupErrorMessages.notFound) ||
                e.toString().contains(GroupErrorMessages.notMember) ||
                e.toString().contains(GroupErrorMessages.ownerCannotLeave))) {
          // 비즈니스 로직 검증 실패: 의미 있는 예외 그대로 전달
          AppLogger.error(
            '그룹 탈퇴 비즈니스 로직 오류',
            tag: 'GroupFirebaseDataSource',
            error: e,
          );
          rethrow;
        } else {
          // Firebase 통신 오류: 원본 예외 정보 보존
          AppLogger.error(
            '그룹 탈퇴 Firebase 통신 오류',
            tag: 'GroupFirebaseDataSource',
            error: e,
            stackTrace: st,
          );
          rethrow;
        }
      }
    }, params: {'groupId': groupId});
  }

  @override
  Future<List<Map<String, dynamic>>> fetchGroupMembers(String groupId) async {
    return ApiCallDecorator.wrap('GroupFirebase.fetchGroupMembers', () async {
      try {
        // 🔧 캐시 확인
        if (_cachedGroupMembers != null && _lastGroupId == groupId) {
          AppLogger.debug(
            'Using cached group members',
            tag: 'GroupFirebaseDataSource',
          );
          return List<Map<String, dynamic>>.from(_cachedGroupMembers!);
        }

        AppLogger.info(
          'Fetching group members from Firestore',
          tag: 'GroupFirebaseDataSource',
        );

        // 그룹 존재 확인
        final groupDoc = await _groupsCollection.doc(groupId).get();
        if (!groupDoc.exists) {
          throw Exception(GroupErrorMessages.notFound);
        }

        // 멤버 컬렉션 조회
        final membersSnapshot =
            await _groupsCollection.doc(groupId).collection('members').get();

        // 멤버 데이터 변환
        final members =
            membersSnapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList();

        // 🔧 캐시 업데이트 및 멤버 변경 감지 시작
        _cachedGroupMembers = List<Map<String, dynamic>>.from(members);
        _lastGroupId = groupId;
        AppLogger.debug(
          'Cached group members for groupId: $groupId',
          tag: 'GroupFirebaseDataSource',
        );

        // 🔧 멤버 변경 감지 시작
        _startMemberChangeDetection(groupId);

        return members;
      } catch (e) {
        AppLogger.error(
          '그룹 멤버 조회 오류',
          tag: 'GroupFirebaseDataSource',
          error: e,
        );
        throw Exception(GroupErrorMessages.loadFailed);
      }
    }, params: {'groupId': groupId});
  }

  @override
  Future<String> updateGroupImage(String groupId, String localImagePath) async {
    return ApiCallDecorator.wrap('GroupFirebase.updateGroupImage', () async {
      try {
        // 그룹 존재 확인
        final groupDoc = await _groupsCollection.doc(groupId).get();

        if (!groupDoc.exists) {
          throw Exception(GroupErrorMessages.notFound);
        }

        String imageUrl;

        // URL인 경우 (이미 업로드된 이미지 사용)
        if (localImagePath.startsWith('http')) {
          imageUrl = localImagePath;
        } else {
          // 로컬 파일 업로드
          final file = File(localImagePath);
          final fileName =
              '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
          final storageRef = _storage.ref().child('groups/$groupId/$fileName');

          // 파일 업로드
          final uploadTask = await storageRef.putFile(file);

          // 다운로드 URL 가져오기
          imageUrl = await uploadTask.ref.getDownloadURL();
        }

        // 그룹 이미지 업데이트
        await _groupsCollection.doc(groupId).update({
          'imageUrl': imageUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 멤버들의 가입 그룹 정보 업데이트
        final groupName = groupDoc.data()!['name'] as String?;

        if (groupName != null) {
          // 모든 멤버 조회
          final membersSnapshot =
              await _groupsCollection.doc(groupId).collection('members').get();

          for (final memberDoc in membersSnapshot.docs) {
            final userId = memberDoc.data()['userId'] as String?;
            if (userId != null) {
              // 사용자 문서 조회
              final userDoc = await _usersCollection.doc(userId).get();

              if (userDoc.exists && userDoc.data()!.containsKey('joingroup')) {
                final joingroups =
                    userDoc.data()!['joingroup'] as List<dynamic>;

                // 그룹 ID로 항목 찾기
                for (final joingroup in joingroups) {
                  if (joingroup['group_id'] == groupId) {
                    // 그룹 이미지 업데이트
                    await _usersCollection.doc(userId).update({
                      'joingroup': FieldValue.arrayRemove([joingroup]),
                    });

                    await _usersCollection.doc(userId).update({
                      'joingroup': FieldValue.arrayUnion([
                        {
                          'group_id': groupId,
                          'group_name': joingroup['group_name'],
                          'group_image': imageUrl,
                        },
                      ]),
                    });

                    break;
                  }
                }
              }
            }
          }
        }

        // 🔧 이미지 변경 시 멤버 캐시 무효화 (필요시)
        _invalidateMemberCache(groupId);

        return imageUrl;
      } catch (e) {
        AppLogger.error(
          '그룹 이미지 업데이트 오류',
          tag: 'GroupFirebaseDataSource',
          error: e,
        );
        throw Exception(GroupErrorMessages.updateFailed);
      }
    }, params: {'groupId': groupId});
  }

  @override
  Future<List<Map<String, dynamic>>> searchGroups(
    String query, {
    bool searchKeywords = true,
    bool searchTags = true,
    int? limit,
    String? sortBy,
  }) async {
    return ApiCallDecorator.wrap(
      'GroupFirebase.searchGroups',
      () async {
        try {
          if (query.isEmpty) {
            return [];
          }

          // 현재 사용자의 가입 그룹 ID 목록 조회
          final joinedGroupIds = await _getCurrentUserJoinedGroupIds();

          final lowercaseQuery = query.toLowerCase();
          final Set<DocumentSnapshot<Map<String, dynamic>>> resultDocs = {};

          // 키워드 검색 (이름, 설명)
          if (searchKeywords) {
            // 이름 기반 검색
            final nameSnapshot =
                await _groupsCollection
                    .orderBy('name')
                    .startAt([lowercaseQuery])
                    .endAt(['$lowercaseQuery\uf8ff'])
                    .get();

            resultDocs.addAll(nameSnapshot.docs);

            // 설명 기반 검색
            final descSnapshot =
                await _groupsCollection
                    .orderBy('description')
                    .startAt([lowercaseQuery])
                    .endAt(['$lowercaseQuery\uf8ff'])
                    .get();

            resultDocs.addAll(descSnapshot.docs);
          }

          // 태그 검색
          if (searchTags) {
            final tagSnapshot =
                await _groupsCollection
                    .where('hashTags', arrayContains: lowercaseQuery)
                    .get();

            resultDocs.addAll(tagSnapshot.docs);
          }

          // 결과가 충분하지 않으면 추가 확장 검색
          if (resultDocs.length < 10) {
            final allGroups =
                await _groupsCollection
                    .orderBy('createdAt', descending: true)
                    .limit(50)
                    .get();

            // 클라이언트 측 추가 필터링
            for (final doc in allGroups.docs) {
              if (resultDocs.contains(doc)) continue;

              final data = doc.data();
              final name = (data['name'] as String? ?? '').toLowerCase();
              final description =
                  (data['description'] as String? ?? '').toLowerCase();
              final hashTags =
                  (data['hashTags'] as List<dynamic>? ?? [])
                      .map((tag) => (tag as String).toLowerCase())
                      .toList();

              // 부분 일치 검색
              if ((searchKeywords &&
                      (name.contains(lowercaseQuery) ||
                          description.contains(lowercaseQuery))) ||
                  (searchTags &&
                      hashTags.any((tag) => tag.contains(lowercaseQuery)))) {
                resultDocs.add(doc);
              }
            }
          }

          // 검색 결과 변환
          final results =
              resultDocs.map((doc) {
                final data = doc.data()!;
                data['id'] = doc.id;

                // 가입 여부 설정
                data['isJoinedByCurrentUser'] = joinedGroupIds.contains(doc.id);

                return data;
              }).toList();

          // 정렬 적용
          if (sortBy != null) {
            switch (sortBy) {
              case 'name':
                results.sort(
                  (a, b) => (a['name'] as String? ?? '').compareTo(
                    b['name'] as String? ?? '',
                  ),
                );
                break;
              case 'createdAt':
                results.sort((a, b) {
                  final timestampA = a['createdAt'] as Timestamp?;
                  final timestampB = b['createdAt'] as Timestamp?;
                  if (timestampA == null || timestampB == null) return 0;
                  return timestampB.compareTo(timestampA); // 최신순
                });
                break;
              case 'memberCount':
                results.sort(
                  (a, b) => ((b['memberCount'] as int?) ?? 0).compareTo(
                    (a['memberCount'] as int?) ?? 0,
                  ),
                );
                break;
            }
          } else {
            // 기본 정렬: 최신순
            results.sort((a, b) {
              final timestampA = a['createdAt'] as Timestamp?;
              final timestampB = b['createdAt'] as Timestamp?;
              if (timestampA == null || timestampB == null) return 0;
              return timestampB.compareTo(timestampA);
            });
          }

          // 결과 개수 제한
          if (limit != null && limit > 0 && results.length > limit) {
            return results.sublist(0, limit);
          }

          return results;
        } catch (e) {
          AppLogger.error(
            '통합 그룹 검색 오류',
            tag: 'GroupFirebaseDataSource',
            error: e,
          );
          throw Exception('그룹 검색 중 오류가 발생했습니다');
        }
      },
      params: {'query': query},
    );
  }

  @override
  Future<List<Map<String, dynamic>>> fetchGroupTimerActivities(
    String groupId,
  ) async {
    return ApiCallDecorator.wrap(
      'GroupFirebase.fetchGroupTimerActivities',
      () async {
        try {
          // 그룹 존재 확인
          final groupDoc = await _groupsCollection.doc(groupId).get();
          if (!groupDoc.exists) {
            throw Exception(GroupErrorMessages.notFound);
          }

          // 🔧 개선: 멤버별 최신 활동만 효율적으로 조회
          final memberUserIds = await _getGroupMemberUserIds(groupId);

          if (memberUserIds.isEmpty) {
            return [];
          }

          // 멤버별로 최신 1개씩만 병렬 조회
          final futures = memberUserIds.map((userId) async {
            final activitySnapshot =
                await _groupsCollection
                    .doc(groupId)
                    .collection('timerActivities')
                    .where('userId', isEqualTo: userId)
                    .orderBy('timestamp', descending: true)
                    .limit(1)
                    .get();

            if (activitySnapshot.docs.isNotEmpty) {
              final doc = activitySnapshot.docs.first;
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }
            return null;
          });

          final results = await Future.wait(futures);

          // null 제거하고 반환
          return results
              .where((data) => data != null)
              .cast<Map<String, dynamic>>()
              .toList();
        } catch (e) {
          AppLogger.error(
            '그룹 타이머 활동 조회 오류',
            tag: 'GroupFirebaseDataSource',
            error: e,
          );
          throw Exception(GroupErrorMessages.loadFailed);
        }
      },
      params: {'groupId': groupId},
    );
  }

  // 🔧 새로운 실시간 스트림 메소드 - 복합 스트림으로 수정
  @override
  Stream<List<Map<String, dynamic>>> streamGroupMemberTimerStatus(
    String groupId,
  ) {
    final membersStream =
        _groupsCollection.doc(groupId).collection('members').snapshots();

    final activitiesStream =
        _groupsCollection
            .doc(groupId)
            .collection('timerActivities')
            .orderBy('timestamp', descending: true)
            .snapshots();

    // 🔧 StreamController를 사용해서 두 스트림을 결합
    late StreamController<List<Map<String, dynamic>>> controller;
    late StreamSubscription membersSub;
    late StreamSubscription activitiesSub;

    void handleUpdate() async {
      try {
        AppLogger.debug(
          '멤버 또는 타이머 활동 변경 감지',
          tag: 'GroupFirebaseDataSource',
        );

        // 1. 멤버 정보 조회 (캐싱 활용)
        final members = await fetchGroupMembers(groupId);

        if (members.isEmpty) {
          AppLogger.warning(
            '멤버가 없어서 빈 리스트 반환',
            tag: 'GroupFirebaseDataSource',
          );
          controller.add(<Map<String, dynamic>>[]);
          return;
        }

        // 2. 최신 타이머 활동 조회
        final activitiesSnapshot =
            await _groupsCollection
                .doc(groupId)
                .collection('timerActivities')
                .orderBy('timestamp', descending: true)
                .get();

        // 3. 멤버별 최신 타이머 활동 추출
        final memberLastActivities = <String, Map<String, dynamic>>{};

        for (final doc in activitiesSnapshot.docs) {
          final activity = doc.data();
          final userId = activity['userId'] as String?;

          if (userId != null && !memberLastActivities.containsKey(userId)) {
            memberLastActivities[userId] = {
              ...activity,
              'id': doc.id,
            };
          }
        }

        AppLogger.debug(
          '멤버별 최신 활동 추출 완료: ${memberLastActivities.length}명',
          tag: 'GroupFirebaseDataSource',
        );

        // 4. DTO 형태로 결합하여 반환
        final result = _combineMemebersWithTimerStatusAsDto(
          members,
          memberLastActivities,
        );

        controller.add(result);
      } catch (e) {
        AppLogger.error(
          '복합 스트림 처리 오류',
          tag: 'GroupFirebaseDataSource',
          error: e,
        );
        controller.addError(e);
      }
    }

    controller = StreamController<List<Map<String, dynamic>>>(
      onListen: () {
        membersSub = membersStream.listen((_) => handleUpdate());
        activitiesSub = activitiesStream.listen((_) => handleUpdate());
      },
      onCancel: () {
        membersSub.cancel();
        activitiesSub.cancel();
      },
    );

    return controller.stream;
  }

  // 🔧 멤버 정보와 타이머 상태를 DTO 형태로 결합하는 헬퍼 메서드
  List<Map<String, dynamic>> _combineMemebersWithTimerStatusAsDto(
    List<Map<String, dynamic>> members,
    Map<String, Map<String, dynamic>> memberLastActivities,
  ) {
    final result = <Map<String, dynamic>>[];

    for (final member in members) {
      final userId = member['userId'] as String?;
      if (userId == null) {
        // userId가 없는 멤버는 그대로 추가 (타이머 상태 없음)
        result.add({
          'memberDto': member,
          'timerActivityDto': null,
        });
        continue;
      }

      // 해당 멤버의 최신 타이머 활동 찾기
      final lastActivity = memberLastActivities[userId];

      // 멤버 DTO와 타이머 활동 DTO를 분리하여 저장
      result.add({
        'memberDto': member,
        'timerActivityDto': lastActivity, // null일 수 있음 (타이머 활동이 없는 경우)
      });
    }

    return result;
  }

  @override
  Future<Map<String, dynamic>> startMemberTimer(String groupId) async {
    return ApiCallDecorator.wrap(
      'GroupFirebase.startMemberTimer',
      () async {
        try {
          // 현재 사용자 정보 가져오기
          final userInfo = await _getCurrentUserInfo();
          final userId = userInfo['userId']!;
          final userName = userInfo['userName']!;

          // 그룹 존재 확인
          final groupDoc = await _groupsCollection.doc(groupId).get();
          if (!groupDoc.exists) {
            throw Exception(GroupErrorMessages.notFound);
          }

          // 타임스탬프 생성
          final now = FieldValue.serverTimestamp();

          // 새 타이머 활동 데이터 준비
          final activityData = {
            'userId': userId,
            'userName': userName,
            'type': 'start',
            'timestamp': now,
            'groupId': groupId,
            'metadata': {},
          };

          // Firestore에 타이머 활동 문서 추가
          final docRef = await _groupsCollection
              .doc(groupId)
              .collection('timerActivities')
              .add(activityData);

          // 생성된 문서 ID와 함께 데이터 반환
          final result = {...activityData};
          result['id'] = docRef.id;
          result['timestamp'] = Timestamp.now();

          return result;
        } catch (e) {
          AppLogger.error(
            '타이머 시작 오류',
            tag: 'GroupFirebaseDataSource',
            error: e,
          );
          throw Exception(GroupErrorMessages.operationFailed);
        }
      },
      params: {'groupId': groupId},
    );
  }

  @override
  Future<Map<String, dynamic>> pauseMemberTimer(String groupId) async {
    return ApiCallDecorator.wrap(
      'GroupFirebase.pauseMemberTimer',
      () async {
        try {
          // 현재 사용자 정보 가져오기
          final userInfo = await _getCurrentUserInfo();
          final userId = userInfo['userId']!;
          final userName = userInfo['userName']!;

          // 그룹 존재 확인
          final groupDoc = await _groupsCollection.doc(groupId).get();
          if (!groupDoc.exists) {
            throw Exception(GroupErrorMessages.notFound);
          }

          // 타임스탬프 생성
          final now = FieldValue.serverTimestamp();

          // 새 타이머 활동 데이터 준비
          final activityData = {
            'userId': userId,
            'userName': userName,
            'type': 'pause',
            'timestamp': now,
            'groupId': groupId,
            'metadata': {},
          };

          // Firestore에 타이머 활동 문서 추가
          final docRef = await _groupsCollection
              .doc(groupId)
              .collection('timerActivities')
              .add(activityData);

          // 생성된 문서 ID와 함께 데이터 반환
          final result = {...activityData};
          result['id'] = docRef.id;
          result['timestamp'] = Timestamp.now();

          return result;
        } catch (e) {
          AppLogger.error(
            '타이머 일시정지 오류',
            tag: 'GroupFirebaseDataSource',
            error: e,
          );
          throw Exception(GroupErrorMessages.operationFailed);
        }
      },
      params: {'groupId': groupId},
    );
  }

  @override
  Future<Map<String, dynamic>> stopMemberTimer(String groupId) async {
    return ApiCallDecorator.wrap(
      'GroupFirebase.stopMemberTimer',
      () async {
        try {
          // 현재 사용자 정보 가져오기
          final userInfo = await _getCurrentUserInfo();
          final userId = userInfo['userId']!;
          final userName = userInfo['userName']!;

          // 그룹 존재 확인
          final groupDoc = await _groupsCollection.doc(groupId).get();
          if (!groupDoc.exists) {
            throw Exception(GroupErrorMessages.notFound);
          }

          // 타임스탬프 생성
          final now = FieldValue.serverTimestamp();

          // 새 타이머 활동 데이터 준비
          final activityData = {
            'userId': userId,
            'userName': userName,
            'type': 'end',
            'timestamp': now,
            'groupId': groupId,
            'metadata': {},
          };

          // Firestore에 타이머 활동 문서 추가
          final docRef = await _groupsCollection
              .doc(groupId)
              .collection('timerActivities')
              .add(activityData);

          // 생성된 문서 ID와 함께 데이터 반환
          final result = {...activityData};
          result['id'] = docRef.id;
          result['timestamp'] = Timestamp.now();

          return result;
        } catch (e) {
          AppLogger.error(
            '타이머 정지 오류',
            tag: 'GroupFirebaseDataSource',
            error: e,
          );
          throw Exception(GroupErrorMessages.operationFailed);
        }
      },
      params: {'groupId': groupId},
    );
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMonthlyAttendances(
    String groupId,
    int year,
    int month, {
    int preloadMonths = 0,
  }) async {
    return ApiCallDecorator.wrap(
      'GroupFirebase.fetchMonthlyAttendances',
      () async {
        try {
          // 그룹 존재 확인
          final groupDoc = await _groupsCollection.doc(groupId).get();
          if (!groupDoc.exists) {
            throw Exception(GroupErrorMessages.notFound);
          }

          // 시작일 계산 (요청 월에서 preloadMonths만큼 이전으로)
          final startMonth = DateTime(year, month - preloadMonths, 1);
          final endDate = DateTime(year, month + 1, 1); // 종료일은 요청 월의 다음 달 1일

          // Timestamp로 변환
          final startTimestamp = Timestamp.fromDate(startMonth);
          final endTimestamp = Timestamp.fromDate(endDate);

          // 해당 기간의 타이머 활동 데이터 조회
          final activitiesSnapshot =
              await _groupsCollection
                  .doc(groupId)
                  .collection('timerActivities')
                  .where('timestamp', isGreaterThanOrEqualTo: startTimestamp)
                  .where('timestamp', isLessThan: endTimestamp)
                  .orderBy('timestamp')
                  .get();

          // 결과가 없는 경우 빈 배열 반환
          if (activitiesSnapshot.docs.isEmpty) {
            return [];
          }

          // 타이머 활동 데이터 변환
          final activities =
              activitiesSnapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return data;
              }).toList();

          return activities;
        } catch (e) {
          AppLogger.error(
            '월별 타이머 활동 데이터 조회 오류',
            tag: 'GroupFirebaseDataSource',
            error: e,
          );
          if (e.toString().contains(GroupErrorMessages.notFound)) {
            throw Exception(GroupErrorMessages.notFound);
          }
          throw Exception(GroupErrorMessages.loadFailed);
        }
      },
      params: {
        'groupId': groupId,
        'year': year,
        'month': month,
        'preloadMonths': preloadMonths,
      },
    );
  }

  // ===== 타임스탬프 지정 가능한 메서드들 추가 =====

  @override
  Future<Map<String, dynamic>> recordTimerActivityWithTimestamp(
    String groupId,
    String activityType,
    DateTime timestamp,
  ) async {
    return ApiCallDecorator.wrap(
      'GroupFirebase.recordTimerActivityWithTimestamp',
      () async {
        try {
          // 현재 사용자 정보 가져오기
          final userInfo = await _getCurrentUserInfo();
          final userId = userInfo['userId']!;
          final userName = userInfo['userName']!;

          // 그룹 존재 확인
          final groupDoc = await _groupsCollection.doc(groupId).get();
          if (!groupDoc.exists) {
            throw Exception(GroupErrorMessages.notFound);
          }

          // 타이머 활동 데이터 준비
          final activityData = {
            'userId': userId,
            'userName': userName,
            'type': activityType,
            'timestamp': Timestamp.fromDate(timestamp), // 특정 시간으로 설정
            'groupId': groupId,
            'metadata': {
              'isManualTimestamp': true, // 수동으로 설정된 타임스탬프 표시
              'recordedAt': FieldValue.serverTimestamp(), // 실제 기록 시간
            },
          };

          // Firestore에 타이머 활동 문서 추가
          final docRef = await _groupsCollection
              .doc(groupId)
              .collection('timerActivities')
              .add(activityData);

          // 생성된 문서 ID와 함께 데이터 반환
          final result = {...activityData};
          result['id'] = docRef.id;

          AppLogger.info(
            '타이머 활동 기록 완료: $activityType at $timestamp',
            tag: 'GroupFirebaseDataSource',
          );

          return result;
        } catch (e) {
          AppLogger.error(
            '타이머 활동 기록 오류',
            tag: 'GroupFirebaseDataSource',
            error: e,
          );
          throw Exception(GroupErrorMessages.operationFailed);
        }
      },
      params: {
        'groupId': groupId,
        'activityType': activityType,
        'timestamp': timestamp.toIso8601String(),
      },
    );
  }

  @override
  Future<Map<String, dynamic>> startMemberTimerWithTimestamp(
    String groupId,
    DateTime timestamp,
  ) async {
    return recordTimerActivityWithTimestamp(groupId, 'start', timestamp);
  }

  @override
  Future<Map<String, dynamic>> pauseMemberTimerWithTimestamp(
    String groupId,
    DateTime timestamp,
  ) async {
    return recordTimerActivityWithTimestamp(groupId, 'pause', timestamp);
  }

  @override
  Future<Map<String, dynamic>> stopMemberTimerWithTimestamp(
    String groupId,
    DateTime timestamp,
  ) async {
    return recordTimerActivityWithTimestamp(groupId, 'end', timestamp);
  }

  // 🔧 새로 추가: 그룹 삭제 시 관련 이미지들 모두 삭제하는 메서드
  Future<void> deleteGroupWithImages(String groupId) async {
    try {
      // 1. 그룹 문서에서 이미지 URL 가져오기
      final groupDoc = await _groupsCollection.doc(groupId).get();
      if (groupDoc.exists) {
        final groupData = groupDoc.data()!;
        final imageUrl = groupData['imageUrl'] as String?;

        // 그룹 대표 이미지 삭제
        if (imageUrl != null && imageUrl.isNotEmpty) {
          await _deleteImageFromStorage(imageUrl);
        }
      }

      // 2. 그룹 폴더 전체 삭제 (혹시 남은 이미지들까지 모두 정리)
      await _deleteGroupFolder(groupId);

      // 3. 그룹 문서 삭제는 별도 메서드에서 처리하도록 함
      print('🗑️ Group images cleanup completed for groupId: $groupId');
    } catch (e) {
      print('❌ Failed to delete group images: $e');
      // 이미지 삭제 실패는 로그만 남기고 계속 진행
    }
  }

  @override
  Future<Map<String, dynamic>> fetchUserMaxStreakDays() async {
    return ApiCallDecorator.wrap(
      'GroupFirebase.fetchUserMaxStreakDays',
      () async {
        try {
          final userId = _getCurrentUserId();

          // 1. 현재 사용자가 가입한 모든 그룹 ID 조회
          final joinedGroupIds = await _getCurrentUserJoinedGroupIds();

          if (joinedGroupIds.isEmpty) {
            return {
              'maxStreakDays': 0,
              'bestGroupId': null,
              'bestGroupName': null,
              'lastActiveDate': Timestamp.now(),
            };
          }

          int maxStreakDays = 0;
          String? bestGroupId;
          String? bestGroupName;
          DateTime? lastActiveDate;

          // 2. 각 그룹별로 연속 출석일 계산
          for (final groupId in joinedGroupIds) {
            final streakInfo = await _calculateUserStreakInfoInGroup(
              groupId,
              userId,
            );

            if (streakInfo['streakDays'] > maxStreakDays) {
              maxStreakDays = streakInfo['streakDays'];
              bestGroupId = groupId;
              bestGroupName = streakInfo['groupName'];
              lastActiveDate = streakInfo['lastActiveDate'];
            }
          }

          return {
            'maxStreakDays': maxStreakDays,
            'bestGroupId': bestGroupId,
            'bestGroupName': bestGroupName,
            'lastActiveDate':
                lastActiveDate != null
                    ? Timestamp.fromDate(lastActiveDate)
                    : Timestamp.now(),
          };
        } catch (e) {
          AppLogger.error(
            '사용자 최대 연속 출석일 조회 오류',
            tag: 'GroupFirebaseDataSource',
            error: e,
          );
          throw Exception('연속 출석일을 불러오는데 실패했습니다');
        }
      },
    );
  }

  /// 특정 그룹에서 특정 사용자의 연속 출석일 및 상세 정보 계산
  /// 특정 그룹에서 특정 사용자의 연속 출석일 및 상세 정보 계산
  Future<Map<String, dynamic>> _calculateUserStreakInfoInGroup(
    String groupId,
    String userId,
  ) async {
    try {
      // 그룹 정보 조회 (그룹 이름 가져오기)
      final groupDoc = await _groupsCollection.doc(groupId).get();
      final groupName =
          groupDoc.exists
              ? (groupDoc.data()?['name'] as String? ?? '알 수 없는 그룹')
              : '알 수 없는 그룹';

      // 최근 30일간의 타이머 활동 조회 (연속 출석일 계산용)
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final startTimestamp = Timestamp.fromDate(thirtyDaysAgo);

      final activitiesSnapshot =
          await _groupsCollection
              .doc(groupId)
              .collection('timerActivities')
              .where('memberId', isEqualTo: userId)
              .where('timestamp', isGreaterThanOrEqualTo: startTimestamp)
              .orderBy('timestamp', descending: true)
              .get();

      if (activitiesSnapshot.docs.isEmpty) {
        return {
          'streakDays': 0,
          'groupName': groupName,
          'lastActiveDate': DateTime.now(),
        };
      }

      // 날짜별로 활동 그룹화
      final Map<String, List<Map<String, dynamic>>> activitiesByDate = {};
      DateTime? latestActiveDate;

      for (final doc in activitiesSnapshot.docs) {
        final data = doc.data();
        final timestamp = data['timestamp'] as Timestamp?;

        if (timestamp != null) {
          final date = timestamp.toDate();
          final dateKey = DateFormat('yyyy-MM-dd').format(date);

          // 가장 최근 활동 날짜 업데이트
          if (latestActiveDate == null || date.isAfter(latestActiveDate)) {
            latestActiveDate = date;
          }

          activitiesByDate[dateKey] ??= [];
          activitiesByDate[dateKey]!.add({
            ...data,
            'id': doc.id,
          });
        }
      }

      // 실제 활동한 날짜들 추출 (start/end 페어가 있는 날만)
      final Set<String> activeDates = {};

      for (final entry in activitiesByDate.entries) {
        final dateKey = entry.key;
        final dayActivities = entry.value;

        // 해당 날짜에 start와 end 활동이 모두 있는지 확인
        final hasStart = dayActivities.any((a) => a['type'] == 'start');
        final hasEnd = dayActivities.any((a) => a['type'] == 'end');

        if (hasStart && hasEnd) {
          activeDates.add(dateKey);
        }
      }

      if (activeDates.isEmpty) {
        return {
          'streakDays': 0,
          'groupName': groupName,
          'lastActiveDate': latestActiveDate ?? DateTime.now(),
        };
      }

      // 연속 출석일 계산
      final streakDays = _calculateStreakDaysFromActiveDates(activeDates);

      return {
        'streakDays': streakDays,
        'groupName': groupName,
        'lastActiveDate': latestActiveDate ?? DateTime.now(),
      };
    } catch (e) {
      AppLogger.error(
        '그룹 $groupId에서 사용자 $userId 연속 출석일 계산 오류',
        tag: 'GroupFirebaseDataSource',
        error: e,
      );
      return {
        'streakDays': 0,
        'groupName': '알 수 없는 그룹',
        'lastActiveDate': DateTime.now(),
      };
    }
  }

  /// 활동한 날짜들로부터 연속 출석일 계산
  int _calculateStreakDaysFromActiveDates(Set<String> activeDates) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final yesterday = DateFormat('yyyy-MM-dd').format(
      DateTime.now().subtract(const Duration(days: 1)),
    );

    // 오늘 또는 어제까지 활동이 있었는지 확인 (연속성 유지 조건)
    bool hasRecentActivity =
        activeDates.contains(today) || activeDates.contains(yesterday);

    if (!hasRecentActivity) {
      return 0; // 최근 활동이 없으면 연속 출석일 0
    }

    int streakDays = 0;

    // 오늘부터 역순으로 연속일 계산
    for (int i = 0; i < 30; i++) {
      // 최대 30일까지만 확인
      final checkDate = DateFormat('yyyy-MM-dd').format(
        DateTime.now().subtract(Duration(days: i)),
      );

      if (activeDates.contains(checkDate)) {
        streakDays++;
      } else {
        break; // 연속성이 끊어지면 중단
      }
    }

    return streakDays;
  }

  @override
  Future<int> fetchWeeklyStudyTimeMinutes() async {
    return ApiCallDecorator.wrap(
      'GroupFirebase.fetchWeeklyStudyTimeMinutes',
      () async {
        try {
          final userId = _getCurrentUserId();

          // 1. 현재 사용자가 가입한 그룹 ID 목록 조회
          final joinedGroupIds = await _getCurrentUserJoinedGroupIds();

          if (joinedGroupIds.isEmpty) {
            return 0; // 가입한 그룹이 없으면 0분 반환
          }

          // 2. 이번 주 시작일과 종료일 계산
          final now = DateTime.now();
          final weekStart = now.subtract(
            Duration(days: now.weekday - 1),
          ); // 월요일
          final weekStartDate = DateTime(
            weekStart.year,
            weekStart.month,
            weekStart.day,
          );
          final weekEndDate = weekStartDate.add(const Duration(days: 7));

          final startTimestamp = Timestamp.fromDate(weekStartDate);
          final endTimestamp = Timestamp.fromDate(weekEndDate);

          int totalWeeklyMinutes = 0;

          // 3. 각 그룹별로 이번 주 타이머 활동 조회 및 집계
          for (final groupId in joinedGroupIds) {
            // 해당 그룹에서 현재 사용자의 이번 주 활동 조회
            final activitiesSnapshot =
                await _groupsCollection
                    .doc(groupId)
                    .collection('timerActivities')
                    .where('memberId', isEqualTo: userId)
                    .where('timestamp', isGreaterThanOrEqualTo: startTimestamp)
                    .where('timestamp', isLessThan: endTimestamp)
                    .orderBy('timestamp')
                    .get();

            if (activitiesSnapshot.docs.isEmpty) continue;

            // 4. 활동 데이터를 시간순으로 정렬하여 start/end 페어 매칭
            final activities =
                activitiesSnapshot.docs.map((doc) {
                  final data = doc.data();
                  data['id'] = doc.id;
                  return data;
                }).toList();

            // start/end 페어 매칭하여 시간 계산
            DateTime? startTime;
            for (final activity in activities) {
              final type = activity['type'] as String?;
              final timestamp = activity['timestamp'] as Timestamp?;

              if (timestamp == null) continue;

              final activityTime = timestamp.toDate();

              if (type == 'start') {
                startTime = activityTime;
              } else if (type == 'end' && startTime != null) {
                final duration = activityTime.difference(startTime).inMinutes;
                if (duration > 0) {
                  totalWeeklyMinutes += duration;
                }
                startTime = null; // 페어 처리 완료
              }
            }
          }

          return totalWeeklyMinutes;
        } catch (e) {
          AppLogger.error(
            '이번 주 공부 시간 조회 오류',
            tag: 'GroupFirebaseDataSource',
            error: e,
          );
          throw Exception('이번 주 공부 시간을 불러오는데 실패했습니다');
        }
      },
    );
  }
}
