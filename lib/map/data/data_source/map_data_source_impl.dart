import 'package:devlink_mobile_app/map/data/data_source/map_data_source.dart';
import 'package:devlink_mobile_app/map/data/dto/location_dto.dart';
import 'package:devlink_mobile_app/map/data/dto/map_marker_dto.dart';
import 'package:devlink_mobile_app/map/data/dto/near_by_items_dto.dart';
import 'package:geolocator/geolocator.dart';

class MapDataSourceImpl implements MapDataSource {
  final GeolocatorPlatform _geolocator;

  // API 호출을 위한 서비스나 클라이언트도 추가 가능합니다.
  // final ApiClient _apiClient;

  MapDataSourceImpl({
    GeolocatorPlatform? geolocator,
    // ApiClient? apiClient,
  }) : _geolocator = geolocator ?? GeolocatorPlatform.instance;
  // _apiClient = apiClient ?? ApiClient();

  @override
  Future<LocationDto> fetchCurrentLocation() async {
    // 위치 권한 확인
    bool hasPermission = await checkLocationPermission();
    if (!hasPermission) {
      throw Exception('위치 접근 권한이 없습니다');
    }

    // 위치 서비스 활성화 확인
    bool serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('위치 서비스가 비활성화되어 있습니다');
    }

    try {
      final position = await _geolocator.getCurrentPosition();

      return LocationDto(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: position.timestamp.millisecondsSinceEpoch,
      );
    } catch (e) {
      throw Exception('현재 위치를 가져오는데 실패했습니다: $e');
    }
  }

  @override
  Future<NearByItemsDto> fetchNearByItems(
    LocationDto location,
    double radius,
  ) async {
    // 실제 구현에서는 API를 호출하여 주변 그룹과 사용자를 가져옵니다.
    // 여기서는 예시로 하드코딩된 더미 데이터를 반환합니다.

    // TODO: API 호출로 대체 필요
    // final response = await _apiClient.get(
    //   '/api/map/nearby',
    //   queryParameters: {
    //     'lat': location.latitude,
    //     'lng': location.longitude,
    //     'radius': radius,
    //   },
    // );

    await Future.delayed(const Duration(milliseconds: 300)); // 네트워크 지연 시뮬레이션

    return NearByItemsDto(
      groups: _getDummyGroups(location),
      users: _getDummyUsers(location),
    );
  }

  @override
  Future<void> saveLocationData(LocationDto location, String userId) async {
    // 실제 구현에서는 API를 호출하여 위치를 저장합니다.
    // TODO: API 호출로 대체 필요
    // await _apiClient.post(
    //   '/api/users/$userId/locations',
    //   data: location.toJson(),
    // );

    await Future.delayed(const Duration(milliseconds: 200)); // 네트워크 지연 시뮬레이션
  }

  @override
  Future<bool> checkLocationPermission() async {
    LocationPermission permission = await _geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await _geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  @override
  Future<bool> isLocationServiceEnabled() {
    return _geolocator.isLocationServiceEnabled();
  }

  // 더미 그룹 데이터 생성 (테스트용)
  List<MapMarkerDto> _getDummyGroups(LocationDto baseLocation) {
    final lat = baseLocation.latitude ?? 0;
    final lng = baseLocation.longitude ?? 0;

    return [
      MapMarkerDto(
        id: 'group1',
        title: '디브링크 스터디',
        description: '플러터 스터디 그룹입니다',
        location: LocationDto(latitude: lat + 0.005, longitude: lng + 0.005),
        type: 'group',
        imageUrl: 'https://example.com/group1.jpg',
        memberCount: 5,
        limitMemberCount: 10,
      ),
      MapMarkerDto(
        id: 'group2',
        title: '코딩테스트 준비방',
        description: '주 2회 알고리즘 스터디',
        location: LocationDto(latitude: lat - 0.003, longitude: lng + 0.002),
        type: 'group',
        imageUrl: 'https://example.com/group2.jpg',
        memberCount: 8,
        limitMemberCount: 12,
      ),
    ];
  }

  // 더미 사용자 데이터 생성 (테스트용)
  List<MapMarkerDto> _getDummyUsers(LocationDto baseLocation) {
    final lat = baseLocation.latitude ?? 0;
    final lng = baseLocation.longitude ?? 0;

    return [
      MapMarkerDto(
        id: 'user1',
        title: '홍길동',
        description: 'Flutter 개발자',
        location: LocationDto(latitude: lat - 0.001, longitude: lng - 0.002),
        type: 'user',
        imageUrl: 'https://example.com/user1.jpg',
      ),
      MapMarkerDto(
        id: 'user2',
        title: '김철수',
        description: 'Java 개발자',
        location: LocationDto(latitude: lat + 0.002, longitude: lng - 0.001),
        type: 'user',
        imageUrl: 'https://example.com/user2.jpg',
      ),
    ];
  }
}
