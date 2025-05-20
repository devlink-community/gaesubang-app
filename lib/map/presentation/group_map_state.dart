// lib/map/presentation/group_map_state.dart 수정
import 'package:devlink_mobile_app/map/domain/model/group_member_location.dart';
import 'package:devlink_mobile_app/map/domain/model/location.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

part 'group_map_state.freezed.dart';

@freezed
class GroupMapState with _$GroupMapState {
  const GroupMapState({
    // 현재 사용자 위치
    this.currentLocation = const AsyncValue.loading(),

    // 그룹 멤버 위치 목록
    this.memberLocations = const AsyncValue.loading(),

    // 선택된 멤버
    this.selectedMember,

    // 위치 추적 모드 활성화 여부
    this.isTrackingMode = false,

    // 맵 카메라 위치
    this.cameraPosition,

    // 맵 초기화 완료 여부
    this.isMapInitialized = false,

    // 위치 권한 상태
    this.hasLocationPermission = false,

    // 위치 서비스 활성화 여부
    this.isLocationServiceEnabled = false,

    // 에러 메시지
    this.errorMessage,

    // 검색 반경 (km)
    this.searchRadius = 5.0,

    // 데이터 로드 중 여부
    this.isLoading = false,

    // 그룹 ID
    this.groupId = '',

    // 그룹명
    this.groupName = '',

    // 위치 공유 동의 여부
    this.isLocationSharingAgreed = false,

    // 위치 공유 동의 대화상자 표시 여부
    this.showLocationSharingDialog = false,
  });

  final AsyncValue<Location> currentLocation;
  final AsyncValue<List<GroupMemberLocation>> memberLocations;
  final GroupMemberLocation? selectedMember;
  final bool isTrackingMode;
  final NCameraPosition? cameraPosition;
  final bool isMapInitialized;
  final bool hasLocationPermission;
  final bool isLocationServiceEnabled;
  final String? errorMessage;
  final double searchRadius;
  final bool isLoading;
  final String groupId;
  final String groupName;
  final bool isLocationSharingAgreed;
  final bool showLocationSharingDialog;
}
