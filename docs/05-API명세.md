# 05. API 명세서 (최종본 — 리뷰 반영)

Base URL: /api/v1 | 인증: JWT Bearer | 권한: ROLE_ADMIN / ROLE_MEMBER

## 공통 규칙
- 사용자 식별: 인증 필요 API의 주체는 JWT subject(userId)에서만 추출.
  Body/Query의 userId는 본인 식별에 사용 금지(IDOR 방지).
  타인 대상(임원) API만 path {userId} 신뢰 + ROLE_ADMIN 선검증.
- 공통 응답: { success, data, error }. error={ code, message }
- 날짜: yyyy-MM-dd / 일시: yyyy-MM-dd'T'HH:mm:ss

### 에러 코드
INVALID_INVITE_CODE / STUDENT_NO_NOT_FOUND / ALREADY_REGISTERED / ALREADY_ASSIGNED /
ASSIGNMENT_CONFLICT / VOTE_CLOSED / CARRYOVER_NOT_AVAILABLE / INVALID_CARRYOVER_TARGET /
INVALID_PARTICIPATION_TYPE / INVALID_REFRESH_TOKEN / FORBIDDEN / RESOURCE_NOT_FOUND

---

## A. 인증 / 가입

### A-1. POST /admin/members  (단건 사전등록, ADMIN)
req: { name, studentNo, department?, phone?, joinTerm }
res: { id, status:"PENDING" }
- studentNo 중복 → ALREADY_REGISTERED. role=MEMBER, status=PENDING, password=NULL

### A-2. POST /admin/members/bulk  (대량등록 부분성공, ADMIN)
req: { members: [A-1 body...] }
res: { succeeded:[{studentNo,id}], failed:[{studentNo,reason}], totalRequested, successCount }
- 건별 트랜잭션. 유효건 커밋, 실패건(DUPLICATE/MISSING_REQUIRED) failed 누적. 207 멀티상태.

### A-3. POST /auth/signup  (회원가입, @Transactional)
req: { code, studentNo, password }
res: { accessToken, refreshToken, user:{id,name,role,groupId} }
- code 유효확인→INVALID_INVITE_CODE / PENDING 학번조회→STUDENT_NO_NOT_FOUND /
  이미ACTIVE→ALREADY_REGISTERED / BCrypt 저장, status=ACTIVE / refreshToken 서버저장

### A-4. POST /auth/login
req: { studentNo, password }
res: { accessToken, refreshToken, user:{id,name,role,groupId} }
- ACTIVE만 허용. refreshToken 신규발급·저장(기존 대체)

### A-5. POST /auth/refresh  (Rotation)
req: { refreshToken }
res: { accessToken, refreshToken(회전) }
- 서버 저장 refreshToken과 대조. 재발급 시 기존 폐기·새토큰 저장.
  재사용/만료/위조 → INVALID_REFRESH_TOKEN

### A-6. POST /auth/logout  (인증)
- JWT subject 기준 저장 refreshToken 삭제 → 재발급 불가. Access는 만료까지 유효(짧게).

---

## B. 운영 설정 (전부 ADMIN, GET /groups만 공통)

### B-1. POST /admin/groups  (조 일괄생성, @Transactional)
req: { groups:[{dayOfWeek, timeSlot}] }  dayOfWeek=MON~FRI, timeSlot=SLOT_13_15/SLOT_15_17
res: { createdGroups:[{id,dayOfWeek,timeSlot,label}] }
- (dayOfWeek,timeSlot) UNIQUE. 존재 조합 skip. label은 서버가 "월 1-3시" 변환

### B-2. GET /groups  (공통)
res: data:[{id,dayOfWeek,timeSlot,label,leaderUserId,memberCount}]

### B-3. PATCH /admin/groups/{groupId}/leader  (@Transactional)
req: { leaderUserId }
- 대상이 해당 조 소속인지 검증. group.leader_user_id + User.is_leader=true. 기존조장 false

### B-4. PUT /admin/activity-schedules  (전체교체, @Transactional)
req: { schedules:[{dayOfWeek,timeSlot,isActive}] }

### B-5. GET /admin/activity-schedules

### B-6. POST /admin/invite-codes
res: { id, code, isActive } - code 서버 랜덤생성 UNIQUE

### B-7. GET /admin/invite-codes  |  PATCH /admin/invite-codes/{id} { isActive }

---

## C. 조 배정

### C-1. PUT /me/availability  (가능요일 교체제출, MEMBER, @Transactional)
req: { groupIds:[...] }
res: { availabilities:[{groupId,dayOfWeek,timeSlot,label}] }
- 주체 JWT. group_id!=NULL(배정확정)이면 ALREADY_ASSIGNED.
  배정전이면 기존 전체삭제 후 재저장. 존재하지않는 조 포함시 400.

### C-2. GET /me/availability  (MEMBER)
res: { availabilities:[...], assigned, assignedGroupId }

### C-3. POST /admin/assignment/preview  (미리보기, DB저장X)
res: { previewToken, basedOnMemberIds:[...], assignments:[{userId,name,assignedGroupId,availableGroupIds}],
       unassigned:[{userId,name,reason}], groupDistribution:[{groupId,label,count}] }
- 대상: group_id=NULL ACTIVE. 알고리즘: 가능요일 적은순→인원 적은조(동점 id순).
  previewToken+basedOnMemberIds 반환(confirm 정합성 대조용)

### C-4. POST /admin/assignment/confirm  (확정, @Transactional)
req: { previewToken, basedOnMemberIds:[...], assignments:[{userId,groupId}] }
res: { assignedCount, skipped:[{userId,reason}] }
정합성 3중:
  1. userId 전부 현재도 미배정 ACTIVE 인지 재조회
  2. basedOnMemberIds vs 현재 미배정 집합 비교 → 달라지면 ASSIGNMENT_CONFLICT
  3. 이미 group_id 있는 건 skipped(중복확정 방지)
  4. 없는 groupId → 전체 롤백
원자성: 단일 트랜잭션 일괄 UPDATE. 동시성: WHERE group_id IS NULL 조건부 UPDATE

### C-5. PATCH /admin/members/{userId}/group  (개별수정, @Transactional)
req: { groupId } - 타인대상이라 path {userId}. groupId 존재검증.

### C-6. GET /admin/members/unassigned
res: data:[{userId,name,availableGroupIds}]  - group_id=NULL ACTIVE

---

## D. 활동 / 투표 / 이월

### D-1. GET /me/activities/today  (MEMBER)
query: scope=MY(기본)/ALL  - MY=본인조만, ALL=타조 가능 전체조 포함
res: data:[{activityId,activityDate,groupId,groupLabel,activityType,isMyGroup,
            availableButtons:[...], myParticipation:{type,targetActivityId}|null, voteClosed}]
- availableButtons 서버결정:
  본인조 REGULAR 자격유지→[ATTEND,ABSENT] / 본인조아님·자격이동→[CARRYOVER,OTHER_GROUP] / FREE→[FREE_ATTEND,ABSENT]
- voteClosed = now >= activityDate + timeSlot 시작시각. is_cancelled 제외.

### D-2. POST /me/activities/{activityId}/participation  (응답, 이월포함통합, @Transactional)
req: { type, targetActivityId? }  type=ATTEND/OTHER_GROUP/FREE_ATTEND/ABSENT/CARRYOVER
res: { participationId, type, targetActivityId }
- 주체 JWT(Body userId 없음). voteClosed→VOTE_CLOSED.
  type이 availableButtons에 없으면 INVALID_PARTICIPATION_TYPE.
  CARRYOVER: targetActivityId 필수, 후보 재계산 검증→INVALID_CARRYOVER_TARGET,
             후보공집합→CARRYOVER_NOT_AVAILABLE.
  (activity_id,user_id) UNIQUE upsert. 동일자격 중복이월 방지(target 기존이월 재확인).

### D-3. GET /me/activities/{activityId}/carryover-candidates  (MEMBER)
res: data:[{targetActivityId,date,status:FUTURE|PAST_ABSENT}]
- 당월 본인조 활동. 미래=FUTURE, 과거미참여=PAST_ABSENT.
  제외: 이미참여/이미이월/당월밖. 공집합이면 "이월불가". (확정 D-2에서 재계산)

### D-4. DELETE /me/activities/{activityId}/participation  (@Transactional)
- voteClosed→VOTE_CLOSED. 삭제. CARRYOVER였으면 기록삭제만으로 target 자격복구.

### D-5. GET /activities/{activityId}  (공통, 집계+명단)
res: { activityId, activityDate, groupLabel, activityType, isCancelled,
       summary:{regular,carryover,otherGroup,freeAttend,absent},
       participants:{regular:[{userId,name}], carryover:[...], otherGroup:[...], freeAttend:[...], absent:[...]} }
- 집계·명단 공개. 충족/미달 등 평가성 데이터는 미포함(E 전용).

### D-6. GET /admin/activities?date=  (ADMIN, 날짜별 전체조)
res: data:[{activityId,groupLabel,activityType,isCancelled,summary}]  날짜미지정=오늘

### D-7. PATCH /admin/activities/{activityId}  (@Transactional)
req: { isCancelled?, activityType? }  최소 하나. 과거응답 삭제안함.

---

## E. 출석 현황 (전부 ADMIN, 계산기반·저장X)

### E-1. GET /admin/attendance?groupId=&year=&month=
res: { groupId, groupLabel, year, month, guaranteedCount,
       members:[{userId,name,fulfilled,guaranteed,shortfall,isShortfall}] }
- guaranteed=그달 REGULAR·미취소 본인조 활동일수 / fulfilled=REGULAR+CARRYOVER /
  shortfall=max(0,guaranteed-fulfilled). OTHER_GROUP/FREE_ATTEND/ABSENT 제외.

### E-2. GET /admin/attendance/shortfall?year=&month=
res: data:[{userId,name,groupLabel,fulfilled,guaranteed,shortfall}]  전체조 미달자

### E-3. GET /admin/attendance/other-group?year=&month=
res: data:[{userId,name,count,activities:[{activityId,date,groupLabel}]}]  타조참 집계

---

## 개발 시 주의
1. confirm: UPDATE users SET group_id=? WHERE id=? AND group_id IS NULL, 영향행수로 skip판정, 단일 @Transactional
2. 이월: D-2의 CARRYOVER는 confirm 시점 후보 재계산. target 기준 기존이월 확인후 삽입
3. voteClosed: 제출 API에서 서버시각 재검증 필수. 시차는 VOTE_CLOSED로 안내
4. Refresh: 사용자별 현재 토큰 DB/Redis 저장, 회전시 갱신, 로그아웃시 삭제. 단일기기 가정
5. 충족 쿼리: 인덱스(activity_date, group_id, user_id, type)
6. enum: 노출 ATTEND ↔ DB REGULAR, DTO 변환레이어에서 매핑
