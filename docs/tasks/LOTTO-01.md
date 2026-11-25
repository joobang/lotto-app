# LOTTO-01 · 전 회차 이력과 적재

- 요구사항 LOTTO-01·05. 작업 시작 기준 앱 `b53efff`, 백엔드 `b667799`. 두 레포의 작업 브랜치는 `codex/lotto-draw-history`다.
- 범위는 초기 이력, 검증·재시도 가능한 적재, 최신·회차 조회다. 배포 환경과 주간 배치 등록은 운영 단계에서 확인한다.
- 예상 실패는 누락·중복 회차, 한국 달력 날짜 오류, 본번호 중복 또는 보너스 충돌, 같은 회차 내용 변경, 부분 저장, 적재 중 동시 갱신이다.
- 사용자 확정 사항으로 뽑기 연출과 화면 디자인을 핵심 경험으로 기록한다. UI 구현 단계에서는 뽑기 화면을 첫 시각 검토 대상으로 삼는다.

## 결과와 검증

- `node scripts/prepare-draw-seed.mjs data/initial-draws.json`으로 1~1251회 1,251건을 생성했다. 두 공개 자료가 겹친 1~1249회의 추첨일과 번호는 모두 일치했다. 마지막 1251회는 동행복권 발표와 일치했다. 1250회는 기본 공개 자료에서 확보했다. [공식 당첨번호 조회](https://www.dhlottery.co.kr/lt645/winNumber)
- 초기 스냅샷 SHA-256은 `b8d0dbbcd111f17b69ea8307a9dba2f141abbf707cd4a11ac3c8719b71cf8b2b`다.
- 백엔드 구현 커밋 `cc22e2fdaab3b98d87bcf8a3fad11720fd07feed`에서 설치 후 Node 24.22.3 `npm test` 389건 통과.
- 일회용 PostgreSQL에 `npx --no-install prisma migrate deploy`로 9개 마이그레이션 적용 성공. 아래 CLI로 실제 1,251건 최초 적재, 동일 입력 재실행 신규 0건. 충돌·누락 입력 모두 거절 후 마지막 정상 데이터 유지.
- 같은 DB에서 가상 1252회 입력을 두 번 동시에 실행했을 때 신규 삽입은 1건이었다. 가상 회차는 초기 스냅샷에 포함하지 않았다.
- Nest HTTP의 최신·첫 회차 조회, 빈 최신 503, 없는 회차 404, 범위 밖 회차 400, 기존 health 200을 확인했다. 일회용 DB는 종료했다.

## 로컬 호출

백엔드 작업 트리에서 격리 테스트 DB의 `DATABASE_URL`과 `CURSOR_SIGNING_KEY`를 지정한 뒤 실행한다.

```sh
npm run build
npx --no-install prisma migrate deploy
node dist/src/cli/import-lotto-draws.js --file ../lotto-app/data/initial-draws.json
```

주간 반영은 최신 공식 회차를 같은 행 형식으로 준비해 위 CLI에 넣는 방식이다. 실행 시 새 회차가 기존 마지막 회차에 이어져야 하며 공식 정정은 별도 검토가 필요하다. 정기 자동 실행과 운영 DB·Render 배포는 미실행이다.
