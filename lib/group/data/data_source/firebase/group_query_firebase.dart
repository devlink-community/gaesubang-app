import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devlink_mobile_app/core/utils/api_call_logger.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/core/utils/messages/auth_error_messages.dart';
import 'package:devlink_mobile_app/core/utils/messages/group_error_messages.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 그룹 조회 기능 (목록, 상세, 검색, 멤버)
class GroupQueryFirebase {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // 가입 그룹 캐싱을 위한 변수들
  Set<String>? _cachedJoinedGroups;
  String? _lastUserId;

  // 멤버 정보 캐싱을 위한 변수들
  List<Map<String, dynamic>>? _cachedGroupMembers;
  String? _lastGroupId;

  GroupQueryFirebase({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore,
       _auth = auth {
    // FirebaseAuth 상태 변화 감지하여 캐시 관리
    _auth.authStateChanges().listen((user) {
      if (user?.uid != _lastUserId) {
        // 사용자가 바뀌면 모든 캐시 초기화
        _cachedJoinedGroups = null;
        _cachedGroupMembers = null;
        _lastUserId = user?.uid;
        _lastGroupId = null;
      }
    });
  }

  // Collection 참조들
  CollectionReference<Map<String, dynamic>> get _groupsCollection =>
      _firestore.collection('groups');
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// 현재 사용자 확인 헬퍼 메서드
  String _getCurrentUserId() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception(AuthErrorMessages.noLoggedInUser);
    }
    return user.uid;
  }

  /// 현재 사용자의 가입 그룹 ID 목록 가져오기 (캐싱 적용)
  Future<Set<String>> _getCurrentUserJoinedGroupIds() async {
    try {
      final userId = _getCurrentUserId();
      AppLogger.debug(
        'Checking joined groups for user: $userId',
        tag: 'GroupQueryFirebase',
      );

      // 캐시 확인
      if (_cachedJoinedGroups != null && _lastUserId == userId) {
        AppLogger.debug(
          'Using cached joined groups: $_cachedJoinedGroups',
          tag: 'GroupQueryFirebase',
        );
        return _cachedJoinedGroups!;
      }

      // Firestore에서 사용자 문서 조회
      final userDoc = await _usersCollection.doc(userId).get();
      AppLogger.debug(
        'User document exists: ${userDoc.exists}',
        tag: 'GroupQueryFirebase',
      );

      if (!userDoc.exists) {
        AppLogger.debug(
          'User document not found, returning empty set',
          tag: 'GroupQueryFirebase',
        );
        _cachedJoinedGroups = {};
        _lastUserId = userId;
        return {};
      }

      final userData = userDoc.data()!;

      if (!userData.containsKey('joingroup')) {
        AppLogger.debug(
          'No joingroup field found, returning empty set',
          tag: 'GroupQueryFirebase',
        );
        _cachedJoinedGroups = {};
        _lastUserId = userId;
        return {};
      }

      final joinGroups = userData['joingroup'] as List<dynamic>;

      final joinedGroupIds =
          joinGroups
              .map((group) => group['group_id'] as String?)
              .where((id) => id != null)
              .cast<String>()
              .toSet();

      AppLogger.debug(
        'Extracted joined group IDs: $joinedGroupIds',
        tag: 'GroupQueryFirebase',
      );

      // 캐시 업데이트
      _cachedJoinedGroups = joinedGroupIds;
      _lastUserId = userId;

      return joinedGroupIds;
    } catch (e, st) {
      AppLogger.error(
        'Error getting joined groups',
        tag: 'GroupQueryFirebase',
        error: e,
        stackTrace: st,
      );
      return {};
    }
  }

  /// 그룹 ID 변경 시 멤버 캐시 무효화
  void _invalidateMemberCacheIfNeeded(String newGroupId) {
    if (_lastGroupId != null && _lastGroupId != newGroupId) {
      AppLogger.info(
        'Group ID changed ($_lastGroupId → $newGroupId), invalidating member cache',
        tag: 'GroupQueryFirebase',
      );
      _cachedGroupMembers = null;
      _lastGroupId = null;
    }
  }

  /// 멤버 정보 캐시 무효화
  void _invalidateMemberCache(String groupId) {
    if (_lastGroupId == groupId) {
      AppLogger.info(
        'Invalidating member cache for group: $groupId',
        tag: 'GroupQueryFirebase',
      );
      _cachedGroupMembers = null;
      _lastGroupId = null;
    }
  }

  /// 전체 그룹 목록 조회
  Future<List<Map<String, dynamic>>> fetchGroupList() async {
    return ApiCallDecorator.wrap('GroupQuery.fetchGroupList', () async {
      try {
        // 1. 그룹 목록 조회
        final querySnapshot =
            await _groupsCollection
                .orderBy('createdAt', descending: true)
                .get();

        if (querySnapshot.docs.isEmpty) {
          AppLogger.debug(
            'No groups found in Firestore',
            tag: 'GroupQueryFirebase',
          );
          return [];
        }

        AppLogger.info(
          'Found ${querySnapshot.docs.length} groups in Firestore',
          tag: 'GroupQueryFirebase',
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
          tag: 'GroupQueryFirebase',
          error: e,
        );
        throw Exception(GroupErrorMessages.loadFailed);
      }
    });
  }

  /// 특정 그룹 상세 정보 조회
  Future<Map<String, dynamic>> fetchGroupDetail(String groupId) async {
    return ApiCallDecorator.wrap('GroupQuery.fetchGroupDetail', () async {
      try {
        // 그룹 ID 변경 감지
        _invalidateMemberCacheIfNeeded(groupId);

        // 1. 그룹 문서 조회
        final docSnapshot = await _groupsCollection.doc(groupId).get();

        // 비즈니스 로직 검증: 그룹 존재 여부
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
        // 예외 구분 처리
        if (e is Exception &&
            e.toString().contains(GroupErrorMessages.notFound)) {
          // 비즈니스 로직 검증 실패: 의미 있는 예외 그대로 전달
          AppLogger.error(
            '그룹 상세 비즈니스 로직 오류',
            tag: 'GroupQueryFirebase',
            error: e,
          );
          rethrow;
        } else {
          // Firebase 통신 오류: 원본 예외 정보 보존
          AppLogger.error(
            '그룹 상세 Firebase 통신 오류',
            tag: 'GroupQueryFirebase',
            error: e,
            stackTrace: st,
          );
          rethrow;
        }
      }
    }, params: {'groupId': groupId});
  }

  /// 그룹의 모든 멤버 조회 (캐싱 적용)
  Future<List<Map<String, dynamic>>> fetchGroupMembers(String groupId) async {
    return ApiCallDecorator.wrap('GroupQuery.fetchGroupMembers', () async {
      try {
        // 캐시 확인
        if (_cachedGroupMembers != null && _lastGroupId == groupId) {
          AppLogger.debug(
            'Using cached group members',
            tag: 'GroupQueryFirebase',
          );
          return List<Map<String, dynamic>>.from(_cachedGroupMembers!);
        }

        AppLogger.info(
          'Fetching group members from Firestore',
          tag: 'GroupQueryFirebase',
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

        // 캐시 업데이트
        _cachedGroupMembers = List<Map<String, dynamic>>.from(members);
        _lastGroupId = groupId;
        AppLogger.debug(
          'Cached group members for groupId: $groupId',
          tag: 'GroupQueryFirebase',
        );

        return members;
      } catch (e) {
        AppLogger.error(
          '그룹 멤버 조회 오류',
          tag: 'GroupQueryFirebase',
          error: e,
        );
        throw Exception(GroupErrorMessages.loadFailed);
      }
    }, params: {'groupId': groupId});
  }

  /// 통합 그룹 검색
  Future<List<Map<String, dynamic>>> searchGroups(
    String query, {
    bool searchKeywords = true,
    bool searchTags = true,
    int? limit,
    String? sortBy,
  }) async {
    return ApiCallDecorator.wrap(
      'GroupQuery.searchGroups',
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
            tag: 'GroupQueryFirebase',
            error: e,
          );
          throw Exception('그룹 검색 중 오류가 발생했습니다');
        }
      },
      params: {'query': query},
    );
  }

  /// 그룹 멤버 목록 조회 (내부 헬퍼 메서드)
  Future<List<String>> getGroupMemberUserIds(String groupId) async {
    try {
      // 멤버 정보 캐시 확인
      List<Map<String, dynamic>> members;

      if (_cachedGroupMembers != null && _lastGroupId == groupId) {
        AppLogger.debug(
          'Using cached group members for memberUserIds',
          tag: 'GroupQueryFirebase',
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
        tag: 'GroupQueryFirebase',
        error: e,
      );
      return [];
    }
  }

  /// 캐시 무효화 메서드들 (외부에서 호출 가능)
  void invalidateJoinedGroupsCache() {
    _cachedJoinedGroups = null;
  }

  void invalidateGroupMembersCache(String groupId) {
    _invalidateMemberCache(groupId);
  }
}
