import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../model/member_register_model.dart';
import '../provider/member_register_provider.dart';

class ApplicantPage extends ConsumerStatefulWidget {
  const ApplicantPage({super.key});

  @override
  ConsumerState<ApplicantPage> createState() => _ApplicantPageState();
}

class _ApplicantPageState extends ConsumerState<ApplicantPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(memberRegisterProvider.notifier)
          .loadPendingApplicants(),
    );
  }

  Future<void> _confirmReject(RegisteredMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('불합격 처리'),
        content: Text('${member.name}(${member.studentNo})님을 불합격 처리할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              '불합격',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(memberRegisterProvider.notifier).reject(member.id);
    }
  }

  Future<void> _confirmRestore(RegisteredMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('불합격 취소'),
        content: Text('${member.name}(${member.studentNo})님의 불합격을 취소할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('되돌리기'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(memberRegisterProvider.notifier).restore(member.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(memberRegisterProvider);

    final sorted = [...state.pendingApplicants]
      ..sort((a, b) {
        if (a.status == b.status) return 0;
        if (a.status == 'REJECTED') return 1;
        if (b.status == 'REJECTED') return -1;
        return 0;
      });
    final pendingCount = sorted.where((m) => m.status == 'PENDING').length;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('지원자 관리'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const _RegisterTextDialog(),
              );
            },
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textTertiary,
                          fontFamily: 'Pretendard',
                        ),
                        children: [
                          const TextSpan(text: '대기 '),
                          TextSpan(
                            text: '$pendingCount',
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const TextSpan(text: '명'),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: sorted.isEmpty
                      ? const Center(child: Text('등록된 지원자가 없습니다.'))
                      : RefreshIndicator(
                          onRefresh: () => ref
                              .read(memberRegisterProvider.notifier)
                              .loadPendingApplicants(),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                            ),
                            itemCount: sorted.length,
                            itemBuilder: (context, index) {
                              final member = sorted[index];
                              final isRejected =
                                  member.status == 'REJECTED';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.cardBg,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            member.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            member.studentNo,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color:
                                                  AppColors.textTertiary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isRejected)
                                      TextButton(
                                        onPressed: () =>
                                            _confirmRestore(member),
                                        child: const Text(
                                          '불합격 취소',
                                          style: TextStyle(
                                            color: AppColors.textTertiary,
                                          ),
                                        ),
                                      )
                                    else
                                      _CircleActionButton(
                                        icon: Icons.close,
                                        bg: AppColors.dangerBg,
                                        fg: AppColors.danger,
                                        onTap: () =>
                                            _confirmReject(member),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const _RegisterTextDialog(),
                      );
                    },
                    icon: const Icon(Icons.list_alt, size: 18),
                    label: const Text('붙여넣기로 대량 등록'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      side: const BorderSide(color: AppColors.divider),
                      foregroundColor: AppColors.textSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  const _CircleActionButton({
    required this.icon,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: fg),
      ),
    );
  }
}

class _RegisterTextDialog extends ConsumerStatefulWidget {
  const _RegisterTextDialog();

  @override
  ConsumerState<_RegisterTextDialog> createState() =>
      _RegisterTextDialogState();
}

class _RegisterTextDialogState extends ConsumerState<_RegisterTextDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await ref
        .read(memberRegisterProvider.notifier)
        .registerFromText(_controller.text);

    final state = ref.read(memberRegisterProvider);
    if (state.lastResult != null && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${state.lastResult!.successCount} / ${state.lastResult!.totalRequested}명 등록 완료'
            '${state.lastResult!.failed.isEmpty ? '' : ' (실패 ${state.lastResult!.failed.length}명)'}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(memberRegisterProvider);

    return Dialog(
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '지원자 등록',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            const Text(
              '엑셀에서 이름, 학번 두 열을 선택해\n그대로 복사(Ctrl+C)해서 붙여넣으세요.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textTertiary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: '김철수    20259001\n이영희    20259002',
              ),
            ),
            if (state.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  state.errorMessage!,
                  style: const TextStyle(
                    color: AppColors.danger,
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
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: state.isSubmitting ? null : _submit,
                    child: state.isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('등록'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
