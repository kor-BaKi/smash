import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../provider/invite_code_provider.dart';

class InviteCodePage extends ConsumerStatefulWidget {
  const InviteCodePage({super.key});

  @override
  ConsumerState<InviteCodePage> createState() => _InviteCodePageState();
}

class _InviteCodePageState extends ConsumerState<InviteCodePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(inviteCodeProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inviteCodeProvider);
    final code = state.code;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: const Text('가입코드 관리')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '현재 가입코드',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          code?.code ?? '없음',
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 4,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (code != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: code.isActive
                                  ? AppColors.freeActivityBg
                                  : AppColors.neutralBg,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: code.isActive
                                        ? AppColors.freeActivity
                                        : AppColors.textTertiary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  code.isActive ? '활성화됨' : '비활성화됨',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: code.isActive
                                        ? AppColors.freeActivityText
                                        : AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (code != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          '코드 활성화',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: const Text(
                          '끄면 신규 가입이 막혀요',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        value: code.isActive,
                        activeThumbColor: Colors.white,
                        activeTrackColor: AppColors.primary,
                        onChanged: (_) =>
                            ref.read(inviteCodeProvider.notifier).toggle(),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (state.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        state.errorMessage!,
                        style: const TextStyle(color: AppColors.danger),
                      ),
                    ),
                  OutlinedButton(
                    onPressed: state.isCreating
                        ? null
                        : () => ref
                              .read(inviteCodeProvider.notifier)
                              .createOrRegenerate(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      side: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: state.isCreating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : Text(code == null ? '가입코드 발급' : '코드 재발급'),
                  ),
                ],
              ),
            ),
    );
  }
}
