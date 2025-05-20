// lib/map/data/data_source/mock_group_location_data_source.dart
import 'dart:async';
import 'dart:math';

import 'package:devlink_mobile_app/map/data/data_source/group_loscation_data_source.dart';
import 'package:devlink_mobile_app/map/data/data_source/mock_current_location_data_source.dart';
import 'package:devlink_mobile_app/map/data/dto/group_member_location_dto.dart';
import 'package:flutter/foundation.dart';

/// 그룹 위치 데이터를 Mock으로 제공하는 DataSource 구현체
class MockGroupLocationDataSource implements GroupLocationDataSource {
  // 그룹별 멤버 위치 정보를 저장하는 메모리 맵
  final Map<String, List<GroupMemberLocationDto>> _groupLocations = {};

  // 스트림 컨트롤러 목록
  final Map<String, StreamController<List<GroupMemberLocationDto>>>
  _controllers = {};

  // 랜덤 생성기
  final Random _random = Random();

  @override
  Future<void> updateMemberLocation(
    String groupId,
    String memberId,
    double latitude,
    double longitude,
  ) async {
    if (kDebugMode) {
      print('MockDataSource: 멤버 위치 업데이트 - $memberId, ($latitude, $longitude)');
    }

    // 해당 그룹에 대한 위치 정보가 없으면 생성
    if (!_groupLocations.containsKey(groupId)) {
      _groupLocations[groupId] = [];
    }

    // 해당 멤버의 위치 정보 찾기
    final index = _groupLocations[groupId]!.indexWhere(
      (location) => location.memberId == memberId,
    );

    // 위치 정보 업데이트 또는 생성
    final updatedLocation = GroupMemberLocationDto(
      memberId: memberId,
      nickname: '그룹 멤버 $memberId',
      imageUrl: 'https://randomuser.me/api/portraits/men/0.jpg',
      latitude: latitude,
      longitude: longitude,
      lastUpdated: DateTime.now(),
      isOnline: true,
    );

    if (index >= 0) {
      _groupLocations[groupId]![index] = updatedLocation;
    } else {
      _groupLocations[groupId]!.add(updatedLocation);
    }

    // 스트림 리스너들에게 업데이트 알림
    _notifyListeners(groupId);

    // 지연 시간 시뮬레이션 (100ms)
    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  Future<List<GroupMemberLocationDto>> getGroupMemberLocations(
    String groupId,
  ) async {
    if (kDebugMode) {
      print('MockDataSource: 그룹 멤버 위치 조회 - $groupId');
    }

    // 해당 그룹의 위치 정보가 없으면 초기 데이터 생성
    if (!_groupLocations.containsKey(groupId)) {
      _createInitialMockDataJeju(groupId);
    }

    // 지연 시간 시뮬레이션 (500ms)
    await Future.delayed(const Duration(milliseconds: 500));

    return _groupLocations[groupId] ?? [];
  }

  @override
  Stream<List<GroupMemberLocationDto>> streamGroupMemberLocations(
    String groupId,
  ) {
    if (kDebugMode) {
      print('MockDataSource: 그룹 멤버 위치 스트림 시작 - $groupId');
    }

    // 이미 존재하는 컨트롤러가 있으면 재사용
    if (_controllers.containsKey(groupId)) {
      return _controllers[groupId]!.stream;
    }

    // 새 스트림 컨트롤러 생성
    final controller = StreamController<List<GroupMemberLocationDto>>.broadcast(
      onCancel: () {
        // 리스너가 없으면 컨트롤러 제거
        if (!_controllers[groupId]!.hasListener) {
          _controllers[groupId]!.close();
          _controllers.remove(groupId);
          if (kDebugMode) {
            print('MockDataSource: 스트림 컨트롤러 종료 - $groupId');
          }
        }
      },
    );

    _controllers[groupId] = controller;

    // 해당 그룹의 위치 정보가 없으면 초기 데이터 생성
    if (!_groupLocations.containsKey(groupId)) {
      _createInitialMockDataJeju(groupId);
    }

    // 초기 데이터 전송
    controller.add(_groupLocations[groupId] ?? []);

    // 주기적으로 멤버 위치 업데이트 시뮬레이션 (실제 구현에서는 필요 없음)
    _simulateRandomUpdates(groupId);

    return controller.stream;
  }

  // 모의 데이터 초기 생성 (제주도 성산일출봉 근처에 자연스럽게 7명 배치)
  void _createInitialMockDataJeju(String groupId) {
    if (kDebugMode) {
      print('MockDataSource: 제주도 성산일출봉 근처 모의 데이터 생성 - $groupId (그룹원 7명)');
    }

    // 성산일출봉 좌표 (MockCurrentLocationDataSource의 상수 사용)
    final baseLatitude = MockCurrentLocationDataSource.latitude;
    final baseLongitude = MockCurrentLocationDataSource.longitude;

    // 그룹 멤버 생성 (성산일출봉 주변에 자연스럽게 배치)
    final locations = <GroupMemberLocationDto>[];

    // 멤버 정보 리스트 (지정한 7명)
    final memberInfo = [
      {
        'nickname': '성용',
        'imageUrl': 'https://randomuser.me/api/portraits/men/1.jpg',
        'isOnline': true,
        'latOffset': 0.00128, // 자연스러운 위치 오프셋
        'lngOffset': -0.00067,
      },
      {
        'nickname': '지원',
        'imageUrl': 'https://randomuser.me/api/portraits/women/2.jpg',
        'isOnline': true,
        'latOffset': 0.00072,
        'lngOffset': 0.00105,
      },
      {
        'nickname': '동성',
        'imageUrl': 'https://randomuser.me/api/portraits/men/3.jpg',
        'isOnline': false,
        'latOffset': -0.00053,
        'lngOffset': 0.00192,
      },
      {
        'nickname': '지영',
        'imageUrl': 'https://randomuser.me/api/portraits/women/4.jpg',
        'isOnline': false,
        'latOffset': -0.00132,
        'lngOffset': 0.00021,
      },
      {
        'nickname': '유준',
        'imageUrl': 'https://randomuser.me/api/portraits/men/5.jpg',
        'isOnline': false,
        'latOffset': -0.00085,
        'lngOffset': -0.00078,
      },
      {
        'nickname': '화목',
        'imageUrl': 'https://randomuser.me/api/portraits/women/6.jpg',
        'isOnline': true,
        'latOffset': 0.00043,
        'lngOffset': -0.00133,
      },
      {
        'nickname': '선호',
        'imageUrl': 'https://randomuser.me/api/portraits/men/7.jpg',
        'isOnline': false,
        'latOffset': 0.00062,
        'lngOffset': 0.00133,
      },
    ];

    // 멤버들을 추가합니다 (자연스러운 위치에)
    for (int i = 0; i < memberInfo.length; i++) {
      final info = memberInfo[i];

      // 약간의 랜덤성 추가 (더 자연스럽게 보이도록)
      final smallRandomLat =
          (_random.nextDouble() - 0.5) * 0.0002; // 약간의 랜덤 오프셋
      final smallRandomLng = (_random.nextDouble() - 0.5) * 0.0002;

      // 멤버 추가
      locations.add(
        GroupMemberLocationDto(
          memberId: 'member_${i + 1}',
          nickname: info['nickname']! as String,
          imageUrl: info['imageUrl']! as String,
          latitude:
              baseLatitude + (info['latOffset']! as double) + smallRandomLat,
          longitude:
              baseLongitude + (info['lngOffset']! as double) + smallRandomLng,
          lastUpdated: DateTime.now().subtract(
            Duration(minutes: _random.nextInt(60) + 5),
          ),
          isOnline: info['isOnline']! as bool,
        ),
      );
    }

    _groupLocations[groupId] = locations;
  }

  // 멤버 위치 랜덤 업데이트 시뮬레이션
  void _simulateRandomUpdates(String groupId) {
    // 10~15초마다 랜덤 업데이트
    Future.delayed(Duration(seconds: _random.nextInt(6) + 10), () {
      // 그룹이 아직 존재하는지 확인
      if (_groupLocations.containsKey(groupId) &&
          _controllers.containsKey(groupId)) {
        // 랜덤 멤버 선택
        final locations = _groupLocations[groupId]!;
        if (locations.isNotEmpty) {
          final index = _random.nextInt(locations.length);
          final location = locations[index];

          // 약간의 위치 변화 추가 (최대 100m)
          final latOffset = (_random.nextDouble() - 0.5) * 0.001; // 약 ±50m
          final lngOffset = (_random.nextDouble() - 0.5) * 0.001; // 약 ±50m

          // 위치 업데이트
          final updatedLocation = GroupMemberLocationDto(
            memberId: location.memberId,
            nickname: location.nickname,
            imageUrl: location.imageUrl,
            latitude: (location.latitude?.toDouble() ?? 0.0) + latOffset,
            longitude: (location.longitude?.toDouble() ?? 0.0) + lngOffset,
            lastUpdated: DateTime.now(),
            isOnline: true,
          );

          _groupLocations[groupId]![index] = updatedLocation;

          // 스트림 업데이트
          _notifyListeners(groupId);

          if (kDebugMode) {
            print(
              'MockDataSource: 랜덤 위치 업데이트 - ${location.memberId}, '
              '(${updatedLocation.latitude}, ${updatedLocation.longitude})',
            );
          }
        }

        // 재귀 호출로 계속 업데이트
        _simulateRandomUpdates(groupId);
      }
    });
  }

  // 스트림 리스너에게 업데이트 알림
  void _notifyListeners(String groupId) {
    if (_controllers.containsKey(groupId) && !_controllers[groupId]!.isClosed) {
      _controllers[groupId]!.add(_groupLocations[groupId] ?? []);
    }
  }
}
