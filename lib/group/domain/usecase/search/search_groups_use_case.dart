// lib/group/domain/usecase/search_groups_use_case.dart
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/group/domain/model/group.dart';
import 'package:devlink_mobile_app/group/domain/repository/group_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SearchGroupsUseCase {
  final GroupRepository _repository;

  SearchGroupsUseCase({required GroupRepository repository})
    : _repository = repository;

  Future<AsyncValue<List<Group>>> execute(String query) async {
    // 빈 검색어 처리
    if (query.trim().isEmpty) {
      return const AsyncData([]);
    }

    final result = await _repository.searchGroups(query);

    switch (result) {
      case Success(:final data):
        // 🔧 중복 제거 및 정렬 처리
        final uniqueGroups = _removeDuplicatesAndSort(data, query);
        return AsyncData(uniqueGroups);

      case Error(failure: final failure):
        return AsyncError(failure, StackTrace.current);
    }
  }

  /// 중복 제거 및 관련도 순으로 정렬
  List<Group> _removeDuplicatesAndSort(List<Group> groups, String query) {
    // 1. ID 기준으로 중복 제거
    final Map<String, Group> uniqueGroupsMap = {};

    for (final group in groups) {
      // ID가 같은 그룹이 있으면 더 완전한 데이터를 유지
      if (uniqueGroupsMap.containsKey(group.id)) {
        final existing = uniqueGroupsMap[group.id]!;
        // 더 많은 정보를 가진 그룹을 유지
        if (_isMoreComplete(group, existing)) {
          uniqueGroupsMap[group.id] = group;
        }
      } else {
        uniqueGroupsMap[group.id] = group;
      }
    }

    final uniqueGroups = uniqueGroupsMap.values.toList();

    // 2. 검색 쿼리와의 관련도 순으로 정렬
    uniqueGroups.sort(
      (a, b) => _calculateRelevanceScore(
        b,
        query,
      ).compareTo(_calculateRelevanceScore(a, query)),
    );

    return uniqueGroups;
  }

  /// 더 완전한 그룹 데이터인지 확인
  bool _isMoreComplete(Group group1, Group group2) {
    int score1 = _calculateCompletenessScore(group1);
    int score2 = _calculateCompletenessScore(group2);
    return score1 > score2;
  }

  /// 그룹 데이터 완성도 점수 계산
  int _calculateCompletenessScore(Group group) {
    int score = 0;

    if (group.name.isNotEmpty) score += 1;
    if (group.description.isNotEmpty) score += 1;
    if (group.imageUrl?.isNotEmpty == true) score += 1;
    if (group.hashTags.isNotEmpty) score += 1;
    if (group.memberCount > 0) score += 1;

    return score;
  }

  /// 검색 쿼리와의 관련도 점수 계산
  int _calculateRelevanceScore(Group group, String query) {
    int score = 0;
    final lowerQuery = query.toLowerCase();
    final lowerName = group.name.toLowerCase();
    final lowerDescription = group.description.toLowerCase();

    // 1. 이름에서 정확히 일치 (최고 점수)
    if (lowerName == lowerQuery) {
      score += 1000;
    }
    // 2. 이름이 검색어로 시작
    else if (lowerName.startsWith(lowerQuery)) {
      score += 500;
    }
    // 3. 이름에 검색어 포함
    else if (lowerName.contains(lowerQuery)) {
      score += 300;
    }

    // 4. 설명에 검색어 포함
    if (lowerDescription.contains(lowerQuery)) {
      score += 100;
    }

    // 5. 해시태그에 검색어 포함
    for (final tag in group.hashTags) {
      final lowerTag = tag.toLowerCase();
      if (lowerTag == lowerQuery) {
        score += 200; // 해시태그 정확 일치
      } else if (lowerTag.contains(lowerQuery)) {
        score += 50; // 해시태그 부분 일치
      }
    }

    // 6. 멤버 수 보너스 (인기도 반영)
    if (group.memberCount > 10) score += 20;
    if (group.memberCount > 50) score += 30;
    if (group.memberCount > 100) score += 50;

    // 7. 이미지가 있으면 약간의 보너스
    if (group.imageUrl?.isNotEmpty == true) {
      score += 10;
    }

    return score;
  }
}
