// lib/core/utils/community_error_messages.dart
class CommunityErrorMessages {
  const CommunityErrorMessages._();

  // === 게시글 관련 ===
  static const String postLoadFailed = '게시글을 불러오는데 실패했습니다';
  static const String postNotFound = '게시글을 찾을 수 없습니다';
  static const String postCreateFailed = '게시글 작성에 실패했습니다';
  static const String postUpdateFailed = '게시글 수정에 실패했습니다';
  static const String postDeleteFailed = '게시글 삭제에 실패했습니다';

  // === 댓글 관련 ===
  static const String commentLoadFailed = '댓글을 불러오는데 실패했습니다';
  static const String commentCreateFailed = '댓글 작성에 실패했습니다';
  static const String commentUpdateFailed = '댓글 수정에 실패했습니다';
  static const String commentDeleteFailed = '댓글 삭제에 실패했습니다';

  // === 좋아요/북마크 관련 ===
  static const String likeFailed = '좋아요 처리에 실패했습니다';
  static const String bookmarkFailed = '북마크 처리에 실패했습니다';

  // === 검색 관련 ===
  static const String searchFailed = '검색에 실패했습니다';
  static const String searchQueryRequired = '검색어를 입력해주세요';
  static const String searchNoResults = '검색 결과가 없습니다';

  // === 입력 유효성 관련 ===
  static const String titleRequired = '제목을 입력해주세요';
  static const String contentRequired = '내용을 입력해주세요';
  static const String titleTooLong = '제목이 너무 길습니다';
  static const String contentTooLong = '내용이 너무 깁니다';
  static const String invalidHashTag = '유효하지 않은 해시태그입니다';
  static const String tooManyHashTags = '해시태그는 최대 10개까지 입력 가능합니다';
  static const String tooManyImages = '이미지는 최대 5개까지 첨부 가능합니다';

  // === 권한 관련 ===
  static const String noPermissionEdit = '게시글을 수정할 권한이 없습니다';
  static const String noPermissionDelete = '게시글을 삭제할 권한이 없습니다';
  static const String noPermissionComment = '댓글을 작성할 권한이 없습니다';
  static const String loginRequired = '로그인이 필요합니다';

  // === 이미지 업로드 관련 ===
  static const String imageUploadFailed = '이미지 업로드에 실패했습니다';
  static const String imageUploadTimeout = '이미지 업로드 시간이 초과되었습니다';
  static const String imageTooLarge = '이미지 크기가 너무 큽니다';
  static const String invalidImageFormat = '지원하지 않는 이미지 형식입니다';

  // === 네트워크 관련 ===
  static const String networkError = '인터넷 연결을 확인해주세요';
  static const String timeoutError = '요청 시간이 초과되었습니다';
  static const String serverError = '서버에 문제가 발생했습니다';
  static const String unknownError = '알 수 없는 오류가 발생했습니다';

  // === 데이터 관련 ===
  static const String dataLoadFailed = '데이터를 불러오는데 실패했습니다';
  static const String dataCorrupted = '데이터가 손상되었습니다';
  static const String dataSyncFailed = '데이터 동기화에 실패했습니다';

  // === 성공 메시지 ===
  static const String postCreateSuccess = '게시글이 성공적으로 작성되었습니다';
  static const String postUpdateSuccess = '게시글이 성공적으로 수정되었습니다';
  static const String postDeleteSuccess = '게시글이 성공적으로 삭제되었습니다';
  static const String commentCreateSuccess = '댓글이 성공적으로 작성되었습니다';
  static const String likeSuccess = '좋아요를 눌렀습니다';
  static const String unlikeSuccess = '좋아요를 취소했습니다';
  static const String bookmarkAddSuccess = '북마크에 추가되었습니다';
  static const String bookmarkRemoveSuccess = '북마크에서 제거되었습니다';

  // === UI 메시지 ===
  static const String loadingPosts = '게시글을 불러오는 중...';
  static const String loadingComments = '댓글을 불러오는 중...';
  static const String submittingPost = '게시글을 등록하는 중...';
  static const String submittingComment = '댓글을 작성하는 중...';
  static const String uploadingImages = '이미지를 업로드하는 중...';

  // === 확인 메시지 ===
  static const String confirmDeletePost = '게시글을 삭제하시겠습니까?';
  static const String confirmDeleteComment = '댓글을 삭제하시겠습니까?';
  static const String confirmDiscardPost = '작성 중인 내용이 사라집니다. 계속하시겠습니까?';
}
