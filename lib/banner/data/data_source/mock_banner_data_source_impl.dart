import 'banner_data_source.dart';
import '../dto/banner_dto.dart';
import '../../../core/utils/app_logger.dart';

class MockBannerDataSourceImpl implements BannerDataSource {
  @override
  Future<List<BannerDto>> fetchAllBanners() async {
    AppLogger.debug('Mock 전체 배너 조회 시작');
    final startTime = DateTime.now();
    
    AppLogger.logState('Mock 배너 조회 설정', {
      'simulated_delay_ms': 150,
      'mock_data_count': _mockBanners.length,
      'data_source': 'mock',
    });
    
    // 네트워크 지연 시뮬레이션 - 실제적인 시간으로 단축
    await Future.delayed(const Duration(milliseconds: 150)); // 800ms → 150ms

    final duration = DateTime.now().difference(startTime);
    AppLogger.logPerformance('Mock 전체 배너 조회', duration);
    
    AppLogger.ui('Mock 전체 배너 조회 완료: ${_mockBanners.length}개');
    AppLogger.logState('Mock 전체 배너 결과', {
      'total_banners': _mockBanners.length,
      'active_banners': _mockBanners.where((b) => b.isActive == true).length,
      'inactive_banners': _mockBanners.where((b) => b.isActive == false).length,
      'simulation_time_ms': duration.inMilliseconds,
    });
    
    return _mockBanners;
  }

  @override
  Future<BannerDto> fetchBannerById(String bannerId) async {
    AppLogger.debug('Mock 특정 배너 조회 시작: $bannerId');
    final startTime = DateTime.now();
    
    AppLogger.logState('Mock 특정 배너 조회 설정', {
      'banner_id': bannerId,
      'simulated_delay_ms': 50,
      'data_source': 'mock',
    });
    
    // 캐시된 데이터 조회 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 50)); // 500ms → 50ms

    try {
      final banner = _mockBanners.firstWhere(
        (banner) => banner.id == bannerId,
        orElse: () => throw Exception('배너를 찾을 수 없습니다: $bannerId'),
      );

      final duration = DateTime.now().difference(startTime);
      AppLogger.logPerformance('Mock 특정 배너 조회', duration);
      
      AppLogger.ui('Mock 특정 배너 조회 성공: $bannerId');
      AppLogger.logState('Mock 조회된 배너 정보', {
        'banner_id': banner.id,
        'is_active': banner.isActive,
        'display_order': banner.displayOrder,
        'has_title': banner.title?.isNotEmpty ?? false,
        'has_link_url': banner.linkUrl?.isNotEmpty ?? false,
        'simulation_time_ms': duration.inMilliseconds,
      });

      return banner;
    } catch (e, st) {
      final duration = DateTime.now().difference(startTime);
      AppLogger.logPerformance('Mock 특정 배너 조회 실패', duration);
      
      AppLogger.error('Mock 특정 배너 조회 실패', error: e, stackTrace: st);
      AppLogger.logState('Mock 배너 조회 실패 상세', {
        'banner_id': bannerId,
        'error_type': e.runtimeType.toString(),
        'available_banner_ids': _mockBanners.map((b) => b.id).toList(),
        'simulation_time_ms': duration.inMilliseconds,
      });
      
      rethrow;
    }
  }

  @override
  Future<List<BannerDto>> fetchActiveBanners() async {
    AppLogger.debug('Mock 활성 배너 조회 시작');
    final startTime = DateTime.now();
    
    AppLogger.logState('Mock 활성 배너 조회 설정', {
      'simulated_delay_ms': 100,
      'filter_criteria': 'active=true, date_range_valid=true',
      'data_source': 'mock',
    });
    
    // 필터링된 데이터 조회 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 100)); // 600ms → 100ms

    final now = DateTime.now();

    AppLogger.logStep(1, 2, '배너 활성 상태 및 날짜 범위 필터링');
    // 서버에서 필터링해서 보내주는 것을 시뮬레이션
    final activeBanners = _mockBanners.where((banner) {
      final isActive = banner.isActive == true;
      final isDateValid = (banner.startDate?.isBefore(now) ?? false) &&
          (banner.endDate?.isAfter(now) ?? false);
      
      return isActive && isDateValid;
    }).toList();

    AppLogger.logStep(2, 2, '활성 배너 필터링 결과 처리');
    final duration = DateTime.now().difference(startTime);
    AppLogger.logPerformance('Mock 활성 배너 조회', duration);
    
    AppLogger.ui('Mock 활성 배너 조회 완료: ${activeBanners.length}개');
    AppLogger.logState('Mock 활성 배너 결과', {
      'total_banners': _mockBanners.length,
      'active_banners': activeBanners.length,
      'filtered_out': _mockBanners.length - activeBanners.length,
      'filter_date': now.toIso8601String(),
      'simulation_time_ms': duration.inMilliseconds,
    });
    
    if (activeBanners.isNotEmpty) {
      AppLogger.logState('활성 배너 목록', {
        'banner_ids': activeBanners.map((b) => b.id).toList(),
        'display_orders': activeBanners.map((b) => b.displayOrder).toList(),
      });
    } else {
      AppLogger.warning('현재 활성화된 배너가 없음');
    }

    return activeBanners;
  }

  // Mock 데이터 정의 - assets 이미지 사용
  static final List<BannerDto> _mockBanners = [
    BannerDto(
      id: 'banner_001',
      title: '',
      imageUrl: 'assets/images/banner_001.png', // assets 이미지 사용
      linkUrl: 'https://example.com/developer-program',
      isActive: true,
      displayOrder: 1,
      startDate: DateTime.now().subtract(const Duration(days: 1)),
      endDate: DateTime.now().add(const Duration(days: 30)),
      targetAudience: 'developer',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    BannerDto(
      id: 'banner_002',
      title: '',
      imageUrl: 'assets/images/banner_002.png', // assets 이미지 사용
      linkUrl: 'https://example.com/flutter-masterclass',
      isActive: true,
      displayOrder: 2,
      startDate: DateTime.now().subtract(const Duration(hours: 12)),
      endDate: DateTime.now().add(const Duration(days: 15)),
      targetAudience: 'flutter_developer',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    BannerDto(
      id: 'banner_003',
      title: '',
      imageUrl: 'assets/images/banner_003.png', // assets 이미지 사용
      linkUrl: 'https://example.com/ai-bootcamp',
      isActive: true,
      displayOrder: 3,
      startDate: DateTime.now().subtract(const Duration(hours: 6)),
      endDate: DateTime.now().add(const Duration(days: 45)),
      targetAudience: 'ai_developer',
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
    ),
    BannerDto(
      id: 'banner_004',
      title: ' ',
      imageUrl: 'assets/images/banner_004.png', // assets 이미지 사용
      linkUrl: 'https://example.com/inactive',
      isActive: false,
      displayOrder: 4,
      startDate: DateTime.now().subtract(const Duration(days: 5)),
      endDate: DateTime.now().add(const Duration(days: 10)),
      targetAudience: 'developer',
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
    ),
    BannerDto(
      id: 'banner_005',
      title: '',
      imageUrl: 'assets/images/banner_005.png', // assets 이미지 사용
      linkUrl: 'https://example.com/expired',
      isActive: true,
      displayOrder: 5,
      startDate: DateTime.now().subtract(const Duration(days: 10)),
      endDate: DateTime.now().subtract(const Duration(days: 1)),
      targetAudience: 'developer',
      createdAt: DateTime.now().subtract(const Duration(days: 11)),
    ),
  ];
}