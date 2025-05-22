// // import 'package:cached_network_image/cached_network_image.dart'; // 기본 Image.network 사용으로 제거 // 패키지 없으면 주석 처리
import 'package:flutter/material.dart' hide Banner;
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/styles/app_color_styles.dart';
import '../../../core/styles/app_text_styles.dart';
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
        data: (banner) => banner != null
            ? _buildBannerContent(banner, bannerNotifier)
            : _buildEmptyState(),
        loading: () => _buildLoadingState(),
        error: (error, stack) => _buildErrorState(bannerNotifier),
      ),
    );
  }

  Widget _buildBannerContent(Banner banner, BannerNotifier bannerNotifier) {
    return GestureDetector(
      onTap: () => bannerNotifier.onAction(
        BannerAction.onTapBanner(banner.id, banner.linkUrl),
      ),
      child: Stack(
        children: [
          // 배너 이미지 - Flutter 기본 Image.network 사용
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.network(
              banner.imageUrl,
              width: 380,
              height: 220,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return _buildImageLoadingState();
              },
              errorBuilder: (context, error, stackTrace) {
                return _buildImageErrorState();
              },
            ),
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

          // 배너 제목 (하단 오버레이)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Text(
                banner.title,
                style: AppTextStyles.subtitle1Bold.copyWith(
                  color: Colors.white,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageLoadingState() {
    return Container(
      width: 380,
      height: 220,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            AppColorStyles.primary80,
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
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            '이미지를 불러올 수 없습니다',
            style: AppTextStyles.body2Regular.copyWith(
              color: Colors.grey.shade600,
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
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColorStyles.primary80,
              ),
              strokeWidth: 2,
            ),
            const SizedBox(height: 16),
            Text(
              '광고를 불러오는 중...',
              style: AppTextStyles.body2Regular.copyWith(
                color: Colors.grey.shade600,
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
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.campaign_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            '현재 표시할 광고가 없습니다',
            style: AppTextStyles.body1Regular.copyWith(
              color: Colors.grey.shade600,
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
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            '광고를 불러오는데 실패했습니다',
            style: AppTextStyles.body1Regular.copyWith(
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => bannerNotifier.onAction(
              const BannerAction.refreshBanners(),
            ),
            child: Text(
              '다시 시도',
              style: AppTextStyles.button2Regular.copyWith(
                color: Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}