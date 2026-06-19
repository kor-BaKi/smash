# CLAUDE.md — SMASH 프로젝트 헌법

> 이 파일은 Claude Code가 세션 시작 시 자동으로 읽습니다.
> 프로젝트의 정체성, 기술 스택, 핵심 도메인 규칙, 개발 순서, 합의된 정책을 담습니다.
> 코드를 작성하기 전에 반드시 `docs/` 폴더의 상세 설계 문서를 함께 참고하세요.

---

## 1. 프로젝트 정체성

**SMASH** — 대학교 배드민턴 동아리 활동 운영 관리 앱 (개인 프로젝트 / 포트폴리오)

단순 동아리 관리 앱이 아니라, **배드민턴 동아리의 고유 운영 규칙(조 편성, 월 4회 활동 보장, 이월 제도, 타조 참여, 매일 활동 투표, 신규 부원 자동 배정)을 시스템화**하는 서비스다.

핵심 가치를 증명하는 두 개의 엔진:
- **엔진 1 — 자동 조 배정**: 가능 요일 기반으로 부원을 10개 조에 균형 배정
- **엔진 2 — 매일 투표 / 이월 / 출석**: 매일 자동 생성되는 투표 + 이월 자격 이동 + 월 4회 충족 계산

이 두 엔진이 포트폴리오의 핵심이다. 나머지(인증, 조 편성 등)는 이 엔진을 떠받치는 최소 껍데기다.

---

## 2. 기술 스택 (확정)

### 백엔드
- **Java 21** (LTS)
- **Spring Boot 3.5.x**
- **Gradle** (빌드)
- **MySQL** (DB)
- **Spring Data JPA / Hibernate**
- **Spring Security + JWT** (Access / Refresh Token)
- **Spring Scheduler** (매일 활동 자동 생성 배치)

### 프론트엔드
- **Flutter** (크로스플랫폼 iOS/Android)
- **Riverpod** (상태관리)
- **Dio** (HTTP, 토큰 자동 재발급 인터셉터)
- **flutter_secure_storage** (토큰 보관 — SharedPreferences 금지)

---

## 3. 핵심 도메인 규칙 (반드시 숙지)

### 3.1 조(Group) 구조
- 월~금 × (1-3시 / 3-5시) = 최대 10개 조
- 부원은 **하나의 조에 소속**(배정 결과). 가능 요일은 여러 개 선택 가능(배정 입력)

### 3.2 참여 유형(Participation.type)
| type | 의미 | 허용 활동 | 체육관비 |
|---|---|---|---|
| REGULAR | 본인 조 정규 참여 | REGULAR | 조장(회비) |
| CARRYOVER | 이월 참여 (보장 자격 이동) | REGULAR | 조장(회비) |
| OTHER_GROUP | 타조 참여 (추가 참여) | REGULAR | 본인 직접 |
| FREE_ATTEND | 자유활동 참여 | FREE | 본인 직접 |
| ABSENT | 불참 | REGULAR / FREE | - |

### 3.3 이월 제도 (가장 중요 — 자기참조 설계)
- 부원은 본인 조 활동 기준 **주당 1회, 월 4회 보장**
- 못 가거나 못 갈 활동은 **같은 달 안에서만** 다른 날로 이월 가능 (다음 달 이월 불가)
- **이월 = "보장 자격을 다른 날로 옮기는 것"**. 별도 상태 저장 없이 "이월 기록의 존재 여부"로 판정
- 이월 시 달력에서 "빠지는/빠진 본인 조 활동일"을 지정 → 그 날의 정규 자격이 오늘로 이동
- 자격을 옮긴 날은 이후 [이월/타조참] 버튼으로 전환됨 (정규 자격 상실)
- 자격 재이동 가능 (계속 밀어내기), 옮길 자격 없으면 "이월이 불가능합니다"
- 이월 후보: 미래 본인 조 활동일(FUTURE) + 과거 미참여 본인 조 활동일(PAST_ABSENT)
- 이월 취소 = 기록 삭제 → 자격 자동 복구 (추가 로직 불필요)

### 3.4 충족 계산 (임원 조회 전용, 저장 안 함)
- guaranteed = 그 달 본인 조 REGULAR·미취소 활동일 수
- fulfilled = 그 달 REGULAR + CARRYOVER 응답 수
- shortfall = max(0, guaranteed - fulfilled)
- OTHER_GROUP / FREE_ATTEND / ABSENT 는 충족 계산 제외
- **부원에게는 잔여 횟수·미달을 절대 노출하지 않는다** (임원 전용)

### 3.5 투표 마감 (시점 제한)
- 부원은 **활동 시작 시각 전까지만** 응답·수정·취소 가능
  - SLOT_13_15 → 13:00 / SLOT_15_17 → 15:00 마감
- 마감 후에는 조회만 가능 (임원은 시점 제한 없이 수정 가능)
- 지난 투표 기록은 부원도 조회 가능, 수정 불가

### 3.6 체육관비
- SMASH는 **결제 주체(조장 회비 / 본인)만 기록**. 금액 계산·정산은 하지 않는다.

### 3.7 가입 구조
- 임원이 합격자를 사전 등록 (status=PENDING)
- 합격자가 가입코드 + 학번 + 비밀번호로 가입 → 학번 대조 → status=ACTIVE 전환
- 학번(student_no)이 로그인 ID 겸용 (UNIQUE)
- 회원 정보 수정은 **임원만 가능** (부원은 본인 조회만)

---

## 4. 개발 순서 (이 순서대로)

각 단계는 **백엔드 API 먼저 (Swagger/Postman 검증) → Flutter 연결** 순으로.

```
[1단계] 인증 + 권한
  - User 엔티티, JWT 발급/검증, 회원가입/로그인/재발급/로그아웃
  - 목표: 로그인하면 임원/부원 홈 분기

[2단계] 운영 설정
  - 조 편성 + 조장 지정, 정규활동 일정, 가입코드 발급
  - 목표: 임원이 10개 조 + 가입코드 생성

[3단계] 엔진 1 — 조 배정 ★
  - 가능요일 제출, 자동배정(preview/confirm), 개별수정, 미배정자
  - 알고리즘 + 단위 테스트 (조별 편차 ±2 검증)
  - 목표: 부원 요일 제출 → 임원 자동배정 확정

[4단계] 엔진 2 — 활동/투표/이월 ★★
  - 스케줄러(매일 활동 생성), 버튼분기, 참여응답(이월 통합), 이월후보, 취소
  - 목표: 매일 투표 뜨고 참여/이월하면 데이터 쌓임

[5단계] 출석 현황
  - 충족 계산 조회 (임원), 미달자, 타조참
  - 목표: 임원이 월 4회 충족 현황 조회
```

Phase 2 이후(지금 구현 안 함): 공지, 회비 관리, 자유활동 기간 UI, 푸시 알림, 이동 동행, 게시판, 일반 투표(MT 등), 통계.

---

## 5. 합의된 기술 정책 (API 리뷰 반영)

코드 작성 시 반드시 지킬 것:

1. **사용자 식별 = JWT subject 고정**
   - `/me/*` 경로의 주체는 항상 JWT에서 추출. Body/Query의 userId는 무시 (IDOR 방지)
   - 타인 대상 API(임원 전용)만 path `{userId}` 신뢰 + ROLE_ADMIN 검증 선행

2. **공통 응답 포맷** — 모든 응답을 감싼다
   ```json
   { "success": true, "data": {}, "error": null }
   { "success": false, "data": null, "error": { "code": "...", "message": "..." } }
   ```

3. **배정 확정(confirm) 3중 정합성**
   - 단일 `@Transactional`
   - 대상 집합(basedOnMemberIds) 대조로 preview~confirm 사이 변동 감지 → ASSIGNMENT_CONFLICT
   - 조건부 UPDATE (`WHERE group_id IS NULL`)로 이미 배정된 건 보호

4. **대량 등록(bulk) 부분 성공** — 건별 처리, succeeded/failed 분리 반환

5. **Refresh Token Rotation** — 재발급 시 회전, 서버 저장·대조, 로그아웃 시 폐기

6. **참여 응답 단일 엔드포인트** — 이월 포함 모든 유형을 `POST .../participation`에서 type으로 구분

7. **이월 확정 시 후보 재계산** — 조회 응답을 신뢰하지 말고 서버에서 재검증

8. **출석/충족/이월 자격은 저장하지 않고 계산** — Participation 기록에서 산출

9. **enum 매핑** — 클라이언트 노출명 ATTEND ↔ DB 저장값 REGULAR (DTO 레이어에서 변환)

---

## 6. 백엔드 패키지 구조 (레이어드)

```
com.smash
├── domain
│   ├── user         (User, Role, Status, Repository)
│   ├── group        (Group, MemberAvailability)
│   ├── activity     (Activity, ActivitySchedule, FreePeriod)
│   ├── participation(Participation, ParticipationType)
│   └── invite       (InviteCode)
├── auth             (JWT, Security 설정, 토큰 서비스)
├── api              (Controller + Request/Response DTO, 영역별: auth, admin, member, activity, attendance)
├── service          (비즈니스 로직 — 엔진1/엔진2 핵심 로직)
├── scheduler        (매일 활동 생성 배치)
├── common           (공통 응답 포맷, 예외 처리, 에러 코드)
└── config           (설정)
```

- Controller → Service → Repository 단방향 의존
- 비즈니스 규칙은 Service에. Controller는 얇게.
- 엔진1(배정 알고리즘), 엔진2(이월/충족 계산)는 별도 Service로 분리하고 단위 테스트 작성

---

## 7. 작업 방식

- 한 번에 한 단계씩. 단계 끝나면 실제로 돌려보고 다음으로.
- 큰 기능은 작은 단위로 쪼개서 작업 (엔티티 → Repository → Service → Controller → 테스트).
- 코드 작성 후 왜 그렇게 했는지 핵심만 짧게 설명.
- 막히면 추측하지 말고 docs/ 문서 또는 사용자에게 확인.
- 보안 관련(토큰 저장, 권한 검증)은 처음부터 적용.
- 상세 스펙은 `docs/06-API명세.md`, 핵심 로직은 `docs/07-핵심로직.md` 참조.
