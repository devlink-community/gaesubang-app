// lib/community/presentation/community_write/community_write_screen.dart
import 'dart:typed_data';
import 'package:devlink_mobile_app/community/presentation/community_write/components/selected_image_tile.dart';
import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:devlink_mobile_app/community/presentation/community_write/community_write_state.dart';
import 'package:devlink_mobile_app/community/presentation/community_write/community_write_action.dart';

class CommunityWriteScreen extends StatefulWidget {
  const CommunityWriteScreen({
    super.key,
    required this.state,
    required this.onAction,
  });

  final CommunityWriteState state;
  final void Function(CommunityWriteAction) onAction;

  @override
  State<CommunityWriteScreen> createState() => _CommunityWriteScreenState();
}

class _CommunityWriteScreenState extends State<CommunityWriteScreen> {
  // Screen 내부에서 컨트롤러 관리
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  late final TextEditingController _tagCtrl;
  final FocusNode _tagFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.state.title);
    _contentCtrl = TextEditingController(text: widget.state.content);
    _tagCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _tagCtrl.dispose();
    _tagFocusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CommunityWriteScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 상태가 외부에서 변경되었을 때만 컨트롤러 업데이트 (필요시)
    if (widget.state.title != oldWidget.state.title &&
        widget.state.title != _titleCtrl.text) {
      _titleCtrl.text = widget.state.title;
    }

    if (widget.state.content != oldWidget.state.content &&
        widget.state.content != _contentCtrl.text) {
      _contentCtrl.text = widget.state.content;
    }

  }

  @override
  Widget build(BuildContext context) {
    final loading = widget.state.submitting;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('게시글 작성', style: AppTextStyles.heading6Bold),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          color: AppColorStyles.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        actions: <Widget>[
          // 제출 버튼
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child:
                loading
                    ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColorStyles.primary100,
                          ),
                        ),
                      ),
                    )
                    : IconButton(
                      icon: const Icon(Icons.check),
                      color: AppColorStyles.primary100,
                      onPressed: _handleSubmit,
                    ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child:
            loading
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColorStyles.primary100,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '게시글을 등록하는 중입니다...',
                        style: AppTextStyles.body1Regular.copyWith(
                          color: AppColorStyles.gray100,
                        ),
                      ),
                    ],
                  ),
                )
                : SafeArea(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: <Widget>[
                      _buildTitleSection(),
                      const SizedBox(height: 16),
                      _buildContentSection(),
                      const SizedBox(height: 24),
                      _buildTagsSection(),
                      const SizedBox(height: 24),
                      _buildImagesSection(),
                      // 에러 메시지 표시
                      if (widget.state.errorMessage != null) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColorStyles.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: AppColorStyles.error,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.state.errorMessage!,
                                  style: AppTextStyles.body1Regular.copyWith(
                                    color: AppColorStyles.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      // 하단 여백 추가
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
      ),
    );
  }

  // 제목 입력 섹션
  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextField(
          controller: _titleCtrl,
          style: AppTextStyles.body1Regular,
          decoration: InputDecoration(
            hintText: '제목을 입력하세요',
            hintStyle: AppTextStyles.body1Regular.copyWith(
              color: AppColorStyles.gray60,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColorStyles.gray40),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColorStyles.gray40),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColorStyles.primary100,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            counter: const SizedBox.shrink(), // 카운터 텍스트 숨김
          ),
          maxLength: 100,
          textInputAction: TextInputAction.next,
        ),
        // Align(
        //   alignment: Alignment.centerRight,
        //   child: Padding(
        //     padding: const EdgeInsets.only(top: 8.0),
        //     child: Text(
        //       '${_titleCtrl.text.length}/100',
        //       style: AppTextStyles.captionRegular.copyWith(
        //         color: AppColorStyles.gray80,
        //       ),
        //     ),
        //   ),
        // ),
      ],
    );
  }

  // 내용 입력 섹션
  Widget _buildContentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextField(
          controller: _contentCtrl,
          style: AppTextStyles.body1Regular,
          decoration: InputDecoration(
            hintText: '내용을 입력하세요',
            hintStyle: AppTextStyles.body1Regular.copyWith(
              color: AppColorStyles.gray60,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColorStyles.gray40),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColorStyles.gray40),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColorStyles.primary100,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.all(16),
            counter: const SizedBox.shrink(), // 카운터 텍스트 숨김
          ),
          maxLines: 10,
          maxLength: 2000,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              '${_contentCtrl.text.length}/2000',
              style: AppTextStyles.captionRegular.copyWith(
                color: AppColorStyles.gray80,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 태그 입력 섹션
  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _tagCtrl,
                focusNode: _tagFocusNode,
                style: AppTextStyles.body1Regular,
                decoration: InputDecoration(
                  hintText: '태그를 입력하고 엔터 또는 추가를 누르세요',
                  hintStyle: AppTextStyles.body1Regular.copyWith(
                    color: AppColorStyles.gray60,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColorStyles.gray40),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColorStyles.gray40),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColorStyles.primary100,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  prefixIcon: const Icon(Icons.tag, size: 20),
                ),
                // 엔터키로 태그 추가
                onSubmitted: (_) => _addTag(),
                // 엔터키 설정
                textInputAction: TextInputAction.done,
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _addTag,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColorStyles.primary100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '추가',
                  style: AppTextStyles.button1Medium.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (widget.state.hashTags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                widget.state.hashTags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColorStyles.primary60.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '#$tag',
                          style: AppTextStyles.captionRegular.copyWith(
                            color: AppColorStyles.primary100,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap:
                              () => widget.onAction(
                                CommunityWriteAction.tagRemoved(tag),
                              ),
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: AppColorStyles.primary100.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 10,
                              color: AppColorStyles.primary100,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ],
      ],
    );
  }

  // 이미지 섹션
  Widget _buildImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppColorStyles.gray40.withOpacity(0.2),
          ),
          child:
              widget.state.images.isEmpty
                  ? Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 40,
                            color: AppColorStyles.gray80,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '이미지 추가하기',
                            style: AppTextStyles.body1Regular.copyWith(
                              color: AppColorStyles.gray80,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: <Widget>[
                          // 선택된 이미지 목록
                          ...widget.state.images.asMap().entries.map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: SelectedImageTile(
                                bytes: e.value,
                                onRemove:
                                    () => widget.onAction(
                                      CommunityWriteAction.imageRemoved(e.key),
                                    ),
                              ),
                            ),
                          ),
                          // 이미지 추가 버튼 (이미지가 이미 있는 경우)
                          if (widget.state.images.isEmpty)
                            GestureDetector(
                              onTap: _pickImage,
                              child: SizedBox(
                                width: 100,
                                height: 100,

                                child: Center(
                                  child: Icon(
                                    Icons.add_photo_alternate,
                                    size: 30,
                                    color: AppColorStyles.gray60,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
        ),
        const SizedBox(height: 8),
        Text(
          '이미지는 한장 만 추가할 수 있습니다.',
          style: AppTextStyles.captionRegular.copyWith(
            color: AppColorStyles.gray80,
          ),
        ),
      ],
    );
  }

  // 태그 추가 기능
  void _addTag() {
    final tag = _tagCtrl.text.trim();
    if (tag.isNotEmpty) {
      widget.onAction(CommunityWriteAction.tagAdded(tag));
      _tagCtrl.clear();
      _tagFocusNode.requestFocus(); // 태그 추가 후 포커스 유지
    }
  }

  // 제출 처리 (컨트롤러 값 사용)
  void _handleSubmit() {
    // 키보드 닫기
    FocusScope.of(context).unfocus();

    // 컨트롤러의 현재 값으로 상태 업데이트
    widget.onAction(CommunityWriteAction.titleChanged(_titleCtrl.text));
    widget.onAction(CommunityWriteAction.contentChanged(_contentCtrl.text));

    // 제출 액션 호출
    widget.onAction(const CommunityWriteAction.submit());
  }

  /* ---------- 이미지 선택 ---------- */
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (xFile != null) {
      final bytes = await xFile.readAsBytes();
      widget.onAction(CommunityWriteAction.imageAdded(bytes));
    }
  }
}
