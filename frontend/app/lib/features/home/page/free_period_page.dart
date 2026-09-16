import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../model/free_period_model.dart';
import '../provider/free_period_provider.dart';

class FreePeriodPage extends ConsumerStatefulWidget {
  const FreePeriodPage({super.key});

  @override
  ConsumerState<FreePeriodPage> createState() => _FreePeriodPageState();
}

class _FreePeriodPageState extends ConsumerState<FreePeriodPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(freePeriodProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(freePeriodProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('자유활동 기간'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.lime),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => const _AddPeriodDialog(),
            ),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.lime),
            )
          : state.periods.isEmpty
          ? const Center(
              child: Text(
                '설정된 자유활동 기간이 없습니다.',
                style: TextStyle(color: AppColors.gray),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: state.periods.length,
              itemBuilder: (context, index) {
                final period = state.periods[index];
                return _PeriodTile(period: period);
              },
            ),
    );
  }
}

class _PeriodTile extends ConsumerWidget {
  final FreePeriodInfo period;
  const _PeriodTile({required this.period});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          '자유활동 기간 삭제',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          '${period.startDate} ~ ${period.endDate}\n이 기간을 삭제할까요?',
          style: const TextStyle(color: AppColors.gray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              '취소',
              style: TextStyle(color: AppColors.gray),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              '삭제',
              style: TextStyle(
                color: AppColors.coral,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(freePeriodProvider.notifier).delete(period.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.beach_access, color: AppColors.green, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${period.startDate} ~ ${period.endDate}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.close,
              size: 20,
              color: AppColors.coral,
            ),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
    );
  }
}

class _AddPeriodDialog extends ConsumerStatefulWidget {
  const _AddPeriodDialog();

  @override
  ConsumerState<_AddPeriodDialog> createState() => _AddPeriodDialogState();
}

class _AddPeriodDialogState extends ConsumerState<_AddPeriodDialog> {
  DateTime? _startDate;
  DateTime? _endDate;

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _submit() async {
    if (_startDate == null || _endDate == null) return;
    final success = await ref
        .read(freePeriodProvider.notifier)
        .add(_formatDate(_startDate!), _formatDate(_endDate!));
    if (success && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(freePeriodProvider);

    return Dialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '자유활동 기간 추가',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: AppColors.card2,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _dateRow(
                    label: _startDate == null
                        ? '시작일 선택'
                        : _formatDate(_startDate!),
                    onTap: _pickStartDate,
                  ),
                  Container(height: 0.5, color: AppColors.border),
                  _dateRow(
                    label: _endDate == null
                        ? '종료일 선택'
                        : _formatDate(_endDate!),
                    onTap: _pickEndDate,
                  ),
                ],
              ),
            ),
            if (state.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  state.errorMessage!,
                  style: const TextStyle(
                    color: AppColors.coral,
                    fontSize: 13,
                  ),
                ),
              ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      '취소',
                      style: TextStyle(color: AppColors.gray),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        state.isSubmitting ||
                            _startDate == null ||
                            _endDate == null
                        ? null
                        : _submit,
                    child: state.isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF111111),
                            ),
                          )
                        : const Text('추가'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateRow({required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today,
              size: 16,
              color: AppColors.lime,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
