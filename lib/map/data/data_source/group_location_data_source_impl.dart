// lib/group/data/data_source/group_location_data_source_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devlink_mobile_app/map/data/data_source/group_loscation_data_source.dart';
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
  }

  @override
  Future<List<GroupMemberLocationDto>> getGroupMemberLocations(
    String groupId,
  ) async {
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
  }

  @override
  Stream<List<GroupMemberLocationDto>> streamGroupMemberLocations(
    String groupId,
  ) {
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
  }
}
