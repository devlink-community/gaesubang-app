// lib/storage/module/storage_di.dart
import 'package:devlink_mobile_app/storage/data_source/storage_data_source.dart';
import 'package:devlink_mobile_app/storage/data_source/storage_firebase_data_source.dart';
import 'package:devlink_mobile_app/storage/domain/repository/storage_repository.dart';
import 'package:devlink_mobile_app/storage/domain/repository/storage_repository_impl.dart';
import 'package:devlink_mobile_app/storage/domain/usecase/upload_image_use_case.dart';
import 'package:devlink_mobile_app/storage/domain/usecase/upload_images_use_case.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'storage_di.g.dart';

// === DataSource Providers ===
@riverpod
StorageDataSource storageDataSource(Ref ref) {
  return StorageFirebaseDataSource(storage: FirebaseStorage.instance);
}

// === Repository Providers ===
@riverpod
StorageRepository storageRepository(Ref ref) {
  return StorageRepositoryImpl(
    dataSource: ref.watch(storageDataSourceProvider),
  );
}

// === UseCase Providers ===
@riverpod
UploadImageUseCase uploadImageUseCase(Ref ref) {
  return UploadImageUseCase(repo: ref.watch(storageRepositoryProvider));
}

@riverpod
UploadImagesUseCase uploadImagesUseCase(Ref ref) {
  return UploadImagesUseCase(repo: ref.watch(storageRepositoryProvider));
}
