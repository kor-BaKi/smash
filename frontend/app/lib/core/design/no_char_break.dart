import 'package:flutter/widgets.dart' show StringCharacters;

/// 글자 사이에 WORD JOINER(U+2060)를 넣어 한글이 낱말 중간에서 줄바꿈되지 않게 한다.
///
/// 한글은 글자(음절) 사이마다 줄바꿈 후보가 있어서, 앞 낱말 뒤에 남은 자리가 모자라면 "같이 가/요"처럼 낱말 중간에서 끊긴다.
/// 이 함수의 결과는 공백에서만 줄바꿈되어 "같이/가요"가 된다.
///
/// - **한글과 이웃한 경계에만** 넣는다. 숫자나 영문만 이어진 구간("12", "3:30", "AB")은 원래 낱말 중간에서 끊기지 않으므로
///   그대로 둔다 ("12분"은 "2"와 "분" 사이에만 들어간다). 달력 숫자나 시각의 글자 모양에 영향을 주지 않기 위해서다
/// - 공백 바로 옆에는 넣지 않는다 (공백 뒤의 줄바꿈이 막히기 때문)
/// - 화면에 그리는 글자에만 쓴다. 스크린리더에는 원문을 읽히도록 `Text(..., semanticsLabel: 원문)`을 함께 넘긴다
///   (`SmashLabel`이 이 둘을 함께 처리한다)
/// - 한계: 낱말 하나가 **한 줄 폭보다 길면** 엔진이 어쩔 수 없이 글자 단위로 끊는다. 이것은 폭을 넉넉히 잡아서 막는다
///   (예: 선택된 조각의 체크 아이콘이 차지하는 폭까지 더한 폭을 잡는다)
String noCharBreak(String text) {
  // 한글이 없으면 바꿀 것이 없다 (새 문자열을 만들지 않는다)
  if (!text.runes.any(_isHangul)) return text;

  const wordJoiner = '⁠';
  final chars = text.characters.toList();
  final out = StringBuffer();
  for (var i = 0; i < chars.length; i++) {
    out.write(chars[i]);
    if (i + 1 < chars.length &&
        !_isSpace(chars[i]) &&
        !_isSpace(chars[i + 1]) &&
        (_hasHangul(chars[i]) || _hasHangul(chars[i + 1]))) {
      out.write(wordJoiner);
    }
  }
  return out.toString();
}

bool _isSpace(String grapheme) => grapheme.trim().isEmpty;

bool _hasHangul(String grapheme) => grapheme.runes.any(_isHangul);

/// 한글 음절(AC00-D7A3), 자모(1100-11FF), 호환 자모(3130-318F), 자모 확장 A(A960-A97F)와 B(D7B0-D7FF)
bool _isHangul(int rune) =>
    (rune >= 0xAC00 && rune <= 0xD7A3) ||
    (rune >= 0x1100 && rune <= 0x11FF) ||
    (rune >= 0x3130 && rune <= 0x318F) ||
    (rune >= 0xA960 && rune <= 0xA97F) ||
    (rune >= 0xD7B0 && rune <= 0xD7FF);
