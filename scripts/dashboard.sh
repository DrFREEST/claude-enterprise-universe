#!/usr/bin/env python3
# enterprise-dashboard.sh (Python) - Enterprise Agent Universe 실시간 대시보드
# Usage: watch -t -n 5 ./scripts/enterprise-dashboard.sh
#   또는: ./scripts/enterprise-dashboard.sh (1회 출력)

import json, time, sys, subprocess, glob, shutil, os
from datetime import datetime
from pathlib import Path

# ── 경로 ──
PLUGIN_ROOT = str(Path(__file__).resolve().parent.parent)
TEAM_CONFIG = Path.home() / ".claude/teams/enterprise/config.json"
UNIVERSE_CONFIG = Path(os.path.join(PLUGIN_ROOT, "config", "universe.json"))
TASKS_DIR = Path.home() / ".claude/tasks/enterprise"

# ── ANSI 색상 (실제 이스케이프 문자) ──
R   = "\033[0m"
B   = "\033[1m"
DIM = "\033[2m"
RED = "\033[31m"
GRN = "\033[32m"
YEL = "\033[33m"
BLU = "\033[34m"
MAG = "\033[35m"
CYN = "\033[36m"
WHT = "\033[97m"
GRY = "\033[90m"
BRED = "\033[1;31m"
BGRN = "\033[1;32m"
BYEL = "\033[1;33m"
BCYN = "\033[1;36m"
BMAG = "\033[1;35m"
BWHT = "\033[1;97m"

# ── 유틸 ──
def pad(text, width):
    """한글 포함 문자열을 고정폭으로 패딩 (한글=2칸)"""
    display_len = 0
    for ch in text:
        if '\uac00' <= ch <= '\ud7a3' or '\u4e00' <= ch <= '\u9fff':
            display_len += 2
        else:
            display_len += 1
    return text + " " * max(0, width - display_len)

# ── 데이터 로드 ──
if not TEAM_CONFIG.exists():
    print(f"{RED}Enterprise 팀이 활성화되지 않았습니다.{R}")
    sys.exit(1)

with open(TEAM_CONFIG) as f:
    team = json.load(f)

universe = None
if UNIVERSE_CONFIG.exists():
    with open(UNIVERSE_CONFIG) as f:
        universe = json.load(f)

members = team.get("members", [])
now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
now_ts = time.time() * 1000

# ── 태스크 로드 ──
tasks = []
if TASKS_DIR.exists():
    for tf in sorted(TASKS_DIR.glob("*.json"), key=lambda p: int(p.stem) if p.stem.isdigit() else 0):
        try:
            with open(tf) as fh:
                t = json.load(fh)
                tasks.append(t)
        except Exception:
            pass

# owner별 활성 미션 매핑
owner_missions = {}  # name -> list of tasks
active_tasks = []
completed_tasks = []
for t in tasks:
    status = t.get("status", "")
    owner = t.get("owner", "")
    if status == "in_progress":
        active_tasks.append(t)
        if owner:
            owner_missions.setdefault(owner, []).append(t)
    elif status == "completed":
        completed_tasks.append(t)

pending_tasks = [t for t in tasks if t.get("status") == "pending"]

# ── 멤버 정보 매핑 ──
ROLE_MAP = {
    "team-lead":   ("CEO",     "👑", "총괄 지휘"),
    "cto":         ("CTO",     "🔧", "기술 총괄"),
    "cpo":         ("CPO",     "📦", "제품 총괄"),
    "cfo":         ("CFO",     "💰", "재무 총괄"),
    "coo":         ("COO",     "⚙️",  "운영 총괄"),
    "cmo":         ("CMO",     "📢", "마케팅 총괄"),
    "ciso":        ("CISO",    "🛡️",  "보안 총괄"),
    "pm-lead":     ("PM",      "📋", "프로젝트 관리"),
    "vl-investor": ("VL",      "🦈", "외인 투자자"),
}

DEPT_ICONS = {
    "command": "👑", "strategy": "📐", "development": "💻",
    "creative": "🎨", "advisory": "⚖️",  "specialist": "🔬",
    "quality": "✅", "operations": "📋",
}

# ── 화면 클리어 (alternate screen 미사용 → 스크롤백 유지) ──
sys.stdout.write("\033[H\033[J")
sys.stdout.flush()

W = 66

# ── 터미널 높이 감지 → 레이아웃 결정 ──
term_h = shutil.get_terminal_size((80, 40)).lines
# 고정 줄: 헤더(5) + C-SUITE 테두리(2) + DEPT 테두리(2) + RESOURCES(4) + FOOTER(4) = 17
# 가변 줄: members(9) + depts(~14) + missions
FIXED_LINES = 17
member_lines = len(members)
dept_count = len(universe.get("departments", {})) if universe else 0
available = term_h - FIXED_LINES - member_lines

# 레이아웃 모드 결정
if available >= dept_count + 12:
    layout = "full"
    max_depts = dept_count
    max_recent = 8
elif available >= dept_count + 4:
    layout = "compact"
    max_depts = dept_count
    max_recent = 4
elif available >= 10:
    layout = "mini"
    max_depts = max(3, available - 6)
    max_recent = 3
else:
    layout = "tiny"
    max_depts = 0
    max_recent = 3

# ── 헤더 ──
print(f"{BWHT}╔{'═'*W}╗")
print(f"║  🏢  ENTERPRISE AGENT UNIVERSE {GRY}— LIVE DASHBOARD{BWHT}              ║")
print(f"║  {DIM}{now}{R}{BWHT}                                              ║")
print(f"╠{'═'*W}╣{R}")
print()

# ── C-SUITE ──
print(f"{BCYN}  ┌─ C-SUITE (임원진) {'─'*44}┐{R}")

for m in members:
    name = m.get("name", "?")
    info = ROLE_MAP.get(name, (name, "🤖", ""))
    title, icon, desc = info
    model = m.get("model", "?")
    joined = m.get("joinedAt", 0)
    uptime_min = int((now_ts - joined) / 1000 / 60) if joined else 0

    if "opus" in str(model):
        model_str = f"{BRED}opus{R}"
    else:
        model_str = f"{BGRN}sonnet{R}"

    # 미션 상태 결정
    my_missions = owner_missions.get(name, [])
    if my_missions:
        mission_text = my_missions[0].get("subject", "")[:28]
        status_str = f"{BGRN}BUSY{R}"
        mission_str = f" {CYN}→ {mission_text}{R}"
    else:
        status_str = f"{GRY}IDLE{R}"
        mission_str = ""

    tag = f"  {DIM}[외인구단]{R}" if name == "vl-investor" else ""
    title_pad = pad(title, 6)
    name_pad = pad(name, 12)

    print(f"  │  {icon} {title_pad} {GRY}({name_pad}){R} {model_str:<6s}  {status_str}  {DIM}{uptime_min}m{R}{tag}{mission_str}")

print(f"{BCYN}  └{'─'*W}┘{R}")
print()

# ── DEPARTMENTS ──
if max_depts > 0:
    print(f"{BYEL}  ┌─ DEPARTMENTS ({dept_count}개 부서) {'─'*(W-21-len(str(dept_count)))}┐{R}")

    if universe:
        depts = universe.get("departments", {})
        shown = 0
        for did, d in depts.items():
            if shown >= max_depts:
                break
            name_ko = d.get("name_ko", did)
            mc = len(d.get("members", {}))
            tier = d.get("tier", "?")
            active = d.get("always_active", False)
            tier_icon = DEPT_ICONS.get(tier, "📁")

            if active:
                status = f"{GRN}● ACTIVE {R}"
            else:
                status = f"{GRY}○ STANDBY{R}"

            name_pad = pad(name_ko, 18)
            tier_pad = pad(tier, 12)

            print(f"  │  {status}  {tier_icon} {name_pad}  {mc}명  {GRY}{tier_pad}{R}")
            shown += 1

        if shown < dept_count:
            print(f"  │  {DIM}... +{dept_count - shown}개 부서 (터미널 확대 시 표시){R}")

    print(f"{BYEL}  └{'─'*W}┘{R}")
    print()
else:
    # tiny 모드: 한 줄 요약
    active_dept = sum(1 for d in (universe or {}).get("departments", {}).values() if d.get("always_active"))
    print(f"  {BYEL}DEPARTMENTS{R} {GRN}{active_dept} active{R} / {dept_count} total {DIM}(터미널 확대 시 상세 표시){R}")
    print()

# ── RECENTLY COMPLETED ──
recent_done = [t for t in tasks if t.get("status") == "completed"][-8:]
if recent_done:
    print(f"{BGRN}  ┌─ RECENTLY COMPLETED ({len(completed_tasks)}) {'─'*(W-25-len(str(len(completed_tasks))))}┐{R}")
    for t in reversed(recent_done):
        subject = t.get("subject", "")[:40]
        tid = t.get("id", "?")
        owner = t.get("owner", "")
        role_info = ROLE_MAP.get(owner, (owner[:4], "🤖", ""))
        print(f"  │  {GRN}✓{R} {GRY}#{tid:<3}{R} {DIM}{pad(subject, 40)}{R} {CYN}{role_info[1]} {role_info[0]}{R}")
    print(f"{BGRN}  └{'─'*W}┘{R}")
    print()

# ── FOOTER ──
print(f"  {DIM}─ Quick Missions ─────────────────────────────────────────────{R}")
print(f"  {DIM}🚀 신규기능  🔒 보안감사  ⚡ 성능최적화  📊 데이터분석  🐛 버그수정{R}")
print()
print(f"  {DIM}자동 갱신 (5초) │ layout: {layout} ({term_h}h) │ Ctrl+B,D detach{R}")
