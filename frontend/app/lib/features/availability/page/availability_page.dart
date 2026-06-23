import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../group/provider/group_controller.dart';
import '../provider/availability_controller.dart';

class AvailabilityPage extends ConsumerStatefulWidget {
  const AvailabilityPage({super.key});

  @override
  ConsumerState<AvailabilityPage> createState() =>
      _AvailabilityPageState();
}

class _AvailabilityPageState
    extends ConsumerState<AvailabilityPage> {
  Set<int>? _selectedGroupIds;

  @override
  Widget build(BuildContext context) {
    final statusState = ref.watch(
      availabilityControllerProvider,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('가능요일 제출')),
      body: statusState.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text(error.toString())),
        data: (status) {
          if (status.assigned) {
            return Center(
              child: Text(
                '이미 조 배정이 완료되었습니다 (조 ID: ${status.assignedGroupId})',
              ),
            );
          }

          _selectedGroupIds ??= status.availabilities
              .map((a) => a.groupId)
              .toSet();
          final groupsState = ref.watch(groupControllerProvider);

          return groupsState.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                Center(child: Text(error.toString())),
            data: (groups) {
              return Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('참여 가능한 조를 모두 선택해 주세요.'),
                  ),
                  Expanded(
                    child: ListView(
                      children: groups.map((group) {
                        final selected = _selectedGroupIds!
                            .contains(group.id);
                        return CheckboxListTile(
                          title: Text(group.label),
                          value: selected,
                          onChanged: (checked) {
                            setState(() {
                              if (checked ?? false) {
                                _selectedGroupIds!.add(group.id);
                              } else {
                                _selectedGroupIds!.remove(
                                  group.id,
                                );
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: FilledButton(
                      onPressed: _selectedGroupIds!.isEmpty
                          ? null
                          : () => ref
                                .read(
                                  availabilityControllerProvider
                                      .notifier,
                                )
                                .submit(
                                  _selectedGroupIds!.toList(),
                                ),
                      child: const Text('제출'),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
