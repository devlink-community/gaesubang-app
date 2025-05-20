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
}
