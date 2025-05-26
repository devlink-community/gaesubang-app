// lib/banner/data/repository_impl/banner_repository_impl.dart - 최종 수정버전

import '../../../core/result/result.dart';
import '../../../core/utils/api_call_logger.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/exception_mappers/banner_exception_mapper.dart';
import '../../../core/utils/time_formatter.dart' show TimeFormatter;
import '../../domain/model/banner.dart';
import '../../domain/repository/banner_repository.dart';
import '../data_source/banner_data_source.dart';
import '../mapper/banner_mapper.dart';

class BannerRepositoryImpl implements BannerRepository {
  final BannerDataSource _dataSource;

  BannerRepositoryImpl({required BannerDataSource dataSource})
    : _dataSource = dataSource {
    AppLogger.ui('BannerRepositoryImpl 초기화 완료');
  }

  @override
  Future<Result<List<Banner>>> getActiveBanners() async {
    return ApiCallDecorator.wrap('BannerRepository.getActiveBanners', () async {
      AppLogger.debug('활성 배너 목록 조회 시작');
      final startTime = TimeFormatter.nowInSeoul();

      try {
        AppLogger.logStep(1, 3, '데이터소스 활성 배너 조회');
        final bannerDtos = await _dataSource.fetchActiveBanners();

        AppLogger.logStep(2, 3, '배너 DTO → 모델 변환');
        final banners = bannerDtos.toModelList();

        AppLogger.logStep(3, 3, '활성 배너 조회 결과 처리');
        final duration = TimeFormatter.nowInSeoul().difference(startTime);
        AppLogger.logPerformance('활성 배너 조회', duration);

        AppLogger.ui('활성 배너 조회 성공: ${banners.length}개');
        AppLogger.logState('활성 배너 조회 결과', {
          'banner_count': banners.length,
          'duration_ms': duration.inMilliseconds,
          'has_banners': banners.isNotEmpty,
        });

        if (banners.isNotEmpty) {
          AppLogger.logState('첫 번째 배너 정보', {
            'banner_id': banners.first.id,
            'is_active': banners.first.isActive,
            'display_order': banners.first.displayOrder,
            'has_link_url': banners.first.linkUrl?.isNotEmpty ?? false,
          });
        }

        return Result.success(banners);
      } catch (e, st) {
        final duration = TimeFormatter.nowInSeoul().difference(startTime);
        AppLogger.logPerformance('활성 배너 조회 실패', duration);

        AppLogger.error('활성 배너 조회 실패', error: e, stackTrace: st);
        AppLogger.logState('활성 배너 조회 실패 상세', {
          'error_type': e.runtimeType.toString(),
          'duration_ms': duration.inMilliseconds,
        });

        // ✅ 배너 전용 예외 매퍼 사용
        return Result.error(BannerExceptionMapper.mapBannerException(e, st));
      }
    });
  }

  @override
  Future<Result<List<Banner>>> getAllBanners() async {
    return ApiCallDecorator.wrap('BannerRepository.getAllBanners', () async {
      AppLogger.debug('전체 배너 목록 조회 시작');
      final startTime = TimeFormatter.nowInSeoul();

      try {
        AppLogger.logStep(1, 3, '데이터소스 전체 배너 조회');
        final bannerDtos = await _dataSource.fetchAllBanners();

        AppLogger.logStep(2, 3, '배너 DTO → 모델 변환');
        final banners = bannerDtos.toModelList();

        AppLogger.logStep(3, 3, '전체 배너 조회 결과 처리');
        final duration = TimeFormatter.nowInSeoul().difference(startTime);
        AppLogger.logPerformance('전체 배너 조회', duration);

        AppLogger.ui('전체 배너 조회 성공: ${banners.length}개');
        AppLogger.logState('전체 배너 조회 결과', {
          'total_banner_count': banners.length,
          'active_banner_count': banners.where((b) => b.isActive).length,
          'inactive_banner_count': banners.where((b) => !b.isActive).length,
          'duration_ms': duration.inMilliseconds,
        });

        return Result.success(banners);
      } catch (e, st) {
        final duration = TimeFormatter.nowInSeoul().difference(startTime);
        AppLogger.logPerformance('전체 배너 조회 실패', duration);

        AppLogger.error('전체 배너 조회 실패', error: e, stackTrace: st);
        AppLogger.logState('전체 배너 조회 실패 상세', {
          'error_type': e.runtimeType.toString(),
          'duration_ms': duration.inMilliseconds,
        });

        // ✅ 배너 전용 예외 매퍼 사용
        return Result.error(BannerExceptionMapper.mapBannerException(e, st));
      }
    });
  }

  @override
  Future<Result<Banner>> getBannerById(String bannerId) async {
    return ApiCallDecorator.wrap('BannerRepository.getBannerById', () async {
      AppLogger.debug('특정 배너 조회 시작: $bannerId');
      final startTime = TimeFormatter.nowInSeoul();

      AppLogger.logState('특정 배너 조회 요청', {
        'banner_id': bannerId,
        'request_type': 'single_banner',
      });

      try {
        AppLogger.logStep(1, 3, '데이터소스 특정 배너 조회');
        final bannerDto = await _dataSource.fetchBannerById(bannerId);

        AppLogger.logStep(2, 3, '배너 DTO → 모델 변환');
        final banner = bannerDto.toModel();

        AppLogger.logStep(3, 3, '특정 배너 조회 결과 처리');
        final duration = TimeFormatter.nowInSeoul().difference(startTime);
        AppLogger.logPerformance('특정 배너 조회', duration);

        AppLogger.ui('특정 배너 조회 성공: $bannerId');
        AppLogger.logState('조회된 배너 정보', {
          'banner_id': banner.id,
          'is_active': banner.isActive,
          'display_order': banner.displayOrder,
          'has_title': banner.title.isNotEmpty,
          'has_link_url': banner.linkUrl?.isNotEmpty ?? false,
          'duration_ms': duration.inMilliseconds,
        });

        return Result.success(banner);
      } catch (e, st) {
        final duration = TimeFormatter.nowInSeoul().difference(startTime);
        AppLogger.logPerformance('특정 배너 조회 실패', duration);

        AppLogger.error('특정 배너 조회 실패', error: e, stackTrace: st);
        AppLogger.logState('특정 배너 조회 실패 상세', {
          'banner_id': bannerId,
          'error_type': e.runtimeType.toString(),
          'duration_ms': duration.inMilliseconds,
        });

        // ✅ 배너 전용 예외 매퍼 사용
        return Result.error(BannerExceptionMapper.mapBannerException(e, st));
      }
    }, params: {'bannerId': bannerId});
  }
}
