---
name: ent-save
description: Enterprise Universe 현재 팀 상태를 파일로 저장 (~/.claude/enterprise/state.json)
triggers:
  - ent-save
  - /ent-save
  - 상태 저장
  - enterprise save
---

# Enterprise Save

## 경로 규칙
> **PLUGIN_ROOT**: 이 SKILL.md 파일의 2단계 상위 디렉토리.

## 실행 프로토콜

이 스킬이 트리거되면 다음을 실행하세요:

```bash
python3 {PLUGIN_ROOT}/scripts/bootstrap.py save
```

저장 완료 후 결과를 사용자에게 표시하세요.
저장 위치: `~/.claude/enterprise/state.json`
