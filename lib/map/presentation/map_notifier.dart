// lib/map/presentation/map_notifier.dart
import 'package:devlink_mobile_app/map/domain/model/location.dart';
import 'package:devlink_mobile_app/map/domain/model/map_marker.dart';
import 'package:devlink_mobile_app/map/domain/usecase/check_location_permission_use_case.dart';
import 'package:devlink_mobile_app/map/domain/usecase/get_current_location_use_case.dart';
import 'package:devlink_mobile_app/map/domain/usecase/get_near_by_items_use_case.dart';
import 'package:devlink_mobile_app/map/domain/usecase/save_location_data_use_case.dart';
import 'package:devlink_mobile_app/map/module/filter_type.dart';
import 'package:devlink_mobile_app/map/module/map_di.dart';
import 'package:devlink_mobile_app/map/presentation/map_action.dart';
import 'package:devlink_mobile_app/map/presentation/map_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'map_notifier.g.dart';

@riverpod
class MapNotifier extends _$MapNotifier {
  late final GetCurrentLocationUseCase _getCurrentLocationUseCase;
  late final GetNearByItemsUseCase _getNearByItemsUseCase;
  late final CheckLocationPermissionUseCase _checkLocationPermissionUseCase;
  late final SaveLocationDataUseCase _saveLocationDataUseCase;

  @override
  MapState build() {
    _getCurrentLocationUseCase = ref.watch(getCurrentLocationUseCaseProvider);
    _getNearByItemsUseCase = ref.watch(getNearByItemsUseCaseProvider);
    _checkLocationPermissionUseCase = ref.watch(
      checkLocationPermissionUseCaseProvider,
    );
    _saveLocationDataUseCase = ref.watch(saveLocationDataUseCaseProvider);

    return const MapState();
  }

  Future<void> onAction(MapAction action) async {
    switch (action) {
      case Initialize():
        await _initialize();

      case RequestLocationPermission():
        await _requestLocationPermission();

      case GetCurrentLocation():
        await _getCurrentLocation();

      case UpdateSearchRadius(:final radius):
        _updateSearchRadius(radius);

      case ToggleTrackingMode():
        _toggleTrackingMode();

      case ChangeZoomLevel(:final level):
        _changeZoomLevel(level);

      case OnMapMoved(:final centerLocation):
        _onMapMoved(centerLocation);

      case OnMapTap(:final location):
        _onMapTap(location);

      case SelectMarker(:final marker):
        _selectMarker(marker);

      case ClearSelection():
        _clearSelection();

      case ChangeFilter(:final filterType):
        _changeFilter(filterType);

      case ToggleClustering():
        _toggleClustering();

      case SelectCard(:final index):
        _selectCard(index);

      case ToggleCardView():
        _toggleCardView();

      // 네비게이션 액션은 Root에서 처리
      case NavigateToUserProfile():
      case NavigateToGroupDetail():
        break;
    }
  }

  // 초기화: 위치 권한 및 서비스 확인, 현재 위치 가져오기
  Future<void> _initialize() async {
    // 위치 권한 확인
    final permissionResult = await _checkLocationPermissionUseCase.execute();

    switch (permissionResult) {
      case AsyncData(:final value):
        state = state.copyWith(hasLocationPermission: value);
        if (value) {
          // 권한이 있으면 현재 위치 가져오기
          await _getCurrentLocation();
        } else {
          state = state.copyWith(
            errorMessage: '위치 접근 권한이 필요합니다. 설정에서 권한을 허용해주세요.',
          );
        }
      case AsyncError(:final error):
        state = state.copyWith(errorMessage: '위치 권한 확인 중 오류가 발생했습니다: $error');
      case AsyncLoading():
        // 로딩 중에는 처리 없음
        break;
    }
  }

  // 위치 권한 요청
  Future<void> _requestLocationPermission() async {
    state = state.copyWith(
      errorMessage: null,
      currentLocation: const AsyncLoading(),
    );

    // 권한 요청은 외부 라이브러리를 통해 수행해야 함
    // 여기서는 이미 권한을 얻은 것처럼 처리
    final permissionResult = await _checkLocationPermissionUseCase.execute();

    switch (permissionResult) {
      case AsyncData(:final value):
        state = state.copyWith(hasLocationPermission: value);
        if (value) {
          await _getCurrentLocation();
        } else {
          state = state.copyWith(
            errorMessage: '위치 권한이 거부되었습니다. 설정에서 권한을 허용해주세요.',
          );
        }
      case AsyncError(:final error):
        state = state.copyWith(errorMessage: '위치 권한 요청 중 오류가 발생했습니다: $error');
      case AsyncLoading():
        // 로딩 중에는 처리 없음
        break;
    }
  }

  // 현재 위치 가져오기
  Future<void> _getCurrentLocation() async {
    state = state.copyWith(
      errorMessage: null,
      currentLocation: const AsyncLoading(),
    );

    final locationResult = await _getCurrentLocationUseCase.execute();

    state = state.copyWith(currentLocation: locationResult);

    // 위치를 성공적으로 가져왔으면 주변 항목 가져오기
    if (locationResult is AsyncData<Location>) {
      await _fetchNearByItems(locationResult.value);
    }
  }

  // 주변 항목 가져오기 (그룹, 사용자)
  Future<void> _fetchNearByItems(Location location) async {
    state = state.copyWith(nearbyItems: const AsyncLoading());

    final nearbyItemsResult = await _getNearByItemsUseCase.execute(
      location,
      state.searchRadius,
    );

    state = state.copyWith(nearbyItems: nearbyItemsResult);
  }

  // 검색 반경 업데이트
  void _updateSearchRadius(double radius) {
    state = state.copyWith(searchRadius: radius);

    // 반경이 변경되면 주변 항목 다시 가져오기
    if (state.currentLocation is AsyncData) {
      _fetchNearByItems((state.currentLocation as AsyncData<Location>).value);
    }
  }

  // 추적 모드 토글
  void _toggleTrackingMode() {
    state = state.copyWith(isTrackingMode: !state.isTrackingMode);

    // 추적 모드가 켜지면 현재 위치 가져오기
    if (state.isTrackingMode) {
      _getCurrentLocation();
    }
  }

  // 지도 줌 레벨 변경
  void _changeZoomLevel(double level) {
    state = state.copyWith(zoomLevel: level);
  }

  // 지도가 이동했을 때
  void _onMapMoved(Location centerLocation) {
    // 추적 모드가 아닐 때만 처리
    if (!state.isTrackingMode) {
      // 중심 위치가 크게 변경된 경우 주변 항목 다시 가져오기
      // (실제 구현에서는 이전 위치와의 거리 계산 필요)
      _fetchNearByItems(centerLocation);
    }
  }

  // 지도를 탭했을 때
  void _onMapTap(Location location) {
    // 선택된 마커 지우기
    _clearSelection();
  }

  // 마커 선택
  void _selectMarker(MapMarker marker) {
    state = state.copyWith(selectedMarker: marker);
  }

  // 선택 해제
  void _clearSelection() {
    state = state.copyWith(selectedMarker: null);
  }

  // 필터 변경
  void _changeFilter(FilterType filterType) {
    state = state.copyWith(selectedFilter: filterType);

    // 필터가 변경되면 UI 업데이트
    // (실제 구현에서는 기존 데이터를 필터링하여 표시)
  }

  // 클러스터링 토글
  void _toggleClustering() {
    state = state.copyWith(isClusteringEnabled: !state.isClusteringEnabled);
  }

  // 카드 선택
  void _selectCard(int index) {
    state = state.copyWith(selectedCardIndex: index);
  }

  // 카드 뷰 토글
  void _toggleCardView() {
    state = state.copyWith(isCardViewExpanded: !state.isCardViewExpanded);
  }
}
