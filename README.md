# 로또 분석 앱

저장한 번호를 로또 6/45의 역대 당첨 결과와 비교하는 iOS 앱이다. 조합 하나를 선택하면 번호별 출현 빈도, 가장 많이 일치한 과거 회차, 조합의 패턴을 페이지별로 확인할 수 있다. 랜덤 뽑기는 공을 당겨 놓으면 전체 화면 발사 컷신에서 여섯 번호 공이 빠르게 연달아 나타난다. 역대 통계에서는 45개 번호의 기록을 보고 역대 홀짝·합계·번호대·연속번호 구성을 재현하는 패턴 뽑기를 할 수 있다.

- [제품 계획](docs/product-plan.md)
- [뽑기 화면과 연출](docs/draw-experience.md)
- [데이터와 서버 설계](docs/architecture.md)
- [로또 API 계약](docs/lotto-api.md)
- [구현 순서와 완료 조건](docs/implementation-plan.md)
- [개발 상태와 인계](docs/status.md)
- [AI 작업 규칙](AGENTS.md)

전 회차 적재와 2단계 통계·분석 API를 로컬에서 검증했다. [LOTTO-01 기록](docs/tasks/LOTTO-01.md) · [LOTTO-03·06 기록](docs/tasks/LOTTO-03-06.md)

## 첫 iPhone 버전

Xcode에서 `ios/Lotto.xcodeproj`를 열고 `Lotto` 스킴으로 iPhone 시뮬레이터를 실행한다. 앱은 번들에 든 1~1251회 이력을 읽고 저장한 조합을 기기에 보관한다.

```sh
open ios/Lotto.xcodeproj
xcodebuild -project ios/Lotto.xcodeproj -scheme Lotto -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO test
```
