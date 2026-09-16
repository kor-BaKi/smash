import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('가입코드 관리')),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.lime),
            )
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '현재 가입코드',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.gray,
                          ),
                        ),
                        const SizedBox(height: 14),
                        GestureDetector(
                          onTap: code == null
                              ? null
                              : () {
                                  Clipboard.setData(
                                    ClipboardData(text: code.code),
                                  );
                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text('가입코드가 복사되었습니다.'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                code?.code ?? '없음',
                                style: const TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 4,
                                  color: AppColors.lime,
                                ),
                              ),
                              if (code != null) ...[
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.copy,
                                  size: 20,
                                  color: AppColors.lime,
                                ),
                              ],
                            ],
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
                                  ? AppColors.greenTag
                                  : AppColors.grayTag,
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
                                        ? AppColors.green
                                        : AppColors.darkGray,
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
                                        ? AppColors.greenTagText
                                        : AppColors.grayTagText,
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
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          '코드 활성화',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.white,
                          ),
                        ),
                        subtitle: const Text(
                          '끄면 신규 가입이 막혀요',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.gray,
                          ),
                        ),
                        value: code.isActive,
                        activeColor: AppColors.lime,
                        activeTrackColor: AppColors.lime.withValues(
                          alpha: 0.3,
                        ),
                        inactiveThumbColor: AppColors.darkGray,
                        inactiveTrackColor: AppColors.card2,
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
                        style: const TextStyle(color: AppColors.coral),
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
                        color: AppColors.lime,
                        width: 1.5,
                      ),
                      foregroundColor: AppColors.lime,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: state.isCreating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.lime,
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
