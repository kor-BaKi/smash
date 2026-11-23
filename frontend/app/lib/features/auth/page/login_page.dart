import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/components/components.dart';
import '../../../core/design/smash_theme.dart';
import '../../../core/design/tokens.dart';
import '../../home/provider/auth_provider.dart';

/// 로그인 화면 (SMASH 라이트 디자인).
///
/// - 서버 호출은 `authProvider`의 `login(학번, 비밀번호)` 한 번이고, 학번은 앞뒤 공백을 지우고 비밀번호는 그대로 보낸다.
/// - 성공하면 화면이 직접 이동하지 않는다. 로그인 상태가 바뀌면 `routerProvider`의 redirect가 `/home`으로 보낸다.
/// - 가입은 `/signup`을 push로 연다 (뒤로 가면 로그인 화면으로 돌아온다).
/// - 입력창이 비었으면 서버를 부르지 않고 그 입력창 아래에 안내를 보이며 포커스를 옮긴다.
/// - 서버·네트워크 오류와 시도 제한은 `authProvider`가 주는 문구를 폼 아래의 안내로 보인다
///   (요청 중에는 이전 문구를 숨긴다).
/// - 학번 칸은 자동완성 힌트 username, 비밀번호 칸은 password다. 로그인에 성공하는 순간 자동완성 정보를 저장한다.
///   (비밀번호 칸의 복사, 잘라내기 차단은 붙여넣기와 자동완성에 영향이 없다)
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _studentNoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _studentNoFocus = FocusNode();
  final _passwordFocus = FocusNode();

  String? _studentNoError;
  String? _passwordError;

  /// 이 화면이 로그인을 요청했는지. 가입 화면이 위에 떠 있는 동안 가입이 성공해도
  /// 이 화면의 (빈) 입력 내용이 자동완성에 저장되지 않게 한다
  bool _requested = false;

  @override
  void dispose() {
    _studentNoController.dispose();
    _passwordController.dispose();
    _studentNoFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // 키보드의 완료 키로도 들어오므로, 버튼의 처리 중 잠금과 별개로 여기서도 막는다
    if (ref.read(authProvider).isLoading) return;

    final studentNo = _studentNoController.text.trim();
    final password = _passwordController.text;
    final studentNoError = studentNo.isEmpty ? '학번을 입력해주세요.' : null;
    final passwordError = password.isEmpty ? '비밀번호를 입력해주세요.' : null;
    setState(() {
      _studentNoError = studentNoError;
      _passwordError = passwordError;
    });
    if (studentNoError != null) {
      _studentNoFocus.requestFocus();
      return;
    }
    if (passwordError != null) {
      _passwordFocus.requestFocus();
      return;
    }

    _requested = true;
    await ref.read(authProvider.notifier).login(studentNo, password);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (_requested && previous?.user == null && next.user != null) {
        TextInput.finishAutofillContext();
      }
    });

    final errorMessage = authState.isLoading ? null : authState.errorMessage;
    // 키보드가 올라오면 로고를 접어 입력창이 들어갈 자리를 만든다 (Scaffold 안쪽에서는 키보드 높이가 빠져 있어 여기서 판단한다)
    final keyboardUp = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Theme(
      data: SmashTheme.light(),
      child: SmashScaffold(
        body: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            SmashSpacing.lg,
            keyboardUp ? SmashSpacing.md : SmashSpacing.xl,
            SmashSpacing.lg,
            SmashSpacing.lg,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: AutofillGroup(
                onDisposeAction: AutofillContextAction.cancel,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!keyboardUp)
                      Padding(
                        padding: const EdgeInsets.only(bottom: SmashSpacing.lg),
                        // 로고는 흰색 투명 그림이라 밝은 배경에서는 브랜드 색으로 칠해 쓴다
                        child: Center(
                          child: Image.asset(
                            'assets/icon/logo_transparent.png',
                            width: 120,
                            fit: BoxFit.contain,
                            color: SmashColors.brand,
                            colorBlendMode: BlendMode.srcIn,
                            excludeFromSemantics: true,
                          ),
                        ),
                      ),
                    Semantics(
                      header: true,
                      child: const SmashLabel(
                        '다시 만나 반가워요',
                        style: SmashText.title,
                      ),
                    ),
                    const SizedBox(height: SmashSpacing.xs),
                    SmashLabel(
                      'SMASH 계정으로 로그인하세요',
                      style: SmashText.body.copyWith(
                        color: SmashColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: SmashSpacing.xl),
                    SmashTextField(
                      label: '학번',
                      controller: _studentNoController,
                      focusNode: _studentNoFocus,
                      errorText: _studentNoError,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.username],
                      autocorrect: false,
                      enableSuggestions: false,
                      onChanged: (_) {
                        if (_studentNoError != null) {
                          setState(() => _studentNoError = null);
                        }
                      },
                    ),
                    const SizedBox(height: SmashSpacing.md),
                    SmashPasswordField(
                      label: '비밀번호',
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      errorText: _passwordError,
                      textInputAction: TextInputAction.done,
                      onChanged: (_) {
                        if (_passwordError != null) {
                          setState(() => _passwordError = null);
                        }
                      },
                      onSubmitted: (_) => _login(),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: SmashSpacing.md),
                      SmashInlineNotice(
                        message: errorMessage,
                        tone: SmashNoticeTone.danger,
                      ),
                    ],
                    const SizedBox(height: SmashSpacing.lg),
                    SmashButton(
                      label: '로그인',
                      isLoading: authState.isLoading,
                      onPressed: _login,
                    ),
                    const SizedBox(height: SmashSpacing.md),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SmashLabel(
                          '아직 회원이 아니신가요?',
                          style: SmashText.body.copyWith(
                            color: SmashColors.textSecondary,
                          ),
                        ),
                        SmashButton(
                          label: '가입하기',
                          variant: SmashButtonVariant.text,
                          size: SmashButtonSize.medium,
                          expanded: false,
                          onPressed: () => context.push('/signup'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
