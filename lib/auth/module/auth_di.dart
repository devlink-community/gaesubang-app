import 'package:devlink_mobile_app/auth/data/data_source/auth_data_source.dart';
import 'package:devlink_mobile_app/auth/data/data_source/mock_auth_data_source.dart';
import 'package:devlink_mobile_app/auth/data/data_source/mock_profile_data_source.dart';
import 'package:devlink_mobile_app/auth/data/data_source/profile_data_source.dart';
import 'package:devlink_mobile_app/auth/data/repository_impl/auth_repository_impl.dart';
import 'package:devlink_mobile_app/auth/domain/repository/auth_repository.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/check_email_availability_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/check_nickname_availability_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/delete_account_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/login_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/mock_login_user_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/reset_password_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/signup_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/validate_email_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/validate_nickname_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/validate_password_confirm_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/validate_password_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/validate_terms_agreement_use_case.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/usecase/get_current_user_use_case.dart';
import '../domain/usecase/get_terms_info_use_case.dart';
import '../domain/usecase/save_terms_agreement_use_case.dart';

part 'auth_di.g.dart';

// ---------------- DI 부분 ----------------

// AuthDataSource 의존성 주입
@riverpod
AuthDataSource authDataSource(Ref ref) => MockAuthDataSource();

// ProfileDataSource 의존성 주입
@riverpod
ProfileDataSource profileDataSource(Ref ref) => MockProfileDataSource();

@riverpod
AuthRepository authRepository(Ref ref) => AuthRepositoryImpl(
  authDataSource: ref.watch(authDataSourceProvider),
  profileDataSource: ref.watch(profileDataSourceProvider),
);

// 로그인 관련 UseCase
@riverpod
LoginUseCase loginUseCase(Ref ref) =>
    LoginUseCase(repository: ref.watch(authRepositoryProvider));

@riverpod
LoginUseCase mockLoginUseCase(Ref ref) {
  return MockLoginUseCase();
}

// 회원가입 관련 UseCase
@riverpod
SignupUseCase signupUseCase(Ref ref) =>
    SignupUseCase(repository: ref.watch(authRepositoryProvider));

@riverpod
CheckNicknameAvailabilityUseCase checkNicknameAvailabilityUseCase(Ref ref) =>
    CheckNicknameAvailabilityUseCase(
      repository: ref.watch(authRepositoryProvider),
    );

@riverpod
CheckEmailAvailabilityUseCase checkEmailAvailabilityUseCase(Ref ref) =>
    CheckEmailAvailabilityUseCase(
      repository: ref.watch(authRepositoryProvider),
    );

@riverpod
ValidateNicknameUseCase validateNicknameUseCase(Ref ref) =>
    ValidateNicknameUseCase();

@riverpod
ValidateEmailUseCase validateEmailUseCase(Ref ref) => ValidateEmailUseCase();

@riverpod
ValidatePasswordUseCase validatePasswordUseCase(Ref ref) =>
    ValidatePasswordUseCase();

@riverpod
ValidatePasswordConfirmUseCase validatePasswordConfirmUseCase(Ref ref) =>
    ValidatePasswordConfirmUseCase();

@riverpod
ValidateTermsAgreementUseCase validateTermsAgreementUseCase(Ref ref) =>
    ValidateTermsAgreementUseCase();

@riverpod
ResetPasswordUseCase resetPasswordUseCase(Ref ref) =>
    ResetPasswordUseCase(repository: ref.watch(authRepositoryProvider));

// 계정삭제 관련 UseCase
@riverpod
DeleteAccountUseCase deleteAccountUseCase(Ref ref) =>
    DeleteAccountUseCase(repository: ref.watch(authRepositoryProvider));

@riverpod
GetTermsInfoUseCase getTermsInfoUseCase(Ref ref) =>
    GetTermsInfoUseCase(repository: ref.watch(authRepositoryProvider));

@riverpod
SaveTermsAgreementUseCase saveTermsAgreementUseCase(Ref ref) =>
    SaveTermsAgreementUseCase(repository: ref.watch(authRepositoryProvider));

@riverpod
GetCurrentUserUseCase getCurrentUserUseCase(Ref ref) =>
    GetCurrentUserUseCase(repository: ref.watch(authRepositoryProvider));
