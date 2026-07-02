import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/availability_provider.dart';

class AvailabilityPage extends ConsumerStatefulWidget {
  const AvailabilityPage({super.key});

  @override
  ConsumerState<AvailabilityPage> createState() =>
      _AvailabilityPageState();
}

class _AvailabilityPageState extends ConsumerState<AvailabilityPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(availabilityProvider.notifier).loadGroups();
    });
  }

  Future<void> _submit() async {
    final success = await ref
        .read(availabilityProvider.notifier)
        .submitAvailability();
    if (success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('가능 요일이 제출되었습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(availabilityProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('가능 요일 선택')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '참여 가능한 조를 모두 선택해주세요.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: state.groups.length,
                    itemBuilder: (context, index) {
                      final group = state.groups[index];
                      final isSelected = state.selectedGroupIds.contains(
                        group.id,
                      );

                      return CheckboxListTile(
                        title: Text(group.label),
                        value: isSelected,
                        onChanged: (_) {
                          ref
                              .read(availabilityProvider.notifier)
                              .toggleGroup(group.id);
                        },
                      );
                    },
                  ),
                ),
                if (state.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      state.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: state.isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: state.isSubmitting
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : Text(
                              '제출 (${state.selectedGroupIds.length}개 선택)',
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
