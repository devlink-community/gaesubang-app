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
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();

  @override
  void didUpdateWidget(covariant CommunityWriteScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.createdPostId != null &&
        oldWidget.state.createdPostId == null) {
      // 작성 성공 → 뒤로가기 or 상세화면 이동
      Navigator.pop(context, widget.state.createdPostId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = widget.state.submitting;

    return Scaffold(
      appBar: AppBar(
        title: const Text('게시글 작성'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed:
                loading
                    ? null
                    : () =>
                        widget.onAction(const CommunityWriteAction.submit()),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildLabeled('제목'),
            TextField(
              controller: _titleCtrl..text = widget.state.title,
              onChanged:
                  (v) => widget.onAction(CommunityWriteAction.titleChanged(v)),
              decoration: _inputDeco('제목을 입력해'),
            ),
            const SizedBox(height: 16),
            _buildLabeled('내용'),
            TextField(
              controller: _contentCtrl..text = widget.state.content,
              onChanged:
                  (v) =>
                      widget.onAction(CommunityWriteAction.contentChanged(v)),
              decoration: _inputDeco('내용'),
              maxLines: 8,
            ),
            const SizedBox(height: 16),
            _buildLabeled('해시태그'),
            TextField(
              controller: _tagCtrl,
              decoration: _inputDeco('태그를 입력 후 Enter'),
              onSubmitted: (v) {
                widget.onAction(CommunityWriteAction.tagAdded(v));
                _tagCtrl.clear();
              },
            ),
            Wrap(
              spacing: 6,
              children:
                  widget.state.hashTags
                      .map(
                        (t) => Chip(
                          label: Text(t),
                          onDeleted:
                              () => widget.onAction(
                                CommunityWriteAction.tagRemoved(t),
                              ),
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 16),
            _buildLabeled('이미지 추가'),
            Row(
              children: [
                _AddImageButton(onPick: _pickImage),
                const SizedBox(width: 8),
                ...widget.state.images.asMap().entries.map(
                  (e) => SelectedImageTile(
                    bytes: e.value,
                    onRemove:
                        () => widget.onAction(
                          CommunityWriteAction.imageRemoved(e.key),
                        ),
                  ),
                ),
              ],
            ),
            if (widget.state.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                widget.state.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            if (loading)
              const Padding(
                padding: EdgeInsets.only(top: 20.0),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabeled(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
  );

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  );

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
      ),
      child: const Icon(Icons.add),
    ),
  );
}
