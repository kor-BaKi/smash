import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/api/application_api.dart';
import '../../../core/theme/app_theme.dart';
import '../model/application_model.dart';
import '../provider/application_provider.dart';

class ApplicationFormPage extends ConsumerStatefulWidget {
  const ApplicationFormPage({super.key});

  @override
  ConsumerState<ApplicationFormPage> createState() =>
      _ApplicationFormPageState();
}

class _ApplicationFormPageState
    extends ConsumerState<ApplicationFormPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(applicationProvider.notifier).load());
  }

  Future<void> _showAddQuestionDialog() async {
    final contentController = TextEditingController();
    String questionType = 'TEXT';
    final optionsController = TextEditingController();
    bool isRequired = true;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            '질문 추가',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  hintText: '질문 내용을 입력해주세요',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              const Text(
                '질문 타입',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: questionType,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'TEXT', child: Text('한 줄 텍스트')),
                  DropdownMenuItem(
                    value: 'MULTILINE',
                    child: Text('여러 줄 텍스트'),
                  ),
                  DropdownMenuItem(value: 'SELECT', child: Text('선택형')),
                ],
                onChanged: (val) =>
                    setDialogState(() => questionType = val!),
              ),
              if (questionType == 'SELECT') ...[
                const SizedBox(height: 12),
                const Text(
                  '선택지 (쉼표로 구분)',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: optionsController,
                  decoration: const InputDecoration(
                    hintText: '예: 있음, 없음, 모름',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: isRequired,
                    activeColor: AppColors.primary,
                    onChanged: (val) =>
                        setDialogState(() => isRequired = val!),
                  ),
                  const Text(
                    '필수 항목',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                if (contentController.text.trim().isEmpty) return;
                Navigator.of(context).pop();
                try {
                  await ApplicationApi.addQuestion(
                    contentController.text.trim(),
                    questionType,
                    isRequired,
                    options: questionType == 'SELECT'
                        ? optionsController.text.trim()
                        : null,
                  );
                  ref
                      .read(applicationProvider.notifier)
                      .load(showLoading: false);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('질문이 추가되었습니다.')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('질문 추가에 실패했습니다.')),
                    );
                  }
                }
              },
              child: const Text(
                '추가',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteQuestion(int questionId, String content) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('질문 삭제'),
        content: Text('"$content"\n\n이 질문을 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              '삭제',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ApplicationApi.deleteQuestion(questionId);
        ref.read(applicationProvider.notifier).load(showLoading: false);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('질문이 삭제되었습니다.')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('질문 삭제에 실패했습니다.')));
        }
      }
    }
  }

  Future<void> _reorder(
    List<QuestionInfo> questions,
    int oldIndex,
    int newIndex,
  ) async {
    if (newIndex > oldIndex) newIndex--;
    final reordered = [...questions];
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);

    try {
      await ApplicationApi.reorderQuestions(
        reordered.map((q) => q.id).toList(),
      );
      ref.read(applicationProvider.notifier).load(showLoading: false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('순서 변경에 실패했습니다.')));
      }
    }
  }

  Future<void> _showPeriodDialog(ApplicationFormInfo form) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    DateTime? startDate = form.startDate != null
        ? DateTime.parse(form.startDate!)
        : null;
    DateTime? endDate = form.endDate != null
        ? DateTime.parse(form.endDate!)
        : null;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            '지원 기간 설정',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  '시작일시',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textTertiary,
                  ),
                ),
                subtitle: Text(
                  startDate != null
                      ? '${startDate!.year}.${startDate!.month.toString().padLeft(2, '0')}.${startDate!.day.toString().padLeft(2, '0')} ${startDate!.hour.toString().padLeft(2, '0')}:${startDate!.minute.toString().padLeft(2, '0')}'
                      : '미설정',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                trailing: const Icon(Icons.calendar_today, size: 18),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: startDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (pickedDate != null && context.mounted) {
                    final pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(
                        startDate ?? DateTime.now(),
                      ),
                    );
                    if (pickedTime != null) {
                      setDialogState(
                        () => startDate = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        ),
                      );
                    }
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  '마감일시',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textTertiary,
                  ),
                ),
                subtitle: Text(
                  endDate != null
                      ? '${endDate!.year}.${endDate!.month.toString().padLeft(2, '0')}.${endDate!.day.toString().padLeft(2, '0')} ${endDate!.hour.toString().padLeft(2, '0')}:${endDate!.minute.toString().padLeft(2, '0')}'
                      : '미설정',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                trailing: const Icon(Icons.calendar_today, size: 18),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: endDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (pickedDate != null && context.mounted) {
                    final pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(
                        endDate ?? DateTime.now(),
                      ),
                    );
                    if (pickedTime != null) {
                      setDialogState(
                        () => endDate = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await ApplicationApi.updatePeriod(
                    startDate?.toIso8601String(),
                    endDate?.toIso8601String(),
                  );
                  ref
                      .read(applicationProvider.notifier)
                      .load(showLoading: false);
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('기간이 설정되었습니다.')),
                  );
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('기간 설정에 실패했습니다.')),
                    );
                  }
                }
              },
              child: const Text(
                '저장',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(applicationProvider);
    final form = state.form;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('지원 폼 관리'),
        actions: [
          // QR코드 버튼 추가
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: const Text(
                  '지원 폼 QR코드',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'QR코드를 스캔하면 지원 폼으로 연결됩니다.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textTertiary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    QrImageView(
                      data: 'https://baki.tailbdb322.ts.net/apply.html',
                      version: QrVersions.auto,
                      size: 220,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'baki.tailbdb322.ts.net/apply.html',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('닫기'),
                  ),
                ],
              ),
            ),
          ),
          // 질문 추가 버튼
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddQuestionDialog,
            tooltip: '질문 추가',
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : form == null
          ? const Center(child: Text('폼을 불러오지 못했습니다.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 폼 상태 카드
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '폼 상태',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textTertiary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            form.isActive ? '접수 중' : '마감',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: form.isActive
                                  ? AppColors.freeActivity
                                  : AppColors.textTertiary,
                            ),
                          ),
                          Switch(
                            value: form.isActive,
                            activeColor: AppColors.freeActivity,
                            onChanged: (val) => ref
                                .read(applicationProvider.notifier)
                                .toggleForm(val),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        children: [
                          const Text(
                            '지원 기간',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textTertiary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            form.endDate != null
                                ? '~ ${form.endDate!.substring(0, 10)}'
                                : '기간 미설정',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _showPeriodDialog(form),
                            child: const Icon(
                              Icons.edit,
                              size: 16,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 질문 목록
                Row(
                  children: [
                    const Text(
                      '질문 목록',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      '길게 눌러서 순서 변경',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (form.questions.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text(
                        '우측 상단 + 버튼으로 질문을 추가해주세요.',
                        style: TextStyle(color: AppColors.textTertiary),
                      ),
                    ),
                  )
                else
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: form.questions.length,
                    onReorder: (oldIndex, newIndex) =>
                        _reorder(form.questions, oldIndex, newIndex),
                    itemBuilder: (context, index) {
                      final q = form.questions[index];
                      return Container(
                        key: ValueKey(q.id),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppColors.primaryBg,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    q.content,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Text(
                                        _typeLabel(q.questionType),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textTertiary,
                                        ),
                                      ),
                                      if (q.isRequired) ...[
                                        const SizedBox(width: 6),
                                        const Text(
                                          '필수',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.danger,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: AppColors.textTertiary,
                                size: 20,
                              ),
                              onPressed: () =>
                                  _deleteQuestion(q.id, q.content),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'TEXT':
        return '한 줄 텍스트';
      case 'MULTILINE':
        return '여러 줄 텍스트';
      case 'SELECT':
        return '선택형';
      default:
        return type;
    }
  }
}
