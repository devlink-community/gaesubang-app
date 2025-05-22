import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 검색어 데이터 모델 (단순화)
class SearchHistoryItem {
  final String term;
  final DateTime createdAt;
  final SearchCategory category;

  const SearchHistoryItem({
    required this.term,
    required this.createdAt,
    this.category = SearchCategory.community,
  });

  /// JSON 변환
  Map<String, dynamic> toJson() => {
    'term': term,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'category': category.name,
  };

  factory SearchHistoryItem.fromJson(Map<String, dynamic> json) {
    return SearchHistoryItem(
      term: json['term'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      category: SearchCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => SearchCategory.community,
      ),
    );
  }

  /// 만료 여부 확인 (30일)
  bool get isExpired {
    final now = DateTime.now();
    final expiryDuration = const Duration(days: 30);
    return now.difference(createdAt) > expiryDuration;
  }
}

/// 검색 카테고리
enum SearchCategory {
  community('community_searches', '커뮤니티'),
  group('group_searches', '그룹'),
  all('all_searches', '전체');

  const SearchCategory(this.key, this.displayName);
  final String key;
  final String displayName;
}

/// 검색어 필터 옵션
enum SearchFilter {
  recent, // 최신순
  alphabetical, // 가나다순
}

class SearchHistoryService {
  static const int _maxHistoryCount = 20; // 최대 저장 개수
  static const int _maxDisplayCount = 10; // 화면에 표시할 최대 개수

  const SearchHistoryService._();

  /// 카테고리별 최근 검색어 목록 조회
  static Future<List<String>> getRecentSearches({
    SearchCategory category = SearchCategory.community,
    SearchFilter filter = SearchFilter.recent,
    int? limit,
  }) async {
    try {
      final items = await _getSearchHistoryItems(category);

      // 만료된 항목 제거
      final validItems = items.where((item) => !item.isExpired).toList();

      // 필터링 및 정렬
      final sortedItems = _sortItems(validItems, filter);

      // 제한된 개수만 반환
      final displayLimit = limit ?? _maxDisplayCount;
      final limitedItems = sortedItems.take(displayLimit).toList();

      return limitedItems.map((item) => item.term).toList();
    } catch (e) {
      print('최근 검색어 조회 오류: $e');
      return [];
    }
  }

  /// 검색어 추가 (중복 제거 및 최신순 정렬)
  static Future<void> addSearchTerm(
    String searchTerm, {
    SearchCategory category = SearchCategory.community,
  }) async {
    if (searchTerm.trim().isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final items = await _getSearchHistoryItems(category);

      // 기존 항목 제거 (중복 방지)
      items.removeWhere((item) => item.term == searchTerm);

      // 새 항목을 맨 앞에 추가
      final newItem = SearchHistoryItem(
        term: searchTerm,
        createdAt: DateTime.now(),
        category: category,
      );
      items.insert(0, newItem);

      // 최대 개수 제한
      if (items.length > _maxHistoryCount) {
        items.removeRange(_maxHistoryCount, items.length);
      }

      await _saveSearchHistoryItems(items, category);

      // 만료된 항목 정리 (백그라운드)
      _cleanupExpiredItems(category);
    } catch (e) {
      print('검색어 추가 오류: $e');
    }
  }

  /// 특정 검색어 삭제
  static Future<void> removeSearchTerm(
    String searchTerm, {
    SearchCategory category = SearchCategory.community,
  }) async {
    try {
      final items = await _getSearchHistoryItems(category);
      items.removeWhere((item) => item.term == searchTerm);
      await _saveSearchHistoryItems(items, category);
    } catch (e) {
      print('검색어 삭제 오류: $e');
    }
  }

  /// 카테고리별 모든 검색어 삭제
  static Future<void> clearAllSearches({
    SearchCategory category = SearchCategory.community,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (category == SearchCategory.all) {
        // 모든 카테고리 삭제
        for (final cat in SearchCategory.values) {
          if (cat != SearchCategory.all) {
            await prefs.remove(cat.key);
          }
        }
      } else {
        await prefs.remove(category.key);
      }
    } catch (e) {
      print('검색어 전체 삭제 오류: $e');
    }
  }

  /// 검색어 존재 여부 확인
  static Future<bool> containsSearchTerm(
    String searchTerm, {
    SearchCategory category = SearchCategory.community,
  }) async {
    try {
      final items = await _getSearchHistoryItems(category);
      return items.any((item) => item.term == searchTerm);
    } catch (e) {
      print('검색어 존재 확인 오류: $e');
      return false;
    }
  }

  /// 검색어 통계 조회
  static Future<Map<String, dynamic>> getSearchStatistics({
    SearchCategory category = SearchCategory.community,
  }) async {
    try {
      final items = await _getSearchHistoryItems(category);
      final validItems = items.where((item) => !item.isExpired).toList();

      final totalSearches = validItems.length;
      final oldestSearch =
          validItems.isNotEmpty
              ? validItems
                  .map((e) => e.createdAt)
                  .reduce((a, b) => a.isBefore(b) ? a : b)
              : null;
      final newestSearch =
          validItems.isNotEmpty
              ? validItems
                  .map((e) => e.createdAt)
                  .reduce((a, b) => a.isAfter(b) ? a : b)
              : null;

      return {
        'totalSearches': totalSearches,
        'oldestSearch': oldestSearch?.toIso8601String(),
        'newestSearch': newestSearch?.toIso8601String(),
        'category': category.displayName,
      };
    } catch (e) {
      print('검색어 통계 조회 오류: $e');
      return {};
    }
  }

  /// 내부 메서드들

  /// 검색 히스토리 아이템 목록 조회
  static Future<List<SearchHistoryItem>> _getSearchHistoryItems(
    SearchCategory category,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStrings = prefs.getStringList(category.key) ?? [];

    return jsonStrings
        .map((jsonString) {
          try {
            final json = jsonDecode(jsonString) as Map<String, dynamic>;
            return SearchHistoryItem.fromJson(json);
          } catch (e) {
            print('검색어 파싱 오류: $e');
            return null;
          }
        })
        .whereType<SearchHistoryItem>()
        .toList();
  }

  /// 검색 히스토리 아이템 목록 저장
  static Future<void> _saveSearchHistoryItems(
    List<SearchHistoryItem> items,
    SearchCategory category,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStrings = items.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList(category.key, jsonStrings);
  }

  /// 아이템 정렬
  static List<SearchHistoryItem> _sortItems(
    List<SearchHistoryItem> items,
    SearchFilter filter,
  ) {
    switch (filter) {
      case SearchFilter.recent:
        items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SearchFilter.alphabetical:
        items.sort((a, b) => a.term.compareTo(b.term));
        break;
    }
    return items;
  }

  /// 만료된 항목 정리 (백그라운드 실행)
  static Future<void> _cleanupExpiredItems(SearchCategory category) async {
    try {
      final items = await _getSearchHistoryItems(category);
      final validItems = items.where((item) => !item.isExpired).toList();

      if (validItems.length != items.length) {
        await _saveSearchHistoryItems(validItems, category);
        print('만료된 검색어 ${items.length - validItems.length}개 정리 완료');
      }
    } catch (e) {
      print('만료된 항목 정리 오류: $e');
    }
  }

  /// 전체 데이터 내보내기 (백업용)
  static Future<Map<String, dynamic>> exportAllData() async {
    final Map<String, dynamic> exportData = {};

    for (final category in SearchCategory.values) {
      if (category != SearchCategory.all) {
        final items = await _getSearchHistoryItems(category);
        exportData[category.key] = items.map((item) => item.toJson()).toList();
      }
    }

    return exportData;
  }

  /// 전체 데이터 가져오기 (복원용)
  static Future<void> importAllData(Map<String, dynamic> data) async {
    try {
      for (final category in SearchCategory.values) {
        if (category != SearchCategory.all && data.containsKey(category.key)) {
          final itemsJson = data[category.key] as List<dynamic>;
          final items =
              itemsJson
                  .map(
                    (json) => SearchHistoryItem.fromJson(
                      json as Map<String, dynamic>,
                    ),
                  )
                  .toList();
          await _saveSearchHistoryItems(items, category);
        }
      }
    } catch (e) {
      print('데이터 가져오기 오류: $e');
    }
  }
}
