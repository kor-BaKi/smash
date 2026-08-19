import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/application_api.dart';
import '../../../core/theme/app_theme.dart';
import '../model/application_model.dart';
import '../provider/application_provider.dart';

class ApplicationDetailPage extends ConsumerStatefulWidget {
  final int applicationId;

  const ApplicationDetailPage({super.key, required this.applicationId});

  @override
  ConsumerState<ApplicationDetailPage> createState() =>
      _ApplicationDetailPageState();
}

class _ApplicationDetailPageState
    extends ConsumerState<ApplicationDetailPage> {
  ApplicationInfo? _detail;
  bool _isLoading = true;

  final TextEditingController _newMemoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  @override
  void dispose() {
    _newMemoController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    try {
      final data = await ApplicationApi.getApplication(
        widget.applicationId,
      );
      print('detail data: $data');
      setState(() {
        _detail = ApplicationInfo.fromJson(data);
        _isLoading = false;
      });
    } catch (e) {
      print('detail error: $e'); // 에러 확인
      setState(() => _isLoading = false);
    }
  }

  Future<void> _accept() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('합격 처리'),
        content: Text(
          '${_detail?.name}님을 합격 처리할까요?\nusers 테이블에 자동으로 등록됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              '합격',
              style: TextStyle(
                color: AppColors.freeActivity,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(applicationProvider.notifier)
          .accept(widget.applicationId);
      setState(
        () => _detail = ApplicationInfo.fromJson({
          'id': _detail!.id,
          'name': _detail!.name,
          'studentNo': _detail!.studentNo,
          'department': _detail!.department,
          'phone': _detail!.phone,
          'availabilities': _detail!.availabilities,
          'status': 'ACCEPTED',
          'memo': _detail!.memo,
          'createdAt': _detail!.createdAt,
          'answers':
              _detail!.answers
                  ?.map(
                    (a) => {
                      'questionId': a.questionId,
                      'questionContent': a.questionContent,
                      'answer': a.answer,
                    },
                  )
                  .toList() ??
              [],
        }),
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('합격 처리되었습니다.')));
      }
    }
  }

  Future<void> _reject() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('불합격 처리'),
        content: Text('${_detail?.name}님을 불합격 처리할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              '불합격',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(applicationProvider.notifier)
          .reject(widget.applicationId);
      setState(
        () => _detail = ApplicationInfo.fromJson({
          'id': _detail!.id,
          'name': _detail!.name,
          'studentNo': _detail!.studentNo,
          'department': _detail!.department,
          'phone': _detail!.phone,
          'availabilities': _detail!.availabilities,
          'status': 'REJECTED',
          'memo': _detail!.memo,
          'createdAt': _detail!.createdAt,
          'answers':
              _detail!.answers
                  ?.map(
                    (a) => {
                      'questionId': a.questionId,
                      'questionContent': a.questionContent,
                      'answer': a.answer,
                    },
                  )
                  .toList() ??
              [],
        }),
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('불합격 처리되었습니다.')));
      }
    }
  }

  Future<void> _addMemo() async {
    if (_newMemoController.text.trim().isEmpty) return;
    try {
      await ApplicationApi.addMemo(
        widget.applicationId,
        _newMemoController.text.trim(),
      );
      _newMemoController.clear();
      FocusScope.of(context).unfocus();
      await _loadDetail();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('메모가 추가되었습니다.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('메모 추가에 실패했습니다.')));
      }
    }
  }

  Future<void> _deleteMemo(int memoId) async {
    try {
      await ApplicationApi.deleteMemo(memoId);
      await _loadDetail();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('메모가 삭제되었습니다.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('메모 삭제에 실패했습니다.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_detail == null) {
      return const Scaffold(body: Center(child: Text('지원서를 불러오지 못했습니다.')));
    }

    final d = _detail!;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBg,
        appBar: AppBar(title: Text('${d.name} 지원서')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 상태 카드
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _statusColor(d.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _statusColor(d.status).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _statusIcon(d.status),
                    color: _statusColor(d.status),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    d.statusLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: _statusColor(d.status),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    d.createdAt.substring(0, 10),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 기본 정보
            _InfoCard(
              title: '기본 정보',
              children: [
                _InfoRow(label: '이름', value: d.name),
                _InfoRow(label: '학번', value: d.studentNo),
                _InfoRow(label: '학과', value: d.department),
                _InfoRow(label: '전화번호', value: d.phone),
                _InfoRow(
                  label: '희망 활동 시간',
                  value: d.availabilitiesFormatted,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 답변
            if (d.answers != null && d.answers!.isNotEmpty)
              _InfoCard(
                title: '질문 답변',
                children: d.answers!
                    .map(
                      (a) => _InfoRow(
                        label: a.questionContent,
                        value: a.answer,
                        multiLine: true,
                      ),
                    )
                    .toList(),
              ),

            const SizedBox(height: 12),

            // 메모
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '임원 메모',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 메모 목록 (타임라인)
                  if (d.memos != null && d.memos!.isNotEmpty)
                    ...d.memos!.map(
                      (memo) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.scaffoldBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  memo.adminName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  memo.createdAt,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _deleteMemo(memo.id),
                                  child: const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              memo.content,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 8),

                  // 새 메모 입력
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _newMemoController,
                          decoration: InputDecoration(
                            hintText: '메모를 입력해주세요',
                            hintStyle: const TextStyle(
                              color: AppColors.textTertiary,
                            ),
                            filled: true,
                            fillColor: AppColors.scaffoldBg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _addMemo,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 합격/불합격 버튼
            if (d.status == 'PENDING' || d.status == 'ACCEPTED') ...[
              OutlinedButton(
                onPressed: _reject,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text(
                  '불합격 처리',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ] else if (d.status == 'REJECTED') ...[
              OutlinedButton(
                onPressed: _cancelReject,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text(
                  '불합격 취소',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ACCEPTED':
        return AppColors.freeActivity;
      case 'REJECTED':
        return AppColors.danger;
      default:
        return AppColors.primary;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'ACCEPTED':
        return Icons.check_circle;
      case 'REJECTED':
        return Icons.cancel;
      default:
        return Icons.pending;
    }
  }

  Future<void> _cancelReject() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('불합격 취소'),
        content: Text('${_detail?.name}님의 불합격을 취소하고 미처리로 되돌릴까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              '확인',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(applicationProvider.notifier)
          .cancelReject(widget.applicationId);
      setState(
        () => _detail = ApplicationInfo.fromJson({
          'id': _detail!.id,
          'name': _detail!.name,
          'studentNo': _detail!.studentNo,
          'department': _detail!.department,
          'phone': _detail!.phone,
          'availabilities': _detail!.availabilities,
          'status': 'PENDING',
          'memo': _detail!.memo,
          'createdAt': _detail!.createdAt,
          'answers':
              _detail!.answers
                  ?.map(
                    (a) => {
                      'questionId': a.questionId,
                      'questionContent': a.questionContent,
                      'answer': a.answer,
                    },
                  )
                  .toList() ??
              [],
        }),
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('불합격이 취소되었습니다.')));
      }
    }
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool multiLine;

  const _InfoRow({
    required this.label,
    required this.value,
    this.multiLine = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: multiLine
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
