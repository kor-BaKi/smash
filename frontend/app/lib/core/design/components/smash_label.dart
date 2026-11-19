import 'package:flutter/material.dart';

import '../no_char_break.dart';

/// 한글이 낱말 중간에서 줄바꿈되지 않는 `Text`.
///
/// 한글은 글자(음절) 사이마다 줄바꿈 후보가 있어서 "같이 이동하고 싶어요"가 "같이 이동하/고 싶어요"처럼 낱말 중간에서 끊긴다.
/// [SmashLabel]은 그려지는 글자에만 WORD JOINER를 넣어([noCharBreak]) 공백에서만 줄바꿈되게 한다.
///
/// - **`Text`의 하위 클래스**라서 `find.text('원문')`, `tester.widget<Text>(...)`, `Text`를 받는 모든 곳에 그대로 쓸 수 있다.
///   `data`는 항상 원문이다. (단 `find.byType(Text)`는 정확한 타입 비교라 [SmashLabel]을 찾지 못한다: `find.byWidgetPredicate((w) => w is Text)`를 쓴다)
/// - 스크린리더는 원문을 읽는다. 호출자가 [semanticsLabel]을 지정하면 그것이 우선이고, 지정하지 않았을 때만 원문을 쓴다
/// - `Text`의 인자는 모두 그대로 전달된다 (style, strutStyle, textAlign, textDirection, locale, softWrap, overflow, textScaler,
///   maxLines, semanticsLabel, semanticsIdentifier, textWidthBasis, textHeightBehavior, selectionColor).
///   예외: `textScaleFactor`는 Flutter가 더 이상 쓰지 않는 인자라 받지 않는다 (`textScaler`를 쓴다). `Text.rich`에 해당하는 생성자는 없다
/// - 한계: 낱말 하나가 한 줄 폭보다 길면 엔진이 글자 단위로 끊는다. 폭을 넉넉히 잡는 것은 쓰는 쪽의 몫이다
/// - 한글이 없는 글자(숫자, 영문)는 바뀌지 않는다
class SmashLabel extends Text {
  const SmashLabel(
    super.data, {
    super.key,
    super.style,
    super.strutStyle,
    super.textAlign,
    super.textDirection,
    super.locale,
    super.softWrap,
    super.overflow,
    super.textScaler,
    super.maxLines,
    super.semanticsLabel,
    super.semanticsIdentifier,
    super.textWidthBasis,
    super.textHeightBehavior,
    super.selectionColor,
  });

  @override
  Widget build(BuildContext context) {
    // 일반 Text가 하는 일(기본 스타일 합치기, 의미 라벨 처리)을 그대로 쓰려고, 그려질 글자만 바꾼 Text에 맡긴다
    return Text(
      noCharBreak(data!),
      style: style,
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaler: textScaler,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel ?? data,
      semanticsIdentifier: semanticsIdentifier,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
    ).build(context);
  }
}
