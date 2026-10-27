# 구절함(句節函)

책을 읽다 좋은 문장을 만나면 사진을 찍고, OCR로 읽어 낸 문장 가운데 원하는 것만 골라 담아 두는 앱입니다.

- 기준 저장소는 **기기의 로컬 SQLite(drift)** 입니다. Google 계정을 연동하지 않아도 모든 기능이 동작합니다.
- 연동하면 본인 Google Drive의 **appDataFolder**(앱 전용 숨김 공간)에 `quotes.json` 하나로 백업·동기화합니다. 별도 서버나 Firebase는 쓰지 않습니다.
- 요청하는 OAuth 스코프는 `https://www.googleapis.com/auth/drive.appdata` 하나뿐입니다.

## 개발 환경

- Flutter stable(3.47 이상), Dart 3.13 이상
- Android: minSdk 24, compileSdk 36
- iOS: 15.5 이상(ML Kit 요구 사항)

```bash
flutter pub get
dart run build_runner build      # drift 코드 생성(스키마를 바꿨을 때)
flutter test
flutter run --dart-define-from-file=google_oauth.json
```

`google_oauth.json`이 없어도 앱은 실행되며, 이 경우 Google 연동만 실패합니다.

## 구조

```
lib/
  core/       테마(theme.dart), 문자열(strings.dart), 라우팅(router.dart),
              문장 분리(sentence_splitter.dart), 공용 위젯(함·낙관)
  data/       drift 스키마·DAO, 저장소(repository), 이미지 보관, Riverpod 프로바이더
  features/   home · capture(촬영·부분 지정) · select · save · detail · share · settings
  sync/       Google 로그인, Drive appData 동기화(drive_sync_service.dart), 병합 규칙
test/         문장 분리 · 부분 지정 · DAO · 마이그레이션 · 동기화 병합 단위 테스트
```

## 주요 기능

- **부분 지정**: 사진을 읽은 뒤 손가락으로 네모를 그리면, 그 안에 중심이 들어오는 단어만 모아 문장으로 나눕니다(`lib/core/ocr_region.dart`). "전체 문장"을 누르면 사진 전체를 씁니다.
- **마음에 새기기**: '좋아요'에 해당합니다. 상세 화면에서 새기면 구절에 '새김' 낙관이 찍히고, 홈에서 "새긴 구절"만 골라 볼 수 있습니다. `cherished_at` 열(스키마 2)에 시각을 저장하고 동기화에도 포함합니다.
- **보내기(공유)**: 상세 화면의 "보내기" → 구절 카드를 PNG로 만들어 보내거나 글로 보냅니다. OS 공유 창(share_plus)을 쓰므로 서버가 필요 없습니다.

## Google Cloud OAuth 클라이언트 설정

Google 로그인 v7(Android Credential Manager)은 **웹 클라이언트 ID**를 `serverClientId`로 요구하므로,
Android·iOS 클라이언트 외에 웹 클라이언트도 하나 만들어야 합니다.

### 1. 프로젝트와 API

1. [Google Cloud Console](https://console.cloud.google.com/)에서 프로젝트를 만들거나 고릅니다.
2. **API 및 서비스 → 라이브러리**에서 **Google Drive API**를 사용 설정합니다.
3. **Google 인증 플랫폼(OAuth 동의 화면)** 을 구성합니다.
   - 사용자 유형: 외부
   - 데이터 액세스(범위)에 `.../auth/drive.appdata` 추가
   - 게시 전(테스트 상태)에는 **테스트 사용자**에 본인 계정을 추가해야 로그인할 수 있습니다.

### 2. 웹 애플리케이션 클라이언트 (Android에 필수)

**클라이언트 → 클라이언트 만들기 → 웹 애플리케이션**. 리디렉션 URI는 비워 둡니다.
만들어진 클라이언트 ID가 `GOOGLE_SERVER_CLIENT_ID` 입니다.

### 3. Android 클라이언트

**클라이언트 만들기 → Android**

- 패키지 이름: `com.jshchz.gujeolham`
- SHA-1 인증서 지문: 서명에 쓰는 키마다 하나씩 등록합니다(디버그 / 릴리스 / Play 앱 서명).

디버그 키의 SHA-1 확인:

```bash
# Windows
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
# macOS / Linux
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
# 또는 모든 빌드 구성의 지문을 한 번에
cd android && ./gradlew signingReport
```

Play Console에서 앱 서명을 쓰는 경우 **Play Console → 앱 무결성 → 앱 서명 키 인증서**의 SHA-1도 등록해야 스토어 빌드에서 로그인이 됩니다.

> Android 클라이언트 ID는 코드에 넣지 않습니다. 패키지 이름 + SHA-1로 식별됩니다.
> 지문이나 패키지 이름이 틀리면 계정을 고른 뒤 `canceled` 오류가 나는 경우가 많습니다.

### 4. iOS 클라이언트

**클라이언트 만들기 → iOS**

- 번들 ID: `com.jshchz.gujeolham`

만들어진 클라이언트 ID(`1234-abcd.apps.googleusercontent.com`)로 두 가지를 설정합니다.

1. `GOOGLE_IOS_CLIENT_ID`로 앱에 전달(아래 설정 파일).
2. `ios/Runner/Info.plist`의 URL scheme 자리표시자를 **REVERSED_CLIENT_ID** 로 바꿉니다.

   ```xml
   <key>CFBundleURLSchemes</key>
   <array>
     <!-- 클라이언트 ID 1234-abcd.apps.googleusercontent.com 이면 -->
     <string>com.googleusercontent.apps.1234-abcd</string>
   </array>
   ```

### 5. 앱에 클라이언트 ID 전달

저장소 루트에 `google_oauth.json`을 만듭니다(`.gitignore`에 포함되어 있습니다). 형식은 `google_oauth.example.json` 참고.

```json
{
  "GOOGLE_SERVER_CLIENT_ID": "웹-클라이언트-ID.apps.googleusercontent.com",
  "GOOGLE_IOS_CLIENT_ID": "iOS-클라이언트-ID.apps.googleusercontent.com"
}
```

```bash
flutter run --dart-define-from-file=google_oauth.json
flutter build apk --release --dart-define-from-file=google_oauth.json
```

## 권한

| 플랫폼 | 항목 | 설명 |
| --- | --- | --- |
| Android | `INTERNET` | Drive 동기화, 웹 서체 |
| Android | `uses-feature camera (required=false)` | 카메라 없는 기기에도 설치 가능 |
| Android | `queries: IMAGE_CAPTURE` | Android 11+에서 시스템 카메라 앱 호출 |
| iOS | `NSCameraUsageDescription` | 촬영 |
| iOS | `NSPhotoLibraryUsageDescription` | 갤러리에서 고르기 |

Android에서는 image_picker가 시스템 카메라 앱과 사진 선택기를 쓰므로 `CAMERA`·저장소 런타임 권한이 필요 없습니다.
`CAMERA` 권한을 선언하면 런타임 승인 전까지 카메라 인텐트가 막히므로 일부러 선언하지 않았습니다.

## 동기화 규칙

- 시점: 앱 시작(연동된 경우), 저장·수정·삭제 직후, 설정의 "지금 동기화"
- 원격 `quotes.json` 다운로드 → `id`로 매칭 → `updated_at`이 더 늦은 쪽 채택(삭제 `deleted_at` 포함) → 로컬 반영 → 병합 결과 업로드
- 원격 파일이 없으면(최초 연동) 로컬 전체로 새로 만듭니다.
- `image_path`는 기기 전용이라 올리지 않으며, 원격 반영 시에도 로컬 값을 유지합니다.
- 실패하거나 연동되지 않았으면 조용히 건너뛰고, 마지막 오류를 설정 화면에 보여 줍니다.
- 동시에 한 번만 실행되며, 실행 중 요청이 오면 끝난 뒤 한 번 더 실행합니다.
- 원격 파일의 `version`이 이 앱이 아는 것(1)보다 크면 덮어쓰지 않고 오류로 남깁니다.
- `cherished_at`은 형식 1에 선택 필드로 더했습니다. 이 필드가 없는 옛 파일은 "새기지 않음"으로 읽습니다.

## 참고

- 서체(Jua, 고운돋움, OFL)는 `assets/google_fonts/`에 포함되어 있고 런타임 내려받기는 꺼져 있습니다.
- 디자인 확인: `flutter test tool/screens_preview_test.dart` → `build/preview/*.png`
- 앱 아이콘 다시 만들기: `flutter test tool/app_icon_test.dart`
- `google_fonts`는 8.x를 씁니다. 9.x는 새 `material_ui` 패키지 기반이라 Flutter의 `ThemeData`와 `TextTheme` 타입이 맞지 않습니다.
