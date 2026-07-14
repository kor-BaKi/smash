import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/free_period_provider.dart';

class FreePeriodPage extends ConsumerStatefulWidget {
  const FreePeriodPage({super.key});

  @override
  ConsumerState<FreePeriodPage> createState() => _FreePeriodPageState();
}

class _FreePeriodPageState extends ConsumerState<FreePeriodPage> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(freePeriodProvider.notifier).load();
    });
  }

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
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _submit() async {
    if (_startDate == null || _endDate == null) return;

    final success = await ref
        .read(freePeriodProvider.notifier)
        .setPeriod(_formatDate(_startDate!), _formatDate(_endDate!));

    if (success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('자유활동 기간이 설정되었습니다.')));
      setState(() {
        _startDate = null;
        _endDate = null;
      });
    }
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('자유활동 기간 해제'),
        content: const Text('설정된 자유활동 기간을 해제할까요?\n이후 정규활동으로 돌아갑니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('해제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(freePeriodProvider.notifier).clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(freePeriodProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('자유활동 기간')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state.period != null) ...[
                    Card(
                      color: Colors.orange.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '현재 설정된 기간',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${state.period!.startDate} ~ ${state.period!.endDate}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _confirmClear,
                                child: const Text(
                                  '해제',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ] else
                    const Padding(
                      padding: EdgeInsets.only(bottom: 24),
                      child: Text(
                        '설정된 자유활동 기간이 없습니다.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  Text(
                    state.period == null ? '새 기간 설정' : '기간 재설정',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: Text(
                      _startDate == null
                          ? '시작일 선택'
                          : _formatDate(_startDate!),
                    ),
                    onTap: _pickStartDate,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: Text(
                      _endDate == null ? '종료일 선택' : _formatDate(_endDate!),
                    ),
                    onTap: _pickEndDate,
                  ),
                  const SizedBox(height: 16),
                  if (state.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        state.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ElevatedButton(
                    onPressed:
                        state.isSubmitting ||
                            _startDate == null ||
                            _endDate == null
                        ? null
                        : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: state.isSubmitting
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text(
                            '설정 저장',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
