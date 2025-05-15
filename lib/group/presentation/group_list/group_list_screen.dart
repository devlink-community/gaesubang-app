import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:devlink_mobile_app/group/presentation/group_list/group_list_action.dart';
import 'package:devlink_mobile_app/group/presentation/group_list/group_list_state.dart';
import 'package:devlink_mobile_app/group/presentation/group_list_item.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../domain/model/group.dart';

class GroupListScreen extends StatelessWidget {
  final GroupListState state;
  final void Function(GroupListAction action) onAction;

  const GroupListScreen({
    super.key,
    required this.state,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group', style: AppTextStyles.heading6Bold),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.search,
              color: AppColorStyles.black,
              size: 24,
            ),
            onPressed: () => onAction(const GroupListAction.onTapSearch()),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => onAction(const GroupListAction.onTapCreateGroup()),
        backgroundColor: AppColorStyles.primary100,
        child: const Icon(Icons.add, color: AppColorStyles.white),
      ),
    );
  }

  Widget _buildBody() {
    switch (state.groupList) {
      case AsyncLoading():
        return const Center(child: CircularProgressIndicator());
      case AsyncError(:final error):
        return Center(child: Text('에러가 발생했습니다: $error'));
      case AsyncData(:final value):
        if (value.isEmpty) {
          return const Center(child: Text('그룹이 없습니다'));
        }
        return _buildGroupList(value);
    }
    return const SizedBox.shrink(); // Default return to handle all cases
  }

  Widget _buildGroupList(List<Group> groups) {
    return ListView.builder(
      itemCount: groups.length,
      physics: const BouncingScrollPhysics(),
      addAutomaticKeepAlives: true, // 항목을 메모리에 유지
      addRepaintBoundaries: true, // 재그리기 경계 추가
      cacheExtent: 500,
      itemBuilder: (context, index) {
        final group = groups[index];
        final isJoined =
            state.currentMember != null &&
            group.members.any((member) => member.id == state.currentMember!.id);
        return GroupListItem(
          key: ValueKey('group_${group.id}'),
          group: group,
          isCurrentMemberJoined: isJoined,
          onTap: () => onAction(GroupListAction.onTapGroup(group.id)),
        );
      },
    );
  }
}
