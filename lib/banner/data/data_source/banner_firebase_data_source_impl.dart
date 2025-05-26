import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devlink_mobile_app/core/utils/time_formatter.dart';

import '../dto/banner_dto.dart';
import 'banner_data_source.dart';

class BannerFirebaseDataSourceImpl implements BannerDataSource {
  final FirebaseFirestore _firestore;

  BannerFirebaseDataSourceImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _bannersCollection =>
      _firestore.collection('banners');

  @override
  Future<List<BannerDto>> fetchAllBanners() async {
    try {
      final querySnapshot =
          await _bannersCollection
              .orderBy('displayOrder')
              .orderBy('createdAt', descending: true)
              .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // 문서 ID를 데이터에 추가
        return BannerDto.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('배너 목록 조회 실패: $e');
    }
  }

  @override
  Future<BannerDto> fetchBannerById(String bannerId) async {
    try {
      final docSnapshot = await _bannersCollection.doc(bannerId).get();

      if (!docSnapshot.exists) {
        throw Exception('배너를 찾을 수 없습니다: $bannerId');
      }

      final data = docSnapshot.data()!;
      data['id'] = docSnapshot.id; // 문서 ID를 데이터에 추가
      return BannerDto.fromJson(data);
    } catch (e) {
      throw Exception('배너 조회 실패: $e');
    }
  }

  @override
  Future<List<BannerDto>> fetchActiveBanners() async {
    try {
      final now = Timestamp.now();

      final querySnapshot =
          await _bannersCollection
              .where('isActive', isEqualTo: true)
              .where('startDate', isLessThanOrEqualTo: now)
              .where('endDate', isGreaterThan: now)
              .orderBy('endDate')
              .orderBy('displayOrder')
              .orderBy('createdAt', descending: true)
              .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // 문서 ID를 데이터에 추가
        return BannerDto.fromJson(data);
      }).toList();
    } catch (e) {
      // Firestore 복합 쿼리 제한으로 인한 오류 시 클라이언트 필터링으로 대체
      if (e.toString().contains('index')) {
        return _fetchActiveBannersWithClientFiltering();
      }
      throw Exception('활성 배너 조회 실패: $e');
    }
  }

  /// Firestore 인덱스 제한으로 인한 복합 쿼리 실패 시 클라이언트 필터링 사용
  Future<List<BannerDto>> _fetchActiveBannersWithClientFiltering() async {
    try {
      final querySnapshot =
          await _bannersCollection
              .where('isActive', isEqualTo: true)
              .orderBy('displayOrder')
              .get();

      final now = TimeFormatter.nowInSeoul();

      final activeBanners =
          querySnapshot.docs
              .map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return BannerDto.fromJson(data);
              })
              .where((banner) {
                // 클라이언트 측에서 날짜 필터링
                return banner.startDate != null &&
                    banner.endDate != null &&
                    banner.startDate!.isBefore(now) &&
                    banner.endDate!.isAfter(now);
              })
              .toList();

      // displayOrder와 createdAt으로 정렬
      activeBanners.sort((a, b) {
        final orderCompare = (a.displayOrder ?? 0).compareTo(
          b.displayOrder ?? 0,
        );
        if (orderCompare != 0) return orderCompare;

        final aCreatedAt = a.createdAt ?? TimeFormatter.nowInSeoul();
        final bCreatedAt = b.createdAt ?? TimeFormatter.nowInSeoul();
        return bCreatedAt.compareTo(aCreatedAt); // 최신순
      });

      return activeBanners;
    } catch (e) {
      throw Exception('활성 배너 조회 실패 (클라이언트 필터링): $e');
    }
  }
}
