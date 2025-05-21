// lib/group/data/data_source/mock_group_chat_data_source.dart
import 'dart:async';
import 'dart:math';

import 'package:devlink_mobile_app/group/data/data_source/group_chat_data_source.dart';
import 'package:intl/intl.dart';

class MockGroupChatDataSource implements GroupChatDataSource {
  final Random _random = Random();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  // 그룹별 메시지 저장소
  final Map<String, List<Map<String, dynamic>>> _groupMessages = {};

  // 메시지 스트림 컨트롤러
  final Map<String, StreamController<List<Map<String, dynamic>>>>
  _streamControllers = {};

  // 메시지 ID 카운터
  int _messageIdCounter = 1;

  // Mock 사용자 데이터 (샘플)
  final List<Map<String, String>> _mockUsers = [
    {
      'id': 'user1',
      'name': '사용자1',
      'image': 'https://randomuser.me/api/portraits/men/1.jpg',
    },
    {
      'id': 'user2',
      'name': '사용자2',
      'image': 'https://randomuser.me/api/portraits/women/2.jpg',
    },
    {
      'id': 'user3',
      'name': '사용자3',
      'image': 'https://randomuser.me/api/portraits/men/3.jpg',
    },
    {
      'id': 'user4',
      'name': '사용자4',
      'image': 'https://randomuser.me/api/portraits/women/4.jpg',
    },
  ];

  // 메시지 내용 샘플
  final List<String> _sampleMessages = [
    '안녕하세요!',
    '오늘 스터디 몇 시에 시작하나요?',
    '혹시 과제 제출 기한이 언제까지인가요?',
    '저는 지금 작업 중이에요',
    '프로젝트 진행 상황 공유해 주세요',
    'API 연동 완료했습니다',
    '다들 화이팅!',
    '질문 있으신 분?',
    '오늘 저녁에 코드 리뷰 어떠세요?',
    '버그를 발견했습니다. 확인 부탁드립니다',
  ];

  // 초기화 여부
  final Map<String, bool> _initialized = {};

  // 그룹별 초기 데이터 생성
  Future<void> _initializeGroupIfNeeded(String groupId) async {
    if (_initialized[groupId] == true) return;

    // 초기 메시지 생성
    _groupMessages[groupId] ??= [];

    // 해당 그룹에 메시지가 없으면 샘플 메시지 생성
    if (_groupMessages[groupId]!.isEmpty) {
      // 20개의 샘플 메시지 생성
      final now = DateTime.now();
      for (int i = 0; i < 20; i++) {
        final userIndex = _random.nextInt(_mockUsers.length);
        final messageIndex = _random.nextInt(_sampleMessages.length);
        final user = _mockUsers[userIndex];

        // 메시지 생성 시각 (최근 24시간 내)
        final timestamp = now.subtract(
          Duration(
            hours: _random.nextInt(24),
            minutes: _random.nextInt(60),
            seconds: _random.nextInt(60),
          ),
        );

        final messageId = 'msg_${_messageIdCounter++}';

        final message = {
          'id': messageId,
          'groupId': groupId,
          'content': _sampleMessages[messageIndex],
          'senderId': user['id'],
          'senderName': user['name'],
          'senderImage': user['image'],
          'timestamp': _dateFormat.format(timestamp),
          'isRead': _random.nextBool(),
        };

        _groupMessages[groupId]!.add(message);
      }

      // 시간순 정렬 (최신순)
      _groupMessages[groupId]!.sort((a, b) {
        try {
          final dateA = _dateFormat.parse(a['timestamp'] as String);
          final dateB = _dateFormat.parse(b['timestamp'] as String);
          return dateB.compareTo(dateA); // 내림차순
        } catch (e) {
          return 0;
        }
      });
    }

    _initialized[groupId] = true;
  }

  // 스트림 컨트롤러 생성 또는 가져오기
  StreamController<List<Map<String, dynamic>>> _getStreamController(
    String groupId,
  ) {
    if (!_streamControllers.containsKey(groupId) ||
        _streamControllers[groupId]!.isClosed) {
      _streamControllers[groupId] =
          StreamController<List<Map<String, dynamic>>>.broadcast();
    }
    return _streamControllers[groupId]!;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchGroupMessages(
    String groupId, {
    int limit = 50,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500)); // 네트워크 지연 시뮬레이션
    await _initializeGroupIfNeeded(groupId);

    // 최신 메시지부터 limit 개수만큼 반환
    final messages = _groupMessages[groupId] ?? [];

    // 메시지가 없으면 초기화 재시도
    if (messages.isEmpty) {
      await _initializeGroupIfNeeded(groupId);
      return _groupMessages[groupId] ?? [];
    }

    // limit 개수만큼 메시지 반환
    return messages.take(limit).toList();
  }

  @override
  Future<Map<String, dynamic>> sendMessage(
    String groupId,
    String content,
    String senderId,
    String senderName,
    String? senderImage,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300)); // 네트워크 지연 시뮬레이션
    await _initializeGroupIfNeeded(groupId);

    // 실패 케이스 시뮬레이션 (10% 확률)
    if (_random.nextInt(10) == 0) {
      throw Exception('메시지 전송 중 오류가 발생했습니다');
    }

    // 새 메시지 ID 생성
    final messageId = 'msg_${_messageIdCounter++}';

    // 현재 시간
    final now = DateTime.now();

    // 새 메시지 데이터
    final message = {
      'id': messageId,
      'groupId': groupId,
      'content': content,
      'senderId': senderId,
      'senderName': senderName,
      'senderImage': senderImage,
      'timestamp': _dateFormat.format(now),
      'isRead': false,
    };

    // 메시지 저장
    _groupMessages[groupId] ??= [];
    _groupMessages[groupId]!.insert(0, message); // 최신 메시지가 첫 번째로

    // 스트림으로 새 메시지 전파
    final controller = _getStreamController(groupId);
    if (!controller.isClosed) {
      controller.add(_groupMessages[groupId]!);
    }

    return message;
  }

  @override
  Stream<List<Map<String, dynamic>>> streamGroupMessages(String groupId) {
    // 그룹 초기화 (비동기)
    _initializeGroupIfNeeded(groupId).then((_) {
      // 초기화 완료 후 첫 데이터 전송
      final controller = _getStreamController(groupId);
      if (!controller.isClosed) {
        controller.add(_groupMessages[groupId] ?? []);
      }
    });

    // 스트림 생성 및 반환
    return _getStreamController(groupId).stream;
  }

  @override
  Future<void> markMessagesAsRead(String groupId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 200)); // 네트워크 지연 시뮬레이션
    await _initializeGroupIfNeeded(groupId);

    // 실패 케이스 시뮬레이션 (5% 확률)
    if (_random.nextInt(20) == 0) {
      throw Exception('메시지 읽음 처리 중 오류가 발생했습니다');
    }

    // 사용자가 보낸 것이 아닌 메시지만 읽음 처리
    for (final message in _groupMessages[groupId] ?? []) {
      if (message['senderId'] != userId && message['isRead'] == false) {
        message['isRead'] = true;
      }
    }

    // 스트림으로 업데이트된 메시지 전파
    final controller = _getStreamController(groupId);
    if (!controller.isClosed) {
      controller.add(_groupMessages[groupId] ?? []);
    }
  }

  Future<void> dispose() async {
    for (final controller in _streamControllers.values) {
      await controller.close();
    }
    _streamControllers.clear();
  }
}
