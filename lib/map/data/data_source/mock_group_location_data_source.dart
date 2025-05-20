// lib/map/data/data_source/mock_group_location_data_source.dart
import 'dart:async';
import 'dart:math';

import 'package:devlink_mobile_app/map/data/data_source/group_loscation_data_source.dart';
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
      nickname: '사용자 $memberId', // 실제로는 사용자 정보를 가져와야 함
      imageUrl: '', // 실제로는 사용자 프로필 이미지 URL
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
      _createInitialMockData(groupId);
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
      _createInitialMockData(groupId);
    }

    // 초기 데이터 전송
    controller.add(_groupLocations[groupId] ?? []);

    // 주기적으로 멤버 위치 업데이트 시뮬레이션 (실제 구현에서는 필요 없음)
    _simulateRandomUpdates(groupId);

    return controller.stream;
  }

  // 모의 데이터 초기 생성
  void _createInitialMockData(String groupId) {
    if (kDebugMode) {
      print('MockDataSource: 초기 모의 데이터 생성 - $groupId');
    }

    // 기준 위치 (서울 시청)
    const baseLatitude = 37.5666;
    const baseLongitude = 126.9784;

    // 5~10명의 멤버 생성
    final memberCount = _random.nextInt(6) + 5;
    final locations = <GroupMemberLocationDto>[];

    for (int i = 1; i <= memberCount; i++) {
      // 약 5km 반경 내의 랜덤 위치 생성 (위도 1도 = 약 111km)
      final latOffset = (_random.nextDouble() - 0.5) * 0.09; // 약 ±5km
      final lngOffset =
          (_random.nextDouble() - 0.5) * 0.12; // 약 ±5km (경도는 위도보다 거리가 좁음)

      final isOnline = _random.nextBool();
      final lastUpdated =
          isOnline
              ? DateTime.now().subtract(Duration(minutes: _random.nextInt(60)))
              : DateTime.now().subtract(
                Duration(hours: _random.nextInt(24) + 1),
              );

      locations.add(
        GroupMemberLocationDto(
          memberId: 'member_$i',
          nickname: '멤버 $i',
          imageUrl: '', // 실제로는 프로필 이미지 URL
          latitude: baseLatitude + latOffset,
          longitude: baseLongitude + lngOffset,
          lastUpdated: lastUpdated,
          isOnline: isOnline,
        ),
      );
    }

    _groupLocations[groupId] = locations;
  }

  // 멤버 위치 랜덤 업데이트 시뮬레이션
  void _simulateRandomUpdates(String groupId) {
    // 3~5초마다 랜덤 업데이트
    Future.delayed(Duration(seconds: _random.nextInt(3) + 3), () {
      // 그룹이 아직 존재하는지 확인
      if (_groupLocations.containsKey(groupId) &&
          _controllers.containsKey(groupId)) {
        // 랜덤 멤버 선택
        final locations = _groupLocations[groupId]!;
        if (locations.isNotEmpty) {
          final index = _random.nextInt(locations.length);
          final location = locations[index];

          // 약간의 위치 변화 추가 (최대 100m)
          final latOffset = (_random.nextDouble() - 0.5) * 0.002; // 약 ±100m
          final lngOffset = (_random.nextDouble() - 0.5) * 0.003; // 약 ±100m

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
