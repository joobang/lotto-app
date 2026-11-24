# 로또 분석 앱

저장한 번호를 로또 6/45의 역대 당첨 결과와 비교하는 iOS 앱이다. 조합 하나를 선택하면 번호별 출현 빈도, 가장 많이 일치한 과거 회차, 조합의 패턴을 페이지별로 확인할 수 있다. 랜덤 뽑기와 역대 통계 뽑기는 각각 독립된 메뉴로 제공할 계획이다.

- [제품 계획](docs/product-plan.md)
- [뽑기 화면과 연출](docs/draw-experience.md)
- [데이터와 서버 설계](docs/architecture.md)
- [로또 API 계약](docs/lotto-api.md)
- [구현 순서와 완료 조건](docs/implementation-plan.md)
- [개발 상태와 인계](docs/status.md)
- [AI 작업 규칙](AGENTS.md)

현재는 전 회차 스냅샷과 1단계 조회·적재를 로컬에서 검증했다. [LOTTO-01 기록](docs/tasks/LOTTO-01.md)에서 구현 커밋과 검증 범위를 확인할 수 있다.
