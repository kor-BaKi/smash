# SMASH — Claude Code 시작 가이드

이 폴더는 SMASH 프로젝트의 기획·설계 문서 모음이다.
Claude Code로 개발을 시작하기 위한 컨텍스트 전부가 여기 있다.

## 폴더 구조
```
smash/
├── CLAUDE.md              ← Claude Code가 자동으로 먼저 읽는 핵심 파일
├── README.md             ← (이 파일)
└── docs/
    ├── 01-기획서.md
    ├── 02-MVP기능정의.md
    ├── 03-ERD.md
    ├── 04-핵심로직.md      ← 엔진1/2 의사코드 (가장 중요)
    └── 05-API명세.md       ← 31개 엔드포인트 최종본
```

## 시작 방법

### 1. 사전 준비
- Java 21 설치: `sdk install java 21.0.5-tem` (SDKMAN)
- Node.js 18+ (Claude Code용)
- MySQL 로컬 설치 및 실행
- Flutter SDK
- Claude Code: `npm install -g @anthropic-ai/claude-code`

### 2. Claude Code 실행
```bash
cd smash
claude
```

### 3. 첫 지시 (예시)
```
CLAUDE.md와 docs/ 폴더 문서를 모두 읽었지?
docs/05-API명세.md와 docs/04-핵심로직.md를 기준으로,
CLAUDE.md의 개발 순서대로 1단계(인증/권한)부터 시작하자.

먼저 Spring Boot 3.5 + Java 21 + Gradle 프로젝트를 셋업하고,
build.gradle 의존성(web, jpa, security, validation, mysql, jwt, lombok)을 구성해줘.
그다음 User 엔티티부터 만들자.
```

## 개발 순서 (CLAUDE.md 참조)
1. 인증 + 권한
2. 운영 설정 (조/일정/가입코드)
3. 엔진1 — 조 배정 ★
4. 엔진2 — 활동/투표/이월 ★★
5. 출석 현황

각 단계는 백엔드 API 먼저(Swagger 검증) → Flutter 연결.

## 주의
- docs는 설계 기준 문서다. 코드와 어긋나면 docs를 신뢰하되,
  설계 변경이 필요하면 사용자에게 먼저 확인.
- 보안 정책(JWT 식별, 권한 검증, 토큰 저장)은 CLAUDE.md 5번 참조, 처음부터 적용.
