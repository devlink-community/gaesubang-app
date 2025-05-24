// lib/auth/data/repository_impl/auth_core_repository_impl.dart
import 'package:devlink_mobile_app/auth/data/data_source/auth_data_source.dart';
import 'package:devlink_mobile_app/auth/data/mapper/terms_mapper.dart';
import 'package:devlink_mobile_app/auth/data/mapper/user_mapper.dart';
import 'package:devlink_mobile_app/auth/domain/model/terms_agreement.dart';
import 'package:devlink_mobile_app/auth/domain/model/user.dart';
import 'package:devlink_mobile_app/auth/domain/repository/auth_core_repository.dart';
import 'package:devlink_mobile_app/core/auth/auth_state.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/core/utils/exception_mappers/auth_exception_mapper.dart';

class AuthCoreRepositoryImpl implements AuthCoreRepository {
  final AuthDataSource _authDataSource;

  AuthCoreRepositoryImpl({
    required AuthDataSource authDataSource,
  }) : _authDataSource = authDataSource;

  @override
  Future<Result<User>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _authDataSource.fetchLogin(
        email: email,
        password: password,
      );
      final user = response.toUser();
      return Result.success(user);
    } catch (e, st) {
      return Result.error(AuthExceptionMapper.mapAuthException(e, st));
    }
  }

  @override
  Future<Result<User>> signup({
    required String email,
    required String password,
    required String nickname,
    required TermsAgreement termsAgreement, // TermsAgreement 객체로 변경
  }) async {
    try {
      final response = await _authDataSource.createUser(
        email: email,
        password: password,
        nickname: nickname,
        termsMap: termsAgreement.toUserDtoMap(), // TermsAgreement 객체 전달
      );
      final user = response.toUser();
      return Result.success(user);
    } catch (e, st) {
      return Result.error(AuthExceptionMapper.mapAuthException(e, st));
    }
  }

  @override
  Future<Result<User>> getCurrentUser() async {
    try {
      final response = await _authDataSource.fetchCurrentUser();
      if (response == null) {
        return Result.error(
          Failure(FailureType.unauthorized, '로그인이 필요합니다'),
        );
      }
      final user = response.toUser();
      return Result.success(user);
    } catch (e, st) {
      return Result.error(AuthExceptionMapper.mapAuthException(e, st));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _authDataSource.signOut();
      return const Result.success(null);
    } catch (e, st) {
      return Result.error(AuthExceptionMapper.mapAuthException(e, st));
    }
  }

  @override
  Future<Result<void>> resetPassword(String email) async {
    try {
      await _authDataSource.sendPasswordResetEmail(email);
      return const Result.success(null);
    } catch (e, st) {
      return Result.error(AuthExceptionMapper.mapAuthException(e, st));
    }
  }

  @override
  Future<Result<void>> deleteAccount(String email) async {
    try {
      await _authDataSource.deleteAccount(email);
      return const Result.success(null);
    } catch (e, st) {
      return Result.error(AuthExceptionMapper.mapAuthException(e, st));
    }
  }

  @override
  Future<Result<bool>> checkNicknameAvailability(String nickname) async {
    try {
      final isAvailable = await _authDataSource.checkNicknameAvailability(
        nickname,
      );
      return Result.success(isAvailable);
    } catch (e, st) {
      return Result.error(AuthExceptionMapper.mapAuthException(e, st));
    }
  }

  @override
  Future<Result<bool>> checkEmailAvailability(String email) async {
    try {
      final isAvailable = await _authDataSource.checkEmailAvailability(email);
      return Result.success(isAvailable);
    } catch (e, st) {
      return Result.error(AuthExceptionMapper.mapAuthException(e, st));
    }
  }

  @override
  Stream<AuthState> get authStateChanges {
    return _authDataSource.authStateChanges
        .map((userData) {
          if (userData == null) {
            return const AuthState.unauthenticated();
          }
          final user = userData.toUser();
          return AuthState.authenticated(user);
        })
        .handleError((error, stackTrace) {
          AppLogger.error('인증 상태 스트림 에러', error: error, stackTrace: stackTrace);
          return const AuthState.unauthenticated();
        });
  }

  @override
  Future<AuthState> getCurrentAuthState() async {
    try {
      final userData = await _authDataSource.getCurrentAuthState();
      if (userData == null) {
        return const AuthState.unauthenticated();
      }
      final user = userData.toUser();
      return AuthState.authenticated(user);
    } catch (e, st) {
      AppLogger.error('현재 인증 상태 확인 실패', error: e, stackTrace: st);
      return const AuthState.unauthenticated();
    }
  }
}
