import 'package:devlink_mobile_app/auth/domain/model/member.dart';
import 'package:devlink_mobile_app/community/domain/model/comment.dart';
import 'package:devlink_mobile_app/community/domain/model/hash_tag.dart';
import 'package:devlink_mobile_app/community/domain/model/like.dart';
import 'package:devlink_mobile_app/community/domain/model/post.dart';
import 'package:devlink_mobile_app/community/module/util/board_type_enum.dart';
import 'package:devlink_mobile_app/group/domain/model/group.dart';
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
  Future<List<Group>> fetchUserGroups() async {
    // 데이터 로딩 시간을 시뮬레이션하기 위한 딜레이
    await Future.delayed(const Duration(milliseconds: 700));

    final mockOwner = Member(
      id: 'owner1',
      email: 'owner@example.com',
      nickname: '그룹장',
      uid: 'owner-uid',
    );

    final members = [
      mockOwner,
      Member(
        id: 'member1',
        email: 'member1@example.com',
        nickname: '멤버1',
        uid: 'member1-uid',
      ),
      Member(
        id: 'member2',
        email: 'member2@example.com',
        nickname: '멤버2',
        uid: 'member2-uid',
      ),
    ];

    return [
      Group(
        id: 'group1',
        name: 'YOLO',
        description: '코딩 스터디 그룹입니다.',
        members: members,
        hashTags: [
          HashTag(id: 'tag1', content: '코딩'),
          HashTag(id: 'tag2', content: '스터디'),
        ],
        limitMemberCount: 10,
        owner: mockOwner,
        imageUrl: 'https://example.com/group1.jpg',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Group(
        id: 'group2',
        name: '콩콩이',
        description: '디자인 스터디 그룹입니다.',
        members: members,
        hashTags: [
          HashTag(id: 'tag3', content: '디자인'),
          HashTag(id: 'tag4', content: 'UI/UX'),
        ],
        limitMemberCount: 8,
        owner: mockOwner,
        imageUrl: 'https://example.com/group2.jpg',
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      Group(
        id: 'group3',
        name: '개발몬',
        description: '프로젝트 협업 그룹입니다.',
        members: members,
        hashTags: [
          HashTag(id: 'tag5', content: '프로젝트'),
          HashTag(id: 'tag6', content: '협업'),
        ],
        limitMemberCount: 12,
        owner: mockOwner,
        imageUrl: 'https://example.com/group3.jpg',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  @override
  Future<List<Post>> fetchPopularPosts() async {
    // 데이터 로딩 시간을 시뮬레이션하기 위한 딜레이
    await Future.delayed(const Duration(milliseconds: 600));

    final mockAuthors = [
      Member(
        id: 'author1',
        email: 'author1@example.com',
        nickname: '개수발',
        uid: 'author1-uid',
        image: 'https://example.com/avatar1.jpg',
      ),
      Member(
        id: 'author2',
        email: 'author2@example.com',
        nickname: '문신용',
        uid: 'author2-uid',
      ),
      Member(
        id: 'author3',
        email: 'author3@example.com',
        nickname: '강지원',
        uid: 'author3-uid',
      ),
    ];

    return [
      Post(
        id: 'post1',
        title: '개발팀 앱 제작',
        content: '플러터로 개발하는 방법을 공유합니다.',
        member: mockAuthors[0],
        userProfileImageUrl: 'https://example.com/avatar1.jpg',
        boardType: BoardType.free,
        createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 4)),
        hashTags: ['텀프로젝트', 'flutter'], // 문자열 리스트로 변경
        imageUrls: ['https://example.com/post1.jpg'], // 문자열 리스트로 변경
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
            userId: 'user$index',
            userName: '사용자$index',
            userProfileImage: 'https://example.com/avatar$index.jpg',
            text: '댓글 내용 $index',
            createdAt: DateTime.now().subtract(Duration(hours: index)),
          ),
        ),
      ),
      Post(
        id: 'post2',
        title: '이것은 인기 게시글 입니다.',
        content: '인기 게시글 내용입니다.',
        member: mockAuthors[1],
        userProfileImageUrl: 'https://example.com/default-profile.jpg',
        boardType: BoardType.free,
        createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 6)),
        hashTags: ['인기글'], // 문자열 리스트로 변경
        imageUrls: ['https://picsum.photos/200/300'], // 문자열 리스트로 변경
        like: List.generate(
          4,
          (index) => Like(
            userId: 'user$index',
            userName: '사용자$index',
            timestamp: DateTime.now().subtract(Duration(hours: index + 2)),
          ),
        ),
        comment: List.generate(
          3,
          (index) => Comment(
            userId: 'user$index',
            userName: '사용자$index',
            userProfileImage: 'https://example.com/default-profile.jpg',
            text: '댓글 $index',
            createdAt: DateTime.now().subtract(Duration(hours: index + 2)),
          ),
        ),
      ),
      Post(
        id: 'post3',
        title: '개발자커뮤니티 앱 제작',
        content: '함께 개발할 분을 찾습니다.',
        member: mockAuthors[2],
        userProfileImageUrl: 'https://example.com/default-profile.jpg',
        boardType: BoardType.qna,
        createdAt: DateTime.now().subtract(const Duration(days: 3, hours: 12)),
        hashTags: ['텀프로젝트', 'flutter'], // 문자열 리스트로 변경
        imageUrls: ['https://picsum.photos/200/300'], // 문자열 리스트로 변경
        like: List.generate(
          7,
          (index) => Like(
            userId: 'user$index',
            userName: '사용자$index',
            timestamp: DateTime.now().subtract(Duration(hours: index + 5)),
          ),
        ),
        comment: List.generate(
          7,
          (index) => Comment(
            userId: 'user$index',
            userName: '사용자$index',
            userProfileImage: 'https://example.com/default-profile.jpg',
            text: '댓글입니다 $index',
            createdAt: DateTime.now().subtract(Duration(hours: index + 5)),
            likeCount: index, // likeCount 추가
          ),
        ),
      ),
    ];
  }
}
