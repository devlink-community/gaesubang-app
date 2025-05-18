import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/module/auth_di.dart';
import '../data/repository_impl/edit_intro_repository_impl.dart';
import '../domain/repository/edit_intro_repository.dart';
import '../domain/use_case/get_current_profile_usecase.dart';
import '../domain/use_case/update_profile_image_usecase.dart';
import '../domain/use_case/update_profile_usecase.dart';

part 'edit_intro_di.g.dart';

// Repository Provider
@riverpod
EditIntroRepository editIntroRepository(Ref ref) {
  return EditIntroRepositoryImpl(
    authDataSource: ref.watch(authDataSourceProvider),
    profileDataSource: ref.watch(profileDataSourceProvider),
  );
}

// UseCase Providers
@riverpod
GetCurrentProfileUseCase getCurrentProfileUseCase(Ref ref) {
  return GetCurrentProfileUseCase(ref.watch(editIntroRepositoryProvider));
}

@riverpod
UpdateProfileUseCase updateProfileUseCase(Ref ref) {
  return UpdateProfileUseCase(ref.watch(editIntroRepositoryProvider));
}

@riverpod
UpdateProfileImageUseCase updateProfileImageUseCase(Ref ref) {
  return UpdateProfileImageUseCase(ref.watch(editIntroRepositoryProvider));
}
