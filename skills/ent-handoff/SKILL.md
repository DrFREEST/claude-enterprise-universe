---
name: ent-handoff
description: Enterprise Universe 인수인계 문서 생성 + 상태 저장. 세션 종료 전 실행 권장.
triggers:
  - ent-handoff
  - /ent-handoff
  - 인수인계
  - enterprise handoff
---

# Enterprise Handoff

## 경로 규칙
> **PLUGIN_ROOT**: 이 SKILL.md 파일의 2단계 상위 디렉토리.

## 실행 프로토콜

이 스킬이 트리거되면 다음을 실행하세요:

```bash
python3 {PLUGIN_ROOT}/scripts/bootstrap.py handoff
```

이 명령은:
1. 현재 팀 상태를 `~/.claude/enterprise/state.json`에 저장
2. 인수인계 문서를 `~/.claude/enterprise/handoff.md`에 생성

완료 후 결과를 사용자에게 표시하고, 다음 세션에서 `/enterprise`로 복원 가능함을 안내하세요.
