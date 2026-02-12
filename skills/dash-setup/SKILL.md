---
name: dash-setup
description: Enterprise Universe tmux 실시간 대시보드 세팅. 듀얼 패널(조직 현황 + 미션 현황) 자동 구성.
triggers:
  - dash-setup
  - /dash-setup
  - 대시보드 설정
  - dashboard setup
---

# Enterprise Dashboard Setup

## 경로 규칙
> **PLUGIN_ROOT**: 이 SKILL.md 파일이 위치한 경로의 2단계 상위 디렉토리입니다.
> 예: 이 파일이 `/path/to/plugin/skills/dash-setup/SKILL.md`이면 `PLUGIN_ROOT=/path/to/plugin/`
> Claude가 이 스킬을 실행할 때, 먼저 이 파일의 절대경로에서 PLUGIN_ROOT를 계산하세요.

## 실행 프로토콜

이 스킬이 트리거되면 **반드시** 다음 순서로 실행하세요:

### Step 1: 사전 조건 확인

```bash
# tmux 설치 확인
which tmux
# 기존 세션 확인
tmux has-session -t enterprise-dash 2>/dev/null && echo "EXISTS" || echo "NOT_EXISTS"
```

- tmux 미설치 시: `apt-get install -y tmux` 실행
- 기존 세션이 있으면: "기존 대시보드가 실행 중입니다. 재시작할까요?" 확인
  - 재시작 시: `tmux kill-session -t enterprise-dash`

### Step 2: Enterprise 팀 활성 확인

```bash
python3 {PLUGIN_ROOT}/scripts/bootstrap.py status
```

- 팀이 비활성이면: "Enterprise 팀이 활성화되지 않았습니다. `/enterprise`로 먼저 팀을 활성화하세요." 안내
- 팀이 활성이면: Step 3으로 진행

### Step 3: tmux 듀얼 패널 대시보드 생성

```bash
# 세션 생성 + 좌측 패널 (조직 현황)
tmux new-session -d -s enterprise-dash -x 160 -y 45 \
  "watch -t -c -n 5 python3 {PLUGIN_ROOT}/scripts/dashboard.sh"

# 우측 패널 (미션 현황)
tmux split-window -h -t enterprise-dash \
  "watch -t -c -n 5 python3 {PLUGIN_ROOT}/scripts/tasks-panel.sh"

# 레이아웃 균등 분할
tmux select-layout -t enterprise-dash even-horizontal
```

### Step 4: 사용자에게 보고

```
"Enterprise 대시보드가 세팅되었습니다.

  연결:   tmux attach -t enterprise-dash
  분리:   Ctrl+B → D
  종료:   tmux kill-session -t enterprise-dash

  좌측: 조직 현황 (C-Suite + 부서 + 최근 완료)
  우측: 미션 현황 (리소스 + 활성/대기 미션)
  갱신: 5초 자동"
```

## 트러블슈팅

| 문제 | 해결 |
|------|------|
| "sessions should be nested" | 이미 tmux 안에 있음. `tmux attach -t enterprise-dash` 로 연결 |
| 한글 깨짐 | `export LANG=ko_KR.UTF-8` 설정 후 재실행 |
| 패널이 너무 좁음 | 터미널 창을 140 컬럼 이상으로 확대 |
| watch 없음 | `apt-get install -y procps` |
