// lib/auth/data/data_source/mock_auth_data_source.dart
import 'dart:async';

import 'auth_data_source.dart';

class MockAuthDataSource implements AuthDataSource {
  Map<String, dynamic>? _currentUser;

  @override
  Future<Map<String, dynamic>> fetchLogin({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (email == 'test@example.com' && password == 'password123') {
      _currentUser = {'id': '0', 'email': email, 'nickname': 'MockUser'};
      return _currentUser!;
    } else {
      throw Exception('Invalid credentials');
    }
  }

  @override
  Future<Map<String, dynamic>> createUser({
    required String email,
    required String password,
    required String nickname,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (email == 'duplicate@example.com') {
      throw Exception('Email already exists');
    }
    _currentUser = {'id': '1', 'email': email, 'nickname': nickname};
    return _currentUser!;
  }

  @override
  Future<Map<String, dynamic>?> fetchCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _currentUser;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
  }

  @override
  Future<bool> checkNicknameAvailability(String nickname) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // 사용 중인 닉네임 목록 (테스트용)
    final takenNicknames = ['test', 'admin', 'user', 'devlink', 'MockUser'];
    return !takenNicknames.contains(nickname.toLowerCase());
  }

  @override
  Future<bool> checkEmailAvailability(String email) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // 사용 중인 이메일 목록 (테스트용)
    final takenEmails = ['test@example.com', 'admin@example.com', 'user@example.com', 'duplicate@example.com'];
    return !takenEmails.contains(email.toLowerCase());
  }
}