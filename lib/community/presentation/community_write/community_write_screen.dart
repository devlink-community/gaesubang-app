// lib/community/presentation/community_write/community_write_screen.dart
import 'dart:typed_data';
import 'package:devlink_mobile_app/community/presentation/community_write/components/selected_image_tile.dart';
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
  
  // 게시글 생성 완료 후 화면 닫기 - 빌드 단계에서 Navigator.pop을 호출하면 오류 발생
  // 대신 WidgetsBinding.instance.addPostFrameCallback 사용
  if (widget.state.createdPostId != null &&
      oldWidget.state.createdPostId == null) {
    // 프레임 렌더링 완료 후 실행되도록 예약
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pop(context, widget.state.createdPostId);
    });
  }
}

  @override
  Widget build(BuildContext context) {
    final loading = widget.state.submitting;

    return Scaffold(
      appBar: AppBar(
        title: const Text('게시글 작성'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: <Widget>[
          // 제출 버튼
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: loading ? null : _handleSubmit,
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child:
            loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                  padding: const EdgeInsets.all(16),
                  children: <Widget>[
                    _buildTitleSection(),
                    const SizedBox(height: 16),
                    _buildContentSection(),
                    const SizedBox(height: 16),
                    _buildTagsSection(),
                    const SizedBox(height: 16),
                    _buildImagesSection(),
                    // 에러 메시지 표시
                    if (widget.state.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          widget.state.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ],
                ),
      ),
    );
  }

  // 제목 입력 섹션
  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          '제목',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _titleCtrl,
          decoration: InputDecoration(
            hintText: '제목을 입력하세요',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          maxLength: 100,
        ),
      ],
    );
  }

  // 내용 입력 섹션
  Widget _buildContentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          '내용',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _contentCtrl,
          decoration: InputDecoration(
            hintText: '내용을 입력하세요',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.all(16),
          ),
          maxLines: 10,
          maxLength: 2000,
        ),
      ],
    );
  }

  // 태그 입력 섹션
  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          '해시태그',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _tagCtrl,
                decoration: InputDecoration(
                  hintText: '태그를 입력하고 추가를 누르세요',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(onPressed: _addTag, child: const Text('추가')),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              widget.state.hashTags.map<Widget>((tag) {
                return Chip(
                  label: Text(tag),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted:
                      () =>
                          widget.onAction(CommunityWriteAction.tagRemoved(tag)),
                );
              }).toList(),
        ),
      ],
    );
  }

  // 이미지 섹션
  Widget _buildImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          '이미지',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              // 이미지 추가 버튼
              _AddImageButton(onPick: _pickImage),
              const SizedBox(width: 8),
              // 선택된 이미지 목록
              ...widget.state.images.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: SelectedImageTile(
                    bytes: e.value,
                    onRemove:
                        () => widget.onAction(
                          CommunityWriteAction.imageRemoved(e.key),
                        ),
                  ),
                ),
              ),
            ],
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
    }
  }

  // 제출 처리 (컨트롤러 값 사용)
  void _handleSubmit() {
    // 컨트롤러의 현재 값으로 상태 업데이트
    widget.onAction(CommunityWriteAction.titleChanged(_titleCtrl.text));
    widget.onAction(CommunityWriteAction.contentChanged(_contentCtrl.text));

    // 제출 액션 호출
    widget.onAction(const CommunityWriteAction.submit());
  }

  /* ---------- 이미지 선택 ---------- */
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery);
    if (xFile != null) {
      final bytes = await xFile.readAsBytes();
      widget.onAction(CommunityWriteAction.imageAdded(bytes));
    }
  }
}

/* ---------------- Add-Image 버튼 ---------------- */
class _AddImageButton extends StatelessWidget {
  const _AddImageButton({required this.onPick});
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onPick,
    child: Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: const Icon(
        Icons.add_photo_alternate,
        size: 40,
        color: Colors.grey,
      ),
    ),
  );
}
