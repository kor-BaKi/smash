import 'package:flutter/widgets.dart' show StringCharacters;

/// 글자 사이에 WORD JOINER(U+2060)를 넣어 한글이 낱말 중간에서 줄바꿈되지 않게 한다.
///
/// 한글은 글자(음절) 사이마다 줄바꿈 후보가 있어서, 앞 낱말 뒤에 남은 자리가 모자라면 "같이 가/요"처럼 낱말 중간에서 끊긴다.
/// 이 함수의 결과는 공백에서만 줄바꿈되어 "같이/가요"가 된다 (공백 바로 옆에는 넣지 않는다: 공백 뒤의 줄바꿈이 막히기 때문).
///
/// - 화면에 그리는 글자에만 쓴다. 스크린리더에는 원문을 읽히도록 `Text(..., semanticsLabel: 원문)`을 함께 넘긴다
/// - 한계: 낱말 하나가 **한 줄 폭보다 길면** 엔진이 어쩔 수 없이 글자 단위로 끊는다. 이것은 폭을 넉넉히 잡아서 막는다
///   (예: 선택된 조각의 체크 아이콘이 차지하는 폭까지 더한 폭을 잡는다)
String noCharBreak(String text) {
  const wordJoiner = '\u2060';
  final chars = text.characters.toList();
  final out = StringBuffer();
  for (var i = 0; i < chars.length; i++) {
    out.write(chars[i]);
    if (i + 1 < chars.length &&
        !_isSpace(chars[i]) &&
        !_isSpace(chars[i + 1])) {
      out.write(wordJoiner);
    }
  }
  return out.toString();
}

bool _isSpace(String grapheme) => grapheme.trim().isEmpty;
