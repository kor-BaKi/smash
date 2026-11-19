import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../spacing.dart';

/// 폭이 넉넉하면 한 줄로, 모자라면 같은 폭의 격자(2열)나 세로로 쌓이는 배치.
///
/// 한 줄에 놓으면 **칸 폭이 가장 넓은 한글 낱말보다 좁아지는지**로 판단한다 (자식의 최소 고유 폭, 낱말 단위 줄바꿈인
/// [SmashLabel]이면 가장 긴 낱말). 낱말이 칸보다 넓으면 엔진이 글자 단위로 끊어 "같이 가/요"처럼 보이기 때문이다.
///
/// - 칸은 모두 같은 폭이고, 한 줄의 칸은 같은 높이로 늘어난다 (Flutter의 `Wrap`, `OverflowBar`로는 같은 폭을 만들 수 없다)
/// - 열 수는 **자식 수의 약수** 중 칸이 들어가는 가장 큰 값이다 (4개: 4열 → 2열 → 1열, 3개: 3열 → 1열). 3+1처럼
///   마지막 줄이 비는 배치는 만들지 않는다. [maxColumns]로 상한을 둘 수 있다
/// - 폭이 무한(가로 스크롤 안 등)이면 한 줄에 각자의 고유 폭 중 가장 넓은 폭으로 놓는다
/// - 스크린리더 읽는 순서와 포커스 순서는 [children] 순서 그대로다 (열 수와 무관하다)
///
/// **쓰는 곳**: 행 수가 적은 고정 영역(버튼 줄, 조각 선택 등)에만 쓴다. 칸 폭을 정하려고 자식마다 고유 폭을
/// 계산하므로(자식 수 × 자식 트리 깊이) 긴 스크롤 목록의 항목이나 자식이 많은 곳에는 쓰지 않는다.
///
/// **자식 조건**: 고유 폭을 지원해야 한다. `LayoutBuilder`, `OrientationBuilder`처럼 고유 크기를 줄 수 없는 위젯을
/// 자식(또는 자식 안)에 두면 디버그에서 이 위젯이 원인을 알려 주는 오류를 낸다.
///
/// [minCellWidth]는 자식이 상태에 따라 넓어지는 경우(선택 표시가 붙는 조각 등)를 미리 반영하는 칸 폭의 하한이다.
/// 상태가 바뀔 때마다 열 수가 바뀌어 화면이 흔들리는 일을 막는다.
class SmashAdaptiveRow extends MultiChildRenderObjectWidget {
  const SmashAdaptiveRow({
    super.key,
    super.children,
    this.spacing = SmashSpacing.sm,
    this.runSpacing,
    this.maxColumns,
    this.minCellWidth = 0,
  }) : assert(spacing >= 0),
       assert(runSpacing == null || runSpacing >= 0),
       assert(maxColumns == null || maxColumns >= 1),
       assert(minCellWidth >= 0);

  /// 칸 사이 가로 간격
  final double spacing;

  /// 줄 사이 세로 간격 (기본은 [spacing])
  final double? runSpacing;

  /// 열 수의 상한 (null이면 자식 수)
  final int? maxColumns;

  /// 칸 폭의 하한 (자식의 최소 고유 폭과 비교해 큰 쪽을 쓴다)
  final double minCellWidth;

  /// 열 수를 정한다: [count]개를 [width] 안에 [spacing] 간격으로 놓을 때, 칸이 [minCell] 이상인 가장 큰 약수 열 수 (없으면 1).
  /// 칸 폭이 [minCell]과 정확히 같아도 들어간다 (1px 모자라면 들어가지 않는다)
  static int columnsFor({
    required int count,
    required double width,
    required double minCell,
    required double spacing,
    int? maxColumns,
  }) {
    if (count <= 1) return 1;
    final limit = maxColumns == null ? count : math.min(maxColumns, count);
    for (var columns = limit; columns >= 2; columns--) {
      if (count % columns != 0) continue;
      final cell = (width - (columns - 1) * spacing) / columns;
      if (cell + 1e-9 >= minCell) return columns;
    }
    return 1;
  }

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderSmashAdaptiveRow(
        spacing: spacing,
        runSpacing: runSpacing ?? spacing,
        maxColumns: maxColumns,
        minCellWidth: minCellWidth,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSmashAdaptiveRow renderObject,
  ) {
    renderObject
      ..spacing = spacing
      ..runSpacing = runSpacing ?? spacing
      ..maxColumns = maxColumns
      ..minCellWidth = minCellWidth;
  }
}

/// [SmashAdaptiveRow]의 렌더 객체 (직접 쓰지 않는다)
class RenderSmashAdaptiveRow extends RenderBox
    with
        ContainerRenderObjectMixin<
          RenderBox,
          ContainerBoxParentData<RenderBox>
        >,
        RenderBoxContainerDefaultsMixin<
          RenderBox,
          ContainerBoxParentData<RenderBox>
        > {
  RenderSmashAdaptiveRow({
    required this._spacing,
    required this._runSpacing,
    required this._maxColumns,
    required this._minCellWidth,
  });

  double _spacing;
  double get spacing => _spacing;
  set spacing(double value) {
    if (_spacing == value) return;
    _spacing = value;
    markNeedsLayout();
  }

  double _runSpacing;
  double get runSpacing => _runSpacing;
  set runSpacing(double value) {
    if (_runSpacing == value) return;
    _runSpacing = value;
    markNeedsLayout();
  }

  int? _maxColumns;
  int? get maxColumns => _maxColumns;
  set maxColumns(int? value) {
    if (_maxColumns == value) return;
    _maxColumns = value;
    markNeedsLayout();
  }

  double _minCellWidth;
  double get minCellWidth => _minCellWidth;
  set minCellWidth(double value) {
    if (_minCellWidth == value) return;
    _minCellWidth = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! MultiChildLayoutParentData) {
      child.parentData = MultiChildLayoutParentData();
    }
  }

  List<RenderBox> get _children {
    final list = <RenderBox>[];
    for (var c = firstChild; c != null; c = childAfter(c)) {
      list.add(c);
    }
    return list;
  }

  /// 고유 폭을 못 주는 자식이면 원인을 알려 주는 오류로 바꿔 다시 던진다 (디버그)
  double _intrinsic(RenderBox child, double Function(RenderBox child) read) {
    try {
      return read(child);
    } on FlutterError catch (error) {
      assert(() {
        throw FlutterError.fromParts([
          ErrorSummary(
            'SmashAdaptiveRow의 자식이 고유 폭(intrinsic width)을 지원하지 않습니다.',
          ),
          ErrorDescription(
            'SmashAdaptiveRow는 칸 폭을 정하려고 자식의 고유 폭을 물어봅니다. '
            'LayoutBuilder, OrientationBuilder처럼 고유 크기를 줄 수 없는 위젯은 자식으로 둘 수 없습니다.',
          ),
          ErrorHint(
            '그 위젯을 고유 크기를 지원하는 위젯(Container, Row, SmashLabel 등)으로 바꾸거나, 폭이 정해진 곳에 따로 두세요.',
          ),
          DiagnosticsProperty<RenderBox>(
            '문제의 자식',
            child,
            style: DiagnosticsTreeStyle.errorProperty,
          ),
          ErrorDescription('원래 오류: ${error.message}'),
        ]);
      }());
      rethrow;
    }
  }

  double _need(double height) {
    var need = _minCellWidth;
    for (final child in _children) {
      need = math.max(
        need,
        _intrinsic(child, (c) => c.getMinIntrinsicWidth(height)),
      );
    }
    return need;
  }

  int _columnsFor(double width, double need) {
    if (!width.isFinite) return childCount;
    return SmashAdaptiveRow.columnsFor(
      count: childCount,
      width: width,
      minCell: need,
      spacing: _spacing,
      maxColumns: _maxColumns,
    );
  }

  double _cellFor(double width, int columns, double need) {
    if (width.isFinite) return (width - (columns - 1) * _spacing) / columns;
    var widest = need;
    for (final child in _children) {
      widest = math.max(
        widest,
        _intrinsic(child, (c) => c.getMaxIntrinsicWidth(double.infinity)),
      );
    }
    return widest;
  }

  double _totalWidth(double width, int columns, double cell) =>
      width.isFinite ? width : columns * cell + (columns - 1) * _spacing;

  @override
  double computeMinIntrinsicWidth(double height) =>
      childCount == 0 ? 0 : _need(height);

  @override
  double computeMaxIntrinsicWidth(double height) {
    if (childCount == 0) return 0;
    var widest = _need(height);
    for (final child in _children) {
      widest = math.max(
        widest,
        _intrinsic(child, (c) => c.getMaxIntrinsicWidth(height)),
      );
    }
    return childCount * widest + (childCount - 1) * _spacing;
  }

  double _heightFor(double width) {
    if (childCount == 0) return 0;
    final need = _need(double.infinity);
    final columns = _columnsFor(width, need);
    final cell = _cellFor(width, columns, need);
    final children = _children;
    var total = 0.0;
    for (var start = 0; start < children.length; start += columns) {
      var rowHeight = 0.0;
      for (var i = start; i < math.min(start + columns, children.length); i++) {
        rowHeight = math.max(
          rowHeight,
          children[i].getMaxIntrinsicHeight(cell),
        );
      }
      total += rowHeight + (start == 0 ? 0 : _runSpacing);
    }
    return total;
  }

  @override
  double computeMinIntrinsicHeight(double width) => _heightFor(width);

  @override
  double computeMaxIntrinsicHeight(double width) => _heightFor(width);

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    if (childCount == 0) {
      return constraints.constrain(
        Size(constraints.hasBoundedWidth ? constraints.maxWidth : 0, 0),
      );
    }
    final width = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : double.infinity;
    final need = _need(double.infinity);
    final columns = _columnsFor(width, need);
    final cell = _cellFor(width, columns, need);
    final children = _children;
    var total = 0.0;
    for (var start = 0; start < children.length; start += columns) {
      var rowHeight = 0.0;
      for (var i = start; i < math.min(start + columns, children.length); i++) {
        rowHeight = math.max(
          rowHeight,
          children[i].getDryLayout(BoxConstraints.tightFor(width: cell)).height,
        );
      }
      total += rowHeight + (start == 0 ? 0 : _runSpacing);
    }
    return constraints.constrain(
      Size(_totalWidth(width, columns, cell), total),
    );
  }

  @override
  void performLayout() {
    if (childCount == 0) {
      size = constraints.constrain(
        Size(constraints.hasBoundedWidth ? constraints.maxWidth : 0, 0),
      );
      return;
    }
    final width = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : double.infinity;
    final need = _need(double.infinity);
    final columns = _columnsFor(width, need);
    final cell = _cellFor(width, columns, need);
    final children = _children;
    var y = 0.0;
    for (var start = 0; start < children.length; start += columns) {
      final end = math.min(start + columns, children.length);
      var rowHeight = 0.0;
      for (var i = start; i < end; i++) {
        children[i].layout(
          BoxConstraints.tightFor(width: cell),
          parentUsesSize: true,
        );
        rowHeight = math.max(rowHeight, children[i].size.height);
      }
      for (var i = start; i < end; i++) {
        if (children[i].size.height != rowHeight) {
          children[i].layout(
            BoxConstraints.tightFor(width: cell, height: rowHeight),
            parentUsesSize: true,
          );
        }
        (children[i].parentData! as ContainerBoxParentData<RenderBox>).offset =
            Offset((i - start) * (cell + _spacing), y);
      }
      y += rowHeight + _runSpacing;
    }
    size = constraints.constrain(
      Size(_totalWidth(width, columns, cell), y - _runSpacing),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
