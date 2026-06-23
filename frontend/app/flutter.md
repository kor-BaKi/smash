# Flutter 프로젝트 파일 맵

> CLAUDE.md 8장 Flutter 파일 규칙에 따른 전체 파일 목록. 새 파일이 추가될 때마다 함께 갱신할 것.
> 경로는 `frontend/app/` 기준.

## 진입점
| 파일 경로 | 역할 |
|---|---|
| lib/main.dart | 앱 시작점 (`runApp`) |
| lib/app.dart | `SmashApp` 위젯, 테마/시작 화면 연결 |

## core/api
| 파일 경로 | 역할 |
|---|---|
| lib/core/api/api_client.dart | Dio 인스턴스, 토큰 인터셉터(자동 재발급) |
| lib/core/api/api_exception.dart | 백엔드 공통 에러 포맷을 감싸는 예외 |
| lib/core/api/auth_api.dart | 로그인 API 호출 |
| lib/core/api/activity_api.dart | 오늘의 투표/활동 상세/임원 활동관리 API 호출 |
| lib/core/api/assignment_api.dart | 조 배정(미배정자/preview/confirm) API 호출 |
| lib/core/api/attendance_api.dart | 출석 현황(조별/미달자/타조참) API 호출 |
| lib/core/api/availability_api.dart | 가능요일 제출 API 호출 |
| lib/core/api/group_api.dart | 조 목록/생성/조장지정 API 호출 |
| lib/core/api/invite_code_api.dart | 가입코드 목록/발급/활성화 API 호출 |
| lib/core/api/activity_schedule_api.dart | 정규활동 일정 조회/전체교체 API 호출 |
| lib/core/api/statistics_api.dart | 통계(충족률추이/조별비교/이월빈도) API 호출 |

## core/constants
| 파일 경로 | 역할 |
|---|---|
| lib/core/constants/api_constants.dart | API base URL |

## core/domain
| 파일 경로 | 역할 |
|---|---|
| lib/core/domain/day_of_week.dart | 요일 enum (여러 기능 공용) |
| lib/core/domain/time_slot.dart | 시간대 enum (여러 기능 공용) |
| lib/core/domain/activity_type.dart | 활동 유형(정규/자유) enum |

## core/storage
| 파일 경로 | 역할 |
|---|---|
| lib/core/storage/token_storage.dart | secure storage 기반 토큰 저장/조회 |

## features/auth
| 파일 경로 | 역할 |
|---|---|
| lib/features/auth/page/login_page.dart | 로그인 화면 |
| lib/features/auth/provider/auth_controller.dart | 로그인 상태 Riverpod controller |
| lib/features/auth/model/auth_user.dart | 로그인 사용자 모델 |

## features/home
| 파일 경로 | 역할 |
|---|---|
| lib/features/home/page/home_page.dart | 임원/부원 홈 분기 화면 |

## features/activity
| 파일 경로 | 역할 |
|---|---|
| lib/features/activity/page/today_activity_page.dart | 오늘의 투표(부원) 화면 |
| lib/features/activity/page/admin_activity_page.dart | 임원 활동 관리 화면 |
| lib/features/activity/page/activity_detail_page.dart | 활동 상세 화면 |
| lib/features/activity/provider/today_activity_controller.dart | 오늘의 투표 controller |
| lib/features/activity/provider/admin_activity_controller.dart | 임원 활동 관리 controller |
| lib/features/activity/provider/activity_detail_controller.dart | 활동 상세 controller |
| lib/features/activity/model/activity.dart | 활동/참여 관련 모델 |

## features/assignment
| 파일 경로 | 역할 |
|---|---|
| lib/features/assignment/page/assignment_page.dart | 조 배정(미배정자/미리보기/확정) 화면 |
| lib/features/assignment/provider/assignment_controller.dart | 조 배정 controller |
| lib/features/assignment/model/assignment.dart | 조 배정 관련 모델 |

## features/attendance
| 파일 경로 | 역할 |
|---|---|
| lib/features/attendance/page/attendance_page.dart | 출석 현황(조별/미달자/타조참) 화면 |
| lib/features/attendance/provider/attendance_controller.dart | 출석 현황 controller |
| lib/features/attendance/model/attendance.dart | 출석 현황 관련 모델 |

## features/availability
| 파일 경로 | 역할 |
|---|---|
| lib/features/availability/page/availability_page.dart | 가능요일 제출 화면 |
| lib/features/availability/provider/availability_controller.dart | 가능요일 제출 controller |
| lib/features/availability/model/availability.dart | 가능요일 관련 모델 |

## features/group
| 파일 경로 | 역할 |
|---|---|
| lib/features/group/page/group_page.dart | 조 관리(조장 지정) 화면 |
| lib/features/group/provider/group_controller.dart | 조 목록 controller (다른 기능에서도 공유) |
| lib/features/group/model/group.dart | 조 모델 |

## features/invite
| 파일 경로 | 역할 |
|---|---|
| lib/features/invite/page/invite_code_page.dart | 가입코드 관리 화면 |
| lib/features/invite/provider/invite_code_controller.dart | 가입코드 controller |
| lib/features/invite/model/invite_code.dart | 가입코드 모델 |

## features/schedule
| 파일 경로 | 역할 |
|---|---|
| lib/features/schedule/page/activity_schedule_page.dart | 정규활동 일정 관리 화면 |
| lib/features/schedule/provider/activity_schedule_controller.dart | 정규활동 일정 controller |
| lib/features/schedule/model/activity_schedule.dart | 정규활동 일정 모델 |

## features/statistics
| 파일 경로 | 역할 |
|---|---|
| lib/features/statistics/page/statistics_page.dart | 통계(충족률추이/조별비교/이월빈도) 화면 |
| lib/features/statistics/provider/statistics_controller.dart | 통계 controller |
| lib/features/statistics/model/statistics.dart | 통계 모델 |

## shared/theme
| 파일 경로 | 역할 |
|---|---|
| lib/shared/theme/app_theme.dart | 앱 공통 ThemeData |

## shared/widgets
(아직 없음 — 여러 화면에서 재사용할 공통 위젯이 생기면 여기에 추가)

## core/utils
(아직 없음 — 공통 유틸 함수가 생기면 여기에 추가)
