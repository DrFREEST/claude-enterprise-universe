#!/usr/bin/env python3
"""
Enterprise Agent Universe - One-Shot Bootstrap & Handoff System
Usage:
  python3 scripts/bootstrap.py save     # 현재 팀 상태 저장
  python3 scripts/bootstrap.py restore   # 저장된 상태에서 복원 안내
  python3 scripts/bootstrap.py status    # 현재 상태 확인
  python3 scripts/bootstrap.py handoff   # 인수인계 문서 생성
"""

import json, sys, os, shutil
from datetime import datetime
from pathlib import Path

# ── 경로 ──
HOME = Path.home()
PLUGIN_ROOT = Path(__file__).resolve().parent.parent
TEAM_CONFIG = HOME / ".claude/teams/enterprise/config.json"
TASKS_DIR = HOME / ".claude/tasks/enterprise"
STATE_DIR = HOME / ".claude/enterprise"
HANDOFF_FILE = STATE_DIR / "handoff.md"
STATE_FILE = STATE_DIR / "state.json"
UNIVERSE_CONFIG = PLUGIN_ROOT / "config" / "universe.json"
GOVERNANCE_CONFIG = PLUGIN_ROOT / "config" / "governance.json"
DOCS_DIR = PLUGIN_ROOT / "docs"

# ANSI
R = "\033[0m"
B = "\033[1m"
GRN = "\033[32m"
YEL = "\033[33m"
CYN = "\033[36m"
RED = "\033[31m"
DIM = "\033[2m"

def ensure_dirs():
    STATE_DIR.mkdir(parents=True, exist_ok=True)

def load_team():
    if not TEAM_CONFIG.exists():
        return None
    with open(TEAM_CONFIG) as f:
        return json.load(f)

def load_tasks():
    tasks = []
    if TASKS_DIR.exists():
        for tf in sorted(TASKS_DIR.glob("*.json"), key=lambda p: int(p.stem) if p.stem.isdigit() else 0):
            try:
                with open(tf) as fh:
                    tasks.append(json.load(fh))
            except Exception:
                pass
    return tasks

def load_governance():
    if not GOVERNANCE_CONFIG.exists():
        return None
    with open(GOVERNANCE_CONFIG) as f:
        return json.load(f)

def cmd_save():
    """현재 팀 상태를 파일로 저장"""
    ensure_dirs()
    team = load_team()
    tasks = load_tasks()
    gov = load_governance()

    if not team:
        print(f"{RED}활성 팀이 없습니다.{R}")
        return

    state = {
        "saved_at": datetime.now().isoformat(),
        "team": {
            "name": "enterprise",
            "member_count": len(team.get("members", [])),
            "members": [
                {
                    "name": m.get("name"),
                    "model": m.get("model", ""),
                    "agentType": m.get("agentType", ""),
                    "joinedAt": m.get("joinedAt", 0)
                }
                for m in team.get("members", [])
            ]
        },
        "tasks": {
            "total": len(tasks),
            "completed": sum(1 for t in tasks if t.get("status") == "completed"),
            "in_progress": sum(1 for t in tasks if t.get("status") == "in_progress"),
            "pending": sum(1 for t in tasks if t.get("status") == "pending"),
            "items": [
                {
                    "id": t.get("id"),
                    "subject": t.get("subject"),
                    "status": t.get("status"),
                    "owner": t.get("owner", "")
                }
                for t in tasks
            ]
        },
        "governance_version": gov.get("version", "unknown") if gov else "not_loaded",
        "phase": "phase_1"  # 현재 Phase
    }

    with open(STATE_FILE, "w") as f:
        json.dump(state, f, indent=2, ensure_ascii=False)

    print(f"{GRN}상태 저장 완료{R}: {STATE_FILE}")
    print(f"  팀원: {state['team']['member_count']}명")
    print(f"  태스크: {state['tasks']['total']}개 (완료 {state['tasks']['completed']})")
    print(f"  거버넌스: v{state['governance_version']}")

def cmd_restore():
    """저장된 상태에서 복원 안내 출력"""
    if not STATE_FILE.exists():
        print(f"{RED}저장된 상태가 없습니다.{R}")
        print(f"먼저 'python3 scripts/bootstrap.py save'를 실행하세요.")
        return

    with open(STATE_FILE) as f:
        state = json.load(f)

    print(f"{B}{CYN}═══ Enterprise Universe 복원 안내 ═══{R}")
    print(f"  저장 시점: {state['saved_at']}")
    print(f"  팀원: {state['team']['member_count']}명")
    print(f"  태스크: {state['tasks']['total']}개")
    print()
    print(f"{YEL}Claude Code에서 다음 명령으로 복원하세요:{R}")
    print()
    print(f"  {B}/enterprise{R}  또는  다음 프롬프트 입력:")
    print()
    print(f'  {DIM}"이전 Enterprise Universe 세션을 복원해줘.')
    print(f'   상태 파일: ~/.claude/enterprise/state.json')
    print(f'   거버넌스: {GOVERNANCE_CONFIG}')
    print(f'   유니버스: {UNIVERSE_CONFIG}"{R}')
    print()

    # 멤버 목록
    print(f"{CYN}복원할 팀원:{R}")
    for m in state["team"]["members"]:
        print(f"  - {m['name']} ({m.get('model', '?')})")

    # 미완료 태스크
    pending = [t for t in state["tasks"]["items"] if t["status"] != "completed"]
    if pending:
        print(f"\n{YEL}미완료 태스크:{R}")
        for t in pending[:10]:
            print(f"  #{t['id']} [{t['status']}] {t['subject']}")

def cmd_status():
    """현재 상태 확인"""
    team = load_team()
    tasks = load_tasks()
    saved = STATE_FILE.exists()

    print(f"{B}{CYN}═══ Enterprise Universe 상태 ═══{R}")
    print()

    if team:
        members = team.get("members", [])
        print(f"  {GRN}팀 활성{R}: {len(members)}명")
        for m in members:
            print(f"    - {m.get('name', '?')} ({m.get('model', '?')})")
    else:
        print(f"  {RED}팀 비활성{R}")

    print()
    if tasks:
        done = sum(1 for t in tasks if t.get("status") == "completed")
        active = sum(1 for t in tasks if t.get("status") == "in_progress")
        pending = sum(1 for t in tasks if t.get("status") == "pending")
        print(f"  태스크: {len(tasks)}개 (완료 {done}, 진행 {active}, 대기 {pending})")
    else:
        print(f"  태스크: 없음")

    print()
    if saved:
        with open(STATE_FILE) as f:
            state = json.load(f)
        print(f"  {GRN}저장된 상태{R}: {state['saved_at']}")
    else:
        print(f"  {YEL}저장된 상태 없음{R}")

    print()
    print(f"  거버넌스: {'존재' if GOVERNANCE_CONFIG.exists() else '없음'}")
    print(f"  유니버스: {'존재' if UNIVERSE_CONFIG.exists() else '없음'}")
    print(f"  조직 문서: {len(list(DOCS_DIR.glob('*.md')))}개" if DOCS_DIR.exists() else "  조직 문서: 없음")

def cmd_handoff():
    """인수인계 문서 생성"""
    ensure_dirs()
    team = load_team()
    tasks = load_tasks()
    gov = load_governance()
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    lines = []
    lines.append(f"# Enterprise Agent Universe - 인수인계 문서")
    lines.append(f"- 생성 시점: {now}")
    lines.append(f"- 자동 생성됨 (bootstrap.py handoff)")
    lines.append(f"- 프로젝트 경로: {PLUGIN_ROOT}")
    lines.append("")
    lines.append("---")
    lines.append("")

    # 1. 현재 상태 요약
    lines.append("## 1. 현재 상태 요약")
    lines.append("")
    if team:
        members = team.get("members", [])
        lines.append(f"- 팀 활성: **{len(members)}명**")
        lines.append(f"- 팀 이름: enterprise")
        lines.append("")
        lines.append("### 팀원 목록")
        lines.append("| 이름 | 모델 | 역할 |")
        lines.append("|------|------|------|")
        for m in members:
            lines.append(f"| {m.get('name', '?')} | {m.get('model', '?')} | {m.get('agentType', '?')} |")
    else:
        lines.append("- 팀 비활성 (재생성 필요)")
    lines.append("")

    # 2. 태스크 현황
    lines.append("## 2. 태스크 현황")
    lines.append("")
    if tasks:
        done = [t for t in tasks if t.get("status") == "completed"]
        active = [t for t in tasks if t.get("status") == "in_progress"]
        pending = [t for t in tasks if t.get("status") == "pending"]

        lines.append(f"- 전체: {len(tasks)}개")
        lines.append(f"- 완료: {len(done)}개")
        lines.append(f"- 진행 중: {len(active)}개")
        lines.append(f"- 대기: {len(pending)}개")
        lines.append("")

        if active:
            lines.append("### 진행 중인 태스크")
            for t in active:
                lines.append(f"- #{t.get('id')} [{t.get('owner', '-')}] {t.get('subject', '')}")

        if pending:
            lines.append("")
            lines.append("### 대기 중인 태스크")
            for t in pending:
                lines.append(f"- #{t.get('id')} {t.get('subject', '')}")
    lines.append("")

    # 3. 복원 방법
    lines.append("## 3. 새 세션에서 복원하는 방법")
    lines.append("")
    lines.append("### 방법 1: 원샷 프롬프트")
    lines.append("```")
    lines.append("Enterprise Universe를 복원해줘.")
    lines.append("- 상태 파일: ~/.claude/enterprise/state.json")
    lines.append(f"- 거버넌스: {GOVERNANCE_CONFIG}")
    lines.append(f"- 유니버스: {UNIVERSE_CONFIG}")
    lines.append(f"- 조직 문서: {DOCS_DIR}/")
    lines.append("```")
    lines.append("")
    lines.append("### 방법 2: 스킬 호출")
    lines.append("```")
    lines.append("/enterprise")
    lines.append("```")
    lines.append("")
    lines.append("### 방법 3: 수동 복원")
    lines.append("```")
    lines.append("1. TeamCreate(team_name='enterprise')")
    lines.append("2. 각 C-Suite 멤버 Task 스폰 (거버넌스 프롬프트 포함)")
    lines.append(f"3. python3 {PLUGIN_ROOT}/scripts/bootstrap.py restore")
    lines.append("```")
    lines.append("")

    # 4. 핵심 파일 위치
    lines.append("## 4. 핵심 파일 위치")
    lines.append("")
    lines.append("| 파일 | 용도 |")
    lines.append("|------|------|")
    lines.append("| `~/.claude/enterprise/state.json` | 팀 상태 스냅샷 |")
    lines.append("| `~/.claude/enterprise/handoff.md` | 이 인수인계 문서 |")
    lines.append(f"| `{GOVERNANCE_CONFIG}` | 거버넌스 규칙 |")
    lines.append(f"| `{UNIVERSE_CONFIG}` | 유니버스 설정 |")
    lines.append(f"| `{DOCS_DIR}` | 조직 운영 문서 |")
    lines.append(f"| `{PLUGIN_ROOT}/scripts/dashboard.sh` | 대시보드 (좌측) |")
    lines.append(f"| `{PLUGIN_ROOT}/scripts/tasks-panel.sh` | 대시보드 (우측) |")
    lines.append(f"| `{PLUGIN_ROOT}/scripts/bootstrap.py` | 이 스크립트 |")
    lines.append("")

    # 5. 5대 원칙
    if gov:
        lines.append("## 5. AI 조직 설계 5대 원칙")
        lines.append("")
        for key, value in gov.get("five_principles", {}).items():
            lines.append(f"- **{key}**: {value}")
    lines.append("")

    # 6. 대시보드 실행
    lines.append("## 6. 대시보드 실행")
    lines.append("")
    lines.append("```bash")
    lines.append("# tmux 듀얼 패널 대시보드")
    lines.append("tmux new-session -d -s enterprise-dash -x 140 -y 40 \\")
    lines.append(f'  "watch -t -c -n 5 python3 {PLUGIN_ROOT}/scripts/dashboard.sh"')
    lines.append("tmux split-window -h -t enterprise-dash \\")
    lines.append(f'  "watch -t -c -n 5 python3 {PLUGIN_ROOT}/scripts/tasks-panel.sh"')
    lines.append("tmux select-layout -t enterprise-dash even-horizontal")
    lines.append("tmux attach -t enterprise-dash")
    lines.append("```")

    content = "\n".join(lines)
    with open(HANDOFF_FILE, "w") as f:
        f.write(content)

    # 상태도 같이 저장
    cmd_save()

    print(f"{GRN}인수인계 문서 생성 완료{R}: {HANDOFF_FILE}")
    print(f"상태 파일도 함께 저장됨: {STATE_FILE}")

# ── Main ──
if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: bootstrap.py [save|restore|status|handoff]")
        sys.exit(1)

    cmd = sys.argv[1]
    if cmd == "save":
        cmd_save()
    elif cmd == "restore":
        cmd_restore()
    elif cmd == "status":
        cmd_status()
    elif cmd == "handoff":
        cmd_handoff()
    else:
        print(f"Unknown command: {cmd}")
        print("Usage: bootstrap.py [save|restore|status|handoff]")
        sys.exit(1)
