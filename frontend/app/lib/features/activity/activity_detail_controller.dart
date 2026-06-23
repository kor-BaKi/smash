import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'activity.dart';
import 'activity_repository.dart';

final activityDetailProvider = FutureProvider.family<ActivityDetail, int>((ref, activityId) {
  return ref.read(activityRepositoryProvider).getActivityDetail(activityId);
});
