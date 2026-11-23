import 'package:flutter/material.dart';

import '../colors.dart';
import '../no_char_break.dart';
import '../radius.dart';
import '../spacing.dart';
import '../typography.dart';
import 'smash_label.dart';
import 'smash_pressable.dart';

/// 한 선택지의 투표 결과. 비율은 득표 수와 전체 득표 수로 계산한다.
class SmashPollResult {
  const SmashPollResult({
    required this.votes,
    required this.totalVotes,
    this.voters = const [],
  }) : assert(votes >= 0),
       assert(totalVotes >= votes, '전체 득표 수는 이 선택지의 득표 수 이상이다');

  /// 이 선택지의 득표 수
  final int votes;

  /// 투표 전체의 득표 수
  final int totalVotes;

  /// 투표한 사람 이름 (기명 투표일 때만 넘긴다. 익명이면 빈 목록)
  final List<String> voters;

  /// 0~1 (전체가 0표이면 0)
  double get ratio => totalVotes == 0 ? 0 : votes / totalVotes;

  /// 0~100 (반올림: 12.5 → 13)
  int get percent => (ratio * 100).round();
}

/// 투표 선택지 한 줄. 투표 전에는 눌러서 고르는 선택지이고, 투표한 뒤나 마감 후에는 결과(비율 막대, 비율, 득표 수)를 보여준다.
///
/// - **투표 전**: [onSelect]가 있고 [result]가 없다. 왼쪽에 빈 동그라미가 보이고 줄 어디를 눌러도 선택된다
/// - **결과**: [result]를 주면 비율 막대(배경), "60%", "3명"이 보인다. 막대는 색만이 아니라 숫자로도 전달된다.
///   기명 투표이면 [SmashPollResult.voters]가 이름 아래에 보인다
/// - **내 선택**: [isMine]이면 체크 아이콘, 굵은 글자, 굵은 테두리와 색 배경으로 구분한다 (색만으로 구분하지 않는다)
/// - **처리 중**: [isLoading]이면 아이콘 자리에 진행 표시가 보이고 누름이 무시된다. 아이콘 자리는 항상 있어서 상태가 바뀌어도 줄이 흔들리지 않는다
/// - 높이는 56 이상이다. 한글 이름은 낱말 중간에서 줄바꿈되지 않고, **폭이 좁으면 비율과 득표 수가 이름 아래로 내려간다**
/// - 스크린리더는 한 번에 "이름, 내가 투표함, 3명, 60%, 투표한 사람 가나다"처럼 읽는다. 눌러서 고를 수 있으면 버튼이다
///
/// 폭에 따라 배치를 바꾸려고 `LayoutBuilder`를 쓰므로 **고유 크기를 지원하지 않는다**: `SmashAdaptiveRow`, `IntrinsicHeight`, `IntrinsicWidth` 안에 두지 않는다
/// (세로 목록의 한 항목으로 쓴다).
class SmashPollOptionRow extends StatelessWidget {
  const SmashPollOptionRow({
    super.key,
    required this.label,
    this.result,
    this.isMine = false,
    this.onSelect,
    this.isLoading = false,
  });

  /// 선택지 이름
  final String label;

  /// null이면 결과를 숨긴다 (투표 전)
  final SmashPollResult? result;

  /// 내가 고른 선택지인지
  final bool isMine;

  /// 눌러서 고른다. null이면 누를 수 없다 (이미 투표했거나 마감)
  final VoidCallback? onSelect;

  /// 이 선택지를 보내는 중. 누름이 무시된다
  final bool isLoading;

  static const double minHeight = 56;
  static const double _markSize = 20;
  static const double _markGap = SmashSpacing.sm;
  static const double _gap = SmashSpacing.md;
  static const double _border = 2;

  bool get _selectable => onSelect != null;

  TextStyle get _labelStyle => (isMine ? SmashText.bodyStrong : SmashText.body);

  /// 스크린리더가 읽는 말
  String get _readAs {
    final parts = <String>[label];
    if (isMine) parts.add('내가 투표함');
    final r = result;
    if (r != null) {
      parts.add('${r.votes}명');
      parts.add('${r.percent}%');
      if (r.voters.isNotEmpty) parts.add('투표한 사람 ${r.voters.join(', ')}');
    }
    final base = parts.join(', ');
    return isLoading ? '$base, 처리 중' : base;
  }

  @override
  Widget build(BuildContext context) {
    final face = LayoutBuilder(builder: _buildFace);
    return Semantics(
      selected: isMine,
      child: (_selectable || isLoading)
          ? SmashPressable(
              onPressed: isLoading ? _noop : onSelect,
              borderRadius: SmashRadius.circular(SmashRadius.md),
              minSize: const Size(SmashSpacing.minTouchTarget, minHeight),
              semanticLabel: _readAs,
              builder: (context, states) => _frame(
                face,
                pressed: states.contains(WidgetState.pressed),
                focused: states.contains(WidgetState.focused),
              ),
            )
          : Semantics(
              label: _readAs,
              excludeSemantics: true,
              child: _frame(face, pressed: false, focused: false),
            ),
    );
  }

  static void _noop() {}

  Widget _frame(Widget face, {required bool pressed, required bool focused}) {
    final borderColor = isMine
        ? SmashColors.brand
        : _selectable
        ? SmashColors.border
        : SmashColors.line;
    return Container(
      constraints: const BoxConstraints(minHeight: minHeight),
      decoration: BoxDecoration(
        color: pressed ? SmashColors.brandTintSoft : SmashColors.surface,
        borderRadius: SmashRadius.circular(SmashRadius.md),
      ),
      // 테두리는 위에 그린다: 굵기가 바뀌어도 안쪽 크기가 변하지 않는다
      foregroundDecoration: BoxDecoration(
        borderRadius: SmashRadius.circular(SmashRadius.md),
        border: Border.all(
          color: focused ? SmashColors.brand : borderColor,
          width: (isMine || focused) ? _border : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: SmashRadius.circular(SmashRadius.md),
        child: face,
      ),
    );
  }

  Widget _buildFace(BuildContext context, BoxConstraints constraints) {
    final r = result;
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);

    double measure(String text, TextStyle style, {bool longestWord = false}) {
      final painter = TextPainter(
        text: TextSpan(
          text: longestWord ? noCharBreak(text) : text,
          style: style,
        ),
        textDirection: direction,
        textScaler: scaler,
      )..layout();
      final width = longestWord ? painter.minIntrinsicWidth : painter.width;
      painter.dispose();
      return width;
    }

    final percentText = r == null ? '' : '${r.percent}%';
    final countText = r == null ? '' : '${r.votes}명';
    final resultWidth = r == null
        ? 0.0
        : measure(percentText, SmashText.bodyStrong) >
              measure(countText, SmashText.caption)
        ? measure(percentText, SmashText.bodyStrong)
        : measure(countText, SmashText.caption);
    final inner = constraints.maxWidth - 2 * SmashSpacing.md - 2 * _border;
    final labelNeed = measure(label, _labelStyle, longestWord: true);
    // 이름의 가장 긴 낱말과 결과 열이 한 줄에 같이 들어가지 않으면 결과를 이름 아래로 내린다
    final stacked =
        r != null &&
        _markSize + _markGap + labelNeed + _gap + resultWidth > inner;

    final nameColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SmashLabel(
          label,
          style: _labelStyle.copyWith(
            color: isMine ? SmashColors.brand : SmashColors.text,
          ),
        ),
        if (r != null && r.voters.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: SmashSpacing.xs),
            child: SmashLabel(r.voters.join(', '), style: SmashText.caption),
          ),
        if (stacked)
          Padding(
            padding: const EdgeInsets.only(top: SmashSpacing.xs),
            child: Wrap(
              spacing: SmashSpacing.sm,
              children: [
                SmashLabel(percentText, style: SmashText.bodyStrong),
                SmashLabel(
                  countText,
                  style: SmashText.caption.copyWith(height: 24 / 13),
                ),
              ],
            ),
          ),
      ],
    );

    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SmashSpacing.md + _border,
        vertical: SmashSpacing.sm + _border,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: _markSize, height: _markSize, child: _mark()),
          const SizedBox(width: _markGap),
          Expanded(child: nameColumn),
          if (r != null && !stacked) ...[
            const SizedBox(width: _gap),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                SmashLabel(percentText, style: SmashText.bodyStrong),
                SmashLabel(countText, style: SmashText.caption),
              ],
            ),
          ],
        ],
      ),
    );

    if (r == null || r.ratio <= 0) return content;
    return Stack(
      children: [
        Positioned.fill(
          child: FractionallySizedBox(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: r.ratio,
            child: ColoredBox(
              key: const ValueKey('pollBar'),
              color: isMine ? SmashColors.brandTint : SmashColors.fillDisabled,
            ),
          ),
        ),
        content,
      ],
    );
  }

  /// 아이콘 자리: 처리 중 진행 표시, 내 선택 체크, 선택 가능 빈 동그라미, 그 외 비어 있음
  Widget _mark() {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(2),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(SmashColors.brand),
        ),
      );
    }
    if (isMine) {
      return const Icon(
        Icons.check_circle,
        size: _markSize,
        color: SmashColors.brand,
      );
    }
    if (_selectable) {
      return const Icon(
        Icons.radio_button_unchecked,
        size: _markSize,
        // 결과 막대(연한 회색) 위에서도 3:1 이상이어야 해서 테두리색이 아니라 보조 글자색이다
        color: SmashColors.textSecondary,
      );
    }
    return const SizedBox.shrink();
  }
}
