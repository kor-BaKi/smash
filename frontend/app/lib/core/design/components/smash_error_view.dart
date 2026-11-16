import 'package:flutter/material.dart';

import '../../error/error_messages.dart';
import '../spacing.dart';
import 'smash_empty.dart';
import 'smash_inline_notice.dart';

/// 화면 전체를 불러오지 못했을 때 보여준다. 문구는 [ErrorMessages]가 정한다
/// (예외 객체의 글자를 그대로 보이지 않는다).
///
/// - 인터넷 문제이면 "인터넷에 연결되지 않았어요"로 제목이 바뀐다 (오프라인 안내는 API 오류를 기준으로 한다)
/// - [onRetry]가 있으면 "다시 시도" 버튼이 붙는다
/// - [scrollable]이 true이면 내용이 짧아도 당겨서 새로고침이 된다. false여도 공간보다 내용이 크면 넘치지 않고 스크롤된다
class SmashErrorView extends StatelessWidget {
  const SmashErrorView({
    super.key,
    required this.error,
    this.onRetry,
    this.scrollable = false,
  });

  final Object? error;
  final VoidCallback? onRetry;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final offline = ErrorMessages.isOffline(error);
    final content = SmashStateMessage(
      icon: offline ? Icons.wifi_off_outlined : Icons.error_outline,
      title: offline ? '인터넷에 연결되지 않았어요' : '불러오지 못했어요',
      message: ErrorMessages.of(error),
      actionLabel: '다시 시도',
      onAction: onRetry,
      liveRegion: true,
    );
    return SmashFillScroll(alwaysScrollable: scrollable, child: content);
  }
}

/// 이미 보여주던 내용 위에 띄우는 한 줄 안내 (새로고침에 실패했을 때).
/// 인터넷 문제이면 오프라인 안내로, 아니면 오류 안내로 바뀐다.
class SmashErrorBanner extends StatelessWidget {
  const SmashErrorBanner({super.key, required this.error, this.onRetry});

  final Object? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final offline = ErrorMessages.isOffline(error);
    return Padding(
      padding: const EdgeInsets.all(SmashSpacing.md),
      child: SmashInlineNotice(
        tone: offline ? SmashNoticeTone.warning : SmashNoticeTone.danger,
        title: offline ? '인터넷에 연결되지 않았어요' : null,
        message: offline ? '연결을 확인하고 다시 시도해 주세요. 지금 보이는 내용은 이전에 불러온 거예요.' : ErrorMessages.of(error),
        actionLabel: '다시 시도',
        onAction: onRetry,
      ),
    );
  }
}
