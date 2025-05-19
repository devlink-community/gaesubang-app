// lib/auth/module/auth_di.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/config/app_config.dart';
import '../../profile/domain/use_case/fetch_profile_data_use_case.dart';
import '../../profile/domain/use_case/fetch_profile_stats_use_case.dart';
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
import '../domain/usecase/validate_email_use_case.dart';
import '../domain/usecase/validate_nickname_use_case.dart';
import '../domain/usecase/validate_password_confirm_use_case.dart';
import '../domain/usecase/validate_password_use_case.dart';
import '../domain/usecase/validate_terms_agreement_use_case.dart';

part 'auth_di.g.dart';

// === DataSource Providers ===

/// AuthDataSource - 플래그에 따라 Mock 또는 Firebase 선택
@riverpod
AuthDataSource authDataSource(Ref ref) {
  if (AppConfig.useMockAuth) {
    return MockAuthDataSource();
  } else {
    return AuthFirebaseDataSource(
      auth: FirebaseAuth.instance,
      firestore: FirebaseFirestore.instance,
    );
  }
}

// === Repository Providers ===

@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepositoryImpl(authDataSource: ref.watch(authDataSourceProvider));
}

// === UseCase Providers ===

/// LoginUseCase - 플래그에 따라 실제 또는 Mock 로그인
@riverpod
LoginUseCase loginUseCase(Ref ref) {
  if (AppConfig.useMockAuth) {
    return MockLoginUseCase();
  } else {
    return LoginUseCase(repository: ref.watch(authRepositoryProvider));
  }
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

// === Validation UseCase Providers ===

@riverpod
ValidateNicknameUseCase validateNicknameUseCase(Ref ref) {
  return ValidateNicknameUseCase();
}

@riverpod
ValidateEmailUseCase validateEmailUseCase(Ref ref) {
  return ValidateEmailUseCase();
}

@riverpod
ValidatePasswordUseCase validatePasswordUseCase(Ref ref) {
  return ValidatePasswordUseCase();
}

@riverpod
ValidatePasswordConfirmUseCase validatePasswordConfirmUseCase(Ref ref) {
  return ValidatePasswordConfirmUseCase();
}

@riverpod
ValidateTermsAgreementUseCase validateTermsAgreementUseCase(Ref ref) {
  return ValidateTermsAgreementUseCase();
}

// === Profile UseCase Providers ===

@riverpod
FetchProfileUserUseCase fetchProfileUserUseCase(Ref ref) {
  return FetchProfileUserUseCase(ref.watch(authRepositoryProvider));
}

@riverpod
FetchProfileStatsUseCase fetchProfileStatsUseCase(Ref ref) {
  return FetchProfileStatsUseCase();
}
