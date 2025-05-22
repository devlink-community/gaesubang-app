import '../dto/banner_dto.dart';

abstract interface class BannerDataSource {
  /// 모든 배너 목록 조회
  Future<List<BannerDto>> fetchAllBanners();

  /// 특정 배너 조회
  Future<BannerDto> fetchBannerById(String bannerId);

  /// 활성화된 배너만 조회 (isActive = true)
  Future<List<BannerDto>> fetchActiveBanners();
}