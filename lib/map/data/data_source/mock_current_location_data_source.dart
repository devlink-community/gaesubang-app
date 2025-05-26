// lib/map/data/data_source/mock_current_location_data_source.dart
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/core/utils/time_formatter.dart';
import 'package:devlink_mobile_app/map/data/data_source/map_data_source.dart';
import 'package:devlink_mobile_app/map/data/dto/location_dto.dart';
import 'package:devlink_mobile_app/map/data/dto/near_by_items_dto.dart';

/// 현재 위치를 Mock으로 제공하는 DataSource 구현체
class MockCurrentLocationDataSource implements MapDataSource {
  /// 제주도 성산일출봉 좌표 (상수로 정의)
  // static const double latitude = 33.4589;
  // static const double longitude = 126.9421;

  // 서울역 좌표 (상수로 정의)
  static const double latitude = 37.5559;
  static const double longitude = 126.9723;

  @override
  Future<LocationDto> fetchCurrentLocation() async {
    AppLogger.debug(
      'MockCurrentLocationDataSource: 서울역 위치 반환 (현재 사용자)',
      tag: 'MockCurrentLocation',
    );

    // 지연 시간 시뮬레이션 (200ms)
    await Future.delayed(const Duration(milliseconds: 200));

    return LocationDto(
      latitude: latitude,
      longitude: longitude,
      address: '어딜까요?',
      timestamp: TimeFormatter.nowInSeoul().millisecondsSinceEpoch,
    );
  }

  @override
  Future<NearByItemsDto> fetchNearByItems(
    LocationDto location,
    double radius,
  ) async {
    // 이 메서드는 사용하지 않음
    throw UnimplementedError();
  }

  @override
  Future<void> saveLocationData(LocationDto location, String userId) async {
    // 이 메서드는 사용하지 않음
    AppLogger.debug(
      'MockCurrentLocationDataSource: 위치 데이터 저장 (아무 작업 안함)',
      tag: 'MockCurrentLocation',
    );
  }

  @override
  Future<bool> checkLocationPermission() async {
    // 항상 권한이 있다고 가정
    return true;
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    // 항상 서비스가 활성화되어 있다고 가정
    return true;
  }
}
