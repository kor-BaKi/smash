import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/free_period_controller.dart';

class FreePeriodPage extends ConsumerStatefulWidget {
  const FreePeriodPage({super.key});

  @override
  ConsumerState<FreePeriodPage> createState() => _FreePeriodPageState();
}

class _FreePeriodPageState extends ConsumerState<FreePeriodPage> {
  final _nameController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _format(DateTime date) => date.toIso8601String().substring(0, 10);

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    final startDate = _startDate;
    final endDate = _endDate;
    if (startDate == null || endDate == null) return;

    final name = _nameController.text.trim();
    await ref.read(freePeriodControllerProvider.notifier).create(
          name: name.isEmpty ? null : name,
          startDate: _format(startDate),
          endDate: _format(endDate),
        );

    _nameController.clear();
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final periodsState = ref.watch(freePeriodControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('자유활동 기간 관리')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: '이름 (선택)'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pickDate(isStart: true),
                        child: Text(_startDate == null ? '시작일 선택' : _format(_startDate!)),
                      ),
                    ),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('~')),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pickDate(isStart: false),
                        child: Text(_endDate == null ? '종료일 선택' : _format(_endDate!)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: (_startDate != null && _endDate != null) ? _submit : null,
                  child: const Text('추가'),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: periodsState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text(error.toString())),
              data: (periods) {
                if (periods.isEmpty) {
                  return const Center(child: Text('등록된 자유활동 기간이 없습니다.'));
                }
                return ListView.builder(
                  itemCount: periods.length,
                  itemBuilder: (context, index) {
                    final period = periods[index];
                    return ListTile(
                      title: Text(period.name ?? '자유활동'),
                      subtitle: Text('${period.startDate} ~ ${period.endDate}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => ref.read(freePeriodControllerProvider.notifier).delete(period.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
