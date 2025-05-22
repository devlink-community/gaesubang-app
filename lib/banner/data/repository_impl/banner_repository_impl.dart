import '../../../core/result/result.dart';
import '../../domain/model/banner.dart';
import '../../domain/repository/banner_repository.dart';
import '../data_source/banner_data_source.dart';
import '../mapper/banner_mapper.dart';

class BannerRepositoryImpl implements BannerRepository {
  final BannerDataSource _dataSource;

  BannerRepositoryImpl({required BannerDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<Result<List<Banner>>> getActiveBanners() async {
    try {
      final bannerDtos = await _dataSource.fetchActiveBanners();
      final banners = bannerDtos.toModelList();
      return Result.success(banners);
    } catch (e, st) {
      return Result.error(mapExceptionToFailure(e, st));
    }
  }

  @override
  Future<Result<List<Banner>>> getAllBanners() async {
    try {
      final bannerDtos = await _dataSource.fetchAllBanners();
      final banners = bannerDtos.toModelList();
      return Result.success(banners);
    } catch (e, st) {
      return Result.error(mapExceptionToFailure(e, st));
    }
  }

  @override
  Future<Result<Banner>> getBannerById(String bannerId) async {
    try {
      final bannerDto = await _dataSource.fetchBannerById(bannerId);
      final banner = bannerDto.toModel();
      return Result.success(banner);
    } catch (e, st) {
      return Result.error(mapExceptionToFailure(e, st));
    }
  }
}