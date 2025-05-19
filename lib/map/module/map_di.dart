import 'package:devlink_mobile_app/map/data/data_source/map_data_source.dart';
import 'package:devlink_mobile_app/map/data/data_source/map_data_source_impl.dart';
import 'package:devlink_mobile_app/map/data/repository_impl/map_repository_impl.dart';
import 'package:devlink_mobile_app/map/domain/repository/map_repository.dart';
import 'package:devlink_mobile_app/map/domain/usecase/check_location_permission_use_case.dart';
import 'package:devlink_mobile_app/map/domain/usecase/get_current_location_use_case.dart';
import 'package:devlink_mobile_app/map/domain/usecase/get_near_by_items_use_case.dart';
import 'package:devlink_mobile_app/map/domain/usecase/save_location_data_use_case.dart';
import 'package:devlink_mobile_app/map/presentation/map_screen_root.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'map_di.g.dart';

@riverpod
MapDataSource mapDataSource(ref) => MapDataSourceImpl();

@riverpod
MapRepository mapRepository(ref) =>
    MapRepositoryImpl(dataSource: ref.watch(mapDataSourceProvider));

@riverpod
GetCurrentLocationUseCase getCurrentLocationUseCase(ref) =>
    GetCurrentLocationUseCase(repository: ref.watch(mapRepositoryProvider));

@riverpod
GetNearByItemsUseCase getNearByItemsUseCase(ref) =>
    GetNearByItemsUseCase(repository: ref.watch(mapRepositoryProvider));

@riverpod
CheckLocationPermissionUseCase checkLocationPermissionUseCase(ref) =>
    CheckLocationPermissionUseCase(
      repository: ref.watch(mapRepositoryProvider),
    );

@riverpod
SaveLocationDataUseCase saveLocationDataUseCase(ref) =>
    SaveLocationDataUseCase(repository: ref.watch(mapRepositoryProvider));

// final mapRoutes = [
//   GoRoute(path: '/map:', builder: (context, state) => const MapScreenRoot()),
// ];
