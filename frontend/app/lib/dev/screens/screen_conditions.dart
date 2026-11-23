/// 화면을 띄우는 조건: 기기 크기, 글자 배율, 키보드.
///
/// 갤러리와 화면 행렬 테스트가 같은 값을 쓴다. 안전 영역은 노치가 있는 기기와 비슷하게 위 44, 아래 34로 둔다
/// (키보드가 올라오면 아래 안전 영역은 키보드가 덮으므로 0이 된다).
class ScreenConditions {
  const ScreenConditions({
    this.width = 360,
    this.textScale = 1.0,
    this.keyboardHeight = 0,
  });

  final double width;
  final double textScale;
  final double keyboardHeight;

  static const widths = [320.0, 360.0, 390.0];
  static const textScales = [1.0, 1.3, 2.0];

  /// 키보드가 올라온 경우의 높이 (일반적인 휴대폰 키보드보다 조금 큰 편)
  static const keyboardUp = 300.0;

  static const safeTop = 44.0;
  static const safeBottom = 34.0;

  /// 폭에 맞는 대표 기기 높이: 320×568(작은 기기), 360×640, 390×844
  double get height => switch (width) {
    <= 320 => 568,
    <= 360 => 640,
    _ => 844,
  };

  ScreenConditions copyWith({
    double? width,
    double? textScale,
    double? keyboardHeight,
  }) => ScreenConditions(
    width: width ?? this.width,
    textScale: textScale ?? this.textScale,
    keyboardHeight: keyboardHeight ?? this.keyboardHeight,
  );

  @override
  String toString() =>
      '폭 $width, 글자 $textScale배, 키보드 ${keyboardHeight > 0 ? '올라옴' : '없음'}';
}
