import 'package:devlink_mobile_app/community/domain/model/post.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/core/utils/exception_mappers/auth_exception_mapper.dart';
import 'package:devlink_mobile_app/core/utils/api_call_logger.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/home/data/data_source/home_data_source.dart';
import 'package:devlink_mobile_app/home/domain/model/notice.dart';
import 'package:devlink_mobile_app/home/domain/repository/home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeDataSource _dataSource;

  HomeRepositoryImpl({required HomeDataSource dataSource})
    : _dataSource = dataSource {
    AppLogger.ui('HomeRepositoryImpl 초기화 완료');
  }

  @override
  Future<Result<List<Notice>>> getNotices() async {
    return ApiCallDecorator.wrap('HomeRepository.getNotices', () async {
      AppLogger.debug('공지사항 조회 시작');
      final startTime = DateTime.now();

      try {
        AppLogger.logStep(1, 2, '데이터소스 공지사항 조회');
        final notices = await _dataSource.fetchNotices();

        AppLogger.logStep(2, 2, '공지사항 조회 결과 처리');
        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('공지사항 조회', duration);

        AppLogger.ui('공지사항 조회 성공: ${notices.length}개');
        AppLogger.logState('공지사항 조회 결과', {
          'notice_count': notices.length,
          'duration_ms': duration.inMilliseconds,
          'has_notices': notices.isNotEmpty,
        });

        return Result.success(notices);
      } catch (e, st) {
        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('공지사항 조회 실패', duration);

        AppLogger.error('공지사항 조회 실패', error: e, stackTrace: st);
        AppLogger.logState('공지사항 조회 실패 상세', {
          'error_type': e.runtimeType.toString(),
          'duration_ms': duration.inMilliseconds,
        });

        return Result.error(AuthExceptionMapper.mapAuthException(e, st));
      }
    });
  }

  @override
  Future<Result<List<Post>>> getPopularPosts() async {
    return ApiCallDecorator.wrap('HomeRepository.getPopularPosts', () async {
      AppLogger.debug('인기 게시글 조회 시작');
      final startTime = DateTime.now();

      try {
        AppLogger.logStep(1, 2, '데이터소스 인기 게시글 조회');
        final posts = await _dataSource.fetchPopularPosts();

        AppLogger.logStep(2, 2, '인기 게시글 조회 결과 처리');
        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('인기 게시글 조회', duration);

        AppLogger.ui('인기 게시글 조회 성공: ${posts.length}개');
        AppLogger.logState('인기 게시글 조회 결과', {
          'post_count': posts.length,
          'duration_ms': duration.inMilliseconds,
          'has_posts': posts.isNotEmpty,
        });

        return Result.success(posts);
      } catch (e, st) {
        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('인기 게시글 조회 실패', duration);

        AppLogger.error('인기 게시글 조회 실패', error: e, stackTrace: st);
        AppLogger.logState('인기 게시글 조회 실패 상세', {
          'error_type': e.runtimeType.toString(),
          'duration_ms': duration.inMilliseconds,
        });

        return Result.error(AuthExceptionMapper.mapAuthException(e, st));
      }
    });
  }
}
