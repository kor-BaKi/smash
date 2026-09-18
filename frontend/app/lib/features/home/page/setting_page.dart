import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/api/notification_setting_api.dart';
import '../../../core/theme/app_theme.dart';
import '../provider/auth_provider.dart';

class SettingPage extends ConsumerStatefulWidget {
  const SettingPage({super.key});

  @override
  ConsumerState<SettingPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingPage> {
  String _appVersion = '';
  bool _pollNotification = true;
  bool _settlementNotification = true;
  bool _activityNotification = true;
  bool _isLoadingSettings = true;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    _loadNotificationSettings();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() => _appVersion = info.version);
  }

  Future<void> _loadNotificationSettings() async {
    try {
      final setting = await NotificationSettingApi.getSetting();
      setState(() {
        _pollNotification = setting['pollNotification'] ?? true;
        _settlementNotification = setting['settlementNotification'] ?? true;
        _activityNotification = setting['activityNotification'] ?? true;
        _isLoadingSettings = false;
      });
    } catch (e) {
      setState(() => _isLoadingSettings = false);
    }
  }

  Future<void> _updateNotificationSetting() async {
    try {
      await NotificationSettingApi.updateSetting(
        pollNotification: _pollNotification,
        settlementNotification: _settlementNotification,
        activityNotification: _activityNotification,
      );
    } catch (e) {
      // 실패 시 무시
    }
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
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            '비밀번호 변경',
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPwController,
                obscureText: obscureCurrent,
                style: const TextStyle(color: AppColors.white),
                decoration: InputDecoration(
                  hintText: '현재 비밀번호',
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureCurrent ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.gray,
                    ),
                    onPressed: () =>
                        setDialogState(() => obscureCurrent = !obscureCurrent),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPwController,
                obscureText: obscureNew,
                style: const TextStyle(color: AppColors.white),
                decoration: InputDecoration(
                  hintText: '새 비밀번호 (8자 이상)',
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureNew ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.gray,
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
                style: const TextStyle(color: AppColors.white),
                decoration: InputDecoration(
                  hintText: '새 비밀번호 확인',
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureConfirm ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.gray,
                    ),
                    onPressed: () =>
                        setDialogState(() => obscureConfirm = !obscureConfirm),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소', style: TextStyle(color: AppColors.gray)),
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
                      success ? '비밀번호가 변경되었습니다.' : '비밀번호 변경에 실패했습니다.',
                    ),
                  ),
                );
              },
              child: const Text(
                '변경',
                style: TextStyle(
                  color: AppColors.lime,
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
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          '로그아웃',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w800),
        ),
        content: const Text(
          '로그아웃 할까요?',
          style: TextStyle(color: AppColors.gray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소', style: TextStyle(color: AppColors.gray)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              '로그아웃',
              style: TextStyle(
                color: AppColors.coral,
                fontWeight: FontWeight.w700,
              ),
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
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 20, 0, 40),
          children: [
            // 헤더
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Text(
                '내 정보',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),

            // 프로필 카드
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.lime,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        user?.name.substring(0, 1) ?? '',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? '',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.studentNo ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.gray,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 알림 설정
            _sectionLabel('알림 설정'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: _isLoadingSettings
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.lime,
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          _NotificationToggle(
                            label: '투표 알림',
                            subLabel: '새 투표가 등록될 때',
                            value: _pollNotification,
                            onChanged: (val) {
                              setState(() => _pollNotification = val);
                              _updateNotificationSetting();
                            },
                          ),
                          Container(
                            height: 0.5,
                            color: AppColors.border,
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                          ),
                          _NotificationToggle(
                            label: '정산 알림',
                            subLabel: '택시비 정산 요청이 올 때',
                            value: _settlementNotification,
                            onChanged: (val) {
                              setState(() => _settlementNotification = val);
                              _updateNotificationSetting();
                            },
                          ),
                          Container(
                            height: 0.5,
                            color: AppColors.border,
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                          ),
                          _NotificationToggle(
                            label: '활동 알림',
                            subLabel: '오늘 활동 마감 임박 시',
                            value: _activityNotification,
                            onChanged: (val) {
                              setState(() => _activityNotification = val);
                              _updateNotificationSetting();
                            },
                          ),
                        ],
                      ),
              ),
            ),

            // 계정 설정
            _sectionLabel('계정'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    _SettingRow(
                      icon: Icons.lock_outline,
                      label: '비밀번호 변경',
                      onTap: _showChangePasswordDialog,
                    ),
                    Container(
                      height: 0.5,
                      color: AppColors.border,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    _SettingRow(
                      icon: Icons.logout,
                      label: '로그아웃',
                      color: AppColors.coral,
                      onTap: _confirmLogout,
                    ),
                  ],
                ),
              ),
            ),

            // 앱 정보
            _sectionLabel('앱 정보'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: _SettingRow(
                  icon: Icons.info_outline,
                  label: '버전 정보',
                  trailing: Text(
                    _appVersion,
                    style: const TextStyle(fontSize: 13, color: AppColors.gray),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.darkGray,
        letterSpacing: 0.08,
      ),
    ),
  );
}

class _NotificationToggle extends StatelessWidget {
  final String label;
  final String subLabel;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotificationToggle({
    required this.label,
    required this.subLabel,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subLabel,
                  style: const TextStyle(fontSize: 12, color: AppColors.gray),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.lime,
            activeTrackColor: AppColors.lime.withValues(alpha: 0.3),
            inactiveThumbColor: AppColors.darkGray,
            inactiveTrackColor: AppColors.card2,
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingRow({
    required this.icon,
    required this.label,
    this.color,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.white;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: c),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: c,
                ),
              ),
            ),
            trailing ??
                (onTap != null
                    ? Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: AppColors.darkGray,
                      )
                    : const SizedBox()),
          ],
        ),
      ),
    );
  }
}
