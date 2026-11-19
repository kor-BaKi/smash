import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../format/hour12.dart';
import '../../rules/time_slots.dart';
import '../colors.dart';
import '../haptics.dart';
import '../motion.dart';
import '../radius.dart';
import '../shadows.dart';
import '../spacing.dart';
import '../typography.dart';
import 'smash_label.dart';
import 'smash_pressable.dart';
import 'smash_segmented_control.dart';

/// 시간을 고르는 입력: `[오전|오후]` 토글과 `[시] : [분]` 두 칸. 칸을 누르면 그 칸에 붙은 팝업에 목록이 열린다.
///
/// - 시는 1~12, 분은 00~59(1분 단위). 목록은 평평한 `ListView`이고 한 줄은 48dp 이상이며, 글자가 커지면 줄이 높아진다 (줄어들지 않는다)
/// - **팝업**: 목록은 화면 위에 뜨는 팝업(오버레이)이라 열려도 시트나 화면의 높이가 변하지 않는다.
///   칸 아래에 열리고, 아래 공간이 모자라면 칸 위에 열린다. 폭은 칸 폭 이상이다.
///   보이는 줄은 [visibleRows](기본 5)이고, 공간이 모자라면 줄 수를 줄인다 ([SmashTimePopupPlacement], 글자 2.0배에서도 화면 밖으로 나가지 않는다)
/// - 줄을 누르면 고르고 팝업이 닫힌다 (확인 버튼 없음). **바깥 누르기, 뒤로 가기, 스크린리더의 탈출 제스처**는 값을 바꾸지 않고
///   팝업만 닫는다 (이 입력이 들어 있는 시트나 화면은 닫히지 않는다)
/// - 팝업이 열리면 포커스가 목록(고른 줄)으로 가고, 닫히면 그 팝업을 연 칸으로 돌아온다
/// - 드래그로 스크롤할 수 있다. 열릴 때는 애니메이션 없이 고른 값이 보이는 위치에 놓이고,
///   고른 값을 지금 고를 수 없으면(날짜를 오늘로 바꾼 직후 등) 처음으로 고를 수 있는 값이 보이는 위치에 놓인다
/// - 어떤 시각을 고를 수 있는지는 [isSelectable]이 정한다 (예: `DeadlineRules.isSelectable`). 고를 수 없는 시, 분 줄과
///   오전/오후 토글은 누를 수 없고, 스크린리더에는 비활성과 이유([disabledHint])로 읽힌다
/// - 시나 오전/오후를 바꿔서 지금 값(분)이 고를 수 없게 되면 고를 수 있는 값으로 맞춘다 ([TimeSlots.resolve])
/// - [value]의 날짜 부분은 어느 날의 시간을 고르는지 알려 주고, 바뀐 값([onChanged])은 같은 날의 시각이다
/// - 열린 목록은 끝에서 튕기지 않아서, 목록을 드래그해도 바깥의 시트나 화면이 함께 움직이지 않는다
/// - 오전/오후 토글 폭은 "체크 + 오전"이 한 줄에 들어가는 내용 폭이다
class SmashTimeFieldPicker extends StatefulWidget {
  const SmashTimeFieldPicker({
    super.key,
    required this.value,
    required this.onChanged,
    required this.isSelectable,
    this.disabledHint = '지금보다 이전이라 선택할 수 없어요',
    this.visibleRows = 5,
  });

  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final SelectablePredicate isSelectable;
  final String disabledHint;

  /// 팝업에 한 번에 보이는 줄 수 (최대). 공간이 모자라면 [SmashTimePopupPlacement.minRows]까지 줄어든다
  final int visibleRows;

  static const double minRowHeight = 48;

  @override
  State<SmashTimeFieldPicker> createState() => _SmashTimeFieldPickerState();
}

/// 팝업의 위치와 크기. 칸([anchor]) 아래에 열고, 아래 공간이 [preferredRows]줄에 모자라면 위에 열며,
/// 위아래 모두 모자라면 더 넓은 쪽에 열고 줄 수를 줄인다. 화면 밖으로 나가지 않는 것이 줄 수 하한보다 우선이다
/// (화면에 [minRows]줄도 안 들어가는 아주 작은 화면에서만 [minRows]줄 미만이 된다).
///
/// 좌표는 모두 오버레이 기준이다. 안쪽 구현이라 [SmashTimeFieldPicker] 밖에서 쓸 일은 없다
@immutable
class SmashTimePopupPlacement {
  const SmashTimePopupPlacement({
    required this.above,
    required this.rows,
    required this.height,
    required this.width,
    required this.dx,
  });

  /// true이면 칸 위에, false이면 칸 아래에 연다
  final bool above;

  /// 보이는 줄 수
  final int rows;

  /// 팝업 전체 높이 (줄 높이 × 줄 수 + 위아래 테두리)
  final double height;
  final double width;

  /// 칸의 왼쪽 끝에서 팝업의 왼쪽 끝까지의 가로 이동 (화면 오른쪽 끝을 넘지 않게 왼쪽으로 밀 때 음수)
  final double dx;

  static const int minRows = 3;
  static const double gap = 4;
  static const double margin = 8;
  static const double minWidth = 96;
  static const double border = 2;

  static SmashTimePopupPlacement compute({
    required Rect anchor,
    required Size bounds,
    required EdgeInsets safe,
    required double rowHeight,
    int preferredRows = 5,
  }) {
    final topLimit = safe.top + margin;
    final bottomLimit = bounds.height - safe.bottom - margin;
    final below = bottomLimit - (anchor.bottom + gap);
    final above = anchor.top - gap - topLimit;
    int fit(double space) =>
        math.max(0, ((space - border) / rowHeight).floor());
    final rowsBelow = fit(below);
    final rowsAbove = fit(above);

    final bool openAbove;
    int rows;
    if (rowsBelow >= preferredRows) {
      openAbove = false;
      rows = preferredRows;
    } else if (rowsAbove >= preferredRows) {
      openAbove = true;
      rows = preferredRows;
    } else if (rowsAbove > rowsBelow) {
      openAbove = true;
      rows = rowsAbove;
    } else {
      openAbove = false;
      rows = rowsBelow;
    }
    rows = math.max(1, rows);

    final maxWidth = math.max(
      0.0,
      bounds.width - safe.left - safe.right - 2 * margin,
    );
    final width = math.min(math.max(anchor.width, minWidth), maxWidth);
    final minLeft = safe.left + margin;
    final maxLeft = math.max(
      minLeft,
      bounds.width - safe.right - margin - width,
    );
    final left = anchor.left.clamp(minLeft, maxLeft).toDouble();

    return SmashTimePopupPlacement(
      above: openAbove,
      rows: rows,
      height: rows * rowHeight + border,
      width: width,
      dx: left - anchor.left,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SmashTimePopupPlacement &&
      other.above == above &&
      other.rows == rows &&
      other.height == height &&
      other.width == width &&
      other.dx == dx;

  @override
  int get hashCode => Object.hash(above, rows, height, width, dx);

  @override
  String toString() =>
      'SmashTimePopupPlacement(above: $above, rows: $rows, height: $height, width: $width, dx: $dx)';
}

enum _Open { none, hour, minute }

class _SmashTimeFieldPickerState extends State<SmashTimeFieldPicker> {
  _Open _open = _Open.none;

  final _portal = OverlayPortalController();
  final _hourLink = LayerLink();
  final _minuteLink = LayerLink();
  final _hourKey = GlobalKey();
  final _minuteKey = GlobalKey();
  final _hourFocus = FocusNode(debugLabel: '시 칸');
  final _minuteFocus = FocusNode(debugLabel: '분 칸');

  DateTime get _date =>
      DateTime(widget.value.year, widget.value.month, widget.value.day);
  ({int hour12, bool isPm}) get _hour => toHour12(widget.value.hour);

  String _hourWord(int hour12, bool isPm) => '${isPm ? '오후' : '오전'} $hour12시';

  @override
  void dispose() {
    _hourFocus.dispose();
    _minuteFocus.dispose();
    super.dispose();
  }

  void _openList(_Open which) {
    setState(() => _open = which);
    if (!_portal.isShowing) _portal.show();
  }

  /// 팝업만 닫는다 (값은 그대로). 포커스는 그 팝업을 연 칸으로 돌아간다
  void _close() {
    final previous = _open;
    if (previous == _Open.none) return;
    setState(() => _open = _Open.none);
    if (_portal.isShowing) _portal.hide();
    (previous == _Open.hour ? _hourFocus : _minuteFocus).requestFocus();
  }

  void _toggleOpen(_Open which) => _open == which ? _close() : _openList(which);

  void _emit(DateTime? next) {
    _close();
    if (next != null) widget.onChanged(next);
  }

  void _chooseHalf(bool isPm) {
    final h = _hour;
    _emit(
      TimeSlots.resolve(
        _date,
        h.hour12,
        isPm,
        widget.value.minute,
        widget.isSelectable,
      ),
    );
  }

  void _chooseHour(int hour12) {
    _emit(
      TimeSlots.resolve(
        _date,
        hour12,
        _hour.isPm,
        widget.value.minute,
        widget.isSelectable,
      ),
    );
  }

  void _chooseMinute(int minute) {
    final h = _hour;
    _emit(TimeSlots.compose(_date, h.hour12, h.isPm, minute));
  }

  double _rowHeight(BuildContext context) {
    final body = SmashText.body;
    final lineHeight =
        MediaQuery.textScalerOf(context).scale(body.fontSize!) * body.height!;
    final needed = lineHeight + 2 * SmashSpacing.sm;
    return needed > SmashTimeFieldPicker.minRowHeight
        ? needed
        : SmashTimeFieldPicker.minRowHeight;
  }

  @override
  Widget build(BuildContext context) {
    final h = _hour;
    final scale = MediaQuery.textScalerOf(context).scale(1);

    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: _buildPopup,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final date = _date;
          final amEnabled = TimeSlots.isHalfEnabled(
            date,
            false,
            widget.isSelectable,
          );
          final pmEnabled = TimeSlots.isHalfEnabled(
            date,
            true,
            widget.isSelectable,
          );
          // 칸 폭은 글자 크기를 따라 커지되 줄 폭을 넘지 않는다 (좁은 화면 + 큰 글자에서도 넘치지 않게)
          final fitted = (constraints.maxWidth - 2 * SmashSpacing.md).clamp(
            60.0,
            double.infinity,
          );
          final cellWidth = (84 * scale).clamp(84.0, 170.0).clamp(0.0, fitted);
          // 글자가 커서 한 줄에 안 들어가면 토글, 시 칸, 분 칸이 각각 아래 줄로 내려간다
          return Wrap(
            spacing: SmashSpacing.md,
            runSpacing: SmashSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // 토글 폭은 "체크 + 오전"이 한 줄에 들어가는 폭(내용 폭)이다. 고정 폭이면 선택된 조각(체크가 폭을 차지)이 모자라 글자가 쪼개진다.
              // 두 조각은 같은 폭(더 넓은 쪽에 맞춤)이라 선택이 바뀌어도 폭이 변하지 않는다. 줄 폭을 넘으면 줄 폭까지만 커진다
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                child: IntrinsicWidth(
                  child: SmashSegmentedControl<bool>(
                    semanticLabel: '오전 또는 오후',
                    segments: [
                      SmashSegment(
                        value: false,
                        label: '오전',
                        enabled: amEnabled,
                      ),
                      SmashSegment(
                        value: true,
                        label: '오후',
                        enabled: pmEnabled,
                      ),
                    ],
                    selected: h.isPm,
                    onChanged: _chooseHalf,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Cell(
                    width: cellWidth,
                    text: '${h.hour12}시',
                    semanticLabel: '시 선택, 현재 ${_hourWord(h.hour12, h.isPm)}',
                    open: _open == _Open.hour,
                    link: _hourLink,
                    anchorKey: _hourKey,
                    focusNode: _hourFocus,
                    onPressed: () => _toggleOpen(_Open.hour),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: SmashSpacing.xs),
                    child: ExcludeSemantics(
                      child: SmashLabel(':', style: SmashText.heading),
                    ),
                  ),
                ],
              ),
              _Cell(
                width: cellWidth,
                text: '${widget.value.minute.toString().padLeft(2, '0')}분',
                semanticLabel: '분 선택, 현재 ${widget.value.minute}분',
                open: _open == _Open.minute,
                link: _minuteLink,
                anchorKey: _minuteKey,
                focusNode: _minuteFocus,
                onPressed: () => _toggleOpen(_Open.minute),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPopup(BuildContext context) {
    final which = _open;
    if (which == _Open.none) return const SizedBox.shrink();
    final isHour = which == _Open.hour;
    final anchorBox = (isHour ? _hourKey : _minuteKey).currentContext
        ?.findRenderObject();
    final overlayBox = Overlay.of(context).context.findRenderObject();
    if (anchorBox is! RenderBox ||
        !anchorBox.attached ||
        !anchorBox.hasSize ||
        overlayBox is! RenderBox) {
      return const SizedBox.shrink();
    }

    final h = _hour;
    final date = _date;
    final rowHeight = _rowHeight(context);
    final media = MediaQuery.of(context);
    final anchor =
        overlayBox.globalToLocal(anchorBox.localToGlobal(Offset.zero)) &
        anchorBox.size;
    final placement = SmashTimePopupPlacement.compute(
      anchor: anchor,
      bounds: overlayBox.size,
      safe: EdgeInsets.fromLTRB(
        media.padding.left,
        media.padding.top,
        media.padding.right,
        math.max(media.padding.bottom, media.viewInsets.bottom),
      ),
      rowHeight: rowHeight,
      preferredRows: widget.visibleRows,
    );

    final list = isHour
        ? _TimeList(
            key: ValueKey('hour-list|${h.isPm}'),
            rowHeight: rowHeight,
            visibleRows: placement.rows,
            itemCount: TimeSlots.hourList.length,
            selectedIndex: TimeSlots.hourList.indexOf(h.hour12),
            labelOf: (i) => '${TimeSlots.hourList[i]}시',
            semanticOf: (i) => _hourWord(TimeSlots.hourList[i], h.isPm),
            enabledOf: (i) => TimeSlots.isHourEnabled(
              date,
              TimeSlots.hourList[i],
              h.isPm,
              widget.isSelectable,
            ),
            onSelected: (i) => _chooseHour(TimeSlots.hourList[i]),
            disabledHint: widget.disabledHint,
          )
        : _TimeList(
            key: ValueKey('minute-list|${h.hour12}|${h.isPm}'),
            rowHeight: rowHeight,
            visibleRows: placement.rows,
            itemCount: 60,
            selectedIndex: widget.value.minute,
            labelOf: (i) => '${i.toString().padLeft(2, '0')}분',
            semanticOf: (i) => '$i분',
            enabledOf: (i) => TimeSlots.isMinuteEnabled(
              date,
              h.hour12,
              h.isPm,
              i,
              widget.isSelectable,
            ),
            onSelected: _chooseMinute,
            disabledHint: widget.disabledHint,
          );

    // 뒤로 가기는 팝업만 닫는다 (팝업이 열려 있는 동안만 이 PopScope가 있어서, 닫힌 뒤의 뒤로 가기는 시트나 화면을 닫는다)
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      // 스크린리더: 팝업을 하나의 화면처럼 읽고 탈출 제스처(onDismiss)로 닫는다. 뒤의 시트 내용은 읽지 않는다
      child: BlockSemantics(
        child: Semantics(
          scopesRoute: true,
          namesRoute: true,
          explicitChildNodes: true,
          label: isHour ? '시 목록' : '분 목록',
          onDismiss: _close,
          child: FocusScope(
            child: Stack(
              children: [
                // 바깥 누르기: 값은 그대로 두고 팝업만 닫는다
                Positioned.fill(
                  child: Semantics(
                    label: '목록 닫기',
                    button: true,
                    excludeSemantics: true,
                    onTap: _close,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _close,
                      child: const ColoredBox(color: Colors.transparent),
                    ),
                  ),
                ),
                CompositedTransformFollower(
                  link: isHour ? _hourLink : _minuteLink,
                  showWhenUnlinked: false,
                  targetAnchor: placement.above
                      ? Alignment.topLeft
                      : Alignment.bottomLeft,
                  followerAnchor: placement.above
                      ? Alignment.bottomLeft
                      : Alignment.topLeft,
                  offset: Offset(
                    placement.dx,
                    placement.above
                        ? -SmashTimePopupPlacement.gap
                        : SmashTimePopupPlacement.gap,
                  ),
                  // 줄(고를 수 없는 줄 포함)은 눌림을 흡수하므로 팝업 안을 눌러도 바깥 누르기로 새지 않는다
                  child: SizedBox(
                    width: placement.width,
                    height: placement.height,
                    child: list,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.width,
    required this.text,
    required this.semanticLabel,
    required this.open,
    required this.link,
    required this.anchorKey,
    required this.focusNode,
    required this.onPressed,
  });

  final double width;
  final String text;
  final String semanticLabel;
  final bool open;
  final LayerLink link;
  final GlobalKey anchorKey;
  final FocusNode focusNode;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: link,
      child: KeyedSubtree(
        key: anchorKey,
        child: Semantics(
          expanded: open,
          child: SmashPressable(
            onPressed: onPressed,
            focusNode: focusNode,
            semanticLabel: semanticLabel,
            borderRadius: SmashRadius.circular(SmashRadius.md),
            minSize: Size(width, SmashTimeFieldPicker.minRowHeight),
            builder: (context, states) {
              final focused = states.contains(WidgetState.focused);
              final thick = open || focused;
              // 테두리가 두꺼워진(열림, 포커스) 만큼 안쪽 여백을 줄여서 칸 크기가 변하지 않게 한다
              // (변하면 팝업을 열 때마다 시트의 아래 내용이 1~2px 밀린다)
              final inset = thick ? 0.0 : 1.0;
              return Container(
                width: width,
                constraints: const BoxConstraints(
                  minHeight: SmashTimeFieldPicker.minRowHeight,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: SmashSpacing.sm + inset,
                  vertical: SmashSpacing.sm + inset,
                ),
                decoration: BoxDecoration(
                  color: SmashColors.surface,
                  borderRadius: SmashRadius.circular(SmashRadius.md),
                  border: Border.all(
                    color: thick ? SmashColors.brand : SmashColors.border,
                    width: thick ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SmashLabel(
                        text,
                        textAlign: TextAlign.center,
                        style: SmashText.bodyStrong,
                      ),
                    ),
                    Icon(
                      open ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                      size: 24,
                      color: SmashColors.textSecondary,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TimeList extends StatefulWidget {
  const _TimeList({
    super.key,
    required this.rowHeight,
    required this.visibleRows,
    required this.itemCount,
    required this.selectedIndex,
    required this.labelOf,
    required this.semanticOf,
    required this.enabledOf,
    required this.onSelected,
    required this.disabledHint,
  });

  final double rowHeight;
  final int visibleRows;
  final int itemCount;
  final int selectedIndex;
  final String Function(int index) labelOf;
  final String Function(int index) semanticOf;
  final bool Function(int index) enabledOf;
  final ValueChanged<int> onSelected;
  final String disabledHint;

  @override
  State<_TimeList> createState() => _TimeListState();
}

class _TimeListState extends State<_TimeList> {
  late final ScrollController _controller;
  final _anchorFocus = FocusNode(debugLabel: '목록의 고른 줄');
  late final int _anchor = _anchorIndex();

  /// 열릴 때 보여줄 줄: 고른 값이 고를 수 있으면 그 값, 아니면 처음으로 고를 수 있는 값
  int _anchorIndex() {
    if (widget.enabledOf(widget.selectedIndex)) return widget.selectedIndex;
    for (var i = 0; i < widget.itemCount; i++) {
      if (widget.enabledOf(i)) return i;
    }
    return widget.selectedIndex;
  }

  @override
  void initState() {
    super.initState();
    // 애니메이션 없이 처음부터 그 위치에 놓는다. 앵커 줄이 위에서 두 번째 줄쯤에 오게 해서 앞뒤 값이 함께 보인다
    final maxOffset =
        (widget.itemCount - widget.visibleRows) * widget.rowHeight;
    final target = (_anchor - 1) * widget.rowHeight;
    _controller = ScrollController(
      initialScrollOffset: target.clamp(0.0, maxOffset < 0 ? 0.0 : maxOffset),
    );
    // 팝업이 열리면 포커스가 목록으로 온다 (키보드, 스위치 접근에서 Enter로 바로 고를 수 있다)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _anchorFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _anchorFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduceMotion ? 1 : 0, end: 1),
      duration: reduceMotion ? Duration.zero : SmashMotion.fast,
      curve: SmashMotion.easeOut,
      // 투명도가 0인 동안(나타나는 150ms)에도 줄이 스크린리더에 잡히게 한다 (기본값은 투명도 0이면 안쪽을 접근성 트리에서 뺀다)
      builder: (context, opacity, child) =>
          Opacity(opacity: opacity, alwaysIncludeSemantics: true, child: child),
      child: Container(
        decoration: BoxDecoration(
          color: SmashColors.surface,
          borderRadius: SmashRadius.circular(SmashRadius.md),
          border: Border.all(color: SmashColors.border),
          boxShadow: SmashShadows.elevation2,
        ),
        // 안쪽은 (바깥 반지름 - 테두리 두께)로 자른다. 바깥 모양으로 자르면 직각인 선택 강조 배경이 모서리에서 테두리 선 위에 덧그려진다
        child: ClipRRect(
          borderRadius: SmashRadius.circular(
            SmashRadius.md - SmashTimePopupPlacement.border / 2,
          ),
          // 오버레이 위에서는 화면의 안전 영역(노치, 홈 인디케이터)이 ListView의 위아래 여백으로 암묵적으로 더해진다.
          // 팝업 목록에는 여백이 없어야 첫 줄과 마지막 줄이 상자 끝에 닿고 초기 스크롤 위치 계산이 맞는다
          child: MediaQuery.removePadding(
            context: context,
            removeLeft: true,
            removeTop: true,
            removeRight: true,
            removeBottom: true,
            child: ListView.builder(
              padding: EdgeInsets.zero,
              controller: _controller,
              // 끝에서 튕기거나 바깥 스크롤로 이어지지 않는다 (바깥 시트나 화면과 제스처가 엉키지 않게)
              physics: const ClampingScrollPhysics(),
              itemExtent: widget.rowHeight,
              itemCount: widget.itemCount,
              itemBuilder: (context, index) {
                final enabled = widget.enabledOf(index);
                final selected = index == widget.selectedIndex;
                return Semantics(
                  selected: selected,
                  hint: enabled ? null : widget.disabledHint,
                  child: SmashPressable(
                    onPressed: enabled ? () => widget.onSelected(index) : null,
                    focusNode: index == _anchor ? _anchorFocus : null,
                    haptic: enabled ? SmashHaptic.selection : null,
                    semanticLabel: widget.semanticOf(index),
                    minSize: Size(0, widget.rowHeight),
                    builder: (context, states) => Container(
                      color: selected
                          ? SmashColors.brandTintSoft
                          : Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: SmashSpacing.md,
                      ),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Expanded(
                            child: SmashLabel(
                              widget.labelOf(index),
                              style:
                                  (selected
                                          ? SmashText.bodyStrong
                                          : SmashText.body)
                                      .copyWith(
                                        color: !enabled
                                            ? SmashColors.textDisabled
                                            : (selected
                                                  ? SmashColors.brand
                                                  : SmashColors.text),
                                      ),
                            ),
                          ),
                          if (selected)
                            const Icon(
                              Icons.check,
                              size: 20,
                              color: SmashColors.brand,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
