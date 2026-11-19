import 'catalog_calendar_sections.dart';
import 'catalog_date_sections.dart';
import 'catalog_display_sections.dart';
import 'catalog_entry.dart';
import 'catalog_frame_sections.dart';
import 'catalog_input_sections.dart';
import 'catalog_label_sections.dart';
import 'catalog_nav_sections.dart';
import 'catalog_overlay_sections.dart';
import 'catalog_sections.dart';
import 'catalog_state_sections.dart';
import 'catalog_time_sections.dart';

/// 카탈로그에 올라간 컴포넌트 목록.
/// 컴포넌트를 만들 때마다 해당 섹션(CatalogEntry)을 만들어 여기에 한 줄을 더한다.
final List<CatalogEntry> catalogEntries = [
  buttonEntry,
  iconButtonEntry,
  textFieldEntry,
  passwordFieldEntry,
  segmentedEntry,
  switchRowEntry,
  checkboxRowEntry,
  chipEntry,
  badgeEntry,
  listRowEntry,
  sectionHeaderEntry,
  panelEntry,
  avatarEntry,
  systemUiEntry,
  appBarEntry,
  bottomBarEntry,
  bottomNavEntry,
  scaffoldEntry,
  tabShellEntry,
  sheetEntry,
  dialogEntry,
  snackBarEntry,
  inlineNoticeEntry,
  skeletonEntry,
  emptyEntry,
  errorViewEntry,
  asyncViewEntry,
  calendarEntry,
  dayPickerEntry,
  dateFieldEntry,
  datePickerEntry,
  timeFieldPickerEntry,
  dateTimeFieldEntry,
  dateTimePickerEntry,
  tabBarEntry,
  selectFieldEntry,
  actionSheetEntry,
  labelEntry,
];
