import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../domain/model/banner.dart';

part 'banner_state.freezed.dart';

@freezed
class BannerState with _$BannerState {
  const BannerState({
    this.activeBanner = const AsyncLoading(),
    this.lastUpdated,
  });

  final AsyncValue<Banner?> activeBanner;
  final DateTime? lastUpdated;
}