import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    Future.microtask(() {
      ref.read(memberRegisterProvider.notifier).loadPendingApplicants();
    });
  }

  Future<void> _confirmReject(RegisteredMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('불합격 처리'),
        content: Text('${member.name}(${member.studentNo})님을 불합격 처리할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('불합격', style: TextStyle(color: Colors.red)),
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

    // PENDING 먼저, REJECTED는 맨 아래로 정렬
    final sortedApplicants = [...state.pendingApplicants]
      ..sort((a, b) {
        if (a.status == b.status) return 0;
        if (a.status == 'REJECTED') return 1;
        if (b.status == 'REJECTED') return -1;
        return 0;
      });

    return Scaffold(
      appBar: AppBar(title: const Text('지원자 관리')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : sortedApplicants.isEmpty
          ? const Center(child: Text('등록된 지원자가 없습니다.'))
          : RefreshIndicator(
              onRefresh: () => ref
                  .read(memberRegisterProvider.notifier)
                  .loadPendingApplicants(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: sortedApplicants.length,
                itemBuilder: (context, index) {
                  final member = sortedApplicants[index];
                  final isRejected = member.status == 'REJECTED';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(member.name),
                      subtitle: Text(member.studentNo),
                      trailing: isRejected
                          ? TextButton(
                              onPressed: () => _confirmRestore(member),
                              child: const Text(
                                '불합격',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : TextButton(
                              onPressed: () => _confirmReject(member),
                              child: const Text(
                                '합격',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const _RegisterTextDialog(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('지원자 등록'),
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
      _showResultSnackBar(state.lastResult!);
    }
  }

  void _showResultSnackBar(BulkRegisterResult result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${result.successCount} / ${result.totalRequested}명 등록 완료'
          '${result.failed.isEmpty ? '' : ' (실패 ${result.failed.length}명)'}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(memberRegisterProvider);

    return AlertDialog(
      title: const Text('지원자 등록'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '엑셀에서 이름, 학번 두 열을 선택해\n그대로 복사(Ctrl+C)해서 붙여넣으세요.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 8,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '김철수    20259001\n이영희    20259002',
              ),
            ),
            if (state.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  state.errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: state.isSubmitting ? null : _submit,
          child: state.isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('등록'),
        ),
      ],
    );
  }
}
