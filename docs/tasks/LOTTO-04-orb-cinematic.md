# LOTTO-04 · 운석과 번호 공 공개

기준 커밋은 `c17c13d`다. 번호 카드 대신 둥근 번호 공을 사용한다. 운석이 중앙으로 날아들면 푸른 파동이 번지고, 같은 위치에서 번호 공 여섯 개가 빠르게 두 줄로 튀어나온다. 마지막은 금빛 충격파로 마무리한다. 랜덤과 패턴 뽑기가 같은 연출을 사용한다.

[원신 공개 컷신](https://www.youtube.com/watch?v=3C-VmlwBVro)의 유성 궤적과 빛의 집중, [붕괴: 스타레일 워프 공개 사례](https://www.hoyolab.com/article/18278979)의 이동과 공개 사이 리듬, [이환 공식 보드 안내](https://store.steampowered.com/news/posts/?enddate=1792567700&feed=steam_community_announcements)의 연속 이동과 착지 단서를 참고했다. 앱은 새 우주 배경과 로또 공을 사용한다.

## 배경 이미지

`ios/Lotto/Resources/draw-vortex.jpg`는 내장 이미지 생성 도구로 만든 원본 배경의 번들용 JPEG 사본이다.

> Use case: stylized-concept. Produce an original portrait 9:16 in-game cinematic environment texture for an iPhone lottery ball reveal. High-end cinematic VFX concept art. A colossal asymmetrical storm aperture in deep indigo outer space, looking straight into the tunnel. Sculpted cobalt and amethyst gaseous clouds spiral diagonally toward a radiant opalescent white and rose center slightly above the middle (x 50%, y 43% from top). At the far edges glowing turquoise arcs, thin amber wisps, sparse stars, fine crystalline dust, layered depth like a macro optical lens. Deep ink at top and bottom for animated overlays. Explosive center, elegant iridescence and volumetric light, clear readable big shapes with rich high-frequency detail at the edges, carefully art directed. Full bleed. No letters, no numerals, no frames, no cards, no lottery balls, no characters, no logos, no interface, no buildings, no existing game imagery. This is a background plate with the numbered 3D spheres composited by the app.

## 검사 범위

공은 310ms부터 58ms 간격으로 공개한다. 여섯 번째 공은 600ms에 진입을 시작하고 약 715ms에 정렬된다. 약 1.62초 후 같은 조합의 결과 화면으로 돌아간다. 시간은 코드 설정값이다. 배경 번들 누락, 첫 컷의 구도, 색과 숫자 대비, 여섯 공 배치, 랜덤·패턴 뽑기 및 저장 복원을 확인한다.

- iPhone 17 Pro 시뮬레이터의 `xcodebuild test`가 통과했다. 랜덤과 패턴에서 여섯 번호가 생성됐고, 저장 복원과 기존 분석 진입을 확인했다. 실제 컷신을 녹화하고 최종 공 배치와 배경 렌더링을 확인했다.
- `xcodebuild -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build`가 통과했다. 실기기 설치와 햅틱 체감은 확인하지 않았다.
