import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../provider/auth_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() => _appVersion = info.version);
  }

  Future<void> _showChangePasswordDialog() async {
    final currentPwController = TextEditingController();
    final newPwController = TextEditingController();
    final confirmPwController = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('비밀번호 변경'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPwController,
                obscureText: obscureCurrent,
                decoration: InputDecoration(
                  hintText: '현재 비밀번호',
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureCurrent
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () => setDialogState(
                      () => obscureCurrent = !obscureCurrent,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPwController,
                obscureText: obscureNew,
                decoration: InputDecoration(
                  hintText: '새 비밀번호 (영문/숫자/특수문자 8자 이상)',
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureNew ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setDialogState(() => obscureNew = !obscureNew),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPwController,
                obscureText: obscureConfirm,
                decoration: InputDecoration(
                  hintText: '새 비밀번호 확인',
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureConfirm
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () => setDialogState(
                      () => obscureConfirm = !obscureConfirm,
                    ),
                  ),
                ),
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
                if (newPwController.text != confirmPwController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('새 비밀번호가 일치하지 않습니다.')),
                  );
                  return;
                }
                Navigator.of(context).pop();
                final success = await ref
                    .read(authProvider.notifier)
                    .changePassword(
                      currentPassword: currentPwController.text,
                      newPassword: newPwController.text,
                    );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? '비밀번호가 변경되었습니다.'
                          : '비밀번호 변경에 실패했습니다. 현재 비밀번호를 확인해주세요.',
                    ),
                  ),
                );
              },
              child: const Text(
                '변경',
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

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('로그아웃'),
        content: const Text('로그아웃 할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              '로그아웃',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(authProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: [
          // 내 정보
          Container(
            margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.studentNo ?? '',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 계정 설정
          _SectionTitle(title: '계정'),
          _SettingsItem(
            icon: Icons.lock_outline,
            label: '비밀번호 변경',
            onTap: _showChangePasswordDialog,
          ),

          const SizedBox(height: 12),

          // 앱 정보
          _SectionTitle(title: '앱 정보'),
          _SettingsItem(
            icon: Icons.info_outline,
            label: '버전 정보',
            trailing: Text(
              _appVersion,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textTertiary,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 로그아웃
          _SectionTitle(title: '계정 관리'),
          _SettingsItem(
            icon: Icons.logout,
            label: '로그아웃',
            labelColor: AppColors.danger,
            onTap: _confirmLogout,
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color labelColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsItem({
    required this.icon,
    required this.label,
    this.labelColor = AppColors.ink,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 2),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: labelColor, size: 20),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: labelColor,
          ),
        ),
        trailing:
            trailing ??
            (onTap != null
                ? const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: AppColors.textTertiary,
                  )
                : null),
        onTap: onTap,
      ),
    );
  }
}
