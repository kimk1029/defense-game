# Defense Game (Godot 4)

2D 디펜스 게임. Android/iOS 출시 목표.

## 문서 (SDD)
| 문서 | 내용 |
|---|---|
| [docs/01_GDD.md](docs/01_GDD.md) | 게임 기획서 (포탑 10종, 스테이지 4종, 수치) |
| [docs/03_ARCHITECTURE.md](docs/03_ARCHITECTURE.md) | 구조와 흐름 |
| [docs/specs/](docs/specs/) | 기능별 스펙과 수용 기준(AC) — SPEC-07이 밸런스 |
| [docs/04_TASKS.md](docs/04_TASKS.md) | 작업 ↔ 스펙 ↔ 테스트 추적표, 범위 밖 이슈 |

## 테스트 · 시뮬레이션
```
godot --headless --import                                          # 새 class_name 추가 후 1회
godot --headless --fixed-fps 60 --path . -s tests/run_tests.gd      # 종료 코드 = 실패 수
godot --headless --fixed-fps 60 --path . -s tools/balance_sim.gd -- 1,2,3,4 40 1   # 밸런스 리포트
```
- `--fixed-fps 60`: 프레임 delta가 1/60초로 고정되어, 봇·밸런스 결과가 결정적이고 빠르게 나온다.
- 밸런스 수치는 `scripts/balance_config.gd` 한 곳에 있다. 수치를 바꾸면 시뮬레이션을 다시 돌려 SPEC-07 목표를 확인한다.

## 웹 빌드 + 브라우저 E2E
```
godot --headless --path . --export-debug "Web" <dir>/index.html   # 디버그 빌드만 window.rbState 노출
python3 -m http.server 8766 -d <dir>
npm i playwright && node tools/e2e_web.js http://127.0.0.1:8766/index.html <out_dir> [chromium 경로]
```
- 웹에는 시스템 폰트 대체가 없어서 `assets/fonts/ui_font.tres`(나눔고딕 + Noto 기호, OFL)를 기본 폰트로 쓴다.

## 열기
1. [Godot 4.6+](https://godotengine.org/download) 다운로드 (단일 실행파일)
2. Godot 실행 → Import → 이 폴더의 `project.godot` 선택
3. F5 로 실행

## 폴더
- `project.godot` — Godot 프로젝트 설정
- `scenes/` — .tscn 씬 파일
- `scripts/` — .gd 스크립트
- `assets/sprites`, `assets/audio` — 리소스
- `addons/` — 플러그인 (광고 SDK 등)

## 모바일 빌드 준비
### Android
1. Android Studio 설치 → SDK + NDK + JDK 17 경로 확인
2. Godot Editor → Editor Settings → Export → Android 경로 설정
3. Project → Export → Add Android → APK/AAB 빌드

### iOS (Mac 필수)
1. Xcode 설치
2. Project → Export → Add iOS → Xcode 프로젝트 생성
3. Xcode에서 서명 후 Archive → App Store Connect 업로드

## 광고 (AdMob) 붙이는 법
Godot은 공식 AdMob이 없고 커뮤니티 플러그인을 씁니다.
- 추천: [Poing Studios godot-admob-android / godot-admob-ios](https://github.com/Poing-Studios)
- 또는 [godot-admob-plus](https://github.com/admob-plus/admob-plus)
- 설치 흐름: addon zip → `addons/` 에 압축 해제 → Godot에서 플러그인 활성화 → AdMob 앱ID/광고단위ID 입력 → custom build template 사용해서 빌드
- 주의: AdMob은 **custom Android build template** 필요 (Project → Install Android Build Template)

## 출시 로드맵
1. 게임 완성 (MVP)
2. 아이콘/스크린샷/스토어 문구 준비
3. Android: Google Play Console 가입($25 1회) → 내부 테스트 → 프로덕션
4. iOS: Apple Developer Program 가입($99/년) → TestFlight → 심사 제출
