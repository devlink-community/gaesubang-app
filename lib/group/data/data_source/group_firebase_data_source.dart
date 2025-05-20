// lib/group/data/data_source/group_firebase_data_source.dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devlink_mobile_app/core/utils/api_call_logger.dart';
import 'package:devlink_mobile_app/core/utils/messages/group_error_messages.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'group_data_source.dart';

class GroupFirebaseDataSource implements GroupDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  GroupFirebaseDataSource({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  // Collection 참조들
  CollectionReference<Map<String, dynamic>> get _groupsCollection =>
      _firestore.collection('groups');

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  @override
  Future<List<Map<String, dynamic>>> fetchGroupList({
    String? currentUserId,
  }) async {
    return ApiCallDecorator.wrap('GroupFirebase.fetchGroupList', () async {
      try {
        // 그룹 목록 조회 (생성일 기준 최신순)
        final querySnapshot =
            await _groupsCollection
                .orderBy('createdAt', descending: true)
                .get();

        if (querySnapshot.docs.isEmpty) {
          return [];
        }

        // FIXME: 왜 groupIds를 불러오고 사용하지 않는지 검토 필요
        // 그룹 문서 ID 목록
        final groupIds = querySnapshot.docs.map((doc) => doc.id).toList();

        // 현재 사용자의 가입 그룹 목록 (로그인한 경우만)
        Set<String> userJoinedGroupIds = {};

        if (currentUserId != null && currentUserId.isNotEmpty) {
          // 사용자 문서에서 가입한 그룹 ID 가져오기
          final userDoc = await _usersCollection.doc(currentUserId).get();

          if (userDoc.exists && userDoc.data()!.containsKey('joingroup')) {
            final joingroups = userDoc.data()!['joingroup'] as List<dynamic>;

            // 가입 그룹 ID 목록 추출
            for (final joingroup in joingroups) {
              final groupName = joingroup['group_name'] as String?;

              // 그룹 이름으로 ID 찾기 (Firebase에서는 관계가 비정규화되어 있기 때문)
              final matchingGroup = querySnapshot.docs.firstWhere(
                (doc) => doc.data()['name'] == groupName,
                orElse: () => querySnapshot.docs.first,
              );

              userJoinedGroupIds.add(matchingGroup.id);
            }
          }
        }

        // 그룹 데이터 변환 및 멤버십 상태 설정
        final groups =
            querySnapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;

              // 현재 사용자 가입 여부 설정
              if (currentUserId != null) {
                data['isJoinedByCurrentUser'] = userJoinedGroupIds.contains(
                  doc.id,
                );
              }

              return data;
            }).toList();

        return groups;
      } catch (e) {
        print('그룹 목록 로드 오류: $e');
        throw Exception(GroupErrorMessages.loadFailed);
      }
    });
  }

  @override
  Future<Map<String, dynamic>> fetchGroupDetail(
    String groupId, {
    String? currentUserId,
  }) async {
    return ApiCallDecorator.wrap('GroupFirebase.fetchGroupDetail', () async {
      try {
        // 그룹 문서 조회
        final docSnapshot = await _groupsCollection.doc(groupId).get();

        if (!docSnapshot.exists) {
          throw Exception(GroupErrorMessages.notFound);
        }

        // 기본 그룹 데이터
        final data = docSnapshot.data()!;
        data['id'] = docSnapshot.id;

        // 현재 사용자 멤버십 상태 확인 (로그인한 경우만)
        if (currentUserId != null && currentUserId.isNotEmpty) {
          // 멤버십 확인 방법 1: 멤버 컬렉션 확인
          final memberDoc =
              await _groupsCollection
                  .doc(groupId)
                  .collection('members')
                  .doc(currentUserId)
                  .get();

          // 멤버십 여부 설정
          data['isJoinedByCurrentUser'] = memberDoc.exists;
        }

        return data;
      } catch (e) {
        if (e.toString().contains(GroupErrorMessages.notFound)) {
          rethrow;
        }
        print('그룹 상세 로드 오류: $e');
        throw Exception(GroupErrorMessages.loadFailed);
      }
    }, params: {'groupId': groupId});
  }

  @override
  Future<void> fetchJoinGroup(
    String groupId, {
    required String userId,
    required String userName,
    required String profileUrl,
  }) async {
    return ApiCallDecorator.wrap('GroupFirebase.fetchJoinGroup', () async {
      try {
        // 트랜잭션을 사용하여 멤버 추가 및 카운터 업데이트
        return _firestore.runTransaction((transaction) async {
          // 1. 그룹 문서 조회
          final groupDoc = await transaction.get(
            _groupsCollection.doc(groupId),
          );

          if (!groupDoc.exists) {
            throw Exception(GroupErrorMessages.notFound);
          }

          // 2. 멤버십 상태 확인
          final memberDoc = await transaction.get(
            _groupsCollection.doc(groupId).collection('members').doc(userId),
          );

          if (memberDoc.exists) {
            throw Exception(GroupErrorMessages.alreadyJoined);
          }

          // 3. 현재 멤버 수 확인
          final data = groupDoc.data()!;
          final currentMemberCount = data['memberCount'] as int? ?? 0;
          final maxMemberCount = data['maxMemberCount'] as int? ?? 10;

          // 4. 멤버 수 제한 확인
          if (currentMemberCount >= maxMemberCount) {
            throw Exception(GroupErrorMessages.memberLimitReached);
          }

          // 5. 멤버 추가
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

          // 6. 멤버 수 증가
          transaction.update(_groupsCollection.doc(groupId), {
            'memberCount': currentMemberCount + 1,
          });

          // 7. 사용자 문서에 가입 그룹 정보 추가
          transaction.update(_usersCollection.doc(userId), {
            'joingroup': FieldValue.arrayUnion([
              {
                'group_name': data['name'] ?? '',
                'group_image': data['imageUrl'] ?? '',
              },
            ]),
          });
        });
      } catch (e) {
        if (e.toString().contains(GroupErrorMessages.notFound) ||
            e.toString().contains(GroupErrorMessages.alreadyJoined) ||
            e.toString().contains(GroupErrorMessages.memberLimitReached)) {
          rethrow;
        }
        print('그룹 가입 오류: $e');
        throw Exception(GroupErrorMessages.joinFailed);
      }
    }, params: {'groupId': groupId, 'userId': userId});
  }

  @override
  Future<Map<String, dynamic>> fetchCreateGroup(
    Map<String, dynamic> groupData, {
    required String ownerId,
    required String ownerName,
    required String ownerProfileUrl,
  }) async {
    return ApiCallDecorator.wrap('GroupFirebase.fetchCreateGroup', () async {
      try {
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
          'createdBy': ownerId,
          'memberCount': 1, // 처음에는 생성자만 멤버
        };

        // 트랜잭션을 사용하여 그룹 생성 및 멤버 추가
        await _firestore.runTransaction((transaction) async {
          // 1. 그룹 문서 생성
          transaction.set(groupRef, finalGroupData);

          // 2. 소유자(방장) 멤버 추가
          transaction.set(groupRef.collection('members').doc(ownerId), {
            'userId': ownerId,
            'userName': ownerName,
            'profileUrl': ownerProfileUrl,
            'role': 'owner',
            'joinedAt': now,
          });

          // 3. 사용자 문서에 가입 그룹 정보 추가
          transaction.update(_usersCollection.doc(ownerId), {
            'joingroup': FieldValue.arrayUnion([
              {
                'group_name': groupData['name'] ?? '',
                'group_image': groupData['imageUrl'] ?? '',
              },
            ]),
          });
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
    }, params: {'ownerId': ownerId});
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

        // 그룹 문서 업데이트
        await _groupsCollection.doc(groupId).update(updates);

        // 그룹 이름이 변경된 경우, 멤버들의 joingroup 정보도 업데이트해야 함
        if (updates.containsKey('name') || updates.containsKey('imageUrl')) {
          // 모든 멤버 조회
          final membersSnapshot =
              await _groupsCollection.doc(groupId).collection('members').get();

          for (final memberDoc in membersSnapshot.docs) {
            final userId = memberDoc.data()['userId'] as String?;
            if (userId != null) {
              // 사용자 문서에서 현재 그룹 정보 조회
              final userDoc = await _usersCollection.doc(userId).get();

              if (userDoc.exists && userDoc.data()!.containsKey('joingroup')) {
                final joingroups =
                    userDoc.data()!['joingroup'] as List<dynamic>;

                // 그룹 이름으로 항목 찾기
                for (int i = 0; i < joingroups.length; i++) {
                  final groupInfo = joingroups[i] as Map<String, dynamic>;
                  final groupName = await _groupsCollection
                      .doc(groupId)
                      .get()
                      .then((doc) => doc.data()?['name'] as String?);

                  if (groupInfo['group_name'] == groupName) {
                    // 그룹 정보 업데이트
                    await _usersCollection.doc(userId).update({
                      'joingroup': FieldValue.arrayRemove([groupInfo]),
                    });

                    await _usersCollection.doc(userId).update({
                      'joingroup': FieldValue.arrayUnion([
                        {
                          'group_name': updates['name'] ?? groupName,
                          'group_image':
                              updates['imageUrl'] ?? groupInfo['group_image'],
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
      } catch (e) {
        print('그룹 업데이트 오류: $e');
        throw Exception(GroupErrorMessages.updateFailed);
      }
    }, params: {'groupId': groupId});
  }

  @override
  Future<void> fetchLeaveGroup(String groupId, String userId) async {
    return ApiCallDecorator.wrap('GroupFirebase.fetchLeaveGroup', () async {
      try {
        // 트랜잭션을 사용하여 멤버 제거 및 카운터 업데이트
        return _firestore.runTransaction((transaction) async {
          // 1. 그룹 문서 조회
          final groupDoc = await transaction.get(
            _groupsCollection.doc(groupId),
          );

          if (!groupDoc.exists) {
            throw Exception(GroupErrorMessages.notFound);
          }

          // 2. 멤버십 상태 확인
          final memberDoc = await transaction.get(
            _groupsCollection.doc(groupId).collection('members').doc(userId),
          );

          if (!memberDoc.exists) {
            throw Exception(GroupErrorMessages.notMember);
          }

          // 3. 소유자 확인 (소유자는 탈퇴 불가)
          final memberData = memberDoc.data()!;
          if (memberData['role'] == 'owner') {
            throw Exception(GroupErrorMessages.ownerCannotLeave);
          }

          // 4. 현재 멤버 수 확인
          final data = groupDoc.data()!;
          final currentMemberCount = data['memberCount'] as int? ?? 0;

          // 5. 멤버 제거
          transaction.delete(
            _groupsCollection.doc(groupId).collection('members').doc(userId),
          );

          // 6. 멤버 수 감소
          transaction.update(_groupsCollection.doc(groupId), {
            'memberCount': currentMemberCount > 0 ? currentMemberCount - 1 : 0,
          });

          // 7. 사용자 문서에서 가입 그룹 정보 제거
          // 그룹 이름 가져오기
          final groupName = data['name'] as String?;

          if (groupName != null) {
            // 사용자 문서 조회
            final userDoc = await transaction.get(_usersCollection.doc(userId));

            if (userDoc.exists && userDoc.data()!.containsKey('joingroup')) {
              final joingroups = userDoc.data()!['joingroup'] as List<dynamic>;

              // 그룹 이름으로 항목 찾기
              for (final joingroup in joingroups) {
                if (joingroup['group_name'] == groupName) {
                  // 그룹 정보 제거
                  transaction.update(_usersCollection.doc(userId), {
                    'joingroup': FieldValue.arrayRemove([joingroup]),
                  });
                  break;
                }
              }
            }
          }
        });
      } catch (e) {
        if (e.toString().contains(GroupErrorMessages.notFound) ||
            e.toString().contains(GroupErrorMessages.notMember) ||
            e.toString().contains(GroupErrorMessages.ownerCannotLeave)) {
          rethrow;
        }
        print('그룹 탈퇴 오류: $e');
        throw Exception(GroupErrorMessages.leaveFailed);
      }
    }, params: {'groupId': groupId, 'userId': userId});
  }

  @override
  Future<List<Map<String, dynamic>>> fetchUserJoinedGroups(
    String userId,
  ) async {
    return ApiCallDecorator.wrap(
      'GroupFirebase.fetchUserJoinedGroups',
      () async {
        try {
          // 1. 사용자 문서에서 가입한 그룹 정보 가져오기
          final userDoc = await _usersCollection.doc(userId).get();

          if (!userDoc.exists) {
            throw Exception(GroupErrorMessages.userNotFound);
          }

          final userData = userDoc.data()!;
          if (!userData.containsKey('joingroup')) {
            return [];
          }

          final joingroups = userData['joingroup'] as List<dynamic>;
          if (joingroups.isEmpty) {
            return [];
          }

          // 2. 가입한 그룹 이름 목록 추출
          final groupNames =
              joingroups
                  .map((joingroup) => joingroup['group_name'] as String?)
                  .where((name) => name != null && name.isNotEmpty)
                  .toList();

          if (groupNames.isEmpty) {
            return [];
          }

          // 3. 그룹 이름으로 그룹 문서 조회
          final results = <Map<String, dynamic>>[];

          // 여러 쿼리를 병렬 처리 (이름이 일치하는 그룹 검색)
          final futures = groupNames.map((groupName) async {
            final querySnapshot =
                await _groupsCollection
                    .where('name', isEqualTo: groupName)
                    .limit(1)
                    .get();

            return querySnapshot.docs;
          });

          // 모든 쿼리 결과 수집
          final allResults = await Future.wait(futures);

          // 모든 문서를 결과 리스트에 추가
          for (final docs in allResults) {
            for (final doc in docs) {
              final data = doc.data();
              data['id'] = doc.id;
              data['isJoinedByCurrentUser'] = true; // 이미 가입된 그룹
              results.add(data);
            }
          }

          return results;
        } catch (e) {
          print('사용자 가입 그룹 조회 오류: $e');
          throw Exception(GroupErrorMessages.loadFailed);
        }
      },
      params: {'userId': userId},
    );
  }

  @override
  Future<List<Map<String, dynamic>>> fetchGroupMembers(String groupId) async {
    return ApiCallDecorator.wrap('GroupFirebase.fetchGroupMembers', () async {
      try {
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

        return members;
      } catch (e) {
        if (e.toString().contains(GroupErrorMessages.notFound)) {
          rethrow;
        }
        print('그룹 멤버 조회 오류: $e');
        throw Exception(GroupErrorMessages.loadFailed);
      }
    }, params: {'groupId': groupId});
  }

  @override
  Future<Map<String, dynamic>?> checkUserMembershipStatus(
    String groupId,
    String userId,
  ) async {
    return ApiCallDecorator.wrap(
      'GroupFirebase.checkUserMembershipStatus',
      () async {
        try {
          // 그룹 존재 확인
          final groupDoc = await _groupsCollection.doc(groupId).get();

          if (!groupDoc.exists) {
            throw Exception(GroupErrorMessages.notFound);
          }

          // 멤버십 확인
          final memberDoc =
              await _groupsCollection
                  .doc(groupId)
                  .collection('members')
                  .doc(userId)
                  .get();

          if (!memberDoc.exists) {
            return null;
          }

          // 멤버십 데이터 반환
          final data = memberDoc.data()!;
          data['id'] = memberDoc.id;
          return data;
        } catch (e) {
          if (e.toString().contains(GroupErrorMessages.notFound)) {
            rethrow;
          }
          print('멤버십 상태 확인 오류: $e');
          throw Exception(GroupErrorMessages.loadFailed);
        }
      },
      params: {'groupId': groupId, 'userId': userId},
    );
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

                // 그룹 이름으로 항목 찾기
                for (final joingroup in joingroups) {
                  if (joingroup['group_name'] == groupName) {
                    // 그룹 이미지 업데이트
                    await _usersCollection.doc(userId).update({
                      'joingroup': FieldValue.arrayRemove([joingroup]),
                    });

                    await _usersCollection.doc(userId).update({
                      'joingroup': FieldValue.arrayUnion([
                        {'group_name': groupName, 'group_image': imageUrl},
                      ]),
                    });

                    break;
                  }
                }
              }
            }
          }
        }

        return imageUrl;
      } catch (e) {
        print('그룹 이미지 업데이트 오류: $e');
        throw Exception(GroupErrorMessages.updateFailed);
      }
    }, params: {'groupId': groupId});
  }

  @override
  Future<List<Map<String, dynamic>>> searchGroupsByTags(
    List<String> tags, {
    String? currentUserId,
  }) async {
    return ApiCallDecorator.wrap('GroupFirebase.searchGroupsByTags', () async {
      try {
        if (tags.isEmpty) {
          return [];
        }

        // 검색 결과 저장 (중복 방지용 Set)
        final Set<DocumentSnapshot<Map<String, dynamic>>> resultDocs = {};

        // 태그별로 검색 (array-contains 쿼리는 배열 내 하나의 요소만 확인 가능)
        for (final tag in tags) {
          final querySnapshot =
              await _groupsCollection
                  .where('hashTags', arrayContains: tag)
                  .get();

          resultDocs.addAll(querySnapshot.docs);
        }

        // 검색 결과가 없으면 빈 리스트 반환
        if (resultDocs.isEmpty) {
          return [];
        }

        // 현재 사용자의 가입 그룹 ID 목록 (로그인한 경우만)
        Set<String> userJoinedGroupIds = {};

        if (currentUserId != null && currentUserId.isNotEmpty) {
          final membershipFutures = resultDocs.map((doc) async {
            final memberDoc =
                await _groupsCollection
                    .doc(doc.id)
                    .collection('members')
                    .doc(currentUserId)
                    .get();

            if (memberDoc.exists) {
              userJoinedGroupIds.add(doc.id);
            }
          });

          await Future.wait(membershipFutures);
        }

        // 검색 결과 변환
        final results =
            resultDocs.map((doc) {
              final data = doc.data()!;
              data['id'] = doc.id;

              // 현재 사용자 가입 여부 설정
              if (currentUserId != null) {
                data['isJoinedByCurrentUser'] = userJoinedGroupIds.contains(
                  doc.id,
                );
              }

              return data;
            }).toList();

        return results;
      } catch (e) {
        print('태그 기반 그룹 검색 오류: $e');
        throw Exception(GroupErrorMessages.searchFailed);
      }
    }, params: {'tags': tags.join(', ')});
  }

  @override
  Future<List<Map<String, dynamic>>> searchGroupsByKeyword(
    String keyword, {
    String? currentUserId,
  }) async {
    return ApiCallDecorator.wrap(
      'GroupFirebase.searchGroupsByKeyword',
      () async {
        try {
          if (keyword.isEmpty) {
            return [];
          }

          final keywordLower = keyword.toLowerCase();
          final Set<DocumentSnapshot<Map<String, dynamic>>> resultDocs = {};

          // Firestore는 대소문자 구분 없이 시작하는 문자열 검색 제한적 지원
          // name 필드 기반 검색 (시작 문자열만 가능)
          final nameSnapshot =
              await _groupsCollection
                  .orderBy('name')
                  .startAt([keywordLower])
                  .endAt([keywordLower + '\uf8ff'])
                  .get();

          resultDocs.addAll(nameSnapshot.docs);

          // description 필드 기반 검색 (시작 문자열만 가능)
          final descSnapshot =
              await _groupsCollection
                  .orderBy('description')
                  .startAt([keywordLower])
                  .endAt([keywordLower + '\uf8ff'])
                  .get();

          resultDocs.addAll(descSnapshot.docs);

          // 결과가 충분하지 않으면 모든 그룹을 가져와 클라이언트 측에서 필터링
          if (resultDocs.length < 10) {
            final allGroups =
                await _groupsCollection
                    .orderBy('createdAt', descending: true)
                    .limit(50)
                    .get();

            // 클라이언트 측 필터링
            for (final doc in allGroups.docs) {
              if (resultDocs.contains(doc)) continue;

              final data = doc.data();
              final name = (data['name'] as String? ?? '').toLowerCase();
              final description =
                  (data['description'] as String? ?? '').toLowerCase();

              // 부분 일치 검색
              if (name.contains(keywordLower) ||
                  description.contains(keywordLower)) {
                resultDocs.add(doc);
              }
            }
          }

          // 현재 사용자의 가입 그룹 ID 목록 (로그인한 경우만)
          Set<String> userJoinedGroupIds = {};

          if (currentUserId != null &&
              currentUserId.isNotEmpty &&
              resultDocs.isNotEmpty) {
            final membershipFutures = resultDocs.map((doc) async {
              final memberDoc =
                  await _groupsCollection
                      .doc(doc.id)
                      .collection('members')
                      .doc(currentUserId)
                      .get();

              if (memberDoc.exists) {
                userJoinedGroupIds.add(doc.id);
              }
            });

            await Future.wait(membershipFutures);
          }

          // 검색 결과 변환
          final results =
              resultDocs.map((doc) {
                final data = doc.data()!;
                data['id'] = doc.id;

                // 현재 사용자 가입 여부 설정
                if (currentUserId != null) {
                  data['isJoinedByCurrentUser'] = userJoinedGroupIds.contains(
                    doc.id,
                  );
                }

                return data;
              }).toList();

          return results;
        } catch (e) {
          print('키워드 기반 그룹 검색 오류: $e');
          throw Exception(GroupErrorMessages.searchFailed);
        }
      },
      params: {'keyword': keyword},
    );
  }

  @override
  Future<List<Map<String, dynamic>>> fetchGroupMembersWithTimerState(
    String groupId,
  ) async {
    return ApiCallDecorator.wrap(
      'GroupFirebase.fetchGroupMembersWithTimerState',
      () async {
        try {
          // 그룹 존재 확인
          final groupDoc = await _groupsCollection.doc(groupId).get();
          if (!groupDoc.exists) {
            throw Exception(GroupErrorMessages.notFound);
          }

          // 그룹 멤버 조회
          final membersSnapshot =
              await _groupsCollection.doc(groupId).collection('members').get();

          if (membersSnapshot.docs.isEmpty) {
            return [];
          }

          // 각 멤버의 최근 타이머 활동 조회 (병렬 처리)
          final memberIds = membersSnapshot.docs.map((doc) => doc.id).toList();
          final List<Future<QuerySnapshot<Map<String, dynamic>>>> queries = [];

          for (final memberId in memberIds) {
            final query =
                _groupsCollection
                    .doc(groupId)
                    .collection('timerActivities')
                    .where('memberId', isEqualTo: memberId)
                    .orderBy('timestamp', descending: true)
                    .limit(1)
                    .get();

            queries.add(query);
          }

          // 모든 쿼리 실행
          final results = await Future.wait(queries);

          // 결과 처리 및 멤버 정보와 타이머 상태 결합
          final membersWithState = <Map<String, dynamic>>[];
          final now = DateTime.now();

          for (int i = 0; i < membersSnapshot.docs.length; i++) {
            final memberDoc = membersSnapshot.docs[i];
            final memberData = memberDoc.data();
            memberData['id'] = memberDoc.id;

            // 해당 멤버의 타이머 활동 가져오기
            final activitySnapshot = results[i];

            if (activitySnapshot.docs.isNotEmpty) {
              final activity = activitySnapshot.docs.first.data();
              activity['id'] = activitySnapshot.docs.first.id;

              final type = activity['type'] as String?;
              final timestamp = activity['timestamp'] as Timestamp?;

              if (timestamp != null) {
                final activityTime = timestamp.toDate();
                final elapsedSeconds = now.difference(activityTime).inSeconds;

                // 타이머 상태 및 경과 시간 추가
                memberData['timerState'] = type ?? 'inactive';
                memberData['timerActivity'] = activity;
                memberData['elapsedSeconds'] = elapsedSeconds;
              } else {
                // 타임스탬프 없는 경우 비활성 상태로 처리
                memberData['timerState'] = 'inactive';
              }
            } else {
              // 활동 기록 없는 경우 비활성 상태로 처리
              memberData['timerState'] = 'inactive';
            }

            membersWithState.add(memberData);
          }

          return membersWithState;
        } catch (e) {
          print('그룹 멤버 및 타이머 상태 조회 오류: $e');
          throw Exception(GroupErrorMessages.loadFailed);
        }
      },
      params: {'groupId': groupId},
    );
  }

  @override
  Future<Map<String, dynamic>?> fetchCurrentUserTimerState(
    String groupId,
    String userId,
  ) async {
    return ApiCallDecorator.wrap(
      'GroupFirebase.fetchCurrentUserTimerState',
      () async {
        try {
          // 멤버십 확인
          final memberDoc =
              await _groupsCollection
                  .doc(groupId)
                  .collection('members')
                  .doc(userId)
                  .get();

          if (!memberDoc.exists) {
            throw Exception(GroupErrorMessages.notMember);
          }

          // 최근 타이머 활동 조회
          final activitySnapshot =
              await _groupsCollection
                  .doc(groupId)
                  .collection('timerActivities')
                  .where('memberId', isEqualTo: userId)
                  .orderBy('timestamp', descending: true)
                  .limit(1)
                  .get();

          if (activitySnapshot.docs.isEmpty) {
            // 활동 기록 없음 - 기본 상태 반환
            final memberData = memberDoc.data()!;
            memberData['id'] = memberDoc.id;
            memberData['timerState'] = 'inactive';
            return memberData;
          }

          // 가장 최근 활동 가져오기
          final activity = activitySnapshot.docs.first.data();
          activity['id'] = activitySnapshot.docs.first.id;

          final type = activity['type'] as String?;
          final timestamp = activity['timestamp'] as Timestamp?;
          final now = DateTime.now();

          // 멤버 정보와 타이머 상태 결합
          final memberData = memberDoc.data()!;
          memberData['id'] = memberDoc.id;
          memberData['timerState'] = type ?? 'inactive';
          memberData['timerActivity'] = activity;

          // 경과 시간 계산 (타임스탬프가 있는 경우)
          if (timestamp != null) {
            final activityTime = timestamp.toDate();
            memberData['elapsedSeconds'] =
                now.difference(activityTime).inSeconds;
          }

          return memberData;
        } catch (e) {
          print('사용자 타이머 상태 조회 오류: $e');
          throw Exception(GroupErrorMessages.loadFailed);
        }
      },
      params: {'groupId': groupId, 'userId': userId},
    );
  }

  @override
  Future<Map<String, dynamic>> startMemberTimer(
    String groupId,
    String memberId,
    String memberName,
  ) async {
    return ApiCallDecorator.wrap(
      'GroupFirebase.startMemberTimer',
      () async {
        try {
          // 멤버십 확인
          final memberDoc =
              await _groupsCollection
                  .doc(groupId)
                  .collection('members')
                  .doc(memberId)
                  .get();

          if (!memberDoc.exists) {
            throw Exception(GroupErrorMessages.notMember);
          }

          // 트랜잭션으로 처리 - 기존 활성 타이머가 있다면 종료 후 새로 시작
          return _firestore.runTransaction<Map<String, dynamic>>((
            transaction,
          ) async {
            // 현재 활성 타이머 확인
            final activeTimerSnapshot = await transaction.get(
              _groupsCollection
                  .doc(groupId)
                  .collection('timerActivities')
                  .where('memberId', isEqualTo: memberId)
                  .where('type', isEqualTo: 'start')
                  .orderBy('timestamp', descending: true)
                  .limit(1),
            );

            // 이미 활성 타이머가 있다면 자동 종료 처리
            if (activeTimerSnapshot.docs.isNotEmpty) {
              final activeTimer = activeTimerSnapshot.docs.first;
              transaction.update(
                _groupsCollection
                    .doc(groupId)
                    .collection('timerActivities')
                    .doc(activeTimer.id),
                {'type': 'end'},
              );
            }

            // 새 타이머 활동 기록 생성
            final timerActivityRef =
                _groupsCollection
                    .doc(groupId)
                    .collection('timerActivities')
                    .doc(); // 자동 ID 생성

            final timerData = {
              'memberId': memberId,
              'memberName': memberName,
              'type': 'start',
              'timestamp': FieldValue.serverTimestamp(),
              'groupId': groupId,
            };

            transaction.set(timerActivityRef, timerData);

            // 결과 반환 (트랜잭션 내에서는 직접 새 문서를 읽을 수 없어 여기서 구성)
            return {
              'id': timerActivityRef.id,
              ...timerData,
              'timestamp': Timestamp.now(), // 클라이언트 시각 사용 (서버 시각은 아직 없음)
              'timerState': 'start',
              'elapsedSeconds': 0,
            };
          });
        } catch (e) {
          print('타이머 시작 오류: $e');
          throw Exception(GroupErrorMessages.operationFailed);
        }
      },
      params: {'groupId': groupId, 'memberId': memberId},
    );
  }

  @override
  Future<Map<String, dynamic>> stopMemberTimer(
    String groupId,
    String memberId,
    String memberName,
    int durationInSeconds,
  ) async {
    return ApiCallDecorator.wrap(
      'GroupFirebase.stopMemberTimer',
      () async {
        try {
          // 멤버십 확인
          final memberDoc =
              await _groupsCollection
                  .doc(groupId)
                  .collection('members')
                  .doc(memberId)
                  .get();

          if (!memberDoc.exists) {
            throw Exception(GroupErrorMessages.notMember);
          }

          // 트랜잭션으로 처리 - 타이머 종료 및 활동 시간 기록
          return _firestore.runTransaction<Map<String, dynamic>>((
            transaction,
          ) async {
            // 현재 활성 타이머 확인
            final activeTimerSnapshot = await transaction.get(
              _groupsCollection
                  .doc(groupId)
                  .collection('timerActivities')
                  .where('memberId', isEqualTo: memberId)
                  .where('type', isEqualTo: 'start')
                  .orderBy('timestamp', descending: true)
                  .limit(1),
            );

            // 활성 타이머가 없으면 오류
            if (activeTimerSnapshot.docs.isEmpty) {
              throw Exception(GroupErrorMessages.timerNotActive);
            }

            // 타이머 활동 업데이트 (종료 상태로)
            final activeTimer = activeTimerSnapshot.docs.first;
            transaction.update(
              _groupsCollection
                  .doc(groupId)
                  .collection('timerActivities')
                  .doc(activeTimer.id),
              {
                'type': 'end',
                'endTimestamp': FieldValue.serverTimestamp(),
                'durationInSeconds': durationInSeconds,
              },
            );

            // 출석부에 시간 기록
            final today = DateTime.now();
            final dateKey =
                '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
            final attendanceId = '${memberId}_${dateKey}';

            final attendanceRef = _groupsCollection
                .doc(groupId)
                .collection('attendances')
                .doc(attendanceId);

            // 기존 출석 기록 확인
            final attendanceDoc = await transaction.get(attendanceRef);

            if (attendanceDoc.exists) {
              // 기존 기록 있음 - 시간만 업데이트
              final existingData = attendanceDoc.data()!;
              final existingMinutes =
                  existingData['timeInMinutes'] as int? ?? 0;
              final additionalMinutes =
                  (durationInSeconds / 60).ceil(); // 초를 분으로 변환

              transaction.update(attendanceRef, {
                'timeInMinutes': existingMinutes + additionalMinutes,
                'updatedAt': FieldValue.serverTimestamp(),
              });
            } else {
              // 새 기록 생성
              final normalizedDate = DateTime(
                today.year,
                today.month,
                today.day,
              );
              final minutes = (durationInSeconds / 60).ceil(); // 초를 분으로 변환

              transaction.set(attendanceRef, {
                'memberId': memberId,
                'memberName': memberName,
                'date': Timestamp.fromDate(normalizedDate),
                'timeInMinutes': minutes,
                'createdAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              });
            }

            // 결과 반환
            return {
              'id': activeTimer.id,
              'memberId': memberId,
              'memberName': memberName,
              'type': 'end',
              'timestamp': activeTimer.data()['timestamp'],
              'endTimestamp': Timestamp.now(),
              'durationInSeconds': durationInSeconds,
              'groupId': groupId,
              'timerState': 'inactive',
            };
          });
        } catch (e) {
          print('타이머 종료 오류: $e');
          throw Exception(GroupErrorMessages.operationFailed);
        }
      },
      params: {
        'groupId': groupId,
        'memberId': memberId,
        'durationInSeconds': durationInSeconds,
      },
    );
  }

  @override
  Future<Map<String, dynamic>> pauseMemberTimer(
    String groupId,
    String memberId,
    String memberName,
  ) async {
    return ApiCallDecorator.wrap(
      'GroupFirebase.pauseMemberTimer',
      () async {
        try {
          // 멤버십 확인
          final memberDoc =
              await _groupsCollection
                  .doc(groupId)
                  .collection('members')
                  .doc(memberId)
                  .get();

          if (!memberDoc.exists) {
            throw Exception(GroupErrorMessages.notMember);
          }

          // 트랜잭션으로 처리
          return _firestore.runTransaction<Map<String, dynamic>>((
            transaction,
          ) async {
            // 현재 활성 타이머 확인
            final activeTimerSnapshot = await transaction.get(
              _groupsCollection
                  .doc(groupId)
                  .collection('timerActivities')
                  .where('memberId', isEqualTo: memberId)
                  .where('type', isEqualTo: 'start')
                  .orderBy('timestamp', descending: true)
                  .limit(1),
            );

            // 활성 타이머가 없으면 오류
            if (activeTimerSnapshot.docs.isEmpty) {
              throw Exception(GroupErrorMessages.timerNotActive);
            }

            // 타이머 활동 업데이트 (일시정지 상태로)
            final activeTimer = activeTimerSnapshot.docs.first;
            transaction.update(
              _groupsCollection
                  .doc(groupId)
                  .collection('timerActivities')
                  .doc(activeTimer.id),
              {'type': 'pause', 'pauseTimestamp': FieldValue.serverTimestamp()},
            );

            // 결과 반환
            return {
              'id': activeTimer.id,
              'memberId': memberId,
              'memberName': memberName,
              'type': 'pause',
              'timestamp': activeTimer.data()['timestamp'],
              'pauseTimestamp': Timestamp.now(),
              'groupId': groupId,
              'timerState': 'pause',
            };
          });
        } catch (e) {
          print('타이머 일시정지 오류: $e');
          throw Exception(GroupErrorMessages.operationFailed);
        }
      },
      params: {'groupId': groupId, 'memberId': memberId},
    );
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMonthlyAttendances(
    String groupId,
    int year,
    int month,
  ) async {
    return ApiCallDecorator.wrap(
      'GroupFirebase.fetchMonthlyAttendances',
      () async {
        try {
          // 그룹 존재 확인
          final groupDoc = await _groupsCollection.doc(groupId).get();
          if (!groupDoc.exists) {
            throw Exception(GroupErrorMessages.notFound);
          }

          // 해당 월의 시작일과 종료일 계산
          final startDate = DateTime(year, month, 1);
          final endDate = DateTime(year, month + 1, 0, 23, 59, 59); // 월의 마지막 날

          // 출석 기록 쿼리 구성
          final query = _groupsCollection
              .doc(groupId)
              .collection('attendances')
              .where(
                'date',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
              )
              .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
              .orderBy('date', descending: false);

          // 쿼리 실행
          final snapshot = await query.get();

          // 결과 변환
          final attendances =
              snapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return data;
              }).toList();

          return attendances;
        } catch (e) {
          print('월별 출석 데이터 조회 오류: $e');
          throw Exception(GroupErrorMessages.loadFailed);
        }
      },
      params: {'groupId': groupId, 'year': year, 'month': month},
    );
  }
}
