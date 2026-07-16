import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../provider/schedule_provider.dart';

const _dayLabels = {
  'MON': '월',
  'TUE': '화',
  'WED': '수',
  'THU': '목',
  'FRI': '금',
};
const _timeSlotLabels = {
  'SLOT_13_15': '13:00–15:00',
  'SLOT_15_17': '15:00–17:00',
};

class SchedulePage extends ConsumerStatefulWidget {
  const SchedulePage({super.key});

  @override
  ConsumerState<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends ConsumerState<SchedulePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(scheduleProvider.notifier).loadSchedules(),
    );
  }

  Future<void> _save() async {
    await ref.read(scheduleProvider.notifier).save();
    final state = ref.read(scheduleProvider);
    if (state.saved && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('저장되었습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scheduleProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('정규활동 일정'),
        actions: [
          TextButton(
            onPressed: state.isSaving ? null : _save,
            child: state.isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Text(
                    '저장',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '활성화된 요일에만 매일 자동으로 활동이 생성됩니다.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ListView.separated(
                      itemCount: state.schedules.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        color: AppColors.neutralBg,
                      ),
                      itemBuilder: (context, index) {
                        final item = state.schedules[index];
                        final label =
                            '${_dayLabels[item.dayOfWeek]} ${_timeSlotLabels[item.timeSlot]}';

                        return SwitchListTile(
                          title: Text(
                            label,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: item.isActive
                                  ? AppColors.ink
                                  : AppColors.textTertiary,
                            ),
                          ),
                          value: item.isActive,
                          activeThumbColor: Colors.white,
                          activeTrackColor: AppColors.primary,
                          onChanged: (_) => ref
                              .read(scheduleProvider.notifier)
                              .toggle(item.id),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
    );
  }
}
