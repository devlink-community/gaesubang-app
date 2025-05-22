// lib/auth/data/data_source/mock_auth_data_source.dart
import 'dart:async';

import 'package:devlink_mobile_app/core/utils/messages/auth_error_messages.dart';
import 'package:flutter/foundation.dart';

import '../../../core/utils/api_call_logger.dart';
import '../dto/user_dto.dart';
import 'auth_data_source.dart';

class MockAuthDataSource implements AuthDataSource {
  // 단순한 메모리 저장소 - Firebase 스키마와 일치
  static final Map<String, Map<String, dynamic>> _users = {};
  static final Map<String, String> _passwords = {};
  static final Map<String, List<Map<String, dynamic>>> _timerActivities = {};
  static final Map<String, Map<String, dynamic>> _termsAgreements = {};
  static String? _currentUserId;

  // 인증 상태 스트림 컨트롤러 (추가)
  static final StreamController<Map<String, dynamic>?> _authStateController =
      StreamController<Map<String, dynamic>?>.broadcast();

  // 기본 사용자 7명 초기화
  static void _initializeDefaultUsers() {
    if (_users.isNotEmpty) return;

    final defaultUsers = [
      {
        'uid': 'user1',
        'email': 'test1@example.com',
        'nickname': '사용자1',
        'image':
            'https://i.pinimg.com/236x/31/fd/53/31fd53b6dc87e714783b5c52531ba6fb.jpg',
        'description': '안녕하세요! 열심히 공부하고 있습니다.',
        'onAir': false,
        'position': '프론트엔드 개발자',
        'skills': 'Flutter, React, JavaScript',
        'streakDays': 7,
        'agreedTermId': 'terms_001',
        'isServiceTermsAgreed': true,
        'isPrivacyPolicyAgreed': true,
        'isMarketingAgreed': true,
        'agreedAt': DateTime.now().subtract(const Duration(days: 30)),
        'joingroup': [],
      },
      {
        'uid': 'user2',
        'email': 'test2@example.com',
        'nickname': '사용자2',
        'image': '',
        'description': '백엔드 개발을 공부하고 있어요!',
        'onAir': true,
        'position': '백엔드 개발자',
        'skills': 'Java, Spring, MySQL',
        'streakDays': 12,
        'agreedTermId': 'terms_002',
        'isServiceTermsAgreed': true,
        'isPrivacyPolicyAgreed': true,
        'isMarketingAgreed': false,
        'agreedAt': DateTime.now().subtract(const Duration(days: 25)),
        'joingroup': [],
      },
      {
        'uid': 'user3',
        'email': 'test3@example.com',
        'nickname': '사용자3',
        'image': 'https://picsum.photos/200?random=3',
        'description': '데이터 분석가가 되고 싶어요.',
        'onAir': false,
        'position': '데이터 분석가',
        'skills': 'Python, Pandas, SQL',
        'streakDays': 5,
        'agreedTermId': 'terms_003',
        'isServiceTermsAgreed': true,
        'isPrivacyPolicyAgreed': true,
        'isMarketingAgreed': true,
        'agreedAt': DateTime.now().subtract(const Duration(days: 20)),
        'joingroup': [],
      },
      {
        'uid': 'user4',
        'email': 'test4@example.com',
        'nickname': '사용자4',
        'image': 'https://picsum.photos/200?random=4',
        'description': 'iOS 앱 개발을 배우고 있습니다.',
        'onAir': true,
        'position': 'iOS 개발자',
        'skills': 'Swift, UIKit, SwiftUI',
        'streakDays': 3,
        'agreedTermId': 'terms_004',
        'isServiceTermsAgreed': true,
        'isPrivacyPolicyAgreed': true,
        'isMarketingAgreed': false,
        'agreedAt': DateTime.now().subtract(const Duration(days: 15)),
        'joingroup': [],
      },
      {
        'uid': 'user5',
        'email': 'test5@example.com',
        'nickname': '사용자5',
        'image': 'https://picsum.photos/200?random=5',
        'description': '풀스택 개발자를 목표로 하고 있어요.',
        'onAir': false,
        'position': '풀스택 개발자',
        'skills': 'Vue.js, Node.js, MongoDB',
        'streakDays': 15,
        'agreedTermId': 'terms_005',
        'isServiceTermsAgreed': true,
        'isPrivacyPolicyAgreed': true,
        'isMarketingAgreed': true,
        'agreedAt': DateTime.now().subtract(const Duration(days: 40)),
        'joingroup': [],
      },
      {
        'uid': 'user6',
        'email': 'admin@example.com',
        'nickname': '관리자',
        'image': 'https://picsum.photos/200?random=6',
        'description': '서비스 관리자입니다.',
        'onAir': true,
        'position': '서비스 관리자',
        'skills': 'DevOps, AWS, Docker',
        'streakDays': 25,
        'agreedTermId': 'terms_006',
        'isServiceTermsAgreed': true,
        'isPrivacyPolicyAgreed': true,
        'isMarketingAgreed': true,
        'agreedAt': DateTime.now().subtract(const Duration(days: 50)),
        'joingroup': [],
      },
      {
        'uid': 'user7',
        'email': 'developer@example.com',
        'nickname': '개발자',
        'image': 'https://picsum.photos/200?random=7',
        'description': '개발이 취미이자 직업입니다.',
        'onAir': false,
        'position': '시니어 개발자',
        'skills': 'Python, Django, PostgreSQL',
        'streakDays': 30,
        'agreedTermId': 'terms_007',
        'isServiceTermsAgreed': true,
        'isPrivacyPolicyAgreed': true,
        'isMarketingAgreed': false,
        'agreedAt': DateTime.now().subtract(const Duration(days: 60)),
        'joingroup': [],
      },
    ];

    // 사용자 데이터 저장
    for (final userData in defaultUsers) {
      final uid = userData['uid'] as String;
      _users[uid] = Map<String, dynamic>.from(userData);
      _passwords[uid] = 'password123'; // 모든 사용자 동일한 비밀번호

      // 타이머 활동 로그 초기화 (샘플 데이터 포함)
      _timerActivities[uid] = _generateSampleTimerActivities(uid);
    }
  }

  // 샘플 타이머 활동 데이터 생성
  static List<Map<String, dynamic>> _generateSampleTimerActivities(
    String userId,
  ) {
    final activities = <Map<String, dynamic>>[];
    final now = DateTime.now();

    // 최근 7일간의 샘플 활동 생성
    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: i));
      final dayActivities = [60, 90, 45, 120, 75, 180, 30][i]; // 다양한 시간

      activities.add({
        'id': 'activity_${userId}_${day.millisecondsSinceEpoch}',
        'memberId': userId,
        'type': 'start',
        'timestamp': day.subtract(Duration(minutes: dayActivities)),
        'metadata': {'task': '집중 공부', 'device': 'mobile'},
      });

      activities.add({
        'id': 'activity_${userId}_${day.millisecondsSinceEpoch}_end',
        'memberId': userId,
        'type': 'end',
        'timestamp': day,
        'metadata': {'task': '집중 공부', 'device': 'mobile'},
      });
    }

    return activities;
  }

  // 인증 상태 변경 통지 (새로 추가)
  void _notifyAuthStateChanged() {
    if (_currentUserId == null) {
      _authStateController.add(null);
      return;
    }

    _fetchUserWithTimerActivities(_currentUserId!)
        .then((userData) {
          _authStateController.add(userData);
        })
        .catchError((error) {
          debugPrint('인증 상태 변경 통지 에러: $error');
          _authStateController.add(null);
        });
  }

  /// Firebase와 동일하게 사용자 정보와 타이머 활동을 함께 반환하는 메서드
  Future<Map<String, dynamic>?> _fetchUserWithTimerActivities(
    String userId,
  ) async {
    return ApiCallDecorator.wrap(
      'MockAuth.fetchUserWithTimerActivities',
      () async {
        final userData = _users[userId];
        if (userData == null) return null;

        // 타이머 활동 데이터 포함하여 반환
        return {...userData, 'timerActivities': _timerActivities[userId] ?? []};
      },
      params: {'userId': userId},
    );
  }

  @override
  Future<Map<String, dynamic>> fetchLogin({
    required String email,
    required String password,
  }) async {
    return ApiCallDecorator.wrap('MockAuth.fetchLogin', () async {
      await Future.delayed(const Duration(milliseconds: 300));
      _initializeDefaultUsers();

      final lowercaseEmail = email.toLowerCase();

      // 이메일로 사용자 찾기
      final userEntry = _users.entries.firstWhere(
        (entry) => entry.value['email'] == lowercaseEmail,
        orElse: () => throw Exception(AuthErrorMessages.loginFailed),
      );

      final userId = userEntry.key;

      // 비밀번호 확인
      if (_passwords[userId] != password) {
        throw Exception(AuthErrorMessages.loginFailed);
      }

      // 로그인 상태 설정
      _currentUserId = userId;

      // 타이머 활동 포함하여 반환
      final userWithActivities = await _fetchUserWithTimerActivities(userId);
      if (userWithActivities == null) {
        throw Exception(AuthErrorMessages.userDataNotFound);
      }

      // 인증 상태 변경 통지 (추가)
      _notifyAuthStateChanged();

      return userWithActivities;
    }, params: {'email': email});
  }

  @override
  Future<Map<String, dynamic>> createUser({
    required String email,
    required String password,
    required String nickname,
    String? agreedTermsId,
  }) async {
    return ApiCallDecorator.wrap('MockAuth.createUser', () async {
      await Future.delayed(const Duration(milliseconds: 300));
      _initializeDefaultUsers();

      final lowercaseEmail = email.toLowerCase();

      // 약관 동의 확인
      if (agreedTermsId == null || agreedTermsId.isEmpty) {
        throw Exception(AuthErrorMessages.termsNotAgreed);
      }

      // 이메일 중복 확인
      final emailExists = _users.values.any(
        (user) => user['email'] == lowercaseEmail,
      );
      if (emailExists) {
        throw Exception(AuthErrorMessages.emailAlreadyInUse);
      }

      // 닉네임 중복 확인
      final nicknameExists = _users.values.any(
        (user) => user['nickname'] == nickname,
      );
      if (nicknameExists) {
        throw Exception(AuthErrorMessages.nicknameAlreadyInUse);
      }

      // 새 사용자 생성
      final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      final newUserData = {
        'uid': userId,
        'email': lowercaseEmail,
        'nickname': nickname,
        'image': '',
        'description': '',
        'onAir': false,
        'position': '',
        'skills': '',
        'streakDays': 0,
        'agreedTermId': agreedTermsId,
        'isServiceTermsAgreed': true,
        'isPrivacyPolicyAgreed': true,
        'isMarketingAgreed': false,
        'agreedAt': DateTime.now(),
        'joingroup': <Map<String, dynamic>>[],
      };

      _users[userId] = newUserData;
      _passwords[userId] = password;
      _timerActivities[userId] = [];

      // 회원가입 후 자동 로그인 상태로 설정
      _currentUserId = userId;

      // 인증 상태 변경 통지 (추가)
      _notifyAuthStateChanged();

      // 회원가입 시에는 빈 타이머 활동 리스트와 함께 반환
      return {...newUserData, 'timerActivities': []};
    }, params: {'email': email, 'nickname': nickname});
  }

  @override
  Future<Map<String, dynamic>?> fetchCurrentUser() async {
    return ApiCallDecorator.wrap('MockAuth.fetchCurrentUser', () async {
      await Future.delayed(const Duration(milliseconds: 300));
      _initializeDefaultUsers();

      if (_currentUserId == null) return null;

      // 타이머 활동 포함하여 현재 사용자 정보 반환
      return await _fetchUserWithTimerActivities(_currentUserId!);
    });
  }

  @override
  Future<void> signOut() async {
    return ApiCallDecorator.wrap('MockAuth.signOut', () async {
      await Future.delayed(const Duration(milliseconds: 300));
      _currentUserId = null;

      // 인증 상태 변경 통지 (추가)
      _notifyAuthStateChanged();
    });
  }

  @override
  Future<bool> checkNicknameAvailability(String nickname) async {
    return ApiCallDecorator.wrap(
      'MockAuth.checkNicknameAvailability',
      () async {
        await Future.delayed(const Duration(milliseconds: 300));
        _initializeDefaultUsers();

        return !_users.values.any((user) => user['nickname'] == nickname);
      },
      params: {'nickname': nickname},
    );
  }

  @override
  Future<bool> checkEmailAvailability(String email) async {
    return ApiCallDecorator.wrap('MockAuth.checkEmailAvailability', () async {
      await Future.delayed(const Duration(milliseconds: 300));
      _initializeDefaultUsers();

      final lowercaseEmail = email.toLowerCase();
      return !_users.values.any((user) => user['email'] == lowercaseEmail);
    }, params: {'email': email});
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    return ApiCallDecorator.wrap('MockAuth.sendPasswordResetEmail', () async {
      await Future.delayed(const Duration(milliseconds: 300));
      _initializeDefaultUsers();

      final lowercaseEmail = email.toLowerCase();
      final emailExists = _users.values.any(
        (user) => user['email'] == lowercaseEmail,
      );

      if (!emailExists) {
        throw Exception(AuthErrorMessages.userDataNotFound);
      }

      // Mock: 실제로는 이메일 전송
    }, params: {'email': email});
  }

  @override
  Future<void> deleteAccount(String email) async {
    return ApiCallDecorator.wrap('MockAuth.deleteAccount', () async {
      await Future.delayed(const Duration(milliseconds: 300));
      _initializeDefaultUsers();

      final lowercaseEmail = email.toLowerCase();

      // 사용자 찾기
      final userEntry = _users.entries.firstWhere(
        (entry) => entry.value['email'] == lowercaseEmail,
        orElse: () => throw Exception(AuthErrorMessages.userDataNotFound),
      );

      final userId = userEntry.key;

      // 현재 로그인된 사용자인지 확인
      if (_currentUserId != userId) {
        throw Exception(AuthErrorMessages.noLoggedInUser);
      }

      // 사용자 데이터 삭제
      _users.remove(userId);
      _passwords.remove(userId);
      _timerActivities.remove(userId);
      _currentUserId = null;

      // 인증 상태 변경 통지 (추가)
      _notifyAuthStateChanged();
    }, params: {'email': email});
  }

  @override
  Future<Map<String, dynamic>> saveTermsAgreement(
    Map<String, dynamic> termsData,
  ) async {
    return ApiCallDecorator.wrap('MockAuth.saveTermsAgreement', () async {
      await Future.delayed(const Duration(milliseconds: 300));

      // 필수 약관 동의 여부 확인
      final isServiceTermsAgreed =
          termsData['isServiceTermsAgreed'] as bool? ?? false;
      final isPrivacyPolicyAgreed =
          termsData['isPrivacyPolicyAgreed'] as bool? ?? false;

      if (!isServiceTermsAgreed || !isPrivacyPolicyAgreed) {
        throw Exception(AuthErrorMessages.termsNotAgreed);
      }

      // 타임스탬프 추가
      termsData['agreedAt'] = DateTime.now();
      final termsId = termsData['id'] as String;
      _termsAgreements[termsId] = Map<String, dynamic>.from(termsData);

      return Map<String, dynamic>.from(termsData);
    }, params: {'termsId': termsData['id']});
  }

  @override
  Future<Map<String, dynamic>> fetchTermsInfo() async {
    return ApiCallDecorator.wrap('MockAuth.fetchTermsInfo', () async {
      await Future.delayed(const Duration(milliseconds: 300));

      return {
        'id': 'terms_${DateTime.now().millisecondsSinceEpoch}',
        'isAllAgreed': false,
        'isServiceTermsAgreed': false,
        'isPrivacyPolicyAgreed': false,
        'isMarketingAgreed': false,
        'agreedAt': DateTime.now(),
      };
    });
  }

  @override
  Future<Map<String, dynamic>?> getTermsInfo(String termsId) async {
    return ApiCallDecorator.wrap('MockAuth.getTermsInfo', () async {
      await Future.delayed(const Duration(milliseconds: 300));

      final termsInfo = _termsAgreements[termsId];
      return termsInfo != null ? Map<String, dynamic>.from(termsInfo) : null;
    }, params: {'termsId': termsId});
  }

  @override
  Future<List<Map<String, dynamic>>> fetchTimerActivities(String userId) async {
    return ApiCallDecorator.wrap('MockAuth.fetchTimerActivities', () async {
      await Future.delayed(const Duration(milliseconds: 300));
      _initializeDefaultUsers();

      final activities = _timerActivities[userId] ?? [];
      return activities
          .map((activity) => Map<String, dynamic>.from(activity))
          .toList();
    }, params: {'userId': userId});
  }

  @override
  Future<void> saveTimerActivity(
    String userId,
    Map<String, dynamic> activityData,
  ) async {
    return ApiCallDecorator.wrap(
      'MockAuth.saveTimerActivity',
      () async {
        await Future.delayed(const Duration(milliseconds: 300));
        _initializeDefaultUsers();

        final activities = _timerActivities[userId] ?? [];
        activities.add(Map<String, dynamic>.from(activityData));
        _timerActivities[userId] = activities;
      },
      params: {'userId': userId, 'activityType': activityData['type']},
    );
  }

  @override
  Future<Map<String, dynamic>> updateUser({
    required String nickname,
    String? description,
    String? position,
    String? skills,
  }) async {
    return ApiCallDecorator.wrap('MockAuth.updateUser', () async {
      await Future.delayed(const Duration(milliseconds: 300));
      _initializeDefaultUsers();

      if (_currentUserId == null) {
        throw Exception(AuthErrorMessages.noLoggedInUser);
      }

      final currentUser = _users[_currentUserId];
      if (currentUser == null) {
        throw Exception(AuthErrorMessages.userDataNotFound);
      }

      // 현재 닉네임과 다른 경우에만 중복 확인
      final currentNickname = currentUser['nickname'] as String?;
      if (currentNickname != nickname) {
        final nicknameAvailable = await checkNicknameAvailability(nickname);
        if (!nicknameAvailable) {
          throw Exception(AuthErrorMessages.nicknameAlreadyInUse);
        }
      }

      // 사용자 정보 업데이트
      final updatedUser = Map<String, dynamic>.from(currentUser);
      updatedUser['nickname'] = nickname;
      updatedUser['description'] = description ?? '';
      updatedUser['position'] = position ?? '';
      updatedUser['skills'] = skills ?? '';

      _users[_currentUserId!] = updatedUser;

      // 타이머 활동 포함하여 반환
      final userWithActivities = await _fetchUserWithTimerActivities(
        _currentUserId!,
      );
      if (userWithActivities == null) {
        throw Exception(AuthErrorMessages.userDataNotFound);
      }

      // 인증 상태 변경 통지 (추가)
      _notifyAuthStateChanged();

      return userWithActivities;
    }, params: {'nickname': nickname});
  }

  @override
  Future<Map<String, dynamic>> updateUserImage(String imagePath) async {
    return ApiCallDecorator.wrap('MockAuth.updateUserImage', () async {
      await Future.delayed(const Duration(milliseconds: 300));
      _initializeDefaultUsers();

      if (_currentUserId == null) {
        throw Exception(AuthErrorMessages.noLoggedInUser);
      }

      final currentUser = _users[_currentUserId];
      if (currentUser == null) {
        throw Exception(AuthErrorMessages.userDataNotFound);
      }

      // 이미지 경로 업데이트
      final updatedUser = Map<String, dynamic>.from(currentUser);
      updatedUser['image'] = imagePath;

      _users[_currentUserId!] = updatedUser;

      // 타이머 활동 포함하여 반환
      final userWithActivities = await _fetchUserWithTimerActivities(
        _currentUserId!,
      );
      if (userWithActivities == null) {
        throw Exception(AuthErrorMessages.userDataNotFound);
      }

      // 인증 상태 변경 통지 (추가)
      _notifyAuthStateChanged();

      return userWithActivities;
    }, params: {'imagePath': imagePath});
  }

  // 인증 상태 변화 스트림 (추가)
  @override
  Stream<Map<String, dynamic>?> get authStateChanges {
    _initializeDefaultUsers();

    // 최초 호출 시 현재 상태 통지
    if (_currentUserId != null) {
      // 비동기적으로 현재 상태 통지
      Future.microtask(() async {
        final userData = await _fetchUserWithTimerActivities(_currentUserId!);
        _authStateController.add(userData);
      });
    } else {
      // 로그아웃 상태 통지
      Future.microtask(() {
        _authStateController.add(null);
      });
    }

    return _authStateController.stream;
  }

  // 현재 인증 상태 확인 (추가)
  @override
  Future<Map<String, dynamic>?> getCurrentAuthState() async {
    _initializeDefaultUsers();

    if (_currentUserId == null) {
      return null;
    }

    return await _fetchUserWithTimerActivities(_currentUserId!);
  }

  @override
  Future<UserDto> fetchUserProfile(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500)); // 네트워크 지연 시뮬레이션

    // Mock 사용자 데이터 생성 (실제 Mock 데이터 구조에 맞춰 수정 필요)
    final mockUserData = {
      'uid': userId,
      'email': 'user$userId@example.com',
      'nickname': '사용자$userId',
      'image':
          'https://randomuser.me/api/portraits/men/${int.tryParse(userId.substring(userId.length - 1)) ?? 1}.jpg',
      'description': '안녕하세요! 열심히 공부하고 있습니다.',
      'onAir': false,
      'position': '개발자',
      'skills': 'Flutter, Dart',
      'streakDays': 7,
      'isServiceTermsAgreed': true,
      'isPrivacyPolicyAgreed': true,
      'isMarketingAgreed': false,
      'agreedAt': DateTime.now().toIso8601String(),
      'joingroup': [],
    };

    return UserDto.fromJson(mockUserData);
  }

  @override
  Future<void> updateUserStats(
    String userId,
    Map<String, dynamic> statsData,
  ) async {
    return ApiCallDecorator.wrap('MockAuth.updateUserStats', () async {
      await Future.delayed(const Duration(milliseconds: 200));

      debugPrint('🔄 Mock 사용자 통계 업데이트 시작: $userId');

      final currentUser = _users[userId];
      if (currentUser == null) {
        throw Exception('사용자를 찾을 수 없습니다');
      }

      // 기존 사용자 데이터에 통계 업데이트
      _users[userId] = {
        ...currentUser,
        ...statsData,
      };

      debugPrint('✅ Mock 사용자 통계 업데이트 완료');
      debugPrint('📊 업데이트 데이터: $statsData');

      // 인증 상태 변경 통지
      _notifyAuthStateChanged();
    }, params: {'userId': userId, 'statsData': statsData});
  }
}
