import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/home/domain/model/notice.dart';
import 'package:devlink_mobile_app/home/domain/repository/home_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class GetNoticesUseCase {
  final HomeRepository _repository;

  GetNoticesUseCase({required HomeRepository repository})
    : _repository = repository;

  Future<AsyncValue<List<Notice>>> execute() async {
    final result = await _repository.getNotices();

    switch (result) {
      case Success(:final data):
        return AsyncData(data);
      case Error(:final failure):
        return AsyncError(failure, failure.stackTrace ?? StackTrace.current);
    }
  }
}
