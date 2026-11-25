# 로또 API 계약 초안

경로의 공통 접두사는 `/v1/lotto`다. 공개 당첨 이력과 통계 요청을 처리한다. 아래 요청·응답 형태는 구현을 위한 계약 초안이다.

## 공통 규칙

- 추첨일은 한국 달력 날짜를 나타내는 `YYYY-MM-DD` 문자열이다. 갱신·확인 시각은 UTC 타임스탬프다.
- 집계 응답은 `coverage`에 `firstRound`, `lastRound`, `drawCount`, `verifiedAt`을 반환한다. 초기 이력이 준비됐으면 `firstRound=1`이고 회차 수와 연속 범위가 일치해야 한다.
- 번호 배열은 1~45 범위의 고유 정수다. 입력 순서는 자유이고 결과는 오름차순이다. 서버는 분석·추천 요청의 번호나 이름을 기록하지 않는다.

## 조회와 분석

| 요청 | 입력과 주요 응답 |
| --- | --- |
| `GET /draws/latest` | `round`, `drawDate`, `numbers`, `bonus`, `sourceUrl`, `coverage`. 마지막 정상 확인 결과를 반환한다. |
| `GET /draws/{round}` | 양의 정수 회차. `round`, `drawDate`, `numbers`, `bonus`, `sourceUrl`을 반환한다. |
| `GET /stats` | `coverage`와 `numberStats` 배열. 각 항목은 1~45번의 `number`, `count`, `rate`, `lastSeenRound`, `rank`다. 동일 횟수는 공동 순위를 사용한다. |
| `POST /analysis` | `numbers` 길이 6. 정렬한 `numbers`, `coverage`, `summary`, `matchDistribution`, `numberStats`, `similarDraws`, `patterns`를 반환한다. |
| `POST /recommendations` | `strategy`는 `historical_frequency` 또는 `historical_balance`. `lockedNumbers`는 0~5개, `count`는 1·3·5 중 하나다. `coverage`와 결과별 `numbers`, `explanation`을 반환한다. |

## 분석 응답 필드

- `summary`는 `maximumMatches`와 6개 완전 일치 횟수인 `exactMatches`로 구성한다. `matchDistribution`의 각 항목은 `matchedCount` 0~6과 그에 해당하는 `count`다.
- `numberStats`는 `GET /stats`와 같은 형식으로 입력 번호 6개에 해당하는 항목을 반환한다. 한 번도 나오지 않은 번호의 `lastSeenRound`는 `null`이다. 순위는 동일 횟수에서 같은 등수를 사용하는 경쟁 순위다.
- `patterns`는 내 조합의 `oddCount`, 번호대별 개수인 `bands`, `sum`, `sumPercentile`과 `pairs`를 담는다. `pairs`는 `first`, `second`, `count`를 포함한 15개 항목이다. `oddDistribution`, `bandDistribution`, `sumDistribution`은 같은 기간 전체 추첨의 분포다.
- 분석은 HTTP 200으로 반환하며 재사용 캐시에 저장하지 않도록 한다. 유효한 입력이지만 저장된 이력이 없으면 `LOTTO_HISTORY_NOT_READY`, 입력이 유효하지 않으면 `INVALID_LOTTO_NUMBERS`를 반환한다.

## 회차 비교와 계산

비율은 본번호로 나온 회차 수를 전체 검증 회차 수로 나눈 0~1 값으로 반환한다. 번호 쌍은 두 번호가 함께 본번호로 나온 횟수다. 조합 합계의 역대 위치는 해당 합계 이하인 검증 회차 수를 전체 회차 수로 나눈 값으로 정의한다.

유사 회차는 본번호가 하나 이상 일치한 회차를 교집합 크기 내림차순, 회차 내림차순으로 정렬한다. 한 항목에 `round`, `drawDate`, `numbers`, `bonus`, `matchedNumbers`, `bonusMatched`를 반환한다. 일치 개수는 `matchedNumbers`의 길이를 쓰고 보너스는 개수에 더하지 않는다. 본번호가 일치하지 않은 회차도 0개 일치 분포에는 집계한다.

## 추천 기준

- `historical_frequency`는 역대 본번호 출현 횟수에 1을 더해 번호별 가중치를 만들고, 고정 번호를 제외한 후보에서 가중치에 따라 비복원 추출한다. 결과 근거에는 추천 번호별 본번호 출현 횟수를 넣는다.
- `historical_balance`는 각 회차의 홀수 개수와 1~15·16~30·31~45 구간별 개수를 묶어 구성의 출현 횟수를 집계한다. 고정 번호를 포함할 수 있는 구성만 대상으로, 자주 관측된 구성부터 해당 조건에 맞는 서로 다른 조합을 만든다. 빈도가 같으면 홀수 개수와 구간별 개수의 순서로 비교한다. 결과 근거에는 사용한 구성과 출현 횟수를 넣는다.
- 한 응답 안에서 같은 6개 번호로 이루어진 조합은 한 번만 반환한다. 요청 수를 만들 수 없으면 가능한 결과와 부족 사유를 반환한다. 구성 조건을 임의로 완화하거나 전략을 바꿔 응답하지 않는다.
- 랜덤 뽑기는 iOS에서 균등 비복원 추출하고, 로컬에서 같은 호출 내 조합 중복을 없앤다.

## 상태와 오류

| 상황 | 처리 |
| --- | --- |
| 입력 범위나 조합 수 오류 | HTTP 400, 사용자에게 설명할 수 있는 안정된 오류 코드 |
| 존재하지 않는 회차 | HTTP 404 |
| 초기 검증 이력이 없음 | HTTP 503과 준비 상태 표시. 통계 집계와 추천은 생성하지 않는다. |
| 최신 회차 수집 실패 | 기존 검증 이력으로 HTTP 200 응답. 응답의 확인 시각과 반영 회차를 유지한다. |
| 추천 API 일시 실패 | 앱은 기존 결과를 유지하고 재시도 동작을 제공한다. |
