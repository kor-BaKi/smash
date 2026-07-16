import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
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
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: const Text('가능 요일 제출')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '아직 조가 배정되지 않았어요. 참여 가능한 활동을 모두 선택해 주세요.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primaryDeep,
                        height: 1.5,
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
                      itemCount: state.groups.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        color: AppColors.neutralBg,
                      ),
                      itemBuilder: (context, index) {
                        final group = state.groups[index];
                        final isSelected = state.selectedGroupIds.contains(
                          group.id,
                        );

                        return InkWell(
                          onTap: () => ref
                              .read(availabilityProvider.notifier)
                              .toggleGroup(group.id),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.transparent,
                                    border: isSelected
                                        ? null
                                        : Border.all(
                                            color: AppColors.divider,
                                            width: 2,
                                          ),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  group.label,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? AppColors.ink
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  color: AppColors.scaffoldBg,
                  child: Column(
                    children: [
                      if (state.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            state.errorMessage!,
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ElevatedButton(
                        onPressed: state.isSubmitting ? null : _submit,
                        child: state.isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('제출하기'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
