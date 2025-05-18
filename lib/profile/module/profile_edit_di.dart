import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/module/auth_di.dart';
import '../data/repository_impl/profile_edit_repository_impl.dart';
import '../domain/repository/profile_edit_repository.dart';
import '../domain/use_case/get_current_profile_usecase.dart';
import '../domain/use_case/update_profile_image_usecase.dart';
import '../domain/use_case/update_profile_usecase.dart';

part 'profile_edit_di.g.dart';

// Repository Provider
@riverpod
ProfileEditRepository profileEditRepository(Ref ref) {
  return ProfileEditRepositoryImpl(
    authDataSource: ref.watch(authDataSourceProvider),
    profileDataSource: ref.watch(profileDataSourceProvider),
  );
}

// UseCase Providers
@riverpod
GetCurrentProfileUseCase getCurrentProfileUseCase(Ref ref) {
  return GetCurrentProfileUseCase(ref.watch(profileEditRepositoryProvider));
}

@riverpod
UpdateProfileUseCase updateProfileUseCase(Ref ref) {
  return UpdateProfileUseCase(ref.watch(profileEditRepositoryProvider));
}

@riverpod
UpdateProfileImageUseCase updateProfileImageUseCase(Ref ref) {
  return UpdateProfileImageUseCase(ref.watch(profileEditRepositoryProvider));
}
