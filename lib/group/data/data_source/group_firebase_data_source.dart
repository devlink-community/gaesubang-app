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
    Set<String>? joinedGroupIds,
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

        // 그룹 데이터 변환 및 멤버십 상태 설정
        final groups =
            querySnapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;

              // 가입 그룹 ID가 전달된 경우, 해당 정보로 멤버십 상태 설정
              if (joinedGroupIds != null) {
                data['isJoinedByCurrentUser'] = joinedGroupIds.contains(doc.id);
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
    bool? isJoined,
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

        // 가입 여부가 전달된 경우, 해당 정보 설정
        if (isJoined != null) {
          data['isJoinedByCurrentUser'] = isJoined;
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
                'group_id': groupId,
                'group_name': data['name'] ?? '',
                'group_image': data['imageUrl'] ?? '',
              },
            ]),
          });
        });
      } catch (e) {
        if (e.toString().contains(GroupErrorMessages.notFound) ||
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
                'group_id': groupId,
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

            // 현재 그룹 정보 조회 (사용자마다 한 번의 조회만 수행)
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

                // 기존 그룹 정보 제거 후 새 정보 추가 (배치에 작업 추가)
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

        return imageUrl;
      } catch (e) {
        print('그룹 이미지 업데이트 오류: $e');
        throw Exception(GroupErrorMessages.updateFailed);
      }
    }, params: {'groupId': groupId});
  }

  @override
  @override
  Future<List<Map<String, dynamic>>> searchGroups(
    String query, {
    bool searchKeywords = true,
    bool searchTags = true,
    Set<String>? joinedGroupIds, // currentUserId 대신 joinedGroupIds 사용
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

          final lowercaseQuery = query.toLowerCase();
          final Set<DocumentSnapshot<Map<String, dynamic>>> resultDocs = {};

          // 키워드 검색 (이름, 설명)
          if (searchKeywords) {
            // 이름 기반 검색 (시작하는 문자열)
            final nameSnapshot =
                await _groupsCollection
                    .orderBy('name')
                    .startAt([lowercaseQuery])
                    .endAt([lowercaseQuery + '\uf8ff'])
                    .get();

            resultDocs.addAll(nameSnapshot.docs);

            // 설명 기반 검색 (시작하는 문자열)
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

                // 가입 그룹 정보를 이용하여 isJoinedByCurrentUser 설정
                if (joinedGroupIds != null) {
                  data['isJoinedByCurrentUser'] = joinedGroupIds.contains(
                    doc.id,
                  );
                } else {
                  data['isJoinedByCurrentUser'] = false; // 기본값 설정
                }

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
      params: {'query': query, 'joinedGroupIds': joinedGroupIds?.length ?? 0},
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

          // 타이머 활동 컬렉션 조회 (최신순)
          final activitiesSnapshot =
              await _groupsCollection
                  .doc(groupId)
                  .collection('timerActivities')
                  .orderBy('timestamp', descending: true)
                  .get();

          // 멤버별로 가장 최근 활동만 필터링
          final memberIdToActivity = <String, Map<String, dynamic>>{};

          for (final activityDoc in activitiesSnapshot.docs) {
            final activityData = activityDoc.data();
            final memberId = activityData['memberId'] as String?;

            if (memberId != null && !memberIdToActivity.containsKey(memberId)) {
              // 아직 추가되지 않은 멤버의 활동만 추가 (가장 최근 활동)
              activityData['id'] = activityDoc.id;
              memberIdToActivity[memberId] = activityData;
            }
          }

          // 타이머 활동 정보 리스트로 반환
          return memberIdToActivity.values.toList();
        } catch (e) {
          print('그룹 타이머 활동 조회 오류: $e');
          throw Exception(GroupErrorMessages.loadFailed);
        }
      },
      params: {'groupId': groupId},
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
          // 그룹 존재 확인
          final groupDoc = await _groupsCollection.doc(groupId).get();
          if (!groupDoc.exists) {
            throw Exception(GroupErrorMessages.notFound);
          }

          // 이미 활성 타이머가 있는지 확인
          final activeTimerQuery =
              await _groupsCollection
                  .doc(groupId)
                  .collection('timerActivities')
                  .where('memberId', isEqualTo: memberId)
                  .where('type', isEqualTo: 'start')
                  .orderBy('timestamp', descending: true)
                  .limit(1)
                  .get();

          // 활성 타이머 세션이 있고, 종료되지 않은 경우 경고
          if (activeTimerQuery.docs.isNotEmpty) {
            final lastEndQuery =
                await _groupsCollection
                    .doc(groupId)
                    .collection('timerActivities')
                    .where('memberId', isEqualTo: memberId)
                    .where('type', isEqualTo: 'end')
                    .orderBy('timestamp', descending: true)
                    .limit(1)
                    .get();

            if (lastEndQuery.docs.isEmpty ||
                (activeTimerQuery.docs[0].data()['timestamp'] as Timestamp)
                    .toDate()
                    .isAfter(
                      (lastEndQuery.docs[0].data()['timestamp'] as Timestamp)
                          .toDate(),
                    )) {
              throw Exception('이미 진행 중인 타이머 세션이 있습니다.');
            }
          }

          // 타임스탬프 생성
          final now = FieldValue.serverTimestamp();

          // 새 타이머 활동 데이터 준비 (중복 타임스탬프 제거)
          final activityData = {
            'memberId': memberId,
            'memberName': memberName,
            'type': 'start',
            'timestamp': now,
            'groupId': groupId,
            'metadata': {}, // 필요한 추가 정보만 포함
          };

          // Firestore에 타이머 활동 문서 추가
          final docRef = await _groupsCollection
              .doc(groupId)
              .collection('timerActivities')
              .add(activityData);

          // 생성된 문서 ID와 함께 데이터 반환
          final result = {...activityData};
          result['id'] = docRef.id;

          // 서버 타임스탬프는 클라이언트에서 바로 확인할 수 없으므로 현재 시간 사용
          result['timestamp'] = Timestamp.now();

          return result;
        } catch (e) {
          print('타이머 시작 오류: $e');
          if (e.toString().contains('이미 진행 중인 타이머 세션이 있습니다')) {
            throw Exception(e.toString());
          }
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
  ) async {
    return ApiCallDecorator.wrap(
      'GroupFirebase.stopMemberTimer',
      () async {
        try {
          // 그룹 존재 확인
          final groupDoc = await _groupsCollection.doc(groupId).get();
          if (!groupDoc.exists) {
            throw Exception(GroupErrorMessages.notFound);
          }

          // 현재 진행 중인 타이머 세션이 있는지 확인
          final activeTimerQuery =
              await _groupsCollection
                  .doc(groupId)
                  .collection('timerActivities')
                  .where('memberId', isEqualTo: memberId)
                  .where('type', isEqualTo: 'start')
                  .orderBy('timestamp', descending: true)
                  .limit(1)
                  .get();

          // 활성화된 타이머가 없는 경우 에러
          if (activeTimerQuery.docs.isEmpty) {
            throw Exception(GroupErrorMessages.timerNotActive);
          }

          // 타임스탬프 생성
          final now = FieldValue.serverTimestamp();

          // 새 타이머 종료 활동 데이터 준비 (불필요한 중복 타임스탬프 제거)
          final activityData = {
            'memberId': memberId,
            'memberName': memberName,
            'type': 'end',
            'timestamp': now,
            'groupId': groupId,
            'metadata': {}, // 필요한 추가 정보만 포함
          };

          // Firestore에 타이머 활동 문서 추가
          final docRef = await _groupsCollection
              .doc(groupId)
              .collection('timerActivities')
              .add(activityData);

          // 생성된 문서 ID와 함께 데이터 반환
          final result = {...activityData};
          result['id'] = docRef.id;

          // 서버 타임스탬프는 클라이언트에서 바로 확인할 수 없으므로 현재 시간 사용
          result['timestamp'] = Timestamp.now();

          return result;
        } catch (e) {
          print('타이머 정지 오류: $e');
          // 구체적인 오류 메시지 전달
          if (e.toString().contains(GroupErrorMessages.timerNotActive)) {
            throw Exception(GroupErrorMessages.timerNotActive);
          }
          throw Exception(GroupErrorMessages.operationFailed);
        }
      },
      params: {'groupId': groupId, 'memberId': memberId},
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
          // 그룹 존재 확인
          final groupDoc = await _groupsCollection.doc(groupId).get();
          if (!groupDoc.exists) {
            throw Exception(GroupErrorMessages.notFound);
          }

          // 현재 진행 중인 타이머 세션이 있는지 확인
          final activeTimerQuery =
              await _groupsCollection
                  .doc(groupId)
                  .collection('timerActivities')
                  .where('memberId', isEqualTo: memberId)
                  .where('type', isEqualTo: 'start')
                  .orderBy('timestamp', descending: true)
                  .limit(1)
                  .get();

          // 활성화된 타이머가 없는 경우 에러
          if (activeTimerQuery.docs.isEmpty) {
            throw Exception(GroupErrorMessages.timerNotActive);
          }

          // 타임스탬프 생성
          final now = FieldValue.serverTimestamp();

          // 새 타이머 일시정지 활동 데이터 준비 (불필요한 중복 타임스탬프 제거)
          final activityData = {
            'memberId': memberId,
            'memberName': memberName,
            'type': 'pause',
            'timestamp': now,
            'groupId': groupId,
            'metadata': {}, // 필요한 추가 정보만 포함
          };

          // Firestore에 타이머 활동 문서 추가
          final docRef = await _groupsCollection
              .doc(groupId)
              .collection('timerActivities')
              .add(activityData);

          // 생성된 문서 ID와 함께 데이터 반환
          final result = {...activityData};
          result['id'] = docRef.id;

          // 서버 타임스탬프는 클라이언트에서 바로 확인할 수 없으므로 현재 시간 사용
          result['timestamp'] = Timestamp.now();

          return result;
        } catch (e) {
          print('타이머 일시정지 오류: $e');
          // 구체적인 오류 메시지 전달
          if (e.toString().contains(GroupErrorMessages.timerNotActive)) {
            throw Exception(GroupErrorMessages.timerNotActive);
          }
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
    int month, {
    int preloadMonths = 0, // 이전 몇 개월의 데이터를 함께 가져올지
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
