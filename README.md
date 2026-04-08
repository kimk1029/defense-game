# Defense Game (Godot 4)

2D 디펜스 게임. Android/iOS 출시 목표.

## 열기
1. [Godot 4.3+](https://godotengine.org/download) 다운로드 (단일 실행파일)
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
