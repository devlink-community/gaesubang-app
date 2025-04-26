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
      _currentUser = {
        'id': 'mock-user-id',
        'email': email,
        'nickname': 'MockUser',
      };
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
    _currentUser = {
      'id': 'mock-new-user-id',
      'email': email,
      'nickname': nickname,
    };
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
}
