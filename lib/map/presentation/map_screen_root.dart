import 'package:devlink_mobile_app/map/presentation/map_action.dart';
import 'package:devlink_mobile_app/map/presentation/map_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class MapScreenRoot extends ConsumerStatefulWidget {
  const MapScreenRoot({super.key});

  @override
  ConsumerState<MapScreenRoot> createState() => _MapScreenRootState();
}

class _MapScreenRootState extends ConsumerState<MapScreenRoot> {
  @override
  void initState() {
    super.initState();

    // 화면 진입 시 초기화 액션 실행
    Future.microtask(() {
      ref
          .read(mapNotifierProvider.notifier)
          .onAction(const MapAction.initialize());
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mapNotifierProvider);
    final notifier = ref.read(mapNotifierProvider.notifier);

    return MapScreen(
      state: state,
      onAction: (action) {
        switch (action) {
          case NavigateToUserProfile(:final userId):
            context.push('/user/$userId/profile');
          case NavigateToGroupDetail(:final groupId):
            context.push('/group/$groupId');
          default:
            notifier.onAction(action);
        }
      },
    );
  }
}
