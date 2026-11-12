import 'dart:ui';

/// WCAG 2.x 명도 대비. 일반 글자는 4.5:1, 큰 글자와 조작 요소 테두리는 3:1 이상이어야 한다.
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}
