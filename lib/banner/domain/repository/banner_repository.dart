import '../../../core/result/result.dart';
import '../model/banner.dart';

abstract interface class BannerRepository {
  /// 활성화된 배너 목록 조회
  /// 현재 날짜 기준으로 활성화되고 기간 내인 배너들을 반환
  Future<Result<List<Banner>>> getActiveBanners();

  /// 모든 배너 목록 조회 (관리용)
  Future<Result<List<Banner>>> getAllBanners();

  /// 특정 배너 조회
  Future<Result<Banner>> getBannerById(String bannerId);
}