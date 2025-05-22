import 'banner_data_source.dart';
import '../dto/banner_dto.dart';

class MockBannerDataSourceImpl implements BannerDataSource {
  @override
  Future<List<BannerDto>> fetchAllBanners() async {
    // 네트워크 지연 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 800));

    return _mockBanners;
  }

  @override
  Future<BannerDto> fetchBannerById(String bannerId) async {
    // 네트워크 지연 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 500));

    final banner = _mockBanners.firstWhere(
          (banner) => banner.id == bannerId,
      orElse: () => throw Exception('배너를 찾을 수 없습니다: $bannerId'),
    );

    return banner;
  }

  @override
  Future<List<BannerDto>> fetchActiveBanners() async {
    // 네트워크 지연 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 600));

    return _mockBanners.where((banner) => banner.isActive == true).toList();
  }

  // Mock 데이터 정의
  static final List<BannerDto> _mockBanners = [
    BannerDto(
      id: 'banner_001',
      title: '개발자 성장 프로그램',
      imageUrl: 'https://picsum.photos/380/220?random=1',
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
      title: 'Flutter 마스터 클래스',
      imageUrl: 'https://picsum.photos/380/220?random=2',
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
      title: 'AI 개발 부트캠프',
      imageUrl: 'https://picsum.photos/380/220?random=3',
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
      title: '비활성화된 배너',
      imageUrl: 'https://picsum.photos/380/220?random=4',
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
      title: '기간 만료된 배너',
      imageUrl: 'https://picsum.photos/380/220?random=5',
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