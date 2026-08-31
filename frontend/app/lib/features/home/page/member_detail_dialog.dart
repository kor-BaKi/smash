import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/assignment_api.dart';
import '../../../core/api/member_register_api.dart';
import '../../../core/theme/app_theme.dart';
import '../model/group_model.dart';
import '../provider/group_management_provider.dart';
import '../provider/member_register_provider.dart';

class MemberDetailDialog extends ConsumerStatefulWidget {
  final int userId;

  const MemberDetailDialog({super.key, required this.userId});

  @override
  ConsumerState<MemberDetailDialog> createState() =>
      _MemberDetailDialogState();
}

class _MemberDetailDialogState extends ConsumerState<MemberDetailDialog> {
  Map<String, dynamic>? _detail;
  bool _isLoading = true;
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _departmentController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _departmentController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveInfo() async {
    try {
      await MemberRegisterApi.updateMemberInfo(
        widget.userId,
        department: _departmentController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      await _loadDetail();
      setState(() => _isEditing = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('정보가 수정되었습니다.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('수정에 실패했습니다.')));
      }
    }
  }

  Future<void> _deleteMember() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('부원 탈퇴'),
        content: Text('${_detail!['name']}님을 탈퇴 처리할까요?\n모든 데이터가 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              '탈퇴',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await MemberRegisterApi.deleteMember(widget.userId);
        if (mounted) {
          Navigator.of(context).pop();
          ref.read(memberRegisterProvider.notifier).loadAllMembers();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('탈퇴 처리되었습니다.')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('탈퇴 처리에 실패했습니다.')));
        }
      }
    }
  }

  Future<void> _loadDetail() async {
    try {
      final data = await MemberRegisterApi.getMember(widget.userId);
      setState(() {
        _detail = data;
        _isLoading = false;
        _departmentController.text = data['department'] ?? '';
        _phoneController.text = data['phone'] ?? '';
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _changeRole(String currentRole) async {
    final newRole = currentRole == 'ADMIN' ? 'MEMBER' : 'ADMIN';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('권한 변경'),
        content: Text(
          '${_detail!['name']}님을 ${newRole == 'ADMIN' ? '임원' : '부원'}으로 변경할까요?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              '변경',
              style: TextStyle(
                color: newRole == 'ADMIN'
                    ? AppColors.primary
                    : AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await MemberRegisterApi.changeRole(widget.userId, newRole);
        await _loadDetail();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('권한이 변경되었습니다.')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('권한 변경에 실패했습니다.')));
        }
      }
    }
  }

  Future<void> _changeGroup(List<GroupDetail> groups) async {
    await showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text('${_detail!['name']} 조 변경'),
        children: groups
            .map(
              (group) => SimpleDialogOption(
                onPressed: () async {
                  Navigator.of(context).pop();
                  try {
                    await AssignmentApi.assignMember(
                      widget.userId,
                      group.id,
                    );
                    await _loadDetail();
                    await ref
                        .read(memberRegisterProvider.notifier)
                        .loadAllMembers();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${_detail!['name']}님을 ${group.label}로 변경했습니다.',
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('조 변경에 실패했습니다.')),
                      );
                    }
                  }
                },
                child: Text(group.label),
              ),
            )
            .toList(),
      ),
    );
  }

  Future<void> _addNote() async {
    if (_noteController.text.trim().isEmpty) return;
    try {
      await MemberRegisterApi.addNote(
        widget.userId,
        _noteController.text.trim(),
      );
      _noteController.clear();
      FocusScope.of(context).unfocus();
      await _loadDetail();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('메모 추가에 실패했습니다.')));
      }
    }
  }

  Future<void> _deleteNote(int noteId) async {
    try {
      await MemberRegisterApi.deleteNote(noteId);
      await _loadDetail();
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
    final groupState = ref.watch(groupManagementProvider);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Dialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 40,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              )
            : _detail == null
            ? const SizedBox(
                height: 200,
                child: Center(child: Text('정보를 불러오지 못했습니다.')),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 헤더
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.primaryBg,
                          child: Text(
                            _detail!['name'].substring(0, 1),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _detail!['name'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _detail!['studentNo'] ?? '-',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _isEditing ? Icons.check : Icons.edit_outlined,
                            color: AppColors.primary,
                          ),
                          onPressed: _isEditing
                              ? _saveInfo
                              : () => setState(() => _isEditing = true),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.person_remove_outlined,
                            color: AppColors.danger,
                          ),
                          onPressed: _deleteMember,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // 기본 정보
                    _CopyableInfoRow(
                      label: '이름',
                      value: _detail!['name'] ?? '-',
                    ),
                    _CopyableInfoRow(
                      label: '학번',
                      value: _detail!['studentNo'] ?? '-',
                    ),

                    if (_isEditing) ...[
                      _EditableInfoRow(
                        label: '학과',
                        controller: _departmentController,
                      ),
                      const SizedBox(height: 8),
                      _EditableInfoRow(
                        label: '전화번호',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                      ),
                    ] else ...[
                      _CopyableInfoRow(
                        label: '학과',
                        value: _detail!['department'] ?? '-',
                      ),
                      _CopyableInfoRow(
                        label: '전화번호',
                        value: _detail!['phone'] ?? '-',
                      ),
                    ],

                    const SizedBox(height: 12),

                    // 조 변경
                    Row(
                      children: [
                        const Text(
                          '조',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () => _changeGroup(groupState.groups),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _detail!['groupId'] == null
                                  ? AppColors.amberBg
                                  : AppColors.primaryBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _detail!['groupLabel'] ?? '미배정',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _detail!['groupId'] == null
                                        ? AppColors.amber
                                        : AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.edit,
                                  size: 12,
                                  color: _detail!['groupId'] == null
                                      ? AppColors.amber
                                      : AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // 권한 변경
                    Row(
                      children: [
                        const Text(
                          '권한',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () => _changeRole(_detail!['role']),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _detail!['role'] == 'ADMIN'
                                  ? AppColors.primaryBg
                                  : AppColors.neutralBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _detail!['role'] == 'ADMIN'
                                      ? '임원'
                                      : '부원',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _detail!['role'] == 'ADMIN'
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.edit,
                                  size: 12,
                                  color: _detail!['role'] == 'ADMIN'
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // 개인 메모
                    const Text(
                      '개인 메모',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 메모 목록
                    if (_detail!['notes'] != null &&
                        (_detail!['notes'] as List).isNotEmpty)
                      ...(_detail!['notes'] as List).map(
                        (note) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.scaffoldBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      note['createdAt'],
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      note['content'],
                                      style: const TextStyle(
                                        fontSize: 13,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _deleteNote(note['id']),
                                child: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 8),

                    // 메모 입력
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _noteController,
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
                          onTap: _addNote,
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
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 60,
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

class _CopyableInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _CopyableInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textTertiary,
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('복사되었습니다.')));
              },
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableInfoRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;

  const _EditableInfoRow({
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textTertiary,
            ),
          ),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.scaffoldBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
