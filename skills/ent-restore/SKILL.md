---
name: ent-restore
description: 저장된 Enterprise Universe 세션 복원 안내 표시
triggers:
  - ent-restore
  - /ent-restore
  - 세션 복원
  - enterprise restore
---

# Enterprise Restore

## 경로 규칙
> **PLUGIN_ROOT**: 이 SKILL.md 파일의 2단계 상위 디렉토리.

## 실행 프로토콜

이 스킬이 트리거되면 다음을 실행하세요:

```bash
python3 {PLUGIN_ROOT}/scripts/bootstrap.py restore
```

복원 안내가 출력되면 사용자에게 표시하세요.

저장된 상태가 없으면 `/enterprise`로 새 세션을 시작하도록 안내하세요.
