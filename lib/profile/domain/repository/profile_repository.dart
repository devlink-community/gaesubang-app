import 'package:devlink_mobile_app/auth/domain/model/member.dart';

import '../../../core/result/result.dart';
import '../model/focus_time_stats.dart';

abstract interface class ProfileRepository {
  Future<Result<Member>> fetchIntroUser();

  Future<Result<FocusTimeStats>> fetchFocusTimeStats();
}
