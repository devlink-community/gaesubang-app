import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/data_source/banner_data_source.dart';
import '../data/data_source/mock_banner_data_source_impl.dart';
import '../data/data_source/banner_firebase_data_source_impl.dart';
import '../data/repository_impl/banner_repository_impl.dart';
import '../domain/repository/banner_repository.dart';
import '../domain/usecase/get_active_banners_use_case.dart';

part 'banner_di.g.dart';

// DataSource Provider - Firebase 구현체로 전환
@riverpod
BannerDataSource bannerDataSource(Ref ref) => BannerFirebaseDataSourceImpl();

// Mock DataSource Provider - 테스트 및 개발용
@riverpod
BannerDataSource mockBannerDataSource(Ref ref) => MockBannerDataSourceImpl();

// Repository Provider
@riverpod
BannerRepository bannerRepository(Ref ref) =>
    BannerRepositoryImpl(dataSource: ref.watch(bannerDataSourceProvider));

// UseCase Provider
@riverpod
GetActiveBannersUseCase getActiveBannersUseCase(Ref ref) =>
    GetActiveBannersUseCase(repository: ref.watch(bannerRepositoryProvider));