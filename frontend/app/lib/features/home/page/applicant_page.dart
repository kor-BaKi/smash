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
                          const TextSpan(text: '등록 '),
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
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _CircleActionButton(
                                            icon: Icons.close,
                                            bg: AppColors.dangerBg,
                                            fg: AppColors.danger,
                                            onTap: () =>
                                                _confirmReject(member),
                                          ),
                                          const SizedBox(width: 8),
                                          _CircleActionButton(
                                            icon: Icons.delete_outline,
                                            bg: AppColors.neutralBg,
                                            fg: AppColors.textTertiary,
                                            onTap: () =>
                                                _confirmDelete(member),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Future<void> _confirmDelete(member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('지원자 삭제'),
        content: Text(
          '${member.name}(${member.studentNo})님을 삭제할까요?\n복구할 수 없습니다.',
        ),
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
      await ref
          .read(memberRegisterProvider.notifier)
          .deleteMember(member.id);
    }
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
  final _nameController = TextEditingController();
  final _studentNoController = TextEditingController();
  final _departmentController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _studentNoController.dispose();
    _departmentController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty ||
        _studentNoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이름과 학번은 필수입니다.')));
      return;
    }

    await ref
        .read(memberRegisterProvider.notifier)
        .registerMember(
          name: _nameController.text.trim(),
          studentNo: _studentNoController.text.trim(),
          department: _departmentController.text.trim(),
          phone: _phoneController.text.trim(),
        );

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('등록되었습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 40,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '지원자 등록',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              _Field(
                label: '이름',
                required: true,
                controller: _nameController,
                hint: '홍길동',
              ),
              const SizedBox(height: 12),
              _Field(
                label: '학번',
                required: true,
                controller: _studentNoController,
                hint: '2026012345',
              ),
              const SizedBox(height: 12),
              _Field(
                label: '학과',
                controller: _departmentController,
                hint: '디지털보안학과',
              ),
              const SizedBox(height: 12),
              _Field(
                label: '전화번호',
                controller: _phoneController,
                hint: '010-1234-5678',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                      child: const Text(
                        '등록',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final bool required;
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;

  const _Field({
    required this.label,
    this.required = false,
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (required)
              const Text(
                ' *',
                style: TextStyle(color: AppColors.danger, fontSize: 13),
              ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textTertiary),
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
      ],
    );
  }
}
