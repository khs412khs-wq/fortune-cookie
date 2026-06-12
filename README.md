# 🥠 포츈쿠키 (Fortune Cookie)

하루 5번, 포츈쿠키를 부수고 행운의 메시지를 받는 iPhone 앱입니다.

## 기능

- **하루 5회 제한** — 내 쿠키 3개 + 선물 쿠키 2개, 자정에 자동 초기화
- **중복 운세 방지** — 같은 날 이미 나온 문구는 다시 나오지 않음
- **잠금화면 위젯** — 잠금화면에서 남은 횟수 확인 및 부수기 (iOS 17+)
- **시각 효과** — 쿠키 균열, 반쪽 분리, 부스러기 파티클, 운세 쪽지 등장
- **진동** — 탭/부수기/운세 공개 시 단계별 햅틱 피드백
- **사운드** — 부수기·운세 공개 효과음

## 요구 사항

- Xcode 15 이상 (권장: Xcode 17+)
- iOS 17.0 이상 (인터랙티브 잠금화면 위젯)
- iPhone (세로 모드)

## 실행 방법

1. `FortuneCookie.xcodeproj`를 Xcode에서 엽니다.
2. **Signing & Capabilities**에서 본인 Apple Developer Team을 선택합니다.
3. 메인 앱 타겟과 위젯 타겟 모두 **App Groups** (`group.com.fortunecookie.shared`)가 활성화되어 있는지 확인합니다.
4. iPhone 시뮬레이터 또는 실제 기기를 선택하고 **Run** (⌘R).

## 잠금화면 위젯 추가

1. iPhone 잠금화면을 길게 누릅니다.
2. **맞춤하기** → 위젯 영역 탭
3. **포츈쿠키** 위젯 선택
4. 원하는 스타일(원형/직사각형/한 줄) 추가

홈 화면 **Small** 위젯에서는 **부수기** 버튼으로 앱을 열지 않고도 포츈쿠키를 부술 수 있습니다.

## 프로젝트 구조

```
FortuneCookie/          # 메인 앱
FortuneCookieWidget/    # 잠금화면·홈화면 위젯
Shared/                 # 앱·위젯 공유 로직
scripts/                # 사운드 생성 스크립트
```

## 공유 & 딥링크

합성 이미지를 **iOS 기본 공유**로 보냅니다. 카카오톡, 메시지, 인스타 등 원하는 앱을 선택하면 됩니다.

### 설정 (`Shared/AppShareConfig.swift`)

1. **`appStoreID`** — App Store 출시 후 숫자 ID 입력
2. **`shareRedirectURL`** (선택) — `docs/share-redirect.html`을 호스팅한 URL  
   - 앱 설치됨 → `fortunecookie://open`으로 앱 실행  
   - 미설치 → App Store로 이동

### 사용 방법

1. 포츈쿠키 열기 → **공유하기**
2. 미리보기에서 **공유하기** 탭
3. 카카오톡 등 원하는 앱 선택

## App Store 배포 시

- `Assets.xcassets/AppIcon.appiconset`에 1024×1024 앱 아이콘 추가
- Bundle ID를 본인 계정에 맞게 변경
- App Group ID를 Apple Developer 포털에서 등록

## 사운드 재생성

```bash
python3 scripts/generate_sounds.py
```

## Lottie 애니메이션

포츈쿠키 애니메이션은 [Lottie](https://github.com/airbnb/lottie-ios)를 사용합니다.

| 파일 | 설명 |
|------|------|
| `FortuneCookie/Animations/cookie_idle.json` | 대기 중 살짝 커졌다 작아지는 모션 |
| `FortuneCookie/Animations/cookie_break.json` | 탭 시 부서지는 모션 |

애니메이션 수정:

```bash
python3 scripts/generate_lottie_cookie.py
```

LottieFiles에서 다운로드한 `.json`으로 교체해도 됩니다. 파일명만 맞추면 앱에 바로 반영됩니다.
