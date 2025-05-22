// lib/auth/module/auth_di.dart
import 'package:devlink_mobile_app/auth/domain/usecase/update_profile_image_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/update_profile_use_case.dart';
import 'package:devlink_mobile_app/core/firebase/firebase_providers.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:devlink_mobile_app/notification/module/fcm_di.dart';

import '../../core/config/app_config.dart';
import '../../profile/presentation/user_profile/get_user_profile_usecase.dart';
import '../data/data_source/auth_data_source.dart';
import '../data/data_source/auth_firebase_data_source.dart';
import '../data/data_source/mock_auth_data_source.dart';
import '../data/repository_impl/auth_repository_impl.dart';
import '../domain/repository/auth_repository.dart';
import '../domain/usecase/check_email_availability_use_case.dart';
import '../domain/usecase/check_nickname_availability_use_case.dart';
import '../domain/usecase/delete_account_use_case.dart';
import '../domain/usecase/get_current_user_use_case.dart';
import '../domain/usecase/get_terms_info_use_case.dart';
import '../domain/usecase/login_use_case.dart';
import '../domain/usecase/mock_login_user_case.dart';
import '../domain/usecase/reset_password_use_case.dart';
import '../domain/usecase/save_terms_agreement_use_case.dart';
import '../domain/usecase/signout_use_case.dart';
import '../domain/usecase/signup_use_case.dart';

part 'auth_di.g.dart';

// === Firebase Providers ===

/// Firebase Storage 인스턴스 Provider
@Riverpod(keepAlive: true)
FirebaseStorage firebaseStorage(Ref ref) {
  return FirebaseStorage.instance;
}

// === DataSource Providers ===

/// AuthDataSource - 플래그에 따라 Mock 또는 Firebase 선택
@riverpod
AuthDataSource authDataSource(Ref ref) {
  if (AppConfig.useMockAuth) {
    return MockAuthDataSource();
  } else {
    return AuthFirebaseDataSource(
      auth: ref.watch(firebaseAuthProvider),
      firestore: ref.watch(firebaseFirestoreProvider),
      storage: ref.watch(firebaseStorageProvider), // FirebaseStorage 추가
    );
  }
}

// === Repository Providers ===

// 리포지토리 제공 - FCMTokenService 주입 추가
@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepositoryImpl(
    authDataSource: ref.watch(authDataSourceProvider),
    fcmTokenService: ref.watch(fcmTokenServiceProvider), // FCM 서비스 주입
  );
}

// === UseCase Providers === (나머지는 동일)

// LoginUseCase 프로바이더 수정 - FCMTokenService 주입 추가
@riverpod
LoginUseCase loginUseCase(Ref ref) {
  return LoginUseCase(
    repository: ref.watch(authRepositoryProvider),
    fcmTokenService: ref.watch(fcmTokenServiceProvider), // FCM 서비스 주입
  );
}

@riverpod
SignupUseCase signupUseCase(Ref ref) {
  return SignupUseCase(repository: ref.watch(authRepositoryProvider));
}

@riverpod
GetCurrentUserUseCase getCurrentUserUseCase(Ref ref) {
  return GetCurrentUserUseCase(repository: ref.watch(authRepositoryProvider));
}

@riverpod
SignoutUseCase signoutUseCase(Ref ref) {
  return SignoutUseCase(repository: ref.watch(authRepositoryProvider));
}

@riverpod
CheckNicknameAvailabilityUseCase checkNicknameAvailabilityUseCase(Ref ref) {
  return CheckNicknameAvailabilityUseCase(
    repository: ref.watch(authRepositoryProvider),
  );
}

@riverpod
CheckEmailAvailabilityUseCase checkEmailAvailabilityUseCase(Ref ref) {
  return CheckEmailAvailabilityUseCase(
    repository: ref.watch(authRepositoryProvider),
  );
}

@riverpod
ResetPasswordUseCase resetPasswordUseCase(Ref ref) {
  return ResetPasswordUseCase(repository: ref.watch(authRepositoryProvider));
}

@riverpod
DeleteAccountUseCase deleteAccountUseCase(Ref ref) {
  return DeleteAccountUseCase(repository: ref.watch(authRepositoryProvider));
}

@riverpod
GetTermsInfoUseCase getTermsInfoUseCase(Ref ref) {
  return GetTermsInfoUseCase(repository: ref.watch(authRepositoryProvider));
}

@riverpod
SaveTermsAgreementUseCase saveTermsAgreementUseCase(Ref ref) {
  return SaveTermsAgreementUseCase(
    repository: ref.watch(authRepositoryProvider),
  );
}

// === Profile UseCase Providers ===

@riverpod
UpdateProfileUseCase updateProfileUseCase(Ref ref) {
  return UpdateProfileUseCase(repository: ref.watch(authRepositoryProvider));
}

@riverpod
UpdateProfileImageUseCase updateProfileImageUseCase(
  Ref ref,
) {
  return UpdateProfileImageUseCase(ref.watch(authRepositoryProvider));
}

@riverpod
GetUserProfileUseCase getUserProfileUseCase(Ref ref) =>
    GetUserProfileUseCase(repository: ref.watch(authRepositoryProvider));
