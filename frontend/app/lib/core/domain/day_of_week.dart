enum DayOfWeek {
  mon,
  tue,
  wed,
  thu,
  fri;

  String get apiValue => name.toUpperCase();

  static DayOfWeek fromApi(String value) => DayOfWeek.values.firstWhere((d) => d.apiValue == value);

  String get koreanLabel {
    switch (this) {
      case DayOfWeek.mon:
        return '월';
      case DayOfWeek.tue:
        return '화';
      case DayOfWeek.wed:
        return '수';
      case DayOfWeek.thu:
        return '목';
      case DayOfWeek.fri:
        return '금';
    }
  }
}
