# 05. API 명세서

> 최종 갱신: 2026-11. 코드(Controller) 기준 **102개 엔드포인트**.
> 운영 환경에서는 Swagger를 비활성화하므로(404) 이 문서가 API의 기준 문서다.

Base URL: `/api/v1` (정적 파일 `/files/photos/**` 제외) | 인증: `Authorization: Bearer {accessToken}` | 권한: ROLE_ADMIN / ROLE_MEMBER

## 정적 페이지 (인증 불필요)
`/privacy.html`(개인정보 처리방침), `/delete-account.html`(계정 삭제 안내), `/apply.html`(웹 지원서) — 스토어 등록·신규 모집용.

## 공통 규칙
- **사용자 식별**: 인증 필요 API의 주체는 JWT subject(userId)에서만 추출한다. Body/Query의 userId는 본인 식별에 쓰지 않는다(IDOR 방지).
  타인 대상 임원 API만 path `{userId}`를 사용하며 ROLE_ADMIN을 선검증한다.
- **공통 응답**: `{ success, data, error }`, 실패 시 `error = { code, message }`
- **형식**: 날짜 `yyyy-MM-dd` / 일시 `yyyy-MM-dd'T'HH:mm:ss` / boolean 키는 `isCancelled`처럼 `is` 접두사 유지
- **인증 실패**: 토큰 없음/만료 → 401, 권한 부족 → 403
- **토큰**: Access 30분, Refresh 180일(Rotation, 서버에는 해시 저장)

### 에러 코드 → HTTP 상태
| HTTP | 코드 |
|---|---|
| 400 | (기본값) INVALID_INPUT(검증 실패) / INVALID_REQUEST / INVALID_PASSWORD / INVALID_CARRYOVER_TARGET / INVALID_FILE / VOTE_CLOSED / POLL_CLOSED / ALREADY_VOTED / ALREADY_APPLIED / ALREADY_PAID / FORM_NOT_ACTIVE / LAST_ADMIN / FILE_ERROR / FILE_TOO_LARGE 등 위에 명시되지 않은 모든 비즈니스 오류 |
| 401 | INVALID_REFRESH_TOKEN, 토큰 없음·만료 |
| 403 | FORBIDDEN / NOT_ALLOWED / NOT_ACTIVE(가입 미완료 계정) |
| 404 | RESOURCE_NOT_FOUND (없는 리소스·없는 주소) |
| 405 | METHOD_NOT_ALLOWED |
| 409 | ALREADY_EXISTS / ALREADY_REGISTERED / ALREADY_ASSIGNED / ASSIGNMENT_CONFLICT / OVERLAPPING_PERIOD |
| 429 | TOO_MANY_ATTEMPTS (로그인·탈퇴 비밀번호 확인 5회 실패 → 10분 잠금) |
| 500 | SERVER_ERROR |

> 정확한 코드→상태 매핑은 `GlobalExceptionHandler`가 단일 기준이다. 새 에러 코드를 추가하면 거기에 매핑을 함께 추가한다.

---

## A. 인증 / 계정

| Method | Path | 권한 | 설명 |
|---|---|---|---|
| POST | /auth/signup | 공개 | `{code, studentNo, password}` 가입코드·사전등록 학번 확인 후 가입(ACTIVE). REJECTED는 NOT_ALLOWED |
| POST | /auth/login | 공개 | `{studentNo, password}` ACTIVE만 허용. 5회 실패 시 10분 잠금(429) |
| POST | /auth/refresh | 공개 | `{refreshToken}` Rotation, 재사용·위조·만료는 INVALID_REFRESH_TOKEN |
| POST | /auth/logout | 인증 | 저장된 refresh 삭제 |
| PATCH | /auth/password | 인증 | `{currentPassword, newPassword}` 현재 비밀번호 확인 |
| GET | /me | 인증 | 내 정보(이름·학번·조·권한 등) |
| POST | /me/withdraw | 인증 | `{password}` 회원 탈퇴(익명화). 마지막 임원은 LAST_ADMIN(400) |

응답 `data`(signup/login): `{ accessToken, refreshToken, user:{id,name,role,groupId} }`

## B. 부원 관리 (ADMIN)

| Method | Path | 설명 |
|---|---|---|
| POST | /admin/members | 단건 사전등록 `{name, studentNo, department?, phone?, joinTerm}` → PENDING. 중복 시 ALREADY_REGISTERED |
| POST | /admin/members/bulk | 대량 사전등록(부분 성공). `{members:[...]}` → `{succeeded, failed, totalRequested, successCount}` |
| GET | /admin/members | 부원 목록 |
| GET | /admin/members/pending | 가입 대기(PENDING) 목록 |
| GET | /admin/members/{userId} | 부원 상세(소속조, 임원 메모 포함) |
| PATCH | /admin/members/{userId}/info | `{department, phone}` 수정 |
| PATCH | /admin/members/{userId}/role | 임원 지정/해제 (마지막 임원 보호) |
| PATCH | /admin/members/{userId}/reject | 가입 거절(REJECTED) |
| PATCH | /admin/members/{userId}/restore | 거절 복구 |
| DELETE | /admin/members/{userId} | 부원 삭제(익명화, 마지막 임원 불가) |
| POST | /admin/members/{userId}/notes | 임원 메모 작성 `{content}` |
| DELETE | /admin/members/notes/{noteId} | 메모 삭제 |
| GET | /admin/groups/{groupId}/members | 조별 부원 목록 |

## C. 조 / 운영 설정

| Method | Path | 권한 | 설명 |
|---|---|---|---|
| POST | /admin/groups | ADMIN | 조 일괄 생성 `{groups:[{dayOfWeek,timeSlot}]}` (이미 있는 조합은 건너뜀) |
| GET | /groups | 인증 | 조 목록 `[{id,dayOfWeek,timeSlot,label,leaderUserId,viceLeaderUserId,memberCount}]` |
| PATCH / DELETE | /admin/groups/{groupId}/leader | ADMIN | 조장 지정 `{leaderUserId}` / 해제 (조 소속 검증) |
| PATCH / DELETE | /admin/groups/{groupId}/vice-leader | ADMIN | 부조장 지정 / 해제 |
| PUT / GET | /admin/activity-schedules | ADMIN | 정규 활동 일정 전체 교체 `{schedules:[{dayOfWeek,timeSlot,isActive}]}` / 조회 |
| POST / GET | /admin/invite-codes | ADMIN | 가입코드 생성(서버 랜덤) / 목록 |
| PATCH | /admin/invite-codes/{id} | ADMIN | `{isActive}` 활성/비활성 |
| GET / POST | /admin/free-periods | ADMIN | 자유활동 기간 조회 / 등록 `{startDate,endDate}` (겹치면 OVERLAPPING_PERIOD) |
| DELETE | /admin/free-periods/{id} | ADMIN | 기간 삭제 |
| GET | /calendar | 인증 | 동아리 일정 조회 |
| POST | /admin/calendar | ADMIN | 일정 등록 `{title,date,memo?}` |
| DELETE | /admin/calendar/{scheduleId} | ADMIN | 일정 삭제 |

## D. 조 배정

| Method | Path | 권한 | 설명 |
|---|---|---|---|
| PUT | /me/availability | 인증 | `{groupIds:[...]}` 가능 요일 교체 제출. 이미 배정된 부원은 ALREADY_ASSIGNED |
| GET | /me/availability | 인증 | `{availabilities, assigned, assignedGroupId}` |
| POST | /admin/assignment/preview | ADMIN | 자동 배정 미리보기(DB 저장 X) → `{previewToken, basedOnMemberIds, assignments, unassigned, groupDistribution}` |
| POST | /admin/assignment/confirm | ADMIN | `{previewToken, basedOnMemberIds, assignments:[{userId,groupId}]}` 확정. 대상 변경 시 ASSIGNMENT_CONFLICT, 이미 배정된 건 skipped |
| PATCH | /admin/members/{userId}/group | ADMIN | 개별 조 변경 `{groupId}` |
| GET | /admin/members/unassigned | ADMIN | 미배정 ACTIVE 부원 + 가능 조 |
| POST | /admin/semester/reset | ADMIN | 학기 초기화(배정 해제 등 학기 단위 데이터 정리) |
| DELETE | /admin/availability | ADMIN | 전체 가능 요일 삭제 |

## E. 활동 / 참여 / 이월

| Method | Path | 권한 | 설명 |
|---|---|---|---|
| GET | /me/activities/today | 인증 | `scope=MY(기본)/ALL`. `[{activityId,activityDate,groupId,groupLabel,activityType,isMyGroup,availableButtons,myParticipation,voteClosed}]` |
| POST | /me/activities/{activityId}/participation | 인증 | `{type, targetActivityId?}` type=ATTEND/OTHER_GROUP/FREE_ATTEND/ABSENT/CARRYOVER. 마감 후 VOTE_CLOSED, 허용되지 않는 유형·이월 대상은 400 오류(INVALID_CARRYOVER_TARGET 등) |
| DELETE | /me/activities/{activityId}/participation | 인증 | 응답 취소(이월이면 기록 삭제로 자격 복구) |
| GET | /me/activities/{activityId}/carryover-candidates | 인증 | `[{targetActivityId,date,status:FUTURE|PAST_ABSENT}]` |
| PATCH | /me/activities/{activityId}/travel-type | 인증 | `{travelType: TOGETHER|ALONE}` 이동 방식 |
| GET | /me/activity-calendar | 인증 | `?year=&month=` 내 조의 월간 활동(실제+예정 투영) |
| GET | /activities/{activityId} | 인증 | 집계 `summary` + 참여자 명단 `participants` |
| GET | /admin/activities | ADMIN | `?date=` 날짜별 전체 조 활동 (미지정=오늘) |
| PATCH | /admin/activities/{activityId} | ADMIN | `{isCancelled?, activityType?}` |
| GET | /admin/activities/{activityId}/participants | ADMIN | 참여자 상세 |

**활동 캘린더 응답**
```json
{
  "year": 2026, "month": 11,
  "myGroup": { "groupId": 3, "label": "수 1-3시" },
  "activities": [
    { "date": "2026-11-18", "activityId": 41, "activityType": "REGULAR", "isCancelled": false, "isProjected": false },
    { "date": "2026-11-25", "activityId": null, "activityType": "REGULAR", "isCancelled": false, "isProjected": true }
  ],
  "freePeriods": [ { "id": 2, "startDate": "2026-12-14", "endDate": "2026-12-31" } ]
}
```
- 미배정이면 `myGroup`은 null, `isProjected=true`는 아직 행이 없는 미래 예정일(activityId null).

## F. 출석 현황 (ADMIN, 계산 기반)

| Method | Path | 설명 |
|---|---|---|
| GET | /admin/attendance | `?groupId=&year=&month=` 조별 충족 현황 `{guaranteedCount, members:[{fulfilled,guaranteed,shortfall,isShortfall}]}` |
| GET | /admin/attendance/shortfall | `?year=&month=` 전체 조 미달자 |
| GET | /admin/attendance/other-group | `?year=&month=` 타조 참여 집계 |

충족 = REGULAR + CARRYOVER, 보장 = 해당 월 본인 조의 REGULAR·미취소 활동 수. OTHER_GROUP/FREE_ATTEND/ABSENT는 제외.

## G. 일반 투표 (Poll)

| Method | Path | 권한 | 설명 |
|---|---|---|---|
| POST | /admin/polls | ADMIN | `{title, description, isAnonymous, closedAt?, sendNotification, options:[...]}` |
| GET | /polls | 인증 | 투표 목록 |
| GET | /polls/{pollId} | 인증 | 상세 `{options:[{id,content,voteCount,voters}], myVotedOptionId, isClosed, isExpired}` (익명이면 voters 숨김) |
| POST | /polls/{pollId}/vote | 인증 | `{optionId}` 1인 1표. 종료 POLL_CLOSED, 중복 ALREADY_VOTED |
| DELETE | /polls/{pollId}/vote | 인증 | 투표 취소 (종료된 투표는 불가) |
| PATCH | /admin/polls/{pollId}/close | ADMIN | 수동 종료 |

## H. 이동 동행 / 정산

| Method | Path | 권한 | 설명 |
|---|---|---|---|
| POST | /admin/activities/{activityId}/transport-groups | ADMIN | 호차 편성 `{groups:[{memberIds:[...]}]}` |
| GET | /activities/{activityId}/transport-groups | 인증 | 호차별 탑승자 `[{groupId,groupNumber,members:[{userId,name,travelType}]}]` |
| DELETE | /admin/activities/{activityId}/transport-groups | ADMIN | 호차 편성 삭제 |
| POST | /activities/{activityId}/transport-groups/{groupId}/settlement | 인증(호차 탑승자) | `{totalAmount, accountBank, accountNumber, sendNotification}` 정산 생성. 호차당 1건 |
| GET | /activities/{activityId}/transport-groups/{groupId}/settlement | 인증(호차 탑승자) | 정산 조회 `{payerName, payerUserId, totalAmount, amountPerPerson, accountBank, accountNumber, payments:[{userId,userName,isPaid,paidAt}]}` |
| PATCH | /settlements/{settlementId}/payments/{userId} | 결제자 | 납부 확인/해제 |
| DELETE | /settlements/{settlementId} | 결제자 | 정산 삭제 |

계좌번호는 DB에 AES-GCM으로 암호화되어 저장되고 응답 시 복호화된다.

## I. 활동 사진

| Method | Path | 권한 | 설명 |
|---|---|---|---|
| POST | /admin/activities/{activityId}/photos | ADMIN | multipart 다중 업로드. JPG/PNG/GIF/WEBP를 **파일 시그니처**로 검증(INVALID_FILE), 용량 초과 FILE_TOO_LARGE |
| GET | /admin/activities/{activityId}/photos | ADMIN | 사진 목록 `[{id,url,uploadedBy,createdAt}]` |
| DELETE | /admin/activities/photos/{photoId} | ADMIN | 사진 삭제 |
| GET | /files/photos/{filename} | ADMIN | 사진 파일 (UUID 파일명, 임원 인증 필요) |

## J. 신규 부원 모집 (지원서)

| Method | Path | 권한 | 설명 |
|---|---|---|---|
| POST | /admin/application-form | ADMIN | 새 폼 생성 `{startDate,endDate,copyQuestions}` |
| GET | /admin/application-form | ADMIN | 현재 폼 + 질문 |
| PATCH | /admin/application-form/toggle | ADMIN | 접수 활성/비활성 |
| PATCH | /admin/application-form/period | ADMIN | 접수 기간 변경 |
| POST | /admin/application-form/questions | ADMIN | 질문 추가 `{content, questionType(TEXT·MULTILINE·SELECT), isRequired, options?}` |
| DELETE | /admin/application-form/questions/{questionId} | ADMIN | 질문 삭제 |
| PATCH | /admin/application-form/questions/order | ADMIN | 질문 순서 변경 |
| GET | /application-form | 공개 | 지원자용 폼 조회 |
| POST | /applications | 공개 | 지원서 제출 `{name,studentNo,department,phone,availabilities:[{dayOfWeek,timeSlot}],answers:[{questionId,answer}]}`. 중복 ALREADY_APPLIED, 비활성 FORM_NOT_ACTIVE |
| GET | /admin/applications | ADMIN | 지원서 목록 |
| GET | /admin/applications/{applicationId} | ADMIN | 상세(답변·메모) |
| PATCH | /admin/applications/{applicationId}/accept | ADMIN | 합격 → users PENDING 사전등록 + 가능 요일 등록 |
| PATCH | /admin/applications/accept-all | ADMIN | 일괄 합격 |
| PATCH | /admin/applications/{applicationId}/reject | ADMIN | 불합격 |
| PATCH | /admin/applications/{applicationId}/cancel-reject | ADMIN | 불합격 취소 |
| PATCH | /admin/applications/{applicationId}/memo | ADMIN | 단일 메모 수정 |
| POST | /admin/applications/{applicationId}/memos | ADMIN | 임원별 메모 추가 |
| DELETE | /admin/applications/memos/{memoId} | ADMIN | 메모 삭제 |
| GET | /admin/applications/export | ADMIN | 지원서 엑셀 내보내기 |

## K. 회비

| Method | Path | 설명 |
|---|---|---|
| GET | /admin/dues | 부원별 납부 현황 `[{userId,name,studentNo,groupId,isPaid}]` |
| POST | /admin/dues/{userId} | 납부 처리 |
| DELETE | /admin/dues/{userId} | 납부 취소 |
| DELETE | /admin/dues | 전체 초기화(학기 시작) |

## L. 알림 / FCM

| Method | Path | 설명 |
|---|---|---|
| POST | /fcm/token | `{token, deviceType}` 기기 토큰 등록 |
| DELETE | /fcm/token | 토큰 해제(로그아웃 시) |
| GET / PUT | /notification/setting | `{pollNotification, settlementNotification, activityNotification}` 조회 / 수정 |

푸시 `data` payload: POLL `{pollId}` / SETTLEMENT `{activityId, transportGroupId}` / ACTIVITY `{activityId}` (모든 값 문자열)

---

## 개발 시 주의
1. **confirm**: `UPDATE users SET group_id=? WHERE id=? AND group_id IS NULL`, 영향 행 수로 skip 판정, 단일 `@Transactional`
2. **이월**: CARRYOVER는 제출 시점에 후보를 재계산해 검증하고, DB 유니크 제약 `(user_id, carryover_target_activity_id)`로 이중 방어
3. **voteClosed**: 제출 API에서 서버 시각으로 재검증(13:30/15:30). 시차는 VOTE_CLOSED로 안내
4. **Refresh**: 사용자당 1개 저장, 회전 시 갱신, 로그아웃 시 삭제 (단일 기기 가정)
5. **로그인 제한**: 인메모리 방식이라 서버 증설 시 Redis 등으로 이전 필요
6. **enum**: 노출 ATTEND ↔ DB REGULAR, DTO 변환 계층에서 매핑
7. **JVM 타임존**: Asia/Seoul 고정(날짜 경계 로직이 서버 시각에 의존)
8. **boolean JSON 키**: `isCancelled`, `isProjected`처럼 `is` 접두사를 유지(Jackson 기본 동작과 달라 `@JsonProperty` 명시)