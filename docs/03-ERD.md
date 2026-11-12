# 03. ERD 설계

> 최종 갱신: 2026-11. 단일 동아리 전용, **27개 테이블**(JPA Entity 기준). Club 테이블 없음.
> 출석·충족·이월 자격은 저장하지 않고 Participation에서 계산한다.

## 테이블 목록 (도메인별)
| 도메인 | 테이블 |
|---|---|
| 회원/인증 | users, refresh_token, fcm_token, user_notification_setting, member_note, invite_code |
| 조/일정 | club_groups, member_availability, activity_schedule, free_period, schedule(동아리 일정) |
| 활동/참여 | activity, participation, activity_photo |
| 이동/정산 | transport_group, transport_member, taxi_settlement, taxi_settlement_payment |
| 일반 투표 | polls, poll_options, poll_votes |
| 모집 지원 | application_form, form_question, application, application_answer, application_memo |
| 회비 | dues_payment |

> 테이블명 주의: Group은 예약어 충돌을 피하려고 `club_groups`, User는 `users`로 만들었다.

## 관계 요약
- users → club_groups : 소속 (users.group_id, 배정 전 NULL) — 단순 Long 컬럼
- club_groups → users : 조장 `leader_user_id`, 부조장 `vice_leader_user_id` (조장 여부는 User가 아니라 Group이 가진다)
- users ↔ club_groups : 가능 요일 N:M (member_availability)
- club_groups → activity : 1:N
- activity → participation : 1:N / users → participation : 1:N
- participation → activity : 이월 대상 자기참조 (`carryover_target_activity_id`)
- activity → activity_photo : 1:N (업로더 users)
- activity → transport_group : 1:N → transport_member(users) N
- transport_group → taxi_settlement : 호차별 정산 1건 → taxi_settlement_payment(탑승자별 납부 여부)
- polls → poll_options → poll_votes(users) : 한 투표당 1인 1표
- application_form → form_question 1:N / application_form → application 1:N → application_answer(question) / application_memo(작성 임원)

## users
| 컬럼 | 타입 | 제약 | 설명 |
|---|---|---|---|
| id | BIGINT | PK | |
| student_no | VARCHAR | UNIQUE, NOT NULL | 학번 = 로그인 ID (탈퇴 시 `withdrawn-{id}`로 변경) |
| name | VARCHAR | | |
| password | VARCHAR | NULL | BCrypt, 가입 완료 시 채워짐 |
| department / phone | VARCHAR | NULL | |
| join_term | VARCHAR | NULL | 가입 기수 (예: 2026-1) |
| group_id | BIGINT | NULL | 소속 조, 배정 전 NULL |
| role | ENUM | NOT NULL | ADMIN / MEMBER |
| status | ENUM | NOT NULL | PENDING(사전등록) / ACTIVE / REJECTED(가입 거절) |
| created_at | DATETIME | | |
| deleted_at | DATETIME | NULL | 탈퇴 시각 (Soft Delete + 익명화) |

## club_groups
`id / day_of_week ENUM(MON~FRI) / time_slot ENUM(SLOT_13_15, SLOT_15_17) / leader_user_id / vice_leader_user_id`
- (day_of_week, time_slot) UNIQUE

## member_availability
`id / user_id FK / group_id FK / create_at` — (user_id, group_id) UNIQUE. 배정 근거로 보관.

## activity_schedule (정규 활동 규칙)
`id / day_of_week / time_slot / is_active` — 스케줄러가 읽어 평일 자정마다 Activity 생성.

## free_period (자유활동 기간)
`id / start_date / end_date / created_at` — 기간이 겹치면 등록 불가(OVERLAPPING_PERIOD). 기간 중 활동은 FREE로 생성.

## schedule (동아리 일정)
`id / title / date / memo / created_by FK users / created_at` — 임원이 등록, 전원 열람.

## activity (활동 = 투표)
| 컬럼 | 설명 |
|---|---|
| id PK / group_id FK / activity_date DATE | (group_id, activity_date) UNIQUE |
| activity_type ENUM | REGULAR / FREE |
| is_cancelled BOOLEAN | 휴강 처리 (과거 응답은 삭제하지 않음) |
| created_by ENUM | AUTO / MANUAL |
| created_at | |

투표 마감 시각은 컬럼으로 저장하지 않고 계산한다: 1-3시 조 13:30, 3-5시 조 15:30 (늦참자 배려로 30분 연장).

## participation (심장)
| 컬럼 | 설명 |
|---|---|
| id PK / activity_id FK / user_id FK | (activity_id, user_id) UNIQUE |
| type ENUM | REGULAR / CARRYOVER / OTHER_GROUP / FREE_ATTEND / ABSENT |
| carryover_target_activity_id | type=CARRYOVER일 때만 채움 (자기참조) |
| travel_type ENUM | TOGETHER / ALONE (이동 방식, NULL 가능) |
| created_at / updated_at | |
- (user_id, carryover_target_activity_id) UNIQUE : 같은 날의 자격을 두 번 이월하는 것을 DB 차원에서 방지

## activity_photo
`id / activity_id FK / uploaded_by FK users / file_path / created_at` — 파일은 서버 디렉토리(활동별 폴더, UUID 파일명), DB에는 경로만 저장.

## transport_group / transport_member
- transport_group : `id / activity_id FK / group_number(호차) / created_at`
- transport_member : `id / transport_group_id FK / user_id FK`

## taxi_settlement / taxi_settlement_payment
- taxi_settlement : `id / transport_group_id FK / activity_id FK / payer_id FK users / total_amount / amount_per_person / account_bank / account_number / created_at`
  - account_number는 **AES-256-GCM 암호화 저장** (`enc:` + base64(IV 12B + 암호문 + 태그)), 결제자 탈퇴 시 계좌 정보 삭제
- taxi_settlement_payment : `id / settlement_id FK / user_id FK / is_paid / paid_at`

## polls / poll_options / poll_votes
- polls : `id / title / description / is_anonymous / closed_at(NULL=수동 종료) / created_by FK / created_at`
- poll_options : `id / poll_id FK / content / order_index`
- poll_votes : `id / poll_id / option_id / user_id / created_at` — (poll_id, user_id) UNIQUE

## 모집 지원
- application_form : `id / is_active / start_date / end_date / created_at` (새 폼 생성 시 이전 질문 복사 옵션)
- form_question : `id / form_id FK / content / question_type(TEXT·MULTILINE·SELECT) / is_required / order_index / options`
- application : `id / form_id FK / name / student_no / department / phone / availabilities("MON:SLOT_13_15,...") / status(PENDING·ACCEPTED·REJECTED) / memo / created_at`
- application_answer : `id / application_id / question_id / answer`
- application_memo : `id / application_id / admin_id FK users / content / created_at`
- 합격 처리 시 users에 PENDING으로 자동 사전등록되고, 지원서의 가능 요일이 member_availability로 자동 등록된다.

## 기타
- invite_code : `id / code UNIQUE / is_active / created_at`
- member_note : `id / member_id FK / admin_id FK / content / created_at` — 임원 전용 부원 메모
- dues_payment : `id / user_id FK(UNIQUE)` — 행이 있으면 납부, 없으면 미납 (납부 취소 = 행 삭제, 학기 초기화 = 전체 삭제)
- refresh_token : `id / user_id UNIQUE / token(SHA-256 해시) / expires_at / create_at` — 사용자당 1개(단일 기기 가정), 회전 시 갱신
- fcm_token : `id / user_id FK / token UNIQUE / device_type / created_at` — 한 사용자 다기기 가능, 같은 기기 다른 계정 로그인 시 토큰 이전
- user_notification_setting : `id / user_id(1:1) / poll_notification / settlement_notification / activity_notification` (기본 true)

## 핵심 설계 결정
- Club 제거(단일 동아리) / 가입 PENDING→ACTIVE / 학번 대조 / 부원 정보 수정은 임원만(본인은 비밀번호만)
- 참여유형 활동별 분리(정규 4종 / 자유 참여·불참)
- 출석·충족 미저장(계산) / 이월 자기참조 + 이중 이월 유니크 제약 / 불참도 저장 / 가능요일 영구 보관
- 탈퇴는 hard delete가 아닌 **익명화**: 활동 기록(Participation)은 통계 연속성을 위해 남기고, 개인정보·토큰·알림설정·메모·계좌는 삭제
- 조장/부조장은 User 플래그가 아닌 Group 컬럼 (조 단위 권한 구조 확장 용이)
- 민감 필드는 애플리케이션 계층에서 암호화(JPA 변환) — DB 유출만으로는 계좌번호 노출 불가