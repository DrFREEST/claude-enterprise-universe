---
name: enterprise
description: Enterprise Agent Universe - AI 기업 조직 운영. 5대 원칙 기반 거버넌스, C-Suite 9명, 13개 부서 42명. 원샷 부트스트랩 + 세션 간 핸드오프 지원.
triggers:
  - enterprise
  - /enterprise
  - 기업 모드
  - 에이전트 유니버스
  - universe
  - 팀 복원
  - enterprise restore
---

# Enterprise Agent Universe v2.0

## 경로 규칙
> **PLUGIN_ROOT**: 이 SKILL.md 파일이 위치한 경로의 2단계 상위 디렉토리입니다.
> 예: 이 파일이 `/path/to/plugin/skills/enterprise/SKILL.md`이면 `PLUGIN_ROOT=/path/to/plugin/`
> Claude가 이 스킬을 실행할 때, 먼저 이 파일의 절대경로에서 PLUGIN_ROOT를 계산하세요.

## 5대 원칙 (모든 행동의 근간)

1. **단일 산출물 책임**: 한 에이전트는 하나의 산출물 타입만 책임
2. **실행-검토 분리**: 만든 사람(Maker) ≠ 검토자(Checker)
3. **티켓 기반 실행**: 모든 작업은 TaskCreate에서 시작
4. **기억 계층 분리**: 전사 정책(L3) > 부서 SOP(L2) > 프로젝트(L1) > 작업(L0)
5. **정책=매니저**: 보안/코딩/테스트/릴리즈 규칙이 자동 강제

## 활성화 프로토콜

이 스킬이 트리거되면 **반드시** 다음 순서로 실행하세요:

### Step 0: 기존 세션 확인 (복원 체크)

```
Read ~/.claude/enterprise/state.json
```

- **파일이 존재하면**: "이전 Enterprise 세션이 발견되었습니다. 복원할까요?" 확인 후 Step 0-R로
- **파일이 없으면**: Step 1로 진행 (신규 생성)

### Step 0-R: 기존 세션 복원

```python
# 1. 상태 파일 읽기
state = Read("~/.claude/enterprise/state.json")

# 2. 거버넌스 로드
governance = Read("{PLUGIN_ROOT}/config/governance.json")

# 3. 팀 생성 (이미 있으면 스킵)
TeamCreate(team_name="enterprise")

# 4. C-Suite 멤버 스폰 (거버넌스 프롬프트 포함)
for member in governance.c_suite_prompts:
    Task(
        subagent_type="general-purpose",
        team_name="enterprise",
        name=member.name,
        model=member.model,
        prompt=member.prompt_template
    )

# 5. 미완료 태스크 복원
for task in state.tasks.items where status != "completed":
    TaskCreate(subject=task.subject, description=task.description)

# 6. 대시보드 시작
Bash("tmux new-session -d -s enterprise-dash -x 140 -y 40 ...")
```

### Step 1: 설정 파일 로드 (신규 생성)

```
Read {PLUGIN_ROOT}/config/universe.json
Read {PLUGIN_ROOT}/config/governance.json
```

### Step 2: 팀 생성 + C-Suite 스폰

```
TeamCreate(team_name="enterprise", description="Enterprise Agent Universe")
```

**C-Suite 9명 스폰** (거버넌스 프롬프트 필수 포함):

| 이름 | 모델 | 권한 | 핵심 역할 |
|------|------|------|----------|
| team-lead | opus | L4 | CEO - 총괄 지휘, 미션 배분 |
| cto | opus | L3-L4 | CTO - 기술 결정, 모델 거버넌스 |
| cpo | sonnet | L4 | CPO - 제품 전략, 우선순위 |
| cfo | sonnet | L4 | CFO - 비용/예산, 토큰 관리 |
| coo | sonnet | L2 | COO - 배포 승인, CAB 운영 |
| cmo | sonnet | L1 | CMO - 마케팅, 대외 커뮤니케이션 |
| ciso | sonnet | L3 | CISO - 보안 정책, 게이트 운영 |
| pm-lead | sonnet | L1 | PM - 프로젝트/태스크 관리 |
| vl-investor | opus | L4(자문) | VL - 외부 투자자 시각 |

**각 에이전트 프롬프트에 반드시 포함:**
- 5대 원칙
- 권한 레벨 (L0~L4)
- 해당 역할의 KPI
- 커뮤니케이션 규칙 (SendMessage 사용)

### Step 3: 대시보드 시작

```bash
tmux new-session -d -s enterprise-dash -x 140 -y 40 \
  "watch -t -c -n 5 python3 {PLUGIN_ROOT}/scripts/dashboard.sh"
tmux split-window -h -t enterprise-dash \
  "watch -t -c -n 5 python3 {PLUGIN_ROOT}/scripts/tasks-panel.sh"
tmux select-layout -t enterprise-dash even-horizontal
```

### Step 4: 상태 저장 (자동)

```bash
python3 {PLUGIN_ROOT}/scripts/bootstrap.py save
```

### Step 5: 사용자에게 보고

```
"Enterprise Agent Universe가 활성화되었습니다.
- C-Suite: 9명 활성 (CEO, CTO, CPO, CFO, COO, CMO, CISO, PM, VL)
- 거버넌스: v2.0 (5대 원칙 기반)
- 대시보드: tmux attach -t enterprise-dash
- 미션을 입력하세요."
```

## Phase 운영

### Phase 1: C-Suite 상시 (현재)
- 9명 상시 활성
- MCP-First: 분석/리뷰는 ask_codex, 디자인/문서는 ask_gemini

### Phase 2: BU 온디맨드
미션 할당 시 CEO가 필요한 BU 팀원을 온디맨드 스폰:

```
CEO 미션 분석 → 필요 부서 결정 → Task 스폰 (최대 4개 부서, 8명 추가)
```

**스폰 규칙:**
- 동시 BU 최대 4개
- 추가 에이전트 최대 8명
- 미션 완료 후 자동 shutdown_request

### Phase 3: CAB/게이트 자동화
배포/정책 변경 시 자동 CAB 워크플로우:

```
1. 요청자 CR 티켓 생성 (L0)
2. QA 팀장 → 품질 게이트 판정 (L1)  [SendMessage]
3. CISO → 보안/정책 게이트 판정 (L3) [SendMessage]
4. COO → 배포 승인/반려 (L2)         [SendMessage]
5. PM → 릴리즈 일정 반영
6. CEO → 최종 확인 (고위험만)
```

**에스컬레이션:**
- Level 1: 팀 내 24시간
- Level 2: 본부장 24시간
- Level 3: C-level 12시간
- Level 4: CEO 즉시

## 미션 템플릿

| 미션 유형 | 활성화 부서 | 비용 |
|----------|-----------|------|
| 신규 기능 | 임원+기획+BE+FE+QA | HIGH |
| 보안 감사 | 임원+보안+법률 | MEDIUM |
| 성능 최적화 | 임원+인프라+분석+BE | MEDIUM |
| 제품 출시 | 전 부서 (4개씩 순차) | VERY HIGH |
| 데이터 분석 | 임원+분석+AI | LOW |
| 코드 리뷰 | 임원+보안+QA+인프라 | MEDIUM |
| 버그 수정 | 임원+BE+QA | LOW |

## 세션 종료 / 핸드오프

**세션 종료 전 반드시 실행:**

```bash
python3 {PLUGIN_ROOT}/scripts/bootstrap.py handoff
```

이 명령은:
1. 현재 팀 상태를 `~/.claude/enterprise/state.json`에 저장
2. 인수인계 문서를 `~/.claude/enterprise/handoff.md`에 생성
3. 다음 세션에서 Step 0-R로 복원 가능

## 핵심 파일 맵

| 파일 | 용도 |
|------|------|
| `{PLUGIN_ROOT}/config/universe.json` | 13개 부서 42명 조직 구조 |
| `{PLUGIN_ROOT}/config/governance.json` | 5대 원칙 + 권한 + CAB + 프롬프트 |
| `{PLUGIN_ROOT}/scripts/bootstrap.py` | 상태 저장/복원/핸드오프 |
| `{PLUGIN_ROOT}/scripts/dashboard.sh` | 대시보드 좌측 (조직+이력) |
| `{PLUGIN_ROOT}/scripts/tasks-panel.sh` | 대시보드 우측 (리소스+미션) |
| `~/.claude/enterprise/state.json` | 팀 상태 스냅샷 |
| `~/.claude/enterprise/handoff.md` | 인수인계 문서 |
| `{PLUGIN_ROOT}/docs/` | 조직 운영 문서 28개 |

## 비용 제어 (CRITICAL)

- 최대 동시 에이전트: 15명 (C-Suite 9 + BU 6)
- 경고 임계값: 에이전트 8명 이상
- MCP-First: 분석/리뷰는 ask_codex/ask_gemini (Task 스폰 불필요)
- 에이전트당 최대 6개 파일, max_turns 설정 필수
