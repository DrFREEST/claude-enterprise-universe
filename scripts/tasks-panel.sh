#!/usr/bin/env python3
# enterprise-tasks-panel.sh - 팀원별 태스크 활성화 상태 (우측 패널)

import json, time, sys, shutil
from datetime import datetime
from pathlib import Path

TEAM_CONFIG = Path.home() / ".claude/teams/enterprise/config.json"
TASKS_DIR = Path.home() / ".claude/tasks/enterprise"

# ── ANSI ──
R   = "\033[0m"
B   = "\033[1m"
DIM = "\033[2m"
RED = "\033[31m"
GRN = "\033[32m"
YEL = "\033[33m"
BLU = "\033[34m"
CYN = "\033[36m"
GRY = "\033[90m"
BRED = "\033[1;31m"
BGRN = "\033[1;32m"
BYEL = "\033[1;33m"
BCYN = "\033[1;36m"
BMAG = "\033[1;35m"
BWHT = "\033[1;97m"

def pad(text, width):
    display_len = 0
    for ch in text:
        if '\uac00' <= ch <= '\ud7a3' or '\u4e00' <= ch <= '\u9fff':
            display_len += 2
        else:
            display_len += 1
    return text + " " * max(0, width - display_len)

# ── 데이터 로드 ──
if not TEAM_CONFIG.exists():
    print(f"{RED}팀 미활성{R}")
    sys.exit(1)

with open(TEAM_CONFIG) as f:
    team = json.load(f)

members = team.get("members", [])
now = datetime.now().strftime("%H:%M:%S")
now_ts = time.time() * 1000
term_h = shutil.get_terminal_size((60, 40)).lines

# ── 태스크 로드 ──
tasks = []
if TASKS_DIR.exists():
    for tf in sorted(TASKS_DIR.glob("*.json"), key=lambda p: int(p.stem) if p.stem.isdigit() else 0):
        try:
            with open(tf) as fh:
                tasks.append(json.load(fh))
        except Exception:
            pass

# owner별 태스크 매핑
owner_tasks = {}
for t in tasks:
    owner = t.get("owner", "")
    if owner:
        owner_tasks.setdefault(owner, []).append(t)

# 상태별 카운트
status_counts = {}
for t in tasks:
    s = t.get("status", "unknown")
    status_counts[s] = status_counts.get(s, 0) + 1

ROLE_MAP = {
    "team-lead":   ("CEO",  "👑", "총괄 지휘"),
    "cto":         ("CTO",  "🔧", "기술 총괄"),
    "cpo":         ("CPO",  "📦", "제품 총괄"),
    "cfo":         ("CFO",  "💰", "재무 총괄"),
    "coo":         ("COO",  "⚙️", "운영 총괄"),
    "cmo":         ("CMO",  "📢", "마케팅 총괄"),
    "ciso":        ("CISO", "🛡️", "보안 총괄"),
    "pm-lead":     ("PM",   "📋", "프로젝트 관리"),
    "vl-investor": ("VL",   "🦈", "외인 투자자"),
}

STATUS_ICON = {
    "completed":   f"{GRN}✓{R}",
    "in_progress": f"{YEL}▶{R}",
    "pending":     f"{GRY}○{R}",
}

# ── 분류 ──
active_tasks = [t for t in tasks if t.get("status") == "in_progress"]
pending_tasks = [t for t in tasks if t.get("status") == "pending"]
completed_tasks = [t for t in tasks if t.get("status") == "completed"]

total = len(tasks)
done = len(completed_tasks)
active = len(active_tasks)
pending = len(pending_tasks)

# ── 렌더링 ──
sys.stdout.write("\033[H\033[J")
sys.stdout.flush()

W = 40

# ── RESOURCES ──
mc = len(members)
opus_count = sum(1 for m in members if "opus" in str(m.get("model", "")))
sonnet_count = mc - opus_count
pct = mc * 100 // 42
bar_fill = mc * 15 // 42
bar_empty = 15 - bar_fill

if active > 0:
    mission_status = f"{BGRN}🔥 {active}개 진행{R}"
elif pending > 0:
    mission_status = f"{YEL}⏳ {pending}개 대기{R}"
else:
    mission_status = f"{GRY}미션 없음{R}"

print(f"{BMAG}┌─ RESOURCES {GRY}({now}){BMAG} {'─'*(W-24)}┐{R}")
print(f"│ 에이전트 {BWHT}{mc:2d}{R}/42 {GRN}{'█'*bar_fill}{GRY}{'░'*bar_empty}{R} {BWHT}{pct}%{R}")
print(f"│ 모델     {RED}Opus {opus_count}{R} {GRN}Sonnet {sonnet_count}{R}")
print(f"│ 미션     {mission_status} {DIM}(완료{done}/전체{total}){R}")
print(f"{BMAG}└{'─'*W}┘{R}")
print()

lines_used = 7  # header (RESOURCES)

# ── ACTIVE MISSIONS ──
if active_tasks and lines_used < term_h - 6:
    max_show = min(8, term_h - lines_used - 3)
    print(f"{BGRN}┌─ ACTIVE MISSIONS ({active}) {'─'*(W-21-len(str(active)))}┐{R}")
    for t in active_tasks[:max_show]:
        tid = t.get("id", "?")
        owner = t.get("owner", "")
        active_form = t.get("activeForm", "")
        subject = t.get("subject", "")
        display = (active_form if active_form else subject)[:28]

        if owner:
            ri = ROLE_MAP.get(owner, (owner[:4], "🤖", ""))
            owner_str = f"{CYN}{ri[1]}{ri[0]}{R}"
        else:
            owner_str = f"{GRY}--{R}"

        print(f"│ {YEL}#{tid:<3}{R} {pad(display, 28)} {owner_str}")
        lines_used += 1

    if active > max_show:
        print(f"│ {DIM}... +{active - max_show}개 더{R}")
    print(f"{BGRN}└{'─'*W}┘{R}")
    print()

# ── PENDING (간략) ──
if pending_tasks and lines_used < term_h - 4:
    show_p = min(3, term_h - lines_used - 2)
    print(f"{BYEL}┌─ PENDING ({pending}) {'─'*(W-13-len(str(pending)))}┐{R}")
    for t in pending_tasks[:show_p]:
        tid = t.get("id", "?")
        subject = t.get("subject", "")[:32]
        print(f"│ {GRY}○ #{tid:<3}{R} {DIM}{subject}{R}")
        lines_used += 1
    if pending > show_p:
        print(f"│ {DIM}... +{pending - show_p}개 더{R}")
    print(f"{BYEL}└{'─'*W}┘{R}")
