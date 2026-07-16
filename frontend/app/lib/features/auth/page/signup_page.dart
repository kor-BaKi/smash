import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../provider/auth_provider.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _codeController = TextEditingController();
  final _studentNoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _codeController.dispose();
    _studentNoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authProvider.notifier)
        .signup(
          _codeController.text.trim(),
          _studentNoController.text.trim(),
          _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.cardBg,
      appBar: AppBar(backgroundColor: AppColors.cardBg, elevation: 0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '회원가입',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '동아리에서 받은 가입코드가 필요해요',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 32),
                _buildLabel('가입코드'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _codeController,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                    color: AppColors.primaryDeep,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.primaryBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? '가입코드를 입력해주세요.' : null,
                ),
                const SizedBox(height: 16),
                _buildLabel('학번'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _studentNoController,
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? '학번을 입력해주세요.' : null,
                ),
                const SizedBox(height: 16),
                _buildLabel('비밀번호'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return '비밀번호를 입력해주세요.';
                    if (v.length < 4) return '비밀번호는 4자 이상이어야 합니다.';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                if (authState.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      authState.errorMessage!,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: authState.isLoading ? null : _signup,
                  child: authState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('가입하기'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: AppColors.textTertiary,
    ),
  );
}
