import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../home/data/data_source/banner_firebase_data_source_impl.dart';
import '../data/data_source/banner_data_source.dart';
import '../data/data_source/mock_banner_data_source_impl.dart';
import '../data/repository_impl/banner_repository_impl.dart';
import '../domain/repository/banner_repository.dart';
import '../domain/usecase/get_active_banners_use_case.dart';

part 'banner_di.g.dart';

// DataSource Provider - 현재 Mock 사용 (Firebase는 구현만 완료)
@riverpod
BannerDataSource bannerDataSource(Ref ref) => MockBannerDataSourceImpl();

// Firebase DataSource Provider - 구현 완료, 추후 전환 시 사용
@riverpod
BannerDataSource firebaseBannerDataSource(Ref ref) => BannerFirebaseDataSourceImpl();

// Repository Provider
@riverpod
BannerRepository bannerRepository(Ref ref) =>
    BannerRepositoryImpl(dataSource: ref.watch(bannerDataSourceProvider));

// UseCase Provider
@riverpod
GetActiveBannersUseCase getActiveBannersUseCase(Ref ref) =>
    GetActiveBannersUseCase(repository: ref.watch(bannerRepositoryProvider));