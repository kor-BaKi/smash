import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/invite_code_controller.dart';

class InviteCodePage extends ConsumerWidget {
  const InviteCodePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codesState = ref.watch(inviteCodeControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('가입코드 관리'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '새 코드 발급',
            onPressed: () => ref.read(inviteCodeControllerProvider.notifier).createInviteCode(),
          ),
        ],
      ),
      body: codesState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (codes) {
          if (codes.isEmpty) {
            return Center(
              child: FilledButton(
                onPressed: () => ref.read(inviteCodeControllerProvider.notifier).createInviteCode(),
                child: const Text('가입코드 발급'),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(inviteCodeControllerProvider.notifier).refresh(),
            child: ListView.builder(
              itemCount: codes.length,
              itemBuilder: (context, index) {
                final code = codes[index];
                return SwitchListTile(
                  title: Text(code.code),
                  subtitle: Text(code.isActive ? '활성' : '비활성'),
                  value: code.isActive,
                  onChanged: (value) =>
                      ref.read(inviteCodeControllerProvider.notifier).setActive(code.id, value),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
