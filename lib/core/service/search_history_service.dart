import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryService {
  static const String _keyRecentSearches = 'recent_searches';
  static const int _maxHistoryCount = 10; // 최대 저장 개수

  const SearchHistoryService._();

  /// 최근 검색어 목록 조회
  static Future<List<String>> getRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final searches = prefs.getStringList(_keyRecentSearches) ?? [];
      return searches;
    } catch (e) {
      print('최근 검색어 조회 오류: $e');
      return [];
    }
  }

  /// 검색어 추가 (맨 앞에 추가, 중복 제거)
  static Future<void> addSearchTerm(String searchTerm) async {
    if (searchTerm.trim().isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final searches = prefs.getStringList(_keyRecentSearches) ?? [];

      // 기존에 있으면 제거 (중복 방지)
      searches.remove(searchTerm);

      // 맨 앞에 추가
      searches.insert(0, searchTerm);

      // 최대 개수 제한
      if (searches.length > _maxHistoryCount) {
        searches.removeRange(_maxHistoryCount, searches.length);
      }

      await prefs.setStringList(_keyRecentSearches, searches);
    } catch (e) {
      print('검색어 추가 오류: $e');
    }
  }

  /// 특정 검색어 삭제
  static Future<void> removeSearchTerm(String searchTerm) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final searches = prefs.getStringList(_keyRecentSearches) ?? [];

      searches.remove(searchTerm);
      await prefs.setStringList(_keyRecentSearches, searches);
    } catch (e) {
      print('검색어 삭제 오류: $e');
    }
  }

  /// 모든 검색어 삭제
  static Future<void> clearAllSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyRecentSearches);
    } catch (e) {
      print('검색어 전체 삭제 오류: $e');
    }
  }

  /// 검색어 존재 여부 확인
  static Future<bool> containsSearchTerm(String searchTerm) async {
    try {
      final searches = await getRecentSearches();
      return searches.contains(searchTerm);
    } catch (e) {
      print('검색어 존재 확인 오류: $e');
      return false;
    }
  }
}
