import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/styles/app_color_styles.dart';
import '../../../core/styles/app_text_styles.dart';
import '../../domain/model/notice.dart';

class NoticeSection extends StatelessWidget {
  final AsyncValue<List<Notice>> notices;
  final Function(String noticeId) onTapNotice;

  const NoticeSection({
    super.key,
    required this.notices,
    required this.onTapNotice,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(),
        const SizedBox(height: 8),
        _buildNoticeList(),
      ],
    );
  }

  Widget _buildSectionTitle() {
    return Row(
      children: [
        Icon(Icons.check_circle, color: AppColorStyles.primary80, size: 20),
        const SizedBox(width: 8),
        Text('Notices', style: AppTextStyles.subtitle1Bold),
      ],
    );
  }

  Widget _buildNoticeList() {
    return notices.when(
      data: (data) {
        if (data.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: Text('공지사항이 없습니다')),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final notice = data[index];
            return _buildNoticeItem(notice);
          },
        );
      },
      loading:
          () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
      error:
          (error, stack) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                '공지사항을 불러오는데 실패했습니다: $error',
                style: AppTextStyles.body1Regular.copyWith(
                  color: AppColorStyles.error,
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildNoticeItem(Notice notice) {
    return InkWell(
      onTap: () => onTapNotice(notice.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Text(
              '${notice.id}. ',
              style: AppTextStyles.body1Regular.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Expanded(
              child: Text(
                notice.title,
                style: AppTextStyles.body1Regular,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (notice.linkUrl != null)
              Text(
                '바로가기',
                style: AppTextStyles.body2Regular.copyWith(
                  color: AppColorStyles.primary100,
                  decoration: TextDecoration.underline,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
