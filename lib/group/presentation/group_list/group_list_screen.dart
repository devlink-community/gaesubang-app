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
        title: const Text('Group'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => onAction(const GroupListAction.onTapSearch()),
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => onAction(const GroupListAction.onTapCreateGroup()),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
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
      padding: const EdgeInsets.all(16),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return GroupListItem(
          group: group,
          onTap: () => onAction(GroupListAction.onTapGroup(group.id)),
        );
      },
    );
  }
}
