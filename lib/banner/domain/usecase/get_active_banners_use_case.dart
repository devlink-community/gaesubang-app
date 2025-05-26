import 'dart:math';

import 'package:devlink_mobile_app/core/utils/time_formatter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/result/result.dart';
import '../model/banner.dart';
import '../repository/banner_repository.dart';

class GetActiveBannersUseCase {
  final BannerRepository _repository;
  final Random _random = Random();

  GetActiveBannersUseCase({required BannerRepository repository})
    : _repository = repository;

  /// 활성 배너 중 랜덤하게 하나를 선택하여 반환
  /// 시간대별 시드를 사용하여 1분마다 다른 배너가 선택되도록 함 (테스트용)
  Future<AsyncValue<Banner?>> execute() async {
    final result = await _repository.getActiveBanners();

    switch (result) {
      case Success(:final data):
        if (data.isEmpty) {
          return const AsyncData(null);
        }

        // 현재 시간 기준 활성 배너 필터링
        final now = TimeFormatter.nowInSeoul();
        final activeBanners =
            data.where((banner) {
              return banner.isActive &&
                  banner.startDate.isBefore(now) &&
                  banner.endDate.isAfter(now);
            }).toList();

        if (activeBanners.isEmpty) {
          return const AsyncData(null);
        }

        // 시간대별 랜덤 시드 생성 (1분 단위 - 테스트용)
        final timeSlot = _generateTimeSlot(now);
        final selectedBanner = _selectRandomBanner(activeBanners, timeSlot);

        return AsyncData(selectedBanner);

      case Error(:final failure):
        return AsyncError(failure, failure.stackTrace ?? StackTrace.current);
    }
  }

  /// 1분 단위로 시간 슬롯 생성 (테스트용)
  int _generateTimeSlot(DateTime now) {
    // 년월일 + 시간 + 분으로 시드 생성
    final year = now.year;
    final month = now.month;
    final day = now.day;
    final hour = now.hour;
    final minute = now.second ~/ 20; // 분 단위로 변경

    return year * 100000000 +
        month * 1000000 +
        day * 10000 +
        hour * 100 +
        minute;
  }

  /// 시간 슬롯을 시드로 사용하여 배너 랜덤 선택
  Banner _selectRandomBanner(List<Banner> banners, int timeSlot) {
    // displayOrder로 정렬 후 랜덤 선택
    banners.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    // 시간 슬롯을 시드로 사용
    final random = Random(timeSlot);
    final selectedIndex = random.nextInt(banners.length);

    return banners[selectedIndex];
  }
}
