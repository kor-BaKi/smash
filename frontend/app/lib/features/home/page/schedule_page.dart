import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/schedule_provider.dart';

const _dayLabels = {
  'MON': '월',
  'TUE': '화',
  'WED': '수',
  'THU': '목',
  'FRI': '금',
};

const _timeSlotLabels = {'SLOT_13_15': '1-3시', 'SLOT_15_17': '3-5시'};

class SchedulePage extends ConsumerStatefulWidget {
  const SchedulePage({super.key});

  @override
  ConsumerState<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends ConsumerState<SchedulePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(scheduleProvider.notifier).loadSchedules();
    });
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
      appBar: AppBar(
        title: const Text('정규활동 일정'),
        actions: [
          TextButton(
            onPressed: state.isSaving ? null : _save,
            child: state.isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    '저장',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    '활성화된 요일에만 매일 자동으로 활동이 생성됩니다.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: state.schedules.length,
                    itemBuilder: (context, index) {
                      final item = state.schedules[index];
                      final label =
                          '${_dayLabels[item.dayOfWeek]} ${_timeSlotLabels[item.timeSlot]}';

                      return SwitchListTile(
                        title: Text(label),
                        value: item.isActive,
                        onChanged: (_) {
                          ref
                              .read(scheduleProvider.notifier)
                              .toggle(item.id);
                        },
                      );
                    },
                  ),
                ),
                if (state.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      state.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
    );
  }
}
