import 'package:devlink_mobile_app/auth/data/dto/profile_dto.dart';
import 'package:devlink_mobile_app/auth/data/dto/user_dto.dart';

/// 통합 사용자 데이터 저장소 (싱글톤)
class UserStorage {
  UserStorage._internal();
  static final UserStorage _instance = UserStorage._internal();
  static UserStorage get instance => _instance;

  // 전체 사용자 데이터
  final Map<String, UserDto> _users = {};
  final Map<String, ProfileDto> _profiles = {};

  // 현재 로그인된 사용자
  String? _currentUserId;

  /// 기본 사용자 7명 초기화
  void _initializeDefaultUsers() {
    if (_users.isEmpty) {
      final defaultUsers = [
        {
          'user': UserDto(id: 'user1', email: 'test1@example.com', nickname: '사용자1', uid: 'uid1'),
          'profile': ProfileDto(userId: 'user1', image: '', onAir: false),
        },
        {
          'user': UserDto(id: 'user2', email: 'test2@example.com', nickname: '사용자2', uid: 'uid2'),
          'profile': ProfileDto(userId: 'user2', image: '', onAir: true),
        },
        {
          'user': UserDto(id: 'user3', email: 'test3@example.com', nickname: '사용자3', uid: 'uid3'),
          'profile': ProfileDto(userId: 'user3', image: '', onAir: false),
        },
        {
          'user': UserDto(id: 'user4', email: 'test4@example.com', nickname: '사용자4', uid: 'uid4'),
          'profile': ProfileDto(userId: 'user4', image: '', onAir: true),
        },
        {
          'user': UserDto(id: 'user5', email: 'test5@example.com', nickname: '사용자5', uid: 'uid5'),
          'profile': ProfileDto(userId: 'user5', image: '', onAir: false),
        },
        {
          'user': UserDto(id: 'user6', email: 'admin@example.com', nickname: '관리자', uid: 'uid6'),
          'profile': ProfileDto(userId: 'user6', image: '', onAir: true),
        },
        {
          'user': UserDto(id: 'user7', email: 'developer@example.com', nickname: '개발자', uid: 'uid7'),
          'profile': ProfileDto(userId: 'user7', image: '', onAir: true),
        },
      ];

      for (final userData in defaultUsers) {
        final user = userData['user'] as UserDto;
        final profile = userData['profile'] as ProfileDto;
        _users[user.email!] = user;
        _profiles[user.id!] = profile;
      }
    }
  }

  /// 초기화 (앱 시작 시 호출)
  void initialize() {
    _initializeDefaultUsers();
  }

  /// 사용자 조회 (이메일로)
  UserDto? getUserByEmail(String email) {
    initialize();
    return _users[email];
  }

  /// 프로필 조회 (ID로)
  ProfileDto? getProfileById(String userId) {
    initialize();
    return _profiles[userId];
  }

  /// 사용자 추가 (회원가입)
  void addUser(UserDto user, ProfileDto profile) {
    initialize();
    _users[user.email!] = user;
    _profiles[user.id!] = profile;
  }

  /// 사용자 삭제 (계정삭제)
  void deleteUser(String email) {
    initialize();
    final user = _users[email];
    if (user != null) {
      _profiles.remove(user.id);
      _users.remove(email);
      // 현재 로그인된 사용자가 삭제되면 로그아웃
      if (_currentUserId == user.id) {
        _currentUserId = null;
      }
    }
  }

  /// 로그인
  void login(String userId) {
    _currentUserId = userId;
  }

  /// 로그아웃
  void logout() {
    _currentUserId = null;
  }

  /// 현재 로그인된 사용자 ID 조회
  String? get currentUserId => _currentUserId;

  /// 현재 로그인된 사용자 조회
  UserDto? get currentUser {
    if (_currentUserId == null) return null;
    return _users.values.firstWhere(
          (user) => user.id == _currentUserId,
      orElse: () => throw Exception('Current user not found'),
    );
  }

  /// 닉네임 중복 체크
  bool isNicknameAvailable(String nickname) {
    initialize();
    return !_users.values.any((user) => user.nickname?.toLowerCase() == nickname.toLowerCase());
  }

  /// 이메일 중복 체크
  bool isEmailAvailable(String email) {
    initialize();
    return !_users.containsKey(email.toLowerCase());
  }
}