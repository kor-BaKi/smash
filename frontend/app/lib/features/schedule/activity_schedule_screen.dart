import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'activity_schedule_controller.dart';

class ActivityScheduleScreen extends ConsumerWidget {
  const ActivityScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedulesState = ref.watch(activityScheduleControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('정규활동 일정 관리')),
      body: schedulesState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (schedules) {
          return ListView.builder(
            itemCount: schedules.length,
            itemBuilder: (context, index) {
              final schedule = schedules[index];
              return SwitchListTile(
                title: Text('${schedule.dayOfWeek.koreanLabel} ${schedule.timeSlot.koreanLabel}'),
                value: schedule.isActive,
                onChanged: (_) => ref
                    .read(activityScheduleControllerProvider.notifier)
                    .toggle(schedule.dayOfWeek, schedule.timeSlot),
              );
            },
          );
        },
      ),
    );
  }
}
