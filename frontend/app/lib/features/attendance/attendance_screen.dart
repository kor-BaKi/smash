import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../group/group_controller.dart';
import 'attendance_controller.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('출석 현황'),
          bottom: const TabBar(
            tabs: [Tab(text: '조별 현황'), Tab(text: '전체 미달자'), Tab(text: '타조참')],
          ),
        ),
        body: Column(
          children: [
            const _YearMonthSelector(),
            const Expanded(
              child: TabBarView(
                children: [_GroupAttendanceTab(), _ShortfallTab(), _OtherGroupTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _YearMonthSelector extends ConsumerWidget {
  const _YearMonthSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = ref.watch(attendanceYearProvider);
    final month = ref.watch(attendanceMonthProvider);
    final now = DateTime.now();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          DropdownButton<int>(
            value: year,
            items: [for (var y = now.year - 1; y <= now.year + 1; y++) DropdownMenuItem(value: y, child: Text('$y년'))],
            onChanged: (value) {
              if (value != null) ref.read(attendanceYearProvider.notifier).state = value;
            },
          ),
          const SizedBox(width: 12),
          DropdownButton<int>(
            value: month,
            items: [for (var m = 1; m <= 12; m++) DropdownMenuItem(value: m, child: Text('$m월'))],
            onChanged: (value) {
              if (value != null) ref.read(attendanceMonthProvider.notifier).state = value;
            },
          ),
        ],
      ),
    );
  }
}

class _GroupAttendanceTab extends ConsumerWidget {
  const _GroupAttendanceTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsState = ref.watch(groupControllerProvider);
    final selectedGroupId = ref.watch(attendanceGroupIdProvider);
    final attendanceState = ref.watch(groupAttendanceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: groupsState.when(
            loading: () => const CircularProgressIndicator(),
            error: (error, _) => Text(error.toString()),
            data: (groups) => DropdownButton<int>(
              hint: const Text('조 선택'),
              value: selectedGroupId,
              items: groups.map((g) => DropdownMenuItem(value: g.id, child: Text(g.label))).toList(),
              onChanged: (value) => ref.read(attendanceGroupIdProvider.notifier).state = value,
            ),
          ),
        ),
        Expanded(
          child: attendanceState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text(error.toString())),
            data: (attendance) {
              if (attendance == null) {
                return const Center(child: Text('조를 선택해 주세요.'));
              }
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('보장 횟수: ${attendance.guaranteedCount}회'),
                  ),
                  ...attendance.members.map(
                    (m) => ListTile(
                      title: Text(m.name),
                      subtitle: Text('충족 ${m.fulfilled} / 보장 ${m.guaranteed}'),
                      trailing: m.isShortfall
                          ? Text('미달 ${m.shortfall}', style: const TextStyle(color: Colors.red))
                          : const Text('충족', style: TextStyle(color: Colors.green)),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ShortfallTab extends ConsumerWidget {
  const _ShortfallTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shortfallState = ref.watch(shortfallMembersProvider);

    return shortfallState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
      data: (members) {
        if (members.isEmpty) {
          return const Center(child: Text('미달자가 없습니다.'));
        }
        return ListView.builder(
          itemCount: members.length,
          itemBuilder: (context, index) {
            final m = members[index];
            return ListTile(
              title: Text('${m.name} (${m.groupLabel})'),
              subtitle: Text('충족 ${m.fulfilled} / 보장 ${m.guaranteed}'),
              trailing: Text('미달 ${m.shortfall}', style: const TextStyle(color: Colors.red)),
            );
          },
        );
      },
    );
  }
}

class _OtherGroupTab extends ConsumerWidget {
  const _OtherGroupTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryState = ref.watch(otherGroupSummaryProvider);

    return summaryState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
      data: (summaries) {
        if (summaries.isEmpty) {
          return const Center(child: Text('타조참 기록이 없습니다.'));
        }
        return ListView.builder(
          itemCount: summaries.length,
          itemBuilder: (context, index) {
            final s = summaries[index];
            return ExpansionTile(
              title: Text('${s.name} (${s.count}회)'),
              children: s.activities
                  .map((a) => ListTile(title: Text('${a.date} · ${a.groupLabel}')))
                  .toList(),
            );
          },
        );
      },
    );
  }
}
