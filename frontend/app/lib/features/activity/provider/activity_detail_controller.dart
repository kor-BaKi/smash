import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/activity_api.dart';
import '../model/activity.dart';

final activityDetailProvider = FutureProvider.family<ActivityDetail, int>((ref, activityId) {
  return ref.read(activityApiProvider).getActivityDetail(activityId);
});
