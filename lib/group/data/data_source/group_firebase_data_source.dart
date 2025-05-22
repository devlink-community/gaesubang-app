// lib/group/data/data_source/group_firebase_data_source.dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devlink_mobile_app/core/utils/api_call_logger.dart';
import 'package:devlink_mobile_app/core/utils/messages/auth_error_messages.dart';
import 'package:devlink_mobile_app/core/utils/messages/group_error_messages.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
  String? _lastGroupId;

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
        _cachedGroupMembers = null; // 🔧 멤버 캐시도 초기화
        _lastUserId = user?.uid;
        _lastGroupId = null; // 🔧 그룹 ID도 초기화
      }
    });
  }

  // Collection 참조들
  CollectionReference<Map<String, dynamic>> get _groupsCollection =>
      _firestore.collection('groups');

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

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
      print('🔍 Checking joined groups for user: $userId');

      // 캐시 확인
      if (_cachedJoinedGroups != null && _lastUserId == userId) {
        print('🔍 Using cached joined groups: $_cachedJoinedGroups');
        return _cachedJoinedGroups!;
      }

      // Firestore에서 사용자 문서 조회
      final userDoc = await _usersCollection.doc(userId).get();
      print('🔍 User document exists: ${userDoc.exists}');

      if (!userDoc.exists) {
        print('🔍 User document not found, returning empty set');
        _cachedJoinedGroups = {};
        _lastUserId = userId;
        return {};
      }

      final userData = userDoc.data()!;
      print('🔍 User document data: $userData');

      if (!userData.containsKey('joingroup')) {
        print('🔍 No joingroup field found, returning empty set');
        _cachedJoinedGroups = {};
        _lastUserId = userId;
        return {};
      }

      final joinGroups = userData['joingroup'] as List<dynamic>;
      print('🔍 Raw joingroup data: $joinGroups');

      final joinedGroupIds =
          joinGroups
              .map((group) {
                print('🔍 Processing group: $group');
                return group['group_id'] as String?;
              })
              .where((id) => id != null)
              .cast<String>()
              .toSet();

      print('🔍 Extracted joined group IDs: $joinedGroupIds');

      // 캐시 업데이트
      _cachedJoinedGroups = joinedGroupIds;
      _lastUserId = userId;

      return joinedGroupIds;
    } catch (e, st) {
      print('🔍 Error getting joined groups: $e');
      print('🔍 StackTrace: $st');
      return {};
    }
  }

  // 🔧 그룹 ID 변경 시 멤버 캐시 무효화
  void _invalidateMemberCacheIfNeeded(String newGroupId) {
    if (_lastGroupId != null && _lastGroupId != newGroupId) {
      print(
        '🗑️ Group ID changed ($_lastGroupId → $newGroupId), invalidating member cache',
      );
      _cachedGroupMembers = null;
      _lastGroupId = null;
    }
  }

  // 🔧 멤버 정보 캐시 무효화 (그룹 변경 작업 시 호출)
  void _invalidateMemberCache(String groupId) {
    if (_lastGroupId == groupId) {
      print('🗑️ Invalidating member cache for group: $groupId');
      _cachedGroupMembers = null;
      _lastGroupId = null;
    }
  }

  // 그룹 멤버 목록 조회 (내부 헬퍼 메서드)
  Future<List<String>> _getGroupMemberIds(String groupId) async {
    try {
      // 🔧 멤버 정보 캐시 확인
      List<Map<String, dynamic>> members;

      if (_cachedGroupMembers != null && _lastGroupId == groupId) {
        print('🔍 Using cached group members for memberIds');
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
      print('그룹 멤버 조회 오류: $e');
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
          print('🔍 No groups found in Firestore');
          return [];
        }

        print('🔍 Found ${querySnapshot.docs.length} groups in Firestore');

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
        print('🔍 Error in fetchGroupList: $e');
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
          print('그룹 상세 비즈니스 로직 오류: $e');
          rethrow;
        } else {
          // Firebase 통신 오류: 원본 예외 정보 보존
          print('그룹 상세 Firebase 통신 오류: $e\n$st');
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
          _invalidateMemberCache(groupId); // 🔧 멤버 캐시 무효화
        });
      } catch (e, st) {
        // ✅ 예외 구분 처리
        if (e is Exception &&
            (e.toString().contains(GroupErrorMessages.notFound) ||
                e.toString().contains(GroupErrorMessages.memberLimitReached))) {
          // 비즈니스 로직 검증 실패: 의미 있는 예외 그대로 전달
          print('그룹 가입 비즈니스 로직 오류: $e');
          rethrow;
        } else {
          // Firebase 통신 오류: 원본 예외 정보 보존
          print('그룹 가입 Firebase 통신 오류: $e\n$st');
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
        print('그룹 생성 오류: $e');
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
        print('그룹 업데이트 오류: $e');
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
          _invalidateMemberCache(groupId); // 🔧 멤버 캐시 무효화
        });
      } catch (e, st) {
        // ✅ 예외 구분 처리
        if (e is Exception &&
            (e.toString().contains(GroupErrorMessages.notFound) ||
                e.toString().contains(GroupErrorMessages.notMember) ||
                e.toString().contains(GroupErrorMessages.ownerCannotLeave))) {
          // 비즈니스 로직 검증 실패: 의미 있는 예외 그대로 전달
          print('그룹 탈퇴 비즈니스 로직 오류: $e');
          rethrow;
        } else {
          // Firebase 통신 오류: 원본 예외 정보 보존
          print('그룹 탈퇴 Firebase 통신 오류: $e\n$st');
          rethrow;
        }
        print('그룹 탈퇴 오류: $e');
        throw Exception(GroupErrorMessages.leaveFailed);
      }
    }, params: {'groupId': groupId});
  }

  @override
  Future<List<Map<String, dynamic>>> fetchGroupMembers(String groupId) async {
    return ApiCallDecorator.wrap('GroupFirebase.fetchGroupMembers', () async {
      try {
        // 🔧 캐시 확인
        if (_cachedGroupMembers != null && _lastGroupId == groupId) {
          print('🔍 Using cached group members');
          return List<Map<String, dynamic>>.from(_cachedGroupMembers!);
        }

        print('🔍 Fetching group members from Firestore');

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

        // 🔧 캐시 업데이트
        _cachedGroupMembers = List<Map<String, dynamic>>.from(members);
        _lastGroupId = groupId;
        print('🔍 Cached group members for groupId: $groupId');

        return members;
      } catch (e) {
        print('그룹 멤버 조회 오류: $e');
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
        print('그룹 이미지 업데이트 오류: $e');
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
                    .endAt([lowercaseQuery + '\uf8ff'])
                    .get();

            resultDocs.addAll(nameSnapshot.docs);

            // 설명 기반 검색
            final descSnapshot =
                await _groupsCollection
                    .orderBy('description')
                    .startAt([lowercaseQuery])
                    .endAt([lowercaseQuery + '\uf8ff'])
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
          print('통합 그룹 검색 오류: $e');
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
          final memberIds = await _getGroupMemberIds(groupId);

          if (memberIds.isEmpty) {
            return [];
          }

          // 멤버별로 최신 1개씩만 병렬 조회
          final futures = memberIds.map((memberId) async {
            final activitySnapshot =
                await _groupsCollection
                    .doc(groupId)
                    .collection('timerActivities')
                    .where('memberId', isEqualTo: memberId)
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
          print('그룹 타이머 활동 조회 오류: $e');
          throw Exception(GroupErrorMessages.loadFailed);
        }
      },
      params: {'groupId': groupId},
    );
  }

  // 🔧 새로운 실시간 스트림 메소드
  @override
  Stream<List<Map<String, dynamic>>> streamGroupMemberTimerStatus(
    String groupId,
  ) {
    return _groupsCollection
        .doc(groupId)
        .collection('members')
        .snapshots()
        .asyncMap((membersSnapshot) async {
          try {
            if (membersSnapshot.docs.isEmpty) {
              return <Map<String, dynamic>>[];
            }

            // 멤버별 실시간 타이머 상태 스트림들 생성
            final memberIds =
                membersSnapshot.docs
                    .map((doc) => doc.data()['userId'] as String?)
                    .where((userId) => userId != null)
                    .cast<String>()
                    .toList();

            // 각 멤버별 최신 타이머 활동 조회
            final futures = memberIds.map((memberId) async {
              final activitySnapshot =
                  await _groupsCollection
                      .doc(groupId)
                      .collection('timerActivities')
                      .where('memberId', isEqualTo: memberId)
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
            return results
                .where((data) => data != null)
                .cast<Map<String, dynamic>>()
                .toList();
          } catch (e) {
            print('실시간 타이머 상태 조회 오류: $e');
            return <Map<String, dynamic>>[];
          }
        });
  }

  @override
  Future<Map<String, dynamic>> startMemberTimer(String groupId) async {
    return ApiCallDecorator.wrap(
      'GroupFirebase.startMemberTimer',
      () async {
        try {
          // 현재 사용자 정보 가져오기
          final userInfo = await _getCurrentUserInfo();
          final memberId = userInfo['userId']!;
          final memberName = userInfo['userName']!;

          // 그룹 존재 확인
          final groupDoc = await _groupsCollection.doc(groupId).get();
          if (!groupDoc.exists) {
            throw Exception(GroupErrorMessages.notFound);
          }

          // 타임스탬프 생성
          final now = FieldValue.serverTimestamp();

          // 새 타이머 활동 데이터 준비
          final activityData = {
            'memberId': memberId,
            'memberName': memberName,
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
          print('타이머 시작 오류: $e');
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
          final memberId = userInfo['userId']!;
          final memberName = userInfo['userName']!;

          // 그룹 존재 확인
          final groupDoc = await _groupsCollection.doc(groupId).get();
          if (!groupDoc.exists) {
            throw Exception(GroupErrorMessages.notFound);
          }

          // 타임스탬프 생성
          final now = FieldValue.serverTimestamp();

          // 새 타이머 활동 데이터 준비
          final activityData = {
            'memberId': memberId,
            'memberName': memberName,
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
          print('타이머 일시정지 오류: $e');
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
          final memberId = userInfo['userId']!;
          final memberName = userInfo['userName']!;

          // 그룹 존재 확인
          final groupDoc = await _groupsCollection.doc(groupId).get();
          if (!groupDoc.exists) {
            throw Exception(GroupErrorMessages.notFound);
          }

          // 타임스탬프 생성
          final now = FieldValue.serverTimestamp();

          // 새 타이머 활동 데이터 준비
          final activityData = {
            'memberId': memberId,
            'memberName': memberName,
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
          print('타이머 정지 오류: $e');
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
          print('월별 타이머 활동 데이터 조회 오류: $e');
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
}
