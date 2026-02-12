# claude-enterprise-universe

![Claude Code Plugin](https://img.shields.io/badge/Claude_Code-Plugin-blue)
![Version](https://img.shields.io/badge/version-1.0.0-green)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

AI 에이전트만으로 구성된 엔터프라이즈 규모 기업을 시뮬레이션하는 Claude Code 플러그인.

5대 원칙 기반 거버넌스, C-Suite 9명, 13개 부서 42명의 조직 구조를 원샷 부트스트랩으로 즉시 활성화하고, 세션 간 핸드오프를 지원합니다.

---

## 핵심 기능

### 1. 5대 원칙 거버넌스

모든 조직 운영의 불변 규칙:

| # | 원칙 | 핵심 규칙 |
|---|------|----------|
| P1 | 단일 산출물 책임 | 한 에이전트 = 하나의 산출물 타입 |
| P2 | 실행-검토 분리 | Maker ≠ Checker |
| P3 | 티켓 기반 실행 | 모든 작업은 Task에서 시작 |
| P4 | 기억 계층 분리 | L3 정책 > L2 SOP > L1 프로젝트 > L0 작업 |
| P5 | 정책=매니저 | 규칙이 자동 강제 (Policy-as-Code) |

### 2. C-Suite 경영위원회 (9명 상시)

| 직책 | 에이전트명 | 모델 | 권한 | 핵심 역할 |
|------|-----------|------|------|----------|
| CEO | team-lead | opus | L4 | 총괄 지휘, 미션 배분 |
| CTO | cto | opus | L3-L4 | 기술 결정, 모델 거버넌스 |
| CPO | cpo | sonnet | L4 | 제품 전략, 우선순위 |
| CFO | cfo | sonnet | L4 | 비용/예산, 토큰 관리 |
| COO | coo | sonnet | L2 | 배포 승인, CAB 운영 |
| CMO | cmo | sonnet | L1 | 마케팅, 대외 커뮤니케이션 |
| CISO | ciso | sonnet | L3 | 보안 정책, 게이트 운영 |
| PM | pm-lead | sonnet | L1 | 프로젝트/태스크 관리 |
| VL | vl-investor | opus | L4(자문) | 외부 투자자 시각 |

### 3. 13개 부서 42명 (온디맨드)

미션 할당 시 CEO가 필요한 부서를 판단하여 온디맨드 스폰합니다.
동시 최대 4개 부서, 추가 에이전트 최대 8명.

### 4. CAB 자동화 워크플로우

배포/정책 변경 시 6단계 자동 승인 프로세스:

```
CR 티켓 생성(L0) -> 품질 게이트(L1) -> 보안 게이트(L3)
  -> 배포 승인(L2) -> 일정 반영 -> 최종 확인(고위험만)
```

### 5. 세션 지속성

상태 저장/복원/핸드오프로 크로스 세션 운영. 컨텍스트 압축에도 복원 가능.

### 6. 실시간 대시보드

tmux 듀얼 패널 (조직 현황 + 미션 현황), 5초 자동 갱신.

---

## 설치

### 방법 1: 마켓플레이스 등록 + 플러그인 설치 (권장)

```bash
# Step 1: 리포지토리 클론
git clone https://github.com/DrFREEST/claude-enterprise-universe.git /opt/claude-enterprise-universe

# Step 2: 마켓플레이스 레지스트리 등록
mkdir -p ~/.claude/plugins/marketplaces/enterprise-universe/.claude-plugin
cp /opt/claude-enterprise-universe/.claude-plugin/marketplace.json \
   ~/.claude/plugins/marketplaces/enterprise-universe/.claude-plugin/marketplace.json

# Step 3: 플러그인 파일 동기화
rsync -av --exclude='.git' --exclude='__pycache__' --exclude='.omc' \
  /opt/claude-enterprise-universe/ ~/.claude/marketplaces/enterprise-universe/
```

### 방법 2: 플러그인 디렉토리 직접 설치

```bash
git clone https://github.com/DrFREEST/claude-enterprise-universe.git \
  ~/.claude/plugins/enterprise-universe/
```

### 업데이트

```bash
# 소스 업데이트 후 마켓플레이스 재동기화
cd /opt/claude-enterprise-universe && git pull
rsync -av --exclude='.git' --exclude='__pycache__' --exclude='.omc' \
  /opt/claude-enterprise-universe/ ~/.claude/marketplaces/enterprise-universe/
```

설치 후 Claude Code를 재시작하면 `/enterprise`, `/dash-setup` 등 6개 커맨드가 자동 등록됩니다.

---

## 사용법

```bash
# 팀 활성화 (원샷 부트스트랩)
/enterprise

# 대시보드 세팅
/dash-setup

# 상태 확인
/ent-status

# 상태 저장
/ent-save

# 인수인계 (세션 종료 전)
/ent-handoff

# 이전 세션 복원 안내
/ent-restore
```

### 커맨드 요약

| 커맨드 | 기능 | 트리거 키워드 |
|--------|------|-------------|
| `/enterprise` | 팀 부트스트랩 (C-Suite 9명 스폰) | enterprise, 기업 모드, universe |
| `/dash-setup` | tmux 실시간 대시보드 자동 세팅 | 대시보드 설정, dashboard setup |
| `/ent-status` | 현재 팀/태스크/거버넌스 상태 확인 | 팀 상태, enterprise status |
| `/ent-save` | 팀 상태를 파일로 저장 | 상태 저장, enterprise save |
| `/ent-handoff` | 인수인계 문서 생성 + 상태 저장 | 인수인계, enterprise handoff |
| `/ent-restore` | 저장된 세션 복원 안내 | 세션 복원, enterprise restore |

---

## 실시간 대시보드

tmux 듀얼 패널 대시보드로 조직 현황과 미션 진행 상태를 실시간 모니터링합니다.

### 자동 세팅

```bash
/dash-setup
```

Claude Code에서 위 커맨드를 입력하면 tmux 세션이 자동 생성됩니다.

### 수동 세팅

```bash
# 세션 생성 + 좌측 패널 (조직 현황)
tmux new-session -d -s enterprise-dash -x 160 -y 45 \
  "watch -t -c -n 5 python3 <plugin-path>/scripts/dashboard.sh"

# 우측 패널 (미션 현황)
tmux split-window -h -t enterprise-dash \
  "watch -t -c -n 5 python3 <plugin-path>/scripts/tasks-panel.sh"

# 레이아웃 균등 분할
tmux select-layout -t enterprise-dash even-horizontal
```

### 대시보드 조작

| 동작 | 명령 |
|------|------|
| 연결 | `tmux attach -t enterprise-dash` |
| 분리 (백그라운드 유지) | `Ctrl+B` -> `D` |
| 종료 | `tmux kill-session -t enterprise-dash` |
| 패널 전환 | `Ctrl+B` -> 방향키 |

### 패널 구성

| 패널 | 표시 내용 |
|------|----------|
| 좌측 (dashboard.sh) | C-Suite 상태, 부서 현황, 최근 완료 미션 |
| 우측 (tasks-panel.sh) | 리소스 요약, 활성 미션, 대기 미션 |

갱신 주기: 5초 자동.
권장 터미널 크기: 140 컬럼 이상.

---

## 미션 템플릿

| 미션 유형 | 활성화 부서 | 비용 등급 |
|----------|-----------|----------|
| 신규 기능 | 임원+기획+BE+FE+QA | HIGH |
| 보안 감사 | 임원+보안+법률 | MEDIUM |
| 성능 최적화 | 임원+인프라+분석+BE | MEDIUM |
| 제품 출시 | 전 부서 (4개씩 순차) | VERY HIGH |
| 데이터 분석 | 임원+분석+AI | LOW |
| 코드 리뷰 | 임원+보안+QA+인프라 | MEDIUM |
| 버그 수정 | 임원+BE+QA | LOW |

---

## 프로젝트 구조

```
claude-enterprise-universe/
├── .claude-plugin/          # 플러그인 메타데이터
│   ├── plugin.json
│   └── marketplace.json
├── config/
│   ├── governance.json      # 거버넌스 (5대 원칙, C-Suite 프롬프트, CAB)
│   └── universe.json        # 조직 구조 (13부서 42명, 미션 템플릿)
├── docs/                    # 28개 조직 운영 문서
├── scripts/
│   ├── bootstrap.py         # 상태 관리 CLI (save/restore/status/handoff)
│   ├── dashboard.sh         # 대시보드 좌측 패널
│   └── tasks-panel.sh       # 대시보드 우측 패널
├── skills/
│   ├── enterprise/          # /enterprise 스킬
│   └── dash-setup/          # /dash-setup 스킬
├── src/
│   └── universe-loader.mjs  # 유니버스 설정 로더
├── CLAUDE.md
├── package.json
└── README.md
```

---

## 조직 문서 (28개)

### 기반 문서
- `00` 5대 원칙 AI 조직 설계 / 전체 개요 한 장 조직도

### 핵심 조직 문서 (01-09)
- `01` 권한 레벨과 역할 체계
- `02` 사업부 운영 플레이북
- `03` 전사 공통 본부 플레이북
- `04` RACI 매트릭스
- `05` 회의체와 거버넌스
- `06` 변경관리/릴리즈/장애대응
- `07` 보안/정책/품질 게이트
- `08` 인사/고충/인원확충 운영
- `09` 단계별 겸임/분리 기준

### 템플릿 (10-19)
- `10` BU별 RACI 상세 / `11` 변경 요청 CR / `12` CAB 의사결정
- `13` 릴리즈 체크리스트 / `14` 인시던트 핸들링 / `15` 포스트모템
- `16` BU별 RACI 팀단위 세분화 / `17` 정책 예외 승인 / `18` 데이터 마이그레이션
- `19` 보안심사 패키지

### 확장 문서 (20-26)
- `20` 예산/비용 배분 / `21` 에스컬레이션 매트릭스 / `22` 크로스BU 협업 SOP
- `23` SLO 정의서 / `24` AI 에이전트 운영 정책 / `25` 온보딩 플레이북
- `26` ADR 의사결정 기록

---

## 비용 제어

| 항목 | 제한 |
|------|------|
| 최대 동시 에이전트 | 15명 (C-Suite 9 + BU 6) |
| 경고 임계값 | 에이전트 8명 이상 |
| MCP-First | 분석/리뷰는 ask_codex/ask_gemini 우선 |
| 에이전트당 파일 | 최대 6개 |
| max_turns | 설정 필수 |

---

## 호환성

- Claude Code 2.0+
- Python 3.10+
- tmux (대시보드용, 선택)

---

## 라이센스

MIT
