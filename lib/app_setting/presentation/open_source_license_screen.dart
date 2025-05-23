import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../oss_licenses.dart';
import '../../core/styles/app_color_styles.dart';
import '../../core/styles/app_text_styles.dart';
import '../../core/utils/app_logger.dart';

class OpenSourceLicenseScreen extends StatefulWidget {
  const OpenSourceLicenseScreen({super.key});

  @override
  State<OpenSourceLicenseScreen> createState() =>
      _OpenSourceLicenseScreenState();
}

class _OpenSourceLicenseScreenState extends State<OpenSourceLicenseScreen> {
  List<Package>? _packages;
  bool _loading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    AppLogger.info('OpenSourceLicenseScreen 초기화', tag: 'OpenSourceLicense');
    _loadLicenses();

    // 검색 컨트롤러 리스너 설정
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });

      if (_searchQuery.isNotEmpty) {
        AppLogger.debug('라이센스 검색: $_searchQuery', tag: 'OpenSourceLicense');
      }
    });
  }

  @override
  void dispose() {
    AppLogger.debug(
      'OpenSourceLicenseScreen dispose',
      tag: 'OpenSourceLicense',
    );
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _loadLicenses() {
    final startTime = DateTime.now();
    AppLogger.info('라이센스 정보 로드 시작', tag: 'OpenSourceLicense');

    try {
      // 라이센스 정보 로드 (allDependencies 사용)
      final packages = List<Package>.from(allDependencies);

      // 알파벳 순으로 정렬
      packages.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

      final duration = DateTime.now().difference(startTime);
      AppLogger.logPerformance('라이센스 정보 로드 완료', duration);

      AppLogger.logState('라이센스 로드 결과', {
        '총 패키지 수': packages.length,
        '정렬': '알파벳 순',
      });

      setState(() {
        _packages = packages;
        _loading = false;
      });

      AppLogger.info(
        '라이센스 정보 로드 성공: ${packages.length}개 패키지',
        tag: 'OpenSourceLicense',
      );
    } catch (e, stackTrace) {
      final duration = DateTime.now().difference(startTime);
      AppLogger.logPerformance('라이센스 정보 로드 실패', duration);

      AppLogger.error(
        '라이센스 정보 로드 실패',
        tag: 'OpenSourceLicense',
        error: e,
        stackTrace: stackTrace,
      );

      setState(() {
        _packages = [];
        _loading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('라이센스 정보를 불러오는데 실패했습니다: $e')),
        );
      }
    }
  }

  List<Package> get _filteredPackages {
    if (_searchQuery.isEmpty) return _packages ?? [];

    final filtered =
        _packages
            ?.where(
              (package) =>
                  package.name.toLowerCase().contains(_searchQuery) ||
                  package.version.toLowerCase().contains(_searchQuery) ||
                  (package.repository?.toLowerCase().contains(_searchQuery) ??
                      false),
            )
            .toList() ??
        [];

    AppLogger.debug(
      '검색 결과: $_searchQuery -> ${filtered.length}개 패키지',
      tag: 'OpenSourceLicense',
    );

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('오픈소스 라이센스', style: AppTextStyles.heading6Bold),
        automaticallyImplyLeading: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 검색 창
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: '패키지 검색...',
                prefixIcon: const Icon(Icons.search, size: 22),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            AppLogger.debug(
                              '검색어 초기화',
                              tag: 'OpenSourceLicense',
                            );
                            _searchController.clear();
                            _searchFocusNode.unfocus();
                          },
                        )
                        : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // 카운트 및 알파벳 순 정보
          if (!_loading && _packages != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Row(
                children: [
                  Text(
                    '총 ${_filteredPackages.length}개',
                    style: AppTextStyles.captionRegular.copyWith(
                      color: AppColorStyles.gray80,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '알파벳 순 정렬',
                    style: AppTextStyles.captionRegular.copyWith(
                      color: AppColorStyles.gray80,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 목록 또는 로딩 표시
          Expanded(
            child:
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildLicenseList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLicenseList() {
    if (_packages == null || _packages!.isEmpty) {
      AppLogger.warning('라이센스 정보가 없음', tag: 'OpenSourceLicense');
      return Center(
        child: Text('라이센스 정보가 없습니다.', style: AppTextStyles.body1Regular),
      );
    }

    final filteredPackages = _filteredPackages;

    if (filteredPackages.isEmpty) {
      AppLogger.debug('검색 결과 없음: $_searchQuery', tag: 'OpenSourceLicense');
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: AppColorStyles.gray60),
            const SizedBox(height: 16),
            Text(
              '검색 결과가 없습니다',
              style: AppTextStyles.subtitle1Medium.copyWith(
                color: AppColorStyles.gray80,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredPackages.length,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemBuilder: (context, index) {
        final package = filteredPackages[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: AppColorStyles.gray40.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              AppLogger.info(
                '라이센스 상세 보기: ${package.name}',
                tag: 'OpenSourceLicense',
              );
              _showLicenseDetail(package);
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 패키지 아이콘 (첫 글자 기반)
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _getColorForPackage(package.name),
                    child: Text(
                      package.name.substring(0, 1).toUpperCase(),
                      style: AppTextStyles.subtitle1Bold.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // 패키지 정보
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          package.name,
                          style: AppTextStyles.subtitle1Medium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          package.version,
                          style: AppTextStyles.body2Regular.copyWith(
                            color: AppColorStyles.gray80,
                          ),
                        ),
                        if (package.repository != null &&
                            package.repository!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            _formatUrl(package.repository!),
                            style: AppTextStyles.captionRegular.copyWith(
                              color: AppColorStyles.gray80,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // 화살표 아이콘
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColorStyles.gray60,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // URL을 보기 좋게 포맷팅
  String _formatUrl(String url) {
    if (url.isEmpty) return '';

    try {
      final uri = Uri.parse(url);
      // github.com/user/repo 형태로 변환
      if (uri.host.isNotEmpty) {
        if (uri.host == 'github.com') {
          return 'GitHub: ${uri.pathSegments.take(2).join('/')}';
        }
        return uri.host + (uri.path.isNotEmpty ? uri.path : '');
      }
    } catch (e) {
      // parsing 실패시 원본 URL 반환
      AppLogger.debug('URL 파싱 실패: $url', tag: 'OpenSourceLicense');
    }

    return url;
  }

  // 패키지 이름에 기반한 색상 생성
  Color _getColorForPackage(String packageName) {
    final colors = [
      AppColorStyles.primary80,
      AppColorStyles.primary60,
      AppColorStyles.secondary01,
      AppColorStyles.secondary02,
      AppColorStyles.info,
      AppColorStyles.success,
    ];

    // 패키지 이름의 각 문자 ASCII 값의 합
    int sum = 0;
    for (int i = 0; i < packageName.length; i++) {
      sum += packageName.codeUnitAt(i);
    }

    // 색상 배열의 인덱스로 변환
    return colors[sum % colors.length];
  }

  void _showLicenseDetail(Package package) {
    AppLogger.info('라이센스 상세 화면 진입: ${package.name}', tag: 'OpenSourceLicense');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LicenseDetailScreen(package: package),
      ),
    );
  }
}

class LicenseDetailScreen extends StatelessWidget {
  final Package package;

  const LicenseDetailScreen({super.key, required this.package});

  @override
  Widget build(BuildContext context) {
    AppLogger.info('라이센스 상세 화면 빌드: ${package.name}', tag: 'LicenseDetail');

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(package.name, style: AppTextStyles.heading6Bold),
        automaticallyImplyLeading: true,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 패키지 헤더 섹션
                  Row(
                    children: [
                      // 패키지 아이콘
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: _getColorForPackage(package.name),
                        child: Text(
                          package.name.substring(0, 1).toUpperCase(),
                          style: AppTextStyles.heading6Bold.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // 패키지 기본 정보
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              package.name,
                              style: AppTextStyles.heading6Bold,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'v${package.version}',
                              style: AppTextStyles.body1Regular.copyWith(
                                color: AppColorStyles.primary100,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 링크 섹션
                  if (package.repository != null &&
                      package.repository!.isNotEmpty)
                    _buildLinkItem(
                      context: context,
                      icon: Icons.code,
                      label: '저장소',
                      url: package.repository!,
                    ),

                  if (package.homepage != null &&
                      package.homepage!.isNotEmpty &&
                      package.homepage != package.repository)
                    _buildLinkItem(
                      context: context,
                      icon: Icons.language,
                      label: '홈페이지',
                      url: package.homepage!,
                    ),

                  const SizedBox(height: 24),

                  // 라이센스 내용 헤더
                  Text('라이센스', style: AppTextStyles.heading6Bold),
                  const SizedBox(height: 12),

                  // 라이센스 내용 카드
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: AppColorStyles.gray40.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SelectableText(
                        package.license ?? '라이센스 정보가 없습니다.',
                        style: AppTextStyles.body2Regular,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String url,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          AppLogger.info('외부 링크 클릭: $label - $url', tag: 'LicenseDetail');
          _launchUrl(url);
        },
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColorStyles.primary100.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColorStyles.primary100, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.subtitle1Medium),
                  Text(
                    url,
                    style: AppTextStyles.body2Regular.copyWith(
                      color: AppColorStyles.primary100,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.open_in_new, color: AppColorStyles.gray60, size: 18),
          ],
        ),
      ),
    );
  }

  // 패키지 이름에 기반한 색상 생성
  Color _getColorForPackage(String packageName) {
    final colors = [
      AppColorStyles.primary80,
      AppColorStyles.primary60,
      AppColorStyles.secondary01,
      AppColorStyles.secondary02,
      AppColorStyles.info,
      AppColorStyles.success,
    ];

    // 패키지 이름의 각 문자 ASCII 값의 합
    int sum = 0;
    for (int i = 0; i < packageName.length; i++) {
      sum += packageName.codeUnitAt(i);
    }

    // 색상 배열의 인덱스로 변환
    return colors[sum % colors.length];
  }

  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) return;

    final uri = Uri.parse(url);
    try {
      AppLogger.info('URL 실행 시도: $url', tag: 'LicenseDetail');

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        AppLogger.info('URL 실행 성공: $url', tag: 'LicenseDetail');
      } else {
        AppLogger.warning('URL을 열 수 없습니다: $url', tag: 'LicenseDetail');
      }
    } catch (e) {
      AppLogger.error(
        'URL 실행 오류',
        tag: 'LicenseDetail',
        error: e,
      );
    }
  }
}
