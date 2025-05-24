import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart' hide Banner;
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/styles/app_color_styles.dart';
import '../../../core/styles/app_text_styles.dart';
import '../../../core/utils/app_logger.dart';
import '../../domain/model/banner.dart';
import '../banner_action.dart';
import '../banner_notifier.dart';

class AdvertisementBanner extends ConsumerWidget {
  const AdvertisementBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannerState = ref.watch(bannerNotifierProvider);
    final bannerNotifier = ref.watch(bannerNotifierProvider.notifier);

    return Container(
      width: 380,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: -3,
          ),
        ],
      ),
      child: bannerState.activeBanner.when(
        data:
            (banner) =>
                banner != null
                    ? _buildBannerContent(banner, bannerNotifier)
                    : _buildEmptyState(),
        loading: () => _buildLoadingState(),
        error: (error, stack) => _buildErrorState(bannerNotifier),
      ),
    );
  }

  Widget _buildBannerContent(Banner banner, BannerNotifier bannerNotifier) {
    // 🔧 URL 유효성 검사 추가
    if (banner.imageUrl.isEmpty) {
      AppLogger.warning(
        '빈 배너 이미지 URL 감지: ${banner.id}',
        tag: 'AdvertisementBanner',
      );
      return _buildEmptyState();
    }

    return GestureDetector(
      onTap:
          () => bannerNotifier.onAction(
            BannerAction.onTapBanner(banner.id, banner.linkUrl),
          ),
      child: Stack(
        children: [
          // 🔧 배너 이미지 - 안전한 이미지 로딩
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: _buildSafeImage(banner),
          ),

          // AD 라벨
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'AD',
                style: AppTextStyles.captionRegular.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ),

          // 배너 제목 제거 - 이미지만 표시
        ],
      ),
    );
  }

  // 🔧 안전한 이미지 빌더 메서드 추가
  Widget _buildSafeImage(Banner banner) {
    final imageUrl = banner.imageUrl;

    // Assets 이미지 처리
    if (imageUrl.startsWith('assets/') || imageUrl.startsWith('asset/')) {
      AppLogger.debug('배너 Asset 이미지 로드: $imageUrl', tag: 'AdvertisementBanner');
      return Image.asset(
        imageUrl,
        width: 380,
        height: 220,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          AppLogger.error(
            '배너 Asset 이미지 로드 실패: $imageUrl',
            tag: 'AdvertisementBanner',
            error: error,
            stackTrace: stackTrace,
          );
          return _buildImageErrorState();
        },
      );
    }

    // 네트워크 이미지 처리 - HTTP/HTTPS 검증 추가
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      AppLogger.debug('배너 네트워크 이미지 로드: $imageUrl', tag: 'AdvertisementBanner');
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: 380,
        height: 220,
        fit: BoxFit.cover,
        memCacheWidth: 380, // 메모리 최적화
        memCacheHeight: 220,
        placeholder: (context, url) => _buildImageLoadingState(),
        errorWidget: (context, url, error) {
          AppLogger.error(
            '배너 네트워크 이미지 로드 실패: $url',
            tag: 'AdvertisementBanner',
            error: error,
          );
          return _buildImageErrorState();
        },
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 100),
      );
    }

    // 잘못된 URL 형식 처리
    AppLogger.warning(
      '잘못된 배너 이미지 URL 형식: $imageUrl (배너 ID: ${banner.id})',
      tag: 'AdvertisementBanner',
    );
    return _buildImageErrorState();
  }

  Widget _buildImageLoadingState() {
    return Container(
      width: 380,
      height: 220,
      decoration: BoxDecoration(
        color: AppColorStyles.gray40,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            AppColorStyles.primary100,
          ),
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildImageErrorState() {
    return Container(
      width: 380,
      height: 220,
      decoration: BoxDecoration(
        color: AppColorStyles.gray40,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColorStyles.gray60),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 48,
            color: AppColorStyles.gray100,
          ),
          const SizedBox(height: 8),
          Text(
            '이미지를 불러올 수 없습니다',
            style: AppTextStyles.body2Regular.copyWith(
              color: AppColorStyles.gray100,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      width: 380,
      height: 220,
      decoration: BoxDecoration(
        color: AppColorStyles.gray40,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColorStyles.primary100,
              ),
              strokeWidth: 2,
            ),
            const SizedBox(height: 16),
            Text(
              '광고를 불러오는 중...',
              style: AppTextStyles.body2Regular.copyWith(
                color: AppColorStyles.gray100,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: 380,
      height: 220,
      decoration: BoxDecoration(
        color: AppColorStyles.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColorStyles.gray40),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.campaign_outlined,
            size: 48,
            color: AppColorStyles.gray80,
          ),
          const SizedBox(height: 12),
          Text(
            '현재 표시할 광고가 없습니다',
            style: AppTextStyles.body1Regular.copyWith(
              color: AppColorStyles.gray100,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BannerNotifier bannerNotifier) {
    return Container(
      width: 380,
      height: 220,
      decoration: BoxDecoration(
        color: AppColorStyles.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColorStyles.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: AppColorStyles.error,
          ),
          const SizedBox(height: 12),
          Text(
            '광고를 불러오는데 실패했습니다',
            style: AppTextStyles.body1Regular.copyWith(
              color: AppColorStyles.error,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed:
                () => bannerNotifier.onAction(
                  const BannerAction.refreshBanners(),
                ),
            child: Text(
              '다시 시도',
              style: AppTextStyles.button2Regular.copyWith(
                color: AppColorStyles.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
