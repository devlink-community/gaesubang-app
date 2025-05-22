// lib/map/data/data_source/group_location_data_source_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devlink_mobile_app/map/data/data_source/group_location_data_source.dart';
import 'package:devlink_mobile_app/map/data/dto/group_member_location_dto.dart';

class GroupLocationDataSourceImpl implements GroupLocationDataSource {
  final FirebaseFirestore _firestore;

  GroupLocationDataSourceImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> updateMemberLocation(
    String groupId,
    String memberId,
    double latitude,
    double longitude,
  ) async {
    try {
      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('locations')
          .doc(memberId)
          .set({
            'memberId': memberId,
            'latitude': latitude,
            'longitude': longitude,
            'lastUpdated': FieldValue.serverTimestamp(),
            'isOnline': true,
          }, SetOptions(merge: true));
    } catch (e, st) {
      // ✅ Firebase 통신 오류: 원본 예외 정보 보존
      print('멤버 위치 업데이트 Firebase 통신 오류: $e\n$st');
      rethrow;
    }
  }

  @override
  Future<List<GroupMemberLocationDto>> getGroupMemberLocations(
    String groupId,
  ) async {
    try {
      final snapshot =
          await _firestore
              .collection('groups')
              .doc(groupId)
              .collection('locations')
              .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return GroupMemberLocationDto.fromJson({...data, 'id': doc.id});
      }).toList();
    } catch (e, st) {
      // ✅ Firebase 통신 오류: 원본 예외 정보 보존
      print('그룹 멤버 위치 조회 Firebase 통신 오류: $e\n$st');
      rethrow;
    }
  }

  @override
  Stream<List<GroupMemberLocationDto>> streamGroupMemberLocations(
    String groupId,
  ) {
    try {
      return _firestore
          .collection('groups')
          .doc(groupId)
          .collection('locations')
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              final data = doc.data();
              return GroupMemberLocationDto.fromJson({...data, 'id': doc.id});
            }).toList();
          });
    } catch (e, st) {
      // ✅ Firebase 스트림 구독 오류: 원본 예외 정보 보존
      print('그룹 멤버 위치 스트림 구독 Firebase 오류: $e\n$st');
      rethrow;
    }
  }
}
