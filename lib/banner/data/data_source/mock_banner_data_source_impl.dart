import 'banner_data_source.dart';
import '../dto/banner_dto.dart';

class MockBannerDataSourceImpl implements BannerDataSource {
  @override
  Future<List<BannerDto>> fetchAllBanners() async {
    // 네트워크 지연 시뮬레이션 - 실제적인 시간으로 단축
    await Future.delayed(const Duration(milliseconds: 150)); // 800ms → 150ms

    return _mockBanners;
  }

  @override
  Future<BannerDto> fetchBannerById(String bannerId) async {
    // 캐시된 데이터 조회 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 50)); // 500ms → 50ms

    final banner = _mockBanners.firstWhere(
          (banner) => banner.id == bannerId,
      orElse: () => throw Exception('배너를 찾을 수 없습니다: $bannerId'),
    );

    return banner;
  }

  @override
  Future<List<BannerDto>> fetchActiveBanners() async {
    // 필터링된 데이터 조회 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 100)); // 600ms → 100ms

    final now = DateTime.now();

    // 서버에서 필터링해서 보내주는 것을 시뮬레이션
    return _mockBanners.where((banner) {
      return banner.isActive == true &&
          (banner.startDate?.isBefore(now) ?? false) &&
          (banner.endDate?.isAfter(now) ?? false);
    }).toList();
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