// lib/community/presentation/community_write/community_write_notifier.dart
import 'package:devlink_mobile_app/community/module/community_di.dart';
import 'package:devlink_mobile_app/community/presentation/community_write/community_write_action.dart';
import 'package:devlink_mobile_app/community/presentation/community_write/community_write_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'community_write_notifier.g.dart';

@riverpod
class CommunityWriteNotifier extends _$CommunityWriteNotifier {
  @override
  CommunityWriteState build() => const CommunityWriteState();

  /* ---------- Action 엔트리 ---------- */
  Future<void> onAction(CommunityWriteAction action) async {
    switch (action) {
      case TitleChanged(:final title):
        state = state.copyWith(title: title);

      case ContentChanged(:final content):
        state = state.copyWith(content: content);

      case TagAdded(:final tag):
        if (tag.trim().isEmpty) return;
        final newTags = {...state.hashTags, tag.trim()}.toList();
        state = state.copyWith(hashTags: newTags);

      case TagRemoved(:final tag):
        state = state.copyWith(
          hashTags: state.hashTags.where((t) => t != tag).toList(),
        );

      case ImageAdded(:final bytes):
        state = state.copyWith(images: [...state.images, bytes]);

      case ImageRemoved(:final index):
        final list = [...state.images]..removeAt(index);
        state = state.copyWith(images: list);

      case Submit():
        await _submit();
    }
  }

  /* ---------- submit ---------- */
  Future<void> _submit() async {
    if (state.title.trim().isEmpty || state.content.trim().isEmpty) {
      state = state.copyWith(errorMessage: '제목과 내용을 입력하세요');
      return;
    }
    state = state.copyWith(submitting: true, errorMessage: null);

    try {
      final usecase = ref.read(createPostUseCaseProvider);
      final postId = await usecase.execute(
        title: state.title.trim(),
        content: state.content.trim(),
        hashTags: state.hashTags,
        imageUris: [], // 파일 업로드 후 URL 로 교체하는 로직이 있으면 전달
      );
      state = state.copyWith(submitting: false, createdPostId: postId);
    } catch (e) {
      state = state.copyWith(submitting: false, errorMessage: '게시글 작성에 실패했습니다');
    }
  }
}
