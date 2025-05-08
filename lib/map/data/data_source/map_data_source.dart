import 'package:devlink_mobile_app/map/data/dto/location_dto.dart';
import 'package:devlink_mobile_app/map/data/dto/near_by_items_dto.dart';

abstract interface class MapDataSource {
  /// 현재 위치 가져오기
  Future<LocationDto> fetchCurrentLocation();

  /// 주변 아이템(그룹, 사용자) 조회
  Future<NearByItemsDto> fetchNearByItems(LocationDto location, double radius);

  /// 위치 데이터 저장 (타이머 시작 등에 사용)
  Future<void> saveLocationData(LocationDto location, String userId);

  /// 위치 권한 상태 확인
  Future<bool> checkLocationPermission();

  /// 위치 서비스 활성화 상태 확인
  Future<bool> isLocationServiceEnabled();
}
