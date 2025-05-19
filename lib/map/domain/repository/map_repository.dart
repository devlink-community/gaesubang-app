import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/map/domain/model/location.dart';
import 'package:devlink_mobile_app/map/domain/model/near_by_items.dart';

abstract interface class MapRepository {
  /// 현재 위치 가져오기
  Future<Result<Location>> getCurrentLocation();

  /// 주변 아이템(그룹, 사용자) 조회
  Future<Result<NearByItems>> getNearByItems(Location location, double radius);

  /// 위치 데이터 저장 (타이머 시작 등에 사용)
  Future<Result<void>> saveLocationData(Location location, String userId);

  /// 위치 권한 상태 확인
  Future<Result<bool>> checkLocationPermission();

  /// 위치 서비스 활성화 상태 확인
  Future<Result<bool>> isLocationServiceEnabled();
}