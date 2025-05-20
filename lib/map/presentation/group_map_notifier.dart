// lib/map/presentation/group_map_notifier.dart
import 'dart:async';

import 'package:devlink_mobile_app/core/auth/auth_provider.dart';
import 'package:devlink_mobile_app/map/domain/model/group_member_location.dart';
import 'package:devlink_mobile_app/map/domain/model/location.dart';
import 'package:devlink_mobile_app/map/domain/usecase/get_current_location_use_case.dart';
import 'package:devlink_mobile_app/map/domain/usecase/get_group_location_use_case.dart';
import 'package:devlink_mobile_app/map/domain/usecase/update_member_location_use_case.dart';
import 'package:devlink_mobile_app/map/module/group_location_di.dart';
import 'package:devlink_mobile_app/map/module/map_di.dart';
import 'package:devlink_mobile_app/map/presentation/group_map_action.dart';
import 'package:devlink_mobile_app/map/presentation/group_map_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'group_map_notifier.g.dart';

@riverpod
class GroupMapNotifier extends _$GroupMapNotifier {
  // Use cases
  late final GetCurrentLocationUseCase _getCurrentLocationUseCase;
  late final GetGroupLocationsUseCase _getGroupLocationsUseCase;
  late final UpdateMemberLocationUseCase _updateMemberLocationUseCase;

  // 맵 컨트롤러
  NaverMapController? _mapController;

  // 위치 스트림 구독
  StreamSubscription? _locationSubscription;

  // 위치 업데이트 타이머
  Timer? _locationUpdateTimer;

  @override
  GroupMapState build() {
    // Dependency Injection
    _getCurrentLocationUseCase = ref.watch(getCurrentLocationUseCaseProvider);
    _getGroupLocationsUseCase = ref.watch(getGroupLocationsUseCaseProvider);
    _updateMemberLocationUseCase = ref.watch(
      updateMemberLocationUseCaseProvider,
    );

    // 화면 이탈 시 자원 정리
    ref.onDispose(() {
      _locationSubscription?.cancel();
      _locationUpdateTimer?.cancel();
      _mapController = null;
      if (kDebugMode) {
        print('🗑️ GroupMapNotifier disposed');
      }
    });

    return const GroupMapState();
  }

  Future<void> onAction(GroupMapAction action) async {
    switch (action) {
      case Initialize(:final groupId, :final groupName):
        await _initialize(groupId, groupName);

      case RequestLocationPermission():
        await _requestLocationPermission();

      case GetCurrentLocation():
        await _getCurrentLocation();

      case UpdateLocation(:final latitude, :final longitude):
        await _updateLocation(latitude, longitude);

      case ToggleTrackingMode():
        _toggleTrackingMode();

      case OnMapInitialized(:final controller):
        _onMapInitialized(controller);

      case OnCameraChange(:final position):
        _onCameraChange(position);

      case OnMapTap():
        _clearSelection();

      case OnMemberMarkerTap(:final member):
        _selectMember(member);

      case ClearSelection():
        _clearSelection();

      case UpdateSearchRadius(:final radius):
        _updateSearchRadius(radius);

      // 네비게이션 액션은 Root에서 처리
      case NavigateToMemberProfile():
        break;
    }
  }

  // 초기화 로직
  Future<void> _initialize(String groupId, String groupName) async {
    if (kDebugMode) {
      print('📱 GroupMapNotifier initializing - groupId: $groupId');
    }

    state = state.copyWith(
      groupId: groupId,
      groupName: groupName,
      isLoading: true,
    );

    // 위치 권한 확인
    await _requestLocationPermission();

    // 그룹 멤버 위치 정보 로드
    await _loadGroupLocations(groupId);

    // 주기적인 위치 업데이트 시작
    _startLocationUpdates();

    state = state.copyWith(isLoading: false);
  }

  // 위치 권한 요청
  Future<void> _requestLocationPermission() async {
    // 실제 구현에서는 위치 권한 요청 로직 추가
    // 예: Geolocator 라이브러리 사용
    state = state.copyWith(
      hasLocationPermission: true, // 실제로는 권한 요청 결과에 따라 설정
      isLocationServiceEnabled: true, // 실제로는 위치 서비스 활성화 여부 확인
    );

    // 권한이 있으면 현재 위치 가져오기
    if (state.hasLocationPermission && state.isLocationServiceEnabled) {
      await _getCurrentLocation();
    }
  }

  // 현재 위치 가져오기
  Future<void> _getCurrentLocation() async {
    state = state.copyWith(currentLocation: const AsyncValue.loading());

    final result = await _getCurrentLocationUseCase.execute();

    state = state.copyWith(currentLocation: result);

    // 위치를 가져왔고 맵이 초기화되었으면 해당 위치로 카메라 이동
    if (result is AsyncData<Location> &&
        state.isMapInitialized &&
        _mapController != null) {
      _moveToCurrentLocation(result.value);
    }
  }

  // 위치 업데이트
  Future<void> _updateLocation(double latitude, double longitude) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null || state.groupId.isEmpty) return;

    await _updateMemberLocationUseCase.execute(
      state.groupId,
      currentUser.uid,
      latitude,
      longitude,
    );
  }

  // 위치 추적 모드 토글
  void _toggleTrackingMode() {
    final newTrackingMode = !state.isTrackingMode;
    state = state.copyWith(isTrackingMode: newTrackingMode);

    if (newTrackingMode) {
      // 추적 모드가 켜지면 현재 위치 가져오기
      _getCurrentLocation();
    }
  }

  // 맵 초기화 완료
  void _onMapInitialized(NaverMapController controller) {
    _mapController = controller;
    state = state.copyWith(isMapInitialized: true);

    // 맵이 초기화되고 현재 위치가 있으면 해당 위치로 카메라 이동
    if (state.currentLocation is AsyncData<Location>) {
      _moveToCurrentLocation(
        (state.currentLocation as AsyncData<Location>).value,
      );
    }
  }

  // 카메라 이동
  void _onCameraChange(NCameraPosition position) {
    state = state.copyWith(cameraPosition: position);

    // 카메라가 이동했고 추적 모드가 아니면 추적 모드 해제
    if (state.isTrackingMode) {
      state = state.copyWith(isTrackingMode: false);
    }
  }

  // 멤버 선택
  void _selectMember(GroupMemberLocation member) {
    state = state.copyWith(selectedMember: member);

    // 선택한 멤버 위치로 카메라 이동
    if (_mapController != null) {
      // 최신 API로 수정 (moveCamera 대신 updateCamera 사용)
      _mapController!.updateCamera(
        NCameraUpdate.withParams(
          target: NLatLng(member.latitude, member.longitude),
          zoom: 15,
        ),
      );
    }
  }

  // 선택 해제
  void _clearSelection() {
    state = state.copyWith(selectedMember: null);
  }

  // 검색 반경 변경
  void _updateSearchRadius(double radius) {
    state = state.copyWith(searchRadius: radius);

    // 반경이 변경되면 맵 카메라 줌 레벨 조정
    if (_mapController != null &&
        state.currentLocation is AsyncData<Location>) {
      final location = (state.currentLocation as AsyncData<Location>).value;
      // 최신 API로 수정
      _mapController!.updateCamera(
        NCameraUpdate.withParams(
          target: NLatLng(location.latitude, location.longitude),
          zoom: _radiusToZoomLevel(radius),
        ),
      );
    }
  }

  // 그룹 멤버 위치 정보 로드
  Future<void> _loadGroupLocations(String groupId) async {
    state = state.copyWith(memberLocations: const AsyncValue.loading());

    final result = await _getGroupLocationsUseCase.execute(groupId);

    state = state.copyWith(memberLocations: result);
  }

  // 현재 위치로 카메라 이동
  void _moveToCurrentLocation(Location location) {
    if (_mapController == null) return;

    // 최신 API로 수정 (moveCamera 대신 updateCamera 사용, animation 파라미터 제거)
    _mapController!.updateCamera(
      NCameraUpdate.withParams(
        target: NLatLng(location.latitude, location.longitude),
        zoom: _radiusToZoomLevel(state.searchRadius),
      ),
    );
  }

  // 주기적인 위치 업데이트 시작
  void _startLocationUpdates() {
    // 이미 타이머가 실행 중이면 취소
    _locationUpdateTimer?.cancel();

    // 30초마다 위치 업데이트
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 30), (
      _,
    ) async {
      if (!state.hasLocationPermission || !state.isLocationServiceEnabled)
        return;

      // 현재 위치 가져오기
      final locationResult = await _getCurrentLocationUseCase.execute();

      if (locationResult is AsyncData<Location>) {
        final location = locationResult.value;

        // 위치 업데이트
        await _updateLocation(location.latitude, location.longitude);

        // 추적 모드가 켜져 있으면 카메라 이동
        if (state.isTrackingMode) {
          _moveToCurrentLocation(location);
        }
      }
    });
  }

  // 검색 반경에 따른 줌 레벨 계산
  double _radiusToZoomLevel(double radiusKm) {
    // 반경이 커질수록 줌 레벨은 작아짐
    // 대략적인 수치로 조정 가능
    if (radiusKm <= 0.5)
      return 16; // 500m 이하
    else if (radiusKm <= 1)
      return 15; // 1km 이하
    else if (radiusKm <= 2)
      return 14; // 2km 이하
    else if (radiusKm <= 5)
      return 13; // 5km 이하
    else if (radiusKm <= 10)
      return 12; // 10km 이하
    else
      return 11; // 10km 초과
  }
}
