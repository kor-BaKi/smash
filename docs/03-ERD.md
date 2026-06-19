# 03. ERD 설계

단일 동아리 전용. 8개 테이블. Club 테이블 없음(단일 동아리라 불필요).
출석·충족·이월 자격은 저장하지 않고 Participation에서 계산.

## 테이블 목록
User / Group / MemberAvailability / ActivitySchedule / FreePeriod / Activity / Participation / InviteCode

## 관계
- User → Group (소속, N:1, User.group_id, 배정 전 NULL)
- Group → User (조장, Group.leader_user_id)
- User ↔ Group (가능요일, N:M, MemberAvailability)
- Group → Activity (1:N, Activity.group_id)
- Activity → Participation (1:N)
- User → Participation (1:N)
- Activity → Participation (이월 대상, 자기참조, Participation.carryover_target_activity_id)

## User
| 컬럼 | 타입 | 제약 | 설명 |
|---|---|---|---|
| id | BIGINT | PK | |
| group_id | BIGINT | FK Group, NULL | 소속 조 |
| name | VARCHAR(50) | NOT NULL | |
| student_no | VARCHAR(20) | UNIQUE, NOT NULL | 학번=로그인ID |
| password | VARCHAR(255) | NULL | 가입완료 시 채워짐(BCrypt) |
| department | VARCHAR(50) | NULL | |
| phone | VARCHAR(20) | NULL | |
| role | ENUM | NOT NULL | ADMIN / MEMBER |
| is_leader | BOOLEAN | DEFAULT false | 조장 여부 |
| join_term | VARCHAR(20) | NULL | 가입기수 2026-1 |
| status | ENUM | NOT NULL | PENDING / ACTIVE |
| created_at | DATETIME | NOT NULL | |
| deleted_at | DATETIME | NULL | Soft Delete |

## Group
| id PK / day_of_week ENUM(MON~FRI) / time_slot ENUM(SLOT_13_15,SLOT_15_17) /
  leader_user_id FK User NULL / created_at |
- (day_of_week, time_slot) UNIQUE

## MemberAvailability
| id PK / user_id FK / group_id FK / created_at |
- (user_id, group_id) UNIQUE. 영구 보관(배정 근거)

## ActivitySchedule (정규활동 규칙)
| id PK / day_of_week ENUM / time_slot ENUM / is_active BOOLEAN |
- 스케줄러가 읽어 매일 Activity 생성

## FreePeriod (자유활동 기간)
| id PK / name VARCHAR NULL / start_date DATE / end_date DATE / created_at |
- 오늘이 이 기간이면 activity_type=FREE로 생성

## Activity (활동=투표)
| 컬럼 | 타입 | 제약 |
|---|---|---|
| id | BIGINT | PK |
| group_id | BIGINT | FK Group |
| activity_date | DATE | NOT NULL |
| activity_type | ENUM | REGULAR / FREE |
| is_cancelled | BOOLEAN | DEFAULT false |
| created_by | ENUM | AUTO / MANUAL |
| created_at | DATETIME | NOT NULL |
- (group_id, activity_date) UNIQUE

## Participation (심장)
| 컬럼 | 타입 | 제약 |
|---|---|---|
| id | BIGINT | PK |
| activity_id | BIGINT | FK Activity |
| user_id | BIGINT | FK User |
| type | ENUM | REGULAR/CARRYOVER/OTHER_GROUP/FREE_ATTEND/ABSENT |
| carryover_target_activity_id | BIGINT | FK Activity, NULL |
| created_at | DATETIME | NOT NULL |
| updated_at | DATETIME | NULL |
- (activity_id, user_id) UNIQUE
- carryover_target_activity_id는 type=CARRYOVER일 때만 채워짐

## InviteCode
| id PK / code VARCHAR UNIQUE / is_active BOOLEAN / created_at |

## 핵심 설계 결정
- Club 제거(단일 동아리) / 가입 PENDING→ACTIVE / 학번 대조 / 수정은 임원만
- 참여유형 활동별 분리(정규 4종 / 자유 참여·불참)
- 출석·충족 미저장(계산) / 이월 자기참조 / 불참 저장 / 가능요일 영구보관 / Soft Delete
