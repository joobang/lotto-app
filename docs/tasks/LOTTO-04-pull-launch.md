# LOTTO-04 · 당겨서 발사하는 번호 뽑기

기준 커밋은 `ed1bcc7`이다. 화면의 공을 직접 끌어 충전하고 손을 놓으면 그 위치에서 컷신으로 이어진다. 기준에 못 미치면 공이 원위치로 돌아온다. 랜덤과 패턴 탭 모두 조작과 탭 대안을 제공한다.

확인할 실패 사례는 짧은 드래그에서 결과 생성, 스크롤 제스처에 드래그가 끊김, 발사 순간 공 위치 점프, 빠른 재발사에서 직전 효과가 남음, 저장한 조합과 컷신 번호 불일치, 동작 줄이기와 무음 모드다.

## 제작 자료

발사대 이미지는 내장 이미지 생성 도구로 만들고 `ios/Lotto/Resources/draw-launcher.jpg`로 번들에 포함했다. 기존 소용돌이 배경에 실제 발사 위치, 공 궤적, 중심부 렌즈 플레어를 합성했다. `ios/Lotto/Resources/draw-launch.wav`는 발사 저음, 6회의 짧은 금속성 소리, 마무리 화음을 합성한 원본 효과음이다. iOS ambient 오디오 세션을 사용한다.

> Use case: stylized-concept. Create an original high-end mobile game's illustrated backdrop plate for a physically interactive lottery ball launcher. Portrait 4:5 composition for a 350 by 400 point inset display. A luminous accelerator chamber seen head on: nested brushed titanium concentric arches and violet-black enamel, subtle gilded edges, radial lavender and electric teal light, opalescent illuminated aperture at x 50 percent y 38 percent, tactile jewelry-like machining and wafer-thin etched rings. Symmetric central axis and impressive sense of depth. Near the bottom half leave dark mostly empty space around the central axis for a real interactive glowing ball that will be composited by software and can travel downward. Keep the center of the bottom clear, softly lit. Scene lighting dramatic and polished, not busy. No balls, no lettering, no labels, no hangers or guns or trigger imagery, no roulette wheels, no existing game objects, no characters, no watermark, no UI.

## 확인 결과

- iPhone 17 Pro 시뮬레이터에서 `xcodebuild test`를 실행했다. 랜덤의 27pt 드래그는 취소됐고 93pt 드래그는 여섯 번호를 출력했다. 패턴의 78pt 드래그와 랜덤 탭 대안, 결과 저장 및 재실행 복원, 분석도 통과했다.
- `xcodebuild -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build`가 통과했다. 실제 iPhone 설치, 무음 모드, 햅틱 타격감은 확인 전이다.
- 영상은 시뮬레이터 화면 녹화에 앱의 원본 효과음을 맞춰 편집했다.
