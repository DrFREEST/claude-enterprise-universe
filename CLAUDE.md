# Enterprise Universe 플러그인

## 개요

AI 기업 조직 운영 시뮬레이션 플러그인. 5대 원칙 기반 거버넌스, C-Suite 9명, 13개 부서 42명.

## 활성화

```
/enterprise
```

## 5대 원칙

1. **단일 산출물 책임**: 한 에이전트 = 하나의 산출물 타입
2. **실행-검토 분리**: Maker ≠ Checker
3. **티켓 기반 실행**: 모든 작업은 Task에서 시작
4. **기억 계층 분리**: L3 정책 > L2 SOP > L1 프로젝트 > L0 작업
5. **정책=매니저**: 규칙이 자동 강제

## 핵심 파일

| 파일 | 용도 |
|------|------|
| `config/governance.json` | 거버넌스 규칙 + C-Suite 프롬프트 |
| `config/universe.json` | 13개 부서 42명 조직 구조 |
| `scripts/bootstrap.py` | 상태 저장/복원/핸드오프 |
| `scripts/dashboard.sh` | tmux 대시보드 (좌측) |
| `scripts/tasks-panel.sh` | tmux 대시보드 (우측) |
| `docs/` | 28개 조직 운영 문서 |

## 상태 관리

```bash
python3 scripts/bootstrap.py status    # 현재 상태
python3 scripts/bootstrap.py save      # 상태 저장
python3 scripts/bootstrap.py handoff   # 인수인계 문서 생성
```

## 버전 관리

`package.json`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` 버전 동기화 필수.
