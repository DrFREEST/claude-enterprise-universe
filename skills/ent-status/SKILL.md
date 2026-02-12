---
name: ent-status
description: Enterprise Universe 현재 상태 확인 (팀, 태스크, 거버넌스, 문서)
triggers:
  - ent-status
  - /ent-status
  - 팀 상태
  - enterprise status
---

# Enterprise Status

## 경로 규칙
> **PLUGIN_ROOT**: 이 SKILL.md 파일의 2단계 상위 디렉토리.

## 실행 프로토콜

이 스킬이 트리거되면 다음을 실행하세요:

```bash
python3 {PLUGIN_ROOT}/scripts/bootstrap.py status
```

결과를 사용자에게 표시하세요. 추가 설명 없이 출력 그대로 보여주면 됩니다.
