import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../auth/data/data_source/mock_auth_data_source.dart';
import '../../auth/data/data_source/mock_profile_data_source.dart';
import '../data/data_source/mock_focus_time_data_source_impl.dart';
import '../data/repository_impl/profile_repository_impl.dart';
import '../domain/repository/profile_repository.dart';
import '../domain/use_case/fetch_profile_data_use_case.dart';
import '../domain/use_case/fetch_profile_stats_use_case.dart';

/// DataSource Providers
final authDataSourceProvider = Provider<MockAuthDataSource>(
  (ref) => MockAuthDataSource(),
);
final profileDataSourceProvider = Provider<MockProfileDataSource>(
  (ref) => MockProfileDataSource(),
);
final focusTimeDataSourceProvider = Provider<MockFocusTimeDataSourceImpl>(
  (ref) => MockFocusTimeDataSourceImpl(),
);

/// Repository Provider
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final authDs = ref.watch(authDataSourceProvider);
  final profileDs = ref.watch(profileDataSourceProvider);
  final focusDs = ref.watch(focusTimeDataSourceProvider);

  return ProfileRepositoryImpl(
    authDataSource: authDs,
    profileDataSource: profileDs,
    focusDataSource: focusDs,
  );
});

/// UseCase Providers
final fetchProfileUserUseCaseProvider = Provider<FetchProfileUserUseCase>(
  (ref) => FetchProfileUserUseCase(ref.watch(profileRepositoryProvider)),
);

final fetchProfileStatsUseCaseProvider = Provider<FetchProfileStatsUseCase>(
  (ref) => FetchProfileStatsUseCase(ref.watch(profileRepositoryProvider)),
);
