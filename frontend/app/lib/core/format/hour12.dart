/// 24시간제 시(0~23)를 12시간제로 바꾼다. 시간 휠(오전/오후 + 1~12시)에서 쓴다.
/// 0시 → 오전 12시, 12시 → 오후 12시, 13시 → 오후 1시.
({int hour12, bool isPm}) toHour12(int hour24) {
  if (hour24 < 0 || hour24 > 23) {
    throw RangeError.range(hour24, 0, 23, 'hour24');
  }
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  return (hour12: hour12, isPm: hour24 >= 12);
}

/// 12시간제(1~12시 + 오전/오후)를 24시간제로 바꾼다.
/// 오전 12시 → 0시, 오후 12시 → 12시, 오후 1시 → 13시.
int toHour24(int hour12, {required bool isPm}) {
  if (hour12 < 1 || hour12 > 12) {
    throw RangeError.range(hour12, 1, 12, 'hour12');
  }
  return hour12 % 12 + (isPm ? 12 : 0);
}
