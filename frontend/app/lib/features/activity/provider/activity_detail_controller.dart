import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/activity_api.dart';
import '../model/activity.dart';

// autoDispose: 화면을 나가면 캐시를 버려서 다음에 들어올 때 항상 최신 참여 현황을 다시 조회한다.
// (그냥 family였다면 같은 activityId를 다시 열어도 처음 조회한 결과가 그대로 남아있었다.)
final activityDetailProvider = FutureProvider.autoDispose.family<ActivityDetail, int>((ref, activityId) {
  return ref.read(activityApiProvider).getActivityDetail(activityId);
});
