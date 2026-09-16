import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../provider/poll_provider.dart';

class PollCreatePage extends ConsumerStatefulWidget {
  const PollCreatePage({super.key});

  @override
  ConsumerState<PollCreatePage> createState() => _PollCreatePageState();
}

class _PollCreatePageState extends ConsumerState<PollCreatePage> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  bool _isAnonymous = false;
  bool _hasDeadline = false;
  bool _sendNotification = true;
  DateTime? _closedAt;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    setState(() => _optionControllers.add(TextEditingController()));
  }

  void _removeOption(int index) {
    if (_optionControllers.length <= 2) return;
    setState(() {
      _optionControllers[index].dispose();
      _optionControllers.removeAt(index);
    });
  }

  Future<void> _pickDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 23, minute: 59),
    );
    if (time == null) return;

    setState(() {
      _closedAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('제목을 입력해주세요.')));
      return;
    }

    final options = _optionControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('옵션을 최소 2개 이상 입력해주세요.')),
      );
      return;
    }

    final success = await ref
        .read(pollProvider.notifier)
        .create(
          title: _titleController.text.trim(),
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
          isAnonymous: _isAnonymous,
          closedAt: _hasDeadline && _closedAt != null
              ? _closedAt!.toIso8601String()
              : null,
          options: options,
          sendNotification: _sendNotification,
        );

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pollProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('투표 만들기'),
        actions: [
          TextButton(
            onPressed: state.isSubmitting ? null : _submit,
            child: state.isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.lime,
                    ),
                  )
                : const Text(
                    '등록',
                    style: TextStyle(
                      color: AppColors.lime,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 제목
            _buildLabel('제목'),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: AppColors.white),
              decoration: const InputDecoration(
                hintText: '투표 제목을 입력해주세요.',
              ),
            ),
            const SizedBox(height: 16),

            // 설명
            _buildLabel('설명 (선택)'),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 3,
              style: const TextStyle(color: AppColors.white),
              decoration: const InputDecoration(
                hintText: '투표에 대한 설명을 입력해주세요.',
              ),
            ),
            const SizedBox(height: 20),

            // 옵션
            _buildLabel('선택지'),
            const SizedBox(height: 8),
            ...List.generate(_optionControllers.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _optionControllers[index],
                        style: const TextStyle(color: AppColors.white),
                        decoration: InputDecoration(
                          hintText: '선택지 ${index + 1}',
                        ),
                      ),
                    ),
                    if (_optionControllers.length > 2) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.coral,
                          size: 20,
                        ),
                        onPressed: () => _removeOption(index),
                      ),
                    ],
                  ],
                ),
              );
            }),
            TextButton.icon(
              onPressed: _addOption,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('선택지 추가'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.lime,
                alignment: Alignment.centerLeft,
              ),
            ),
            const SizedBox(height: 20),

            // 설정
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text(
                      '익명 투표',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.white,
                      ),
                    ),
                    subtitle: const Text(
                      '누가 뭘 선택했는지 숨겨집니다.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.gray,
                      ),
                    ),
                    value: _isAnonymous,
                    activeColor: AppColors.lime,
                    activeTrackColor: AppColors.lime.withValues(
                      alpha: 0.3,
                    ),
                    inactiveThumbColor: AppColors.darkGray,
                    inactiveTrackColor: AppColors.card2,
                    onChanged: (v) => setState(() => _isAnonymous = v),
                  ),
                  Container(
                    height: 0.5,
                    color: AppColors.border,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  SwitchListTile(
                    title: const Text(
                      '마감 시간 설정',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.white,
                      ),
                    ),
                    subtitle: const Text(
                      '끄면 임원이 수동으로 종료합니다.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.gray,
                      ),
                    ),
                    value: _hasDeadline,
                    activeColor: AppColors.lime,
                    activeTrackColor: AppColors.lime.withValues(
                      alpha: 0.3,
                    ),
                    inactiveThumbColor: AppColors.darkGray,
                    inactiveTrackColor: AppColors.card2,
                    onChanged: (v) => setState(() => _hasDeadline = v),
                  ),
                  if (_hasDeadline) ...[
                    Container(
                      height: 0.5,
                      color: AppColors.border,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: AppColors.lime,
                      ),
                      title: Text(
                        _closedAt == null
                            ? '마감 시간 선택'
                            : _formatDateTime(_closedAt!),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _closedAt == null
                              ? AppColors.gray
                              : AppColors.white,
                        ),
                      ),
                      onTap: _pickDeadline,
                    ),
                  ],
                  Container(
                    height: 0.5,
                    color: AppColors.border,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  SwitchListTile(
                    title: const Text(
                      '알림 보내기',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.white,
                      ),
                    ),
                    subtitle: const Text(
                      '전체 부원에게 새 투표 알림을 전송합니다.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.gray,
                      ),
                    ),
                    value: _sendNotification,
                    activeColor: AppColors.lime,
                    activeTrackColor: AppColors.lime.withValues(
                      alpha: 0.3,
                    ),
                    inactiveThumbColor: AppColors.darkGray,
                    inactiveTrackColor: AppColors.card2,
                    onChanged: (v) =>
                        setState(() => _sendNotification = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (state.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  state.errorMessage!,
                  style: const TextStyle(color: AppColors.coral),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: AppColors.gray,
    ),
  );
}
