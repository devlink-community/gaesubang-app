// lib/core/component/app_image.dart
import 'dart:io';

import 'package:flutter/material.dart';

/// 이미지 경로 타입에 따라 자동으로 적절한 이미지 위젯을 반환하는 공통 컴포넌트입니다.
/// - assets/, asset/ 로 시작: Asset 이미지
/// - http://, https:// 로 시작: 네트워크 이미지
/// - file:// 또는 / 로 시작: 로컬 파일 이미지
///
/// Image.asset, Image.network, Image.file 위젯과 완전히 호환됩니다.
/// 메모리 관리와 성능 최적화를 위한 기능 포함:
/// - 네트워크 이미지 캐싱
/// - 비동기 로딩
/// - 에러 처리 및 플레이스홀더
/// - 기본 이미지 폴백 처리
class AppImage extends StatelessWidget {
  /// 이미지 경로 (asset, network, file)
  final String? path;

  /// 기본 이미지 경로 (path 로드 실패 시 사용, asset만 지원)
  final String? defaultImagePath;

  /// 이미지 키 (이미지 캐싱 및 구분에 사용)
  final String? imageKey;

  /// 이미지 스케일
  final double scale;

  /// 이미지 너비
  final double? width;

  /// 이미지 높이
  final double? height;

  /// 이미지 색상
  final Color? color;

  /// 색상 혼합 모드
  final BlendMode? colorBlendMode;

  /// BoxFit 속성
  final BoxFit? fit;

  /// 정렬 방식
  final Alignment alignment;

  /// 이미지 반복 옵션
  final ImageRepeat repeat;

  /// 중심점 유지 여부
  final bool centerSlice;

  /// 반전 적용 여부
  final bool matchTextDirection;

  /// 게스쳐 확대/축소 컨트롤러
  final bool gaplessPlayback;

  /// 의미론적 라벨 (접근성)
  final String? semanticLabel;

  /// Asset 번들
  final AssetBundle? bundle;

  /// 패키지 이름 (Asset에서 사용)
  final String? package;

  /// 이미지 품질 필터
  final FilterQuality filterQuality;

  /// 이미지 로드 중 표시할 위젯
  final Widget? loadingWidget;

  /// 이미지 로드 실패 시 표시할 위젯
  final Widget? errorWidget;

  /// 이미지 경로가 없거나 null일 때 표시할 위젯
  final Widget? placeholderWidget;

  /// 테두리 반경
  final BorderRadius? borderRadius;

  /// 메모리 캐시 사용 여부
  final bool useMemoryCache;

  /// 이미지 캐시 너비
  final int? cacheWidth;

  /// 이미지 캐시 높이
  final int? cacheHeight;

  /// HTTP 헤더 (네트워크 이미지)
  final Map<String, String>? headers;

  /// 최대 너비 (픽셀)
  final int? maxWidth;

  /// 최대 높이 (픽셀)
  final int? maxHeight;

  /// 앱 내장 기본 이미지 플레이스홀더 타입
  final AppImagePlaceholder placeholderType;

  const AppImage({
    super.key,
    required this.path,
    this.defaultImagePath,
    this.imageKey,
    this.scale = 1.0,
    this.width,
    this.height,
    this.color,
    this.colorBlendMode,
    this.fit,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.centerSlice = false,
    this.matchTextDirection = false,
    this.gaplessPlayback = false,
    this.semanticLabel,
    this.bundle,
    this.package,
    this.filterQuality = FilterQuality.low,
    this.loadingWidget,
    this.errorWidget,
    this.placeholderWidget,
    this.borderRadius,
    this.useMemoryCache = true,
    this.cacheWidth,
    this.cacheHeight,
    this.headers,
    this.maxWidth,
    this.maxHeight,
    this.placeholderType = AppImagePlaceholder.imageIcon,
  });

  /// 내장 기본 이미지가 있는 AppImage 생성 (경로 없이)
  const AppImage.placeholder({
    super.key,
    this.width,
    this.height,
    this.fit,
    this.borderRadius,
    this.color,
    this.placeholderType = AppImagePlaceholder.imageIcon,
  }) : path = null,
       defaultImagePath = null,
       imageKey = null,
       scale = 1.0,
       colorBlendMode = null,
       alignment = Alignment.center,
       repeat = ImageRepeat.noRepeat,
       centerSlice = false,
       matchTextDirection = false,
       gaplessPlayback = false,
       semanticLabel = null,
       bundle = null,
       package = null,
       filterQuality = FilterQuality.low,
       loadingWidget = null,
       errorWidget = null,
       placeholderWidget = null,
       useMemoryCache = true,
       cacheWidth = null,
       cacheHeight = null,
       headers = null,
       maxWidth = null,
       maxHeight = null;

  /// 프로필 이미지용 원형 이미지 생성 간편 생성자
  static Widget profile({
    required String? imagePath,
    String? defaultImagePath,
    double size = 40,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    return AppImage(
      path: imagePath,
      defaultImagePath: defaultImagePath,
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(size / 2),
      placeholderType: AppImagePlaceholder.person,
      placeholderWidget: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.grey.shade200,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.person,
          size: size * 0.6,
          color: foregroundColor ?? Colors.grey.shade400,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 이미지 경로가 없는 경우 플레이스홀더 표시
    if (path == null || path!.isEmpty) {
      return _buildEmptyPlaceholder();
    }

    // 테두리 반경이 있는 경우 ClipRRect로 감싸기
    final Widget imageWidget = _buildImageBasedOnPath();

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }

    return imageWidget;
  }

  /// 이미지 경로에 따라 적절한 이미지 위젯 반환
  Widget _buildImageBasedOnPath() {
    // 최종 캐시 크기 계산
    final int? finalCacheWidth = cacheWidth ?? _calculateCacheSize(width);
    final int? finalCacheHeight = cacheHeight ?? _calculateCacheSize(height);

    // Asset 이미지
    if (path!.startsWith('assets/') || path!.startsWith('asset/')) {
      return Image.asset(
        path!,
        key: imageKey != null ? Key(imageKey!) : null,
        scale: scale,
        width: width,
        height: height,
        color: color,
        colorBlendMode: colorBlendMode,
        fit: fit,
        alignment: alignment,
        repeat: repeat,
        centerSlice: centerSlice ? const Rect.fromLTRB(0, 0, 0, 0) : null,
        matchTextDirection: matchTextDirection,
        gaplessPlayback: gaplessPlayback,
        semanticLabel: semanticLabel,
        package: package,
        filterQuality: filterQuality,
        cacheWidth: finalCacheWidth,
        cacheHeight: finalCacheHeight,
        bundle: bundle,
        errorBuilder: _defaultImageErrorBuilder,
        frameBuilder: _frameBuilder,
      );
    }
    // 네트워크 이미지
    else if (path!.startsWith('http://') || path!.startsWith('https://')) {
      return Image.network(
        path!,
        key: imageKey != null ? Key(imageKey!) : null,
        scale: scale,
        width: width,
        height: height,
        color: color,
        colorBlendMode: colorBlendMode,
        fit: fit,
        alignment: alignment,
        repeat: repeat,
        centerSlice: centerSlice ? const Rect.fromLTRB(0, 0, 0, 0) : null,
        matchTextDirection: matchTextDirection,
        gaplessPlayback: gaplessPlayback,
        semanticLabel: semanticLabel,
        filterQuality: filterQuality,
        cacheWidth: finalCacheWidth,
        cacheHeight: finalCacheHeight,
        headers: headers,
        errorBuilder: _defaultImageErrorBuilder,
        frameBuilder: _frameBuilder,
        loadingBuilder: _loadingBuilder,
      );
    }
    // 로컬 파일 이미지
    else if (path!.startsWith('file://') || path!.startsWith('/')) {
      String filePath = path!;
      if (filePath.startsWith('file://')) {
        filePath = filePath.replaceFirst('file://', '');
      }

      return Image.file(
        File(filePath),
        key: imageKey != null ? Key(imageKey!) : null,
        scale: scale,
        width: width,
        height: height,
        color: color,
        colorBlendMode: colorBlendMode,
        fit: fit,
        alignment: alignment,
        repeat: repeat,
        centerSlice: centerSlice ? const Rect.fromLTRB(0, 0, 0, 0) : null,
        matchTextDirection: matchTextDirection,
        gaplessPlayback: gaplessPlayback,
        semanticLabel: semanticLabel,
        filterQuality: filterQuality,
        cacheWidth: finalCacheWidth,
        cacheHeight: finalCacheHeight,
        errorBuilder: _defaultImageErrorBuilder,
        frameBuilder: _frameBuilder,
      );
    }

    // 기타 경우 (지원하지 않는 경로)
    return _buildImageWithFallback();
  }

  /// 캐시 사이즈 계산 (메모리 최적화)
  int? _calculateCacheSize(double? size) {
    if (size == null || !useMemoryCache) return null;

    // 화면 픽셀 밀도를 고려한 최적화된 캐시 사이즈 계산
    final double pixelRatio =
        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    return (size * pixelRatio).round();
  }

  /// 기본 이미지 사용하는 에러 빌더
  Widget Function(BuildContext, Object, StackTrace?)
  get _defaultImageErrorBuilder {
    return (BuildContext context, Object error, StackTrace? stackTrace) {
      // 사용자 정의 에러 위젯이 있으면 사용
      if (errorWidget != null) {
        return errorWidget!;
      }

      // 기본 이미지 경로가 있으면 Asset 이미지 표시
      if (defaultImagePath != null && defaultImagePath!.isNotEmpty) {
        return Image.asset(
          defaultImagePath!,
          width: width,
          height: height,
          fit: fit,
          color: color,
          colorBlendMode: colorBlendMode,
          alignment: alignment,
          package: package,
          cacheWidth: cacheWidth ?? _calculateCacheSize(width),
          cacheHeight: cacheHeight ?? _calculateCacheSize(height),
          errorBuilder: (context, error, stack) => _buildPlaceholderImage(),
        );
      }

      // 둘 다 없으면 기본 플레이스홀더 표시
      return _buildPlaceholderImage();
    };
  }

  /// 폴백 이미지 처리 (defaultImagePath 사용)
  Widget _buildImageWithFallback() {
    // 폴백 이미지가 있으면 사용
    if (defaultImagePath != null && defaultImagePath!.isNotEmpty) {
      return Image.asset(
        defaultImagePath!,
        width: width,
        height: height,
        fit: fit,
        color: color,
        colorBlendMode: colorBlendMode,
        alignment: alignment,
        package: package,
        cacheWidth: cacheWidth ?? _calculateCacheSize(width),
        cacheHeight: cacheHeight ?? _calculateCacheSize(height),
        errorBuilder: (context, error, stack) => _buildPlaceholderImage(),
      );
    }

    // 없으면 플레이스홀더
    return _buildPlaceholderImage();
  }

  /// 플레이스홀더 이미지 (타입에 따라 다른 아이콘 표시)
  Widget _buildPlaceholderImage() {
    // 사용자 정의 플레이스홀더가 있으면 사용
    if (placeholderWidget != null) {
      return placeholderWidget!;
    }

    final IconData iconData = _getPlaceholderIcon();
    final double iconSize =
        (width != null && height != null)
            ? min((width! * 0.5), (height! * 0.5))
            : 24;

    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade100,
      child: Center(
        child: Icon(iconData, color: Colors.grey.shade300, size: iconSize),
      ),
    );
  }

  /// 빈 이미지를 위한 플레이스홀더
  Widget _buildEmptyPlaceholder() {
    return placeholderWidget ?? _buildPlaceholderImage();
  }

  /// 플레이스홀더 타입에 따른 아이콘 선택
  IconData _getPlaceholderIcon() {
    switch (placeholderType) {
      case AppImagePlaceholder.person:
        return Icons.person;
      case AppImagePlaceholder.image:
        return Icons.image;
      case AppImagePlaceholder.brokenImage:
        return Icons.broken_image;
      case AppImagePlaceholder.imageIcon:
      default:
        return Icons.image_outlined;
    }
  }

  /// 프레임 빌더 - 이미지 로드 완료될 때까지 전환 효과
  Widget Function(BuildContext, Widget, int?, bool) get _frameBuilder {
    return (
      BuildContext context,
      Widget child,
      int? frame,
      bool wasSynchronouslyLoaded,
    ) {
      if (wasSynchronouslyLoaded) return child;

      return AnimatedOpacity(
        opacity: frame == null ? 0 : 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        child: child,
      );
    };
  }

  /// 로딩 빌더 - 네트워크 이미지 로딩 중 표시
  Widget Function(BuildContext, Widget, ImageChunkEvent?) get _loadingBuilder {
    return (
      BuildContext context,
      Widget child,
      ImageChunkEvent? loadingProgress,
    ) {
      if (loadingProgress == null) return child;

      return loadingWidget ??
          Center(
            child: SizedBox(
              width: (width != null) ? width! * 0.3 : 20,
              height: (width != null) ? width! * 0.3 : 20,
              child: CircularProgressIndicator(
                value:
                    loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                strokeWidth: 2,
                color: Colors.grey.shade400,
              ),
            ),
          );
    };
  }

  // lib/core/component/app_image.dart에 다음 메서드를 추가

  /// 여러 이미지를 미리 캐싱하는 정적 메서드
  static Future<void> precacheImages(
    List<String> imagePaths,
    BuildContext context,
  ) async {
    for (final path in imagePaths) {
      if (path.isEmpty) continue;

      try {
        if (path.startsWith('http://') || path.startsWith('https://')) {
          await precacheImage(NetworkImage(path), context);
        } else if (path.startsWith('assets/') || path.startsWith('asset/')) {
          await precacheImage(AssetImage(path), context);
        } else if (path.startsWith('file://') || path.startsWith('/')) {
          String filePath = path;
          if (filePath.startsWith('file://')) {
            filePath = filePath.replaceFirst('file://', '');
          }
          await precacheImage(FileImage(File(filePath)), context);
        }
      } catch (e) {
        // 이미지 사전 로딩 중 오류가 발생해도 다른 이미지에 영향을 주지 않도록 처리
        debugPrint('이미지 사전 캐싱 오류: $e');
      }
    }
  }

  /// 최소값 계산 헬퍼 함수
  double min(double a, double b) => a < b ? a : b;
}

/// 플레이스홀더 이미지 타입
enum AppImagePlaceholder {
  /// 일반 이미지 아이콘
  imageIcon,

  /// 이미지 아이콘 (Filled)
  image,

  /// 깨진 이미지 아이콘
  brokenImage,

  /// 사람 아이콘 (프로필 이미지용)
  person,
}
