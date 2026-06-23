enum TimeSlot {
  slot1315,
  slot1517;

  String get apiValue => this == TimeSlot.slot1315 ? 'SLOT_13_15' : 'SLOT_15_17';

  static TimeSlot fromApi(String value) => value == 'SLOT_13_15' ? TimeSlot.slot1315 : TimeSlot.slot1517;

  String get koreanLabel => this == TimeSlot.slot1315 ? '1-3시' : '3-5시';
}
