아래 내 요구사항을 반영해서 코드를 다시 작성해줘.

1.  dataSource에서 sort파라미터를 받지 않고 모든 postList를 제공하는 메소드로 수정해줘.
2.  PostDto도 freezed 3.0.6 버전을 이용해서 작성해줘.
3.  id는 int 말고 String 타입으로 만들어줘.
4.  내가 사용할 모델인 Post의 필드값들은 아래와 같아. 필요한 필드값이 있다면 더 추가해줘도 돼.
    id, String
    title, String
    content, String
    member, <Member>
    boardType, enum
    createdAt, DateTime
    hashTag, List<HashTag>
    like, List<Like>
5.  RepositoryImpl의 필드값에는 외부에서 주입해주는 DataSource가 존재해. 유즈케이스에서는 내가 말한대로 만들어준거같은데, namedParameter를 이용하면 더 좋을거같아.
6.  내가 다루는 CommunityListState의 필드값에 AsyncValue가 들어가면 Notifier파일에서 asyncNotifier 보다 notifier를 사용해서 구현하는게 더 섬세한 부분을 커버해줄거 같은데, 만약 내말이 맞다면 그렇게 구현해줘.



아래 내 요구사항을 반영해서 코드를 다시 작성해줘.
1. DTO는 nullable하게 구현하는게 좋을거같아.
2. DTO에 있는 Member 필드는 lib/auth를 담당하고있는 다른 사람이 작성하고있어서 내가 작성하면 안될것같아. 일단 목데이터같은걸로 사용할 수 있게 구현해줘. Member모델에는 id, email, nickname, uid, onAir, image 필드가 존재해.
3. 내가 담당해서 만들 모델들인 Like, Comment, HashTag모델에서 다루는 필드값은 아래와 같아.
   Table Like {
   boardId, String, , ;
   memberId, String, , ;
   }
   Table Comment {
   boardId, String, , ;
   memberId, String, , ;
   createdAt, DateTime, , ;
   content, String, , ;
   }
   Table HashTag {
   id, String, , ;
   content, String, , ;
   }
4. import할때 경로는 가능한 package:로 시작하는 절대경로로 작성해줘.
5. presentation에 만든 action, state등의 파일들은 presentation/community_list 폴더로 이동시켜줘. 나중에 community_detail등 다른 폴더도 만들거거든.

아래 내 요구사항을 반영해서 코드를 다시 작성해줘.
1. 일단 내가 사용할 Member 모델도 만들어줘.
2. 내가 사용할 enum들은 module/util에 dart파일로 따로따로 만들어줘.
