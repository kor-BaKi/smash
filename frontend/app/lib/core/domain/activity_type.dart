enum ActivityType {
  regular,
  free;

  String get apiValue => this == ActivityType.regular ? 'REGULAR' : 'FREE';

  static ActivityType fromApi(String value) => value == 'REGULAR' ? ActivityType.regular : ActivityType.free;

  String get koreanLabel => this == ActivityType.regular ? '정규' : '자유';
}
