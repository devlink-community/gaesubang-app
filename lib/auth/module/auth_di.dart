// lib/auth/module/auth_di.dart
import 'package:devlink_mobile_app/auth/data/data_source/auth_data_source.dart';
import 'package:devlink_mobile_app/auth/data/data_source/auth_firebase_data_source.dart';
import 'package:devlink_mobile_app/auth/data/data_source/mock_auth_data_source.dart';
import 'package:devlink_mobile_app/auth/data/repository_impl/auth_activity_repository_impl.dart';
import 'package:devlink_mobile_app/auth/data/repository_impl/auth_core_repository_impl.dart';
import 'package:devlink_mobile_app/auth/data/repository_impl/auth_fcm_repository_impl.dart';
import 'package:devlink_mobile_app/auth/data/repository_impl/auth_profile_repository_impl.dart';
import 'package:devlink_mobile_app/auth/data/repository_impl/auth_terms_repository_impl.dart';
import 'package:devlink_mobile_app/auth/domain/repository/auth_activity_repository.dart';
import 'package:devlink_mobile_app/auth/domain/repository/auth_core_repository.dart';
import 'package:devlink_mobile_app/auth/domain/repository/auth_fcm_repository.dart';
import 'package:devlink_mobile_app/auth/domain/repository/auth_profile_repository.dart';
import 'package:devlink_mobile_app/auth/domain/repository/auth_terms_repository.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/core/check_email_availability_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/core/check_nickname_availability_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/core/delete_account_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/core/get_current_user_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/core/login_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/core/reset_password_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/core/signout_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/core/signup_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/profile/get_user_profile_usecase.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/profile/update_profile_image_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/profile/update_profile_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/terms/clear_terms_from_memory_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/terms/get_terms_from_memory_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/terms/get_terms_info_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/terms/save_terms_agreement_use_case.dart';
import 'package:devlink_mobile_app/core/config/app_config.dart';
import 'package:devlink_mobile_app/notification/service/fcm_token_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_di.g.dart';

// === DataSource Providers ===

@riverpod
AuthDataSource authDataSource(Ref ref) {
  if (AppConfig.useMockAuth) {
    return MockAuthDataSource();
  }
  return AuthFirebaseDataSource();
}

// === Repository Providers ===

@riverpod
AuthCoreRepository authCoreRepository(Ref ref) {
  return AuthCoreRepositoryImpl(
    authDataSource: ref.watch(authDataSourceProvider),
  );
}

@riverpod
AuthProfileRepository authProfileRepository(Ref ref) {
  return AuthProfileRepositoryImpl(
    authDataSource: ref.watch(authDataSourceProvider),
  );
}

@riverpod
AuthActivityRepository authActivityRepository(Ref ref) {
  return AuthActivityRepositoryImpl(
    authDataSource: ref.watch(authDataSourceProvider),
  );
}

@riverpod
AuthTermsRepository authTermsRepository(Ref ref) {
  return AuthTermsRepositoryImpl(
    authDataSource: ref.watch(authDataSourceProvider),
  );
}

@riverpod
AuthFCMRepository authFCMRepository(Ref ref) {
  return AuthFCMRepositoryImpl(
    fcmTokenService: ref.watch(fcmTokenServiceProvider),
  );
}

// === UseCase Providers ===

@riverpod
LoginUseCase loginUseCase(Ref ref) {
  return LoginUseCase(
    repository: ref.watch(authCoreRepositoryProvider),
    fcmTokenService: ref.watch(fcmTokenServiceProvider),
  );
}

@riverpod
SignupUseCase signupUseCase(Ref ref) {
  return SignupUseCase(
    repository: ref.watch(authCoreRepositoryProvider),
  );
}

@riverpod
GetCurrentUserUseCase getCurrentUserUseCase(Ref ref) {
  return GetCurrentUserUseCase(
    repository: ref.watch(authCoreRepositoryProvider),
  );
}

@riverpod
SignoutUseCase signoutUseCase(Ref ref) {
  return SignoutUseCase(
    repository: ref.watch(authCoreRepositoryProvider),
  );
}

@riverpod
ResetPasswordUseCase resetPasswordUseCase(Ref ref) {
  return ResetPasswordUseCase(
    repository: ref.watch(authCoreRepositoryProvider),
  );
}

@riverpod
DeleteAccountUseCase deleteAccountUseCase(Ref ref) {
  return DeleteAccountUseCase(
    repository: ref.watch(authCoreRepositoryProvider),
  );
}

@riverpod
CheckEmailAvailabilityUseCase checkEmailAvailabilityUseCase(Ref ref) {
  return CheckEmailAvailabilityUseCase(
    repository: ref.watch(authCoreRepositoryProvider),
  );
}

@riverpod
CheckNicknameAvailabilityUseCase checkNicknameAvailabilityUseCase(Ref ref) {
  return CheckNicknameAvailabilityUseCase(
    repository: ref.watch(authCoreRepositoryProvider),
  );
}

@riverpod
GetUserProfileUseCase getUserProfileUseCase(Ref ref) {
  return GetUserProfileUseCase(
    repository: ref.watch(authProfileRepositoryProvider),
  );
}

@riverpod
UpdateProfileUseCase updateProfileUseCase(Ref ref) {
  return UpdateProfileUseCase(
    repository: ref.watch(authProfileRepositoryProvider),
  );
}

@riverpod
UpdateProfileImageUseCase updateProfileImageUseCase(Ref ref) {
  return UpdateProfileImageUseCase(
    ref.watch(authProfileRepositoryProvider),
  );
}

@riverpod
GetTermsInfoUseCase getTermsInfoUseCase(Ref ref) {
  return GetTermsInfoUseCase(
    repository: ref.watch(authTermsRepositoryProvider),
  );
}

@riverpod
SaveTermsAgreementUseCase saveTermsAgreementUseCase(Ref ref) {
  return SaveTermsAgreementUseCase(
    repository: ref.watch(authTermsRepositoryProvider),
  );
}

@riverpod
GetTermsFromMemoryUseCase getTermsFromMemoryUseCase(Ref ref) {
  return GetTermsFromMemoryUseCase(
    repository: ref.watch(authTermsRepositoryProvider),
  );
}

@riverpod
ClearTermsFromMemoryUseCase clearTermsFromMemoryUseCase(Ref ref) {
  return ClearTermsFromMemoryUseCase(
    repository: ref.watch(authTermsRepositoryProvider),
  );
}

// === FCM Token Service Provider ===

@riverpod
FCMTokenService fcmTokenService(Ref ref) {
  return FCMTokenService();
}
