import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/components/components.dart';
import '../../../core/design/smash_theme.dart';
import '../../../core/design/tokens.dart';
import '../../home/provider/auth_provider.dart';
import '../provider/signup_draft_provider.dart';

/// 가입 3단계의 경로. 1단계가 `/signup`이고 2, 3단계는 그 아래 경로다.
/// 단계는 각각 별도 화면이라 시스템 뒤로 가기(Android 버튼, iOS 가장자리 스와이프)가 기본 동작으로 이전 단계로 간다.
/// 1단계에서 뒤로 가면 가입 화면을 나가 로그인 화면으로 돌아간다.
const signupCodePath = '/signup';
const signupIdPath = '/signup/id';
const signupPasswordPath = '/signup/password';

/// 가입 경로들 (app.dart와 화면 갤러리가 같은 것을 쓴다)
List<GoRoute> signupRoutes() => [
  GoRoute(
    path: signupCodePath,
    builder: (context, state) => const SignupPage(),
  ),
  GoRoute(
    path: signupIdPath,
    builder: (context, state) => const SignupIdPage(),
  ),
  GoRoute(
    path: signupPasswordPath,
    builder: (context, state) => const SignupPasswordPage(),
  ),
];

const _stepNames = ['가입코드', '학번', '비밀번호'];

/// 가입 단계 화면의 공통 틀: 밝은 테마, 앱바(뒤로), 진행 표시, 제목
class _SignupFrame extends StatelessWidget {
  const _SignupFrame({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.children,
  });

  final int step;
  final String title;
  final String subtitle;
  final VoidCallback? onBack;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: SmashTheme.light(),
      child: SmashScaffold(
        appBar: SmashAppBar(title: '회원가입', onBack: onBack),
        body: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(SmashSpacing.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SmashStepIndicator(steps: _stepNames, current: step),
                  const SizedBox(height: SmashSpacing.lg),
                  Semantics(
                    header: true,
                    child: SmashLabel(title, style: SmashText.title),
                  ),
                  const SizedBox(height: SmashSpacing.xs),
                  SmashLabel(
                    subtitle,
                    style: SmashText.body.copyWith(
                      color: SmashColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: SmashSpacing.xl),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 뒤로 간다. 가입 흐름은 로그인 화면 위에 쌓여 있으므로 보통 이전 화면이 있다
void _goBack(BuildContext context) {
  if (context.canPop()) context.pop();
}

/// 1단계: 가입코드
class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(signupDraftProvider).code,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_controller.text.trim().isEmpty) {
      setState(() => _error = '가입코드를 입력해주세요.');
      return;
    }
    ref.read(signupDraftProvider.notifier).setCode(_controller.text);
    context.push(signupIdPath);
  }

  @override
  Widget build(BuildContext context) {
    // 가입 흐름이 끝날 때까지 입력 상태를 살려 둔다 (watch로 붙어 있으면 autoDispose되지 않는다)
    ref.watch(signupDraftProvider.notifier);

    return _SignupFrame(
      step: 0,
      title: '회원가입',
      subtitle: '동아리에서 받은 가입코드가 필요해요',
      onBack: () => _goBack(context),
      children: [
        SmashTextField(
          label: '가입코드',
          controller: _controller,
          errorText: _error,
          textInputAction: TextInputAction.next,
          autofocus: true,
          onChanged: (value) {
            ref.read(signupDraftProvider.notifier).setCode(value);
            if (_error != null) setState(() => _error = null);
          },
          onSubmitted: (_) => _next(),
        ),
        const SizedBox(height: SmashSpacing.lg),
        SmashButton(label: '다음', onPressed: _next),
      ],
    );
  }
}

/// 2단계: 학번
class SignupIdPage extends ConsumerStatefulWidget {
  const SignupIdPage({super.key});

  @override
  ConsumerState<SignupIdPage> createState() => _SignupIdPageState();
}

class _SignupIdPageState extends ConsumerState<SignupIdPage> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(signupDraftProvider).studentNo,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_controller.text.trim().isEmpty) {
      setState(() => _error = '학번을 입력해주세요.');
      return;
    }
    ref.read(signupDraftProvider.notifier).setStudentNo(_controller.text);
    context.push(signupPasswordPath);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(signupDraftProvider.notifier);

    return _SignupFrame(
      step: 1,
      title: '학번을 입력해 주세요',
      subtitle: '로그인할 때 학번을 사용해요',
      onBack: () => _goBack(context),
      children: [
        SmashTextField(
          label: '학번',
          controller: _controller,
          errorText: _error,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          autofocus: true,
          onChanged: (value) {
            ref.read(signupDraftProvider.notifier).setStudentNo(value);
            if (_error != null) setState(() => _error = null);
          },
          onSubmitted: (_) => _next(),
        ),
        const SizedBox(height: SmashSpacing.lg),
        SmashButton(label: '다음', onPressed: _next),
      ],
    );
  }
}

/// 3단계: 비밀번호. 여기서 서버에 가입을 요청한다
class SignupPasswordPage extends ConsumerStatefulWidget {
  const SignupPasswordPage({super.key});

  @override
  ConsumerState<SignupPasswordPage> createState() => _SignupPasswordPageState();
}

class _SignupPasswordPageState extends ConsumerState<SignupPasswordPage> {
  late final TextEditingController _controller;
  String? _error;

  /// 이 화면이 가입을 요청했는지 (가입 화면이 위에 없는 동안의 상태 변화에 자동완성을 저장하지 않으려는 표시)
  bool _requested = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(signupDraftProvider).password,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // 키보드의 완료 키로도 들어오므로, 버튼의 처리 중 잠금과 별개로 여기서도 막는다
    if (ref.read(authProvider).isLoading) return;

    final password = _controller.text;
    final error = password.isEmpty
        ? '비밀번호를 입력해주세요.'
        : password.length < 4
        ? '비밀번호는 4자 이상이어야 합니다.'
        : null;
    setState(() => _error = error);
    if (error != null) return;

    final draft = ref.read(signupDraftProvider.notifier);
    draft.setPassword(password);
    draft.setAttempted(true);
    _requested = true;
    final values = ref.read(signupDraftProvider);
    await ref
        .read(authProvider.notifier)
        .signup(values.code.trim(), values.studentNo.trim(), password);
  }

  /// 1단계(가입코드)로 돌아간다. 입력은 그대로 남는다 (3단계 → 2단계 → 1단계)
  void _backToFirst() {
    ref.read(signupDraftProvider.notifier).setAttempted(false);
    final router = GoRouter.of(context);
    for (var i = 0; i < 2 && router.canPop(); i++) {
      router.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(signupDraftProvider.notifier);
    final authState = ref.watch(authProvider);
    final attempted = ref.watch(
      signupDraftProvider.select((draft) => draft.attempted),
    );
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (_requested && previous?.user == null && next.user != null) {
        TextInput.finishAutofillContext();
      }
    });

    final errorMessage = (attempted && !authState.isLoading)
        ? authState.errorMessage
        : null;

    return PopScope(
      // 요청 중에는 이 화면을 나갈 수 없다 (결과를 보지 못하고 떠나지 않도록)
      canPop: !authState.isLoading,
      child: _SignupFrame(
        step: 2,
        title: '비밀번호를 정해 주세요',
        subtitle: '4자 이상으로 입력해 주세요',
        onBack: authState.isLoading ? null : () => _goBack(context),
        children: [
          AutofillGroup(
            onDisposeAction: AutofillContextAction.cancel,
            child: SmashPasswordField(
              label: '비밀번호',
              controller: _controller,
              errorText: _error,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.done,
              autofocus: true,
              onChanged: (value) {
                ref.read(signupDraftProvider.notifier).setPassword(value);
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (_) => _submit(),
            ),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: SmashSpacing.md),
            SmashInlineNotice(
              message: errorMessage,
              tone: SmashNoticeTone.danger,
              actionLabel: '1단계로 가기',
              onAction: _backToFirst,
            ),
          ],
          const SizedBox(height: SmashSpacing.lg),
          SmashButton(
            label: '가입하기',
            isLoading: authState.isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
