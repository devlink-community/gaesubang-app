import 'package:devlink_mobile_app/community/domain/model/comment.dart';
import 'package:devlink_mobile_app/community/domain/model/like.dart';
import 'package:devlink_mobile_app/community/domain/model/post.dart';
import 'package:devlink_mobile_app/community/module/util/board_type_enum.dart';
import 'package:devlink_mobile_app/home/data/data_source/home_data_source.dart';
import 'package:devlink_mobile_app/home/domain/model/notice.dart';

class MockHomeDataSourceImpl implements HomeDataSource {
  @override
  Future<List<Notice>> fetchNotices() async {
    // 데이터 로딩 시간을 시뮬레이션하기 위한 딜레이
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      Notice(
        id: '1',
        title: '오늘의 공지사항',
        content: '서비스 이용에 참고하세요.',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        linkUrl: '/notice/1',
      ),
      Notice(
        id: '2',
        title: '게시판 이용 공지',
        content: '게시판 이용 규칙에 관한 공지사항입니다.',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        linkUrl: '/notice/2',
      ),
    ];
  }

  @override
  Future<List<Post>> fetchPopularPosts() async {
    // 데이터 로딩 시간을 시뮬레이션하기 위한 딜레이
    await Future.delayed(const Duration(milliseconds: 600));

    return [
      Post(
        id: 'post1',
        title: '개발팀 앱 제작',
        content: '플러터로 개발하는 방법을 공유합니다.',
        authorId: 'author1-uid',
        authorNickname: '개수발',
        authorPosition: '프론트엔드 개발자',
        userProfileImageUrl:
            'https://api.dicebear.com/6.x/micah/png?seed=author1',
        boardType: BoardType.free,
        createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 4)),
        hashTags: ['텀프로젝트', 'flutter'],
        imageUrls: ['https://picsum.photos/id/237/400/300'], // Lorem Picsum 사용
        like: List.generate(
          7,
          (index) => Like(
            userId: 'user$index',
            userName: '사용자$index',
            timestamp: DateTime.now().subtract(Duration(hours: index)),
          ),
        ),
        comment: List.generate(
          7,
          (index) => Comment(
            id: 'comment_post1_$index', // 추가된 ID 필드
            userId: 'user$index',
            userName: '사용자$index',
            userProfileImage:
                'https://api.dicebear.com/6.x/micah/png?seed=user$index',
            text: '댓글 내용 $index',
            createdAt: DateTime.now().subtract(Duration(hours: index)),
            likeCount: index, // 명시적으로 likeCount 추가
            isLikedByCurrentUser: index % 2 == 0, // 임의의 좋아요 상태 설정 (짝수 인덱스만 좋아요)
          ),
        ),
      ),
      Post(
        id: 'post2',
        title: '이것은 인기 게시글 입니다.',
        content: '인기 게시글 내용입니다.',
        authorId: 'author2-uid',
        authorNickname: '문성용',
        authorPosition: '백엔드 개발자',
        userProfileImageUrl:
            'https://api.dicebear.com/6.x/micah/png?seed=author2',
        boardType: BoardType.free,
        createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 6)),
        hashTags: ['인기글'],
        imageUrls: ['https://picsum.photos/id/1/400/300'], // Lorem Picsum 사용
        like: List.generate(
          4,
          (index) => Like(
            userId: 'user${index + 10}',
            userName: '사용자${index + 10}',
            timestamp: DateTime.now().subtract(Duration(hours: index + 2)),
          ),
        ),
        comment: List.generate(
          3,
          (index) => Comment(
            id: 'comment_post2_$index', // 추가된 ID 필드
            userId: 'user${index + 10}',
            userName: '사용자${index + 10}',
            userProfileImage:
                'https://api.dicebear.com/6.x/micah/png?seed=user${index + 10}',
            text: '댓글 $index',
            createdAt: DateTime.now().subtract(Duration(hours: index + 2)),
            likeCount: index, // 명시적으로 likeCount 추가
            isLikedByCurrentUser:
                index % 3 == 0, // 임의의 좋아요 상태 설정 (3의 배수 인덱스만 좋아요)
          ),
        ),
      ),
      Post(
        id: 'post3',
        title: '개발자커뮤니티 앱 제작',
        content: '함께 개발할 분을 찾습니다.',
        authorId: 'author3-uid',
        authorNickname: '강지원',
        authorPosition: '데이터 분석가',
        userProfileImageUrl:
            'https://api.dicebear.com/6.x/micah/png?seed=author3',
        boardType: BoardType.qna,
        createdAt: DateTime.now().subtract(const Duration(days: 3, hours: 12)),
        hashTags: ['텀프로젝트', 'flutter'],
        imageUrls: ['https://picsum.photos/id/20/400/300'], // Lorem Picsum 사용
        like: List.generate(
          7,
          (index) => Like(
            userId: 'user${index + 20}',
            userName: '사용자${index + 20}',
            timestamp: DateTime.now().subtract(Duration(hours: index + 5)),
          ),
        ),
        comment: List.generate(
          7,
          (index) => Comment(
            id: 'comment_post3_$index', // 추가된 ID 필드
            userId: 'user${index + 20}',
            userName: '사용자${index + 20}',
            userProfileImage:
                'https://api.dicebear.com/6.x/micah/png?seed=user${index + 20}',
            text: '댓글입니다 $index',
            createdAt: DateTime.now().subtract(Duration(hours: index + 5)),
            likeCount: index,
            isLikedByCurrentUser: index % 2 == 1, // 임의의 좋아요 상태 설정 (홀수 인덱스만 좋아요)
          ),
        ),
      ),
    ];
  }
}
