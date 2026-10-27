# 구절함(句節函) MVP 작업 기록

- 작성일: 2026-10-26
- 범위: 프로젝트 생성부터 구현 7단계(권한 설정·README)까지

## 1. 요약

| 항목 | 결과 |
| --- | --- |
| 정적 분석(`flutter analyze`) | 오류 0건 |
| 단위 테스트(`flutter test`) | 25개 모두 통과 |
| Android 디버그 빌드(`flutter build apk --debug`) | 성공 → `build\app\outputs\flutter-apk\app-debug.apk` |
| 실기기·에뮬레이터 실행 | **하지 않음**. 카메라, OCR, Google 로그인·동기화는 실제 동작을 확인하지 못함 |
| iOS 빌드 | **하지 않음**. Windows 환경이라 Mac이 필요함 |

## 2. 개발 환경 준비

- 작업 폴더 `C:\WorkSpace\Gujeolham`은 비어 있었고, Flutter가 설치되어 있지 않았음.
- **Flutter 3.47.8 stable**(Dart 3.13.7)을 `git clone`으로 `C:\src\flutter`에 설치함. 사용자 PATH는 바꾸지 않았고, 이 세션에서는 `C:\src\flutter\bin\flutter.bat` 전체 경로로 실행함.
- 기존 Android SDK(`%LOCALAPPDATA%\Android\Sdk`, platform 35, build-tools 35)와 라이선스를 그대로 사용함. 빌드 중에 Gradle이 CMake 3.22.1을 자동으로 설치함.
- Java 17 사용.
- 사용자 결정 사항:
  - Flutter 설치 위치: `C:\src\flutter`
  - 패키지 ID: **`com.jshchz.gujeolham`**(Android applicationId와 iOS bundle ID 공통)

## 3. 사용 패키지

| 구분 | 패키지 | 비고 |
| --- | --- | --- |
| 상태관리 | flutter_riverpod ^3.4.3 | |
| 라우팅 | go_router ^18.1.1 | |
| OCR | google_mlkit_text_recognition ^0.17.1 | `TextRecognitionScript.korean` |
| 이미지 | image_picker ^1.2.4 | |
| 로컬 DB | drift ^2.35.3, drift_flutter ^0.3.1 | 개발용: drift_dev, build_runner |
| 클라우드 | google_sign_in ^7.2.0, googleapis ^17.0.0, extension_google_sign_in_as_googleapis_auth ^3.0.0 | 스코프는 `drive.appdata` 하나 |
| 기타 | uuid, path_provider, path, intl, **google_fonts ^8.0.0** | |
| 추가 | http, package_info_plus | 아래 4절 참고 |

## 4. 명세와 다른 점

1. **단계별 빌드 확인**: 첫 Gradle 빌드가 약 17분 걸려서, 그동안 2~7단계 코드를 미리 작성함. "단계마다 빌드 통과 후 다음 단계"는 1단계에만 지켰고, 나머지는 완성된 코드를 한꺼번에 검증함(분석·테스트·빌드).
2. **google_fonts 8.x로 고정**: 9.x는 새 `material_ui` 패키지 기반이라 `TextTheme` 타입이 Flutter의 `ThemeData`와 달라 컴파일 오류가 남.
3. **sqlite3_flutter_libs 제거**: 지원이 끝난(EOL) 패키지임. sqlite3 3.x가 빌드 훅으로 네이티브 라이브러리를 직접 포함하고, `drift_flutter`가 그 역할을 맡음.
4. **목록에 없는 패키지 추가**
   - `drift_flutter`: drift의 Flutter용 DB 연결 도우미
   - `http`: Google 로그인 인증을 Drive API 클라이언트에 연결하는 데 사용
   - `package_info_plus`: 설정 화면의 앱 버전 표시. 명시된 스택만 쓰려면 버전을 상수로 바꿀 수 있음
5. **문장 분리 규칙 2 보완**: `"간다."라고 했다`처럼 닫는 따옴표 바로 뒤에 조사가 붙으면 한 문장으로 둠. 규칙을 문자 그대로 적용하면 `"간다."`와 `라고 했다.`로 잘려서 한국어로는 틀린 결과가 됨.
6. **이미지 경로는 상대 경로로 저장**: `image_path`에는 앱 문서 폴더 기준 상대 경로(`images/<id>.jpg`)를 저장함. iOS는 앱을 업데이트하면 컨테이너의 절대 경로가 바뀔 수 있기 때문.
7. **동기화 기록 저장 위치**: 연동 여부, 이메일, 마지막 동기화 시각, 마지막 오류는 DB 테이블을 새로 만들지 않고 앱 지원 폴더의 `sync_state.json`에 저장함.
8. **Android CAMERA 권한 미선언**: image_picker는 시스템 카메라 앱을 띄우므로 권한이 필요 없음. 오히려 `CAMERA`를 선언하면 사용자가 허용하기 전까지 카메라 인텐트가 막힘.

## 5. 단계별 작업 내용

### 1단계 — 프로젝트·테마·라우팅
- `flutter create --org com.jshchz --project-name gujeolham --platforms android,ios .`
- `lib/core/theme.dart`
  - 팔레트(한지 #F5EFE4, 카드 #FBF8F1, 먹 #2B2B2B, 보조 #6B6560, 단청 #A33A2E, 쪽빛 #2F4F6F, 먹선은 먹색 20%)
  - 색은 `ColorScheme`과 `ThemeExtension`(`HanjiColors`)으로 정의함. 위젯에서는 `context.hanji`로만 접근하고 하드코딩한 색은 없음
  - 본문 서체는 Noto Serif KR, 타이틀은 나눔명조(굵게)
  - 모서리 radius 4, 그림자 없음(elevation 0), 테두리로 구분
  - 버튼, 입력창, 카드, 다이얼로그, 스낵바, 스위치, 확장 타일 테마를 모두 정의함
- `lib/core/strings.dart`: 한국어 문자열을 모두 모아 둠(`S` 클래스)
- `lib/core/router.dart`: go_router 경로
  - `/splash`, `/`, `/capture`, `/capture/select`, `/capture/select/save`, `/quote/:id`, `/settings`
- `lib/core/widgets/ham_box.dart`: 각진 '함' 상자 위젯(뚜껑 열림 정도를 값으로 받음)
- `lib/features/home/splash_screen.dart`: 함 뚜껑이 열리는 1.4초 애니메이션 뒤에 홈으로 이동

### 2단계 — drift 스키마·DAO·프로바이더
- `lib/data/database.dart`: `quotes` 테이블. 컬럼은 명세 그대로이고, 날짜는 ISO8601 UTC 문자열(TEXT)로 저장
- `lib/data/quotes_dao.dart`
  - `watchQuotes(query)`: 삭제되지 않은 구절을 최신순(created_at 내림차순)으로. content, book_title, author 부분일치 검색. `%`, `_` 같은 LIKE 특수문자는 이스케이프함
  - `watchQuote`, `findById`
  - `recentBooks()`: 최근 책 제목(중복 없이 최근순)과 그 책의 최근 저자
  - `insertQuote`, `updateQuote`(updated_at 갱신), `softDelete`(deleted_at과 updated_at만 기록)
  - `allIncludingDeleted()`, `applyRemote()`(동기화 반영용, 6단계 참고)
- `lib/data/image_store.dart`: 원본 사진을 앱 문서 폴더 `images/`에 복사하고 상대 경로를 돌려줌
- `lib/data/quote_repository.dart`: 저장, 수정, 삭제를 처리하고, 끝나면 `onChanged` 훅을 호출함(동기화 요청용)
- `lib/data/providers.dart`: DB, DAO, 저장소, 검색어, 목록, 단건, 최근 책, 이미지 파일 프로바이더

### 3단계 — 촬영 → OCR → 문장 분리 → 문장 고르기
- `lib/core/sentence_splitter.dart`: 명세의 규칙 1~5 구현
  - 종결부호는 `. ! ? …`. 연속된 부호(`?!`, `...`)와 바로 뒤의 닫는 따옴표·괄호까지 한 문장으로 봄
  - 숫자 사이의 `.`(3.14, 1.2.3), 영문·숫자가 바로 붙은 `.`(e.g, URL), 영문 약어(Mr, Dr, etc 등), 대문자 이니셜(J. K.)에서는 나누지 않음
  - 2글자 이하 조각은 앞 문장에 병합함(첫 조각이면 다음 문장 앞에 붙임)
  - 종결부호가 없는 마지막 조각도 한 문장으로 포함함
- `lib/features/capture/ocr_service.dart`: ML Kit 한국어 인식 → 블록·줄 순서로 이어 붙인 뒤 문장으로 분리
- `lib/features/capture/capture_session.dart`: 촬영부터 담기까지의 상태(사진 경로, 문장 목록, 선택 순서)
- `lib/features/capture/capture_screen.dart`: 카메라와 갤러리 버튼. 사진을 고르면 바로 OCR을 돌리고 로딩을 표시함. 실패하거나 글자가 없으면 스낵바로 알림
- `lib/features/select/select_screen.dart`: 문장 목록. 탭하면 선택·해제되고 선택 순서가 유지됨. 선택한 문장은 쪽빛 테두리와 순번 배지로 표시됨. 하단에 "N개 문장 담기" 버튼

### 4단계 — 담기·낙관 애니메이션·홈
- `lib/features/save/quote_form.dart`: 담기 화면과 수정 화면이 함께 쓰는 입력 폼
  - 구절(필수), 책 제목, 저자, 쪽수(숫자만), 메모
  - 책 제목은 최근 제목을 자동완성으로 제안하고, 고르면 저자가 비어 있을 때 채워 줌
- `lib/features/save/save_screen.dart`: 선택한 문장을 이어 붙여 편집 가능한 상태로 보여 줌 → 저장 → 낙관 애니메이션 → 홈으로 이동
- `lib/core/widgets/seal.dart`: 붉은 낙관('藏')과 0.4초 scale+fade 찍힘 애니메이션
- `lib/features/home/home_screen.dart`
  - 상단 검색창, 최신순 구절 카드 목록(왼쪽 단청색 띠, 책·저자·쪽수·날짜)
  - 우하단 "담기" FAB, 설정 버튼
  - 빈 상태 문구: "아직 담긴 구절이 없습니다"(검색 결과가 없을 때는 "찾는 구절이 없습니다")

### 5단계 — 상세·수정·삭제
- `lib/features/detail/detail_screen.dart`
  - 전체 내용(복사 가능), 책, 저자, 쪽수, 메모, 담은 날, 고친 날
  - 수정: 모든 필드를 고칠 수 있음(공용 폼 사용)
  - 삭제: 확인 다이얼로그 → 소프트 삭제 → 이전 화면으로
  - 원본 사진이 있으면 접힌 상태로 표시함. 펼치면 확대할 수 있고, 파일이 없으면 안내 문구를 보여 줌

### 6단계 — Google 로그인·Drive 동기화·설정
- `lib/sync/google_auth.dart`: google_sign_in v7
  - `initialize`, 조용한 로그인 복원, 대화형 로그인, `drive.appdata` 권한 요청, 인증된 http 클라이언트 생성
  - 클라이언트 ID는 `--dart-define`으로 주입함(`GOOGLE_SERVER_CLIENT_ID`, `GOOGLE_IOS_CLIENT_ID`)
- `lib/sync/sync_merge.dart`: JSON 직렬화(image_path 제외), 내보내기 형식 `{version: 1, exported_at, quotes}`, 파싱(잘못된 항목은 건너뜀), 병합 규칙
- `lib/sync/drive_sync_service.dart`
  - appDataFolder의 `quotes.json` 검색 → 다운로드 → id 매칭 → updated_at이 더 늦은 쪽 채택(deleted_at 포함) → 로컬 반영 → 병합 결과 업로드. 파일이 없으면 새로 만듦
  - **락**: 동시에 한 번만 실행함. 실행 중에 요청이 오면 끝난 뒤 한 번 더 실행함
  - 원격 파일의 version이 1보다 크면 덮어쓰지 않고 오류를 기록함
- `QuotesDao.applyRemote`: 트랜잭션 안에서 로컬 updated_at을 다시 확인해, 그 사이 로컬에서 더 늦게 고친 항목은 덮어쓰지 않음. image_path는 유지함
- `lib/sync/sync_state_store.dart`: 연동 상태와 기록을 `sync_state.json`에 저장
- `lib/sync/sync_controller.dart`(Riverpod Notifier)
  - 앱 시작 시: 저장된 상태 복원 → 연동되어 있으면 로그인을 조용히 복원하고 동기화
  - 연동(로그인 → 최초 동기화), 연동 해제(로그아웃, 로컬 데이터는 그대로)
  - 저장·수정·삭제 직후 조용히 동기화. 미연동이면 아무것도 하지 않음
  - 오류는 한국어 메시지로 바꿔서 마지막 오류로 기록함(취소, 권한 거부, 네트워크, Drive, 파일 형식)
- `lib/main.dart`: `ProviderContainer`에서 변경 훅을 동기화에 연결하고, 앱 시작 시 동기화 컨트롤러를 실행함
- `lib/features/settings/settings_screen.dart`: 연동 스위치(해제할 때는 확인), 연동된 이메일, 마지막 동기화 시각, 마지막 오류(단청색), "지금 동기화" 버튼, 앱 버전

### 7단계 — 플랫폼 설정·README
- Android (`android/app/src/main/AndroidManifest.xml`, `build.gradle.kts`)
  - `INTERNET` 권한
  - `uses-feature camera required=false`
  - `queries`에 `IMAGE_CAPTURE` 추가(Android 11 이상에서 카메라 앱 호출)
  - 앱 이름을 "구절함"으로 변경
  - ML Kit 한국어 모델 의존성 `com.google.mlkit:text-recognition-korean:16.0.1` 추가
- iOS
  - `Info.plist`: 표시 이름 "구절함", `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, Google 로그인 URL scheme 자리표시자(`REPLACE_WITH_IOS_CLIENT_ID`)
  - `Podfile`: `platform :ios, '15.5'`, `GoogleMLKit/TextRecognitionKorean ~> 9.0.0`, armv7 제외, 최소 배포 버전 보정
  - Xcode 프로젝트의 배포 대상을 15.0에서 15.5로 변경
- `README.md`: 개요, 구조, Google Cloud OAuth 설정(Drive API, 동의 화면, 웹·Android(SHA-1)·iOS(URL scheme) 클라이언트), 클라이언트 ID 전달 방법, 권한 표, 동기화 규칙
- `google_oauth.example.json` 추가. `.gitignore`에 `/google_oauth.json` 추가

## 6. 테스트

| 파일 | 개수 | 내용 |
| --- | --- | --- |
| `test/sentence_splitter_test.dart` | 16 | 규칙 1~5 전부(줄 잇기, 종결부호와 따옴표·괄호, 숫자·약어·이니셜·URL, 짧은 조각 병합, 마지막 조각) |
| `test/quotes_dao_test.dart` | 5 | 최신순 저장과 변경 훅, 부분일치 검색(LIKE 이스케이프), 수정 시 updated_at 갱신과 소프트 삭제, 최근 책 목록, applyRemote의 image_path 보존과 최신 로컬 보호 |
| `test/sync_merge_test.dart` | 4 | 내보내기 형식(image_path 제외)과 JSON 왕복, 잘못된 항목 건너뛰기, id 매칭과 최신 항목 채택, ISO 문자열 길이와 무관한 시각 비교 |

DAO 테스트는 drift의 메모리 DB(`NativeDatabase.memory()`)로 실행함.

## 7. 파일 구조

```
lib/
  main.dart
  core/
    router.dart  sentence_splitter.dart  strings.dart  theme.dart
    widgets/ham_box.dart  widgets/seal.dart
  data/
    database.dart(.g)  quotes_dao.dart(.g)  quote_repository.dart
    image_store.dart  providers.dart
  features/
    home/home_screen.dart  home/splash_screen.dart
    capture/capture_screen.dart  capture/capture_session.dart  capture/ocr_service.dart
    select/select_screen.dart
    save/save_screen.dart  save/quote_form.dart
    detail/detail_screen.dart
    settings/settings_screen.dart
  sync/
    google_auth.dart  drive_sync_service.dart  sync_merge.dart
    sync_controller.dart  sync_state_store.dart
test/
  sentence_splitter_test.dart  quotes_dao_test.dart  sync_merge_test.dart
README.md  WORKLOG.md  google_oauth.example.json
```

## 8. 남은 일

1. Google Cloud에서 OAuth 클라이언트 세 개(웹, Android, iOS) 만들기. Android 로그인에는 **웹 클라이언트 ID**가 필요함(README 참고)
2. 루트에 `google_oauth.json`을 만들고 `flutter run --dart-define-from-file=google_oauth.json`으로 실행
3. `ios/Runner/Info.plist`의 `REPLACE_WITH_IOS_CLIENT_ID`를 iOS 클라이언트 ID를 뒤집은 값으로 바꾸기
4. Mac에서 iOS 빌드하고 확인하기
5. 실기기에서 확인할 것: 카메라·갤러리, 한국어 OCR 품질, 낙관과 스플래시 애니메이션, 로그인·동기화(두 기기 간 병합, 삭제 전파)
6. 선택 사항
   - 서체를 앱에 포함하기(지금은 첫 실행 때 내려받으므로 오프라인 첫 실행에서는 기본 서체로 보임)
   - `package_info_plus`를 상수로 바꾸기
   - `git init`과 첫 커밋

## 9. UI 재구성 — 「스타일 가이드 · 색 · 서체 · 아이콘.pdf」 반영 (2026-10-26)

처음 명세의 디자인(단청·쪽빛, 명조, 모서리 4px, 테두리만 사용)을 PDF 가이드로 **전부 교체**함.

| 항목 | 이전 | 이후(가이드) |
| --- | --- | --- |
| 색 | 한지 #F5EFE4, 먹 #2B2B2B, 단청 #A33A2E, 쪽빛 #2F4F6F | 한지 미색 #F6F0E4, 종이 백색 #FBF7EE, 연한 모래 #EFE3CF, 갈먹 #5A3F2B, 연갈 #B59A7C, 다홍 #C9594C, 옥색 #8FB8A5, 치자 #E0B457 |
| 서체 | Noto Serif KR, 나눔명조 | Jua(제목·화면명·상세 구절·버튼·낙관), 고운돋움(목록·입력·메모·보조 정보) |
| 모서리 | 4px | 카드 20px, 버튼·입력 알약(full-pill), 낙관 7–12px |
| 그림자 | 없음(테두리) | 아래쪽 3px 단색 그림자(0 3px 0), 누르면 쏙 들어감 |
| 장식 | 각진 함, 붉은 '藏' 낙관 | 구름 코너(홈·상세 2겹+점, 나머지 1겹+점), 통통 노리개(홈·상세 상단 중앙, 살랑 흔들림), 둥근 '담' 낙관(카드마다 다홍/옥/치자, ±4~7° 기울임), 마스코트 함이 |
| 저장 완료 | 낙관 0.4초 | 함이가 뚜껑을 톡 열며 웃고 → '담' 낙관이 0.4초 동안 찍힘 |
| 앱 아이콘 | Flutter 기본 | 한지 바탕 + 구름 코너 + 함이 |

### 새로 만든 공용 위젯 (`lib/core/widgets/`)
- `decor.dart`: `CloudCorners`(구름 코너), `Norigae`(노리개)
- `hami.dart`: `Hami`(뚜껑 열림·웃음 정도를 값으로 받음), `HamiCheer`(톡 열리며 웃는 애니메이션)
- `seal.dart`: `Seal`(한 글자 또는 세로쓰기, 색·기울기), `Seal.forIndex`(번갈아 색·각도), `SaveCelebration`
- `puffy.dart`: `PillButton`(다홍/갈먹/종이 3가지), `RoundIconButton`, `PuffyCard`, `SandChip`
- `hanji_page.dart`: 모든 화면의 공통 틀(한지 바탕, 구름 코너, 노리개, 헤더, 하단 버튼 자리)
- `confirm_dialog.dart`: 함이가 묻는 둥근 확인 대화상자(삭제·연동 해제)
- `ham_box.dart`(각진 함)는 삭제

### 화면별 변경
- **스플래시**: 함이가 뚜껑을 열며 웃고 '구절함' 제목이 떠오름
- **홈**: 노리개 + 2겹 코너, Jua 제목과 '담긴 구절 N', 알약 검색창, 둥근 카드(책·저자·쪽수는 모래색 칩), 카드마다 다른 색·각도의 '담' 낙관, 알약 "담기" 버튼. 빈 상태에는 함이
- **촬영**: 뚜껑을 조금 연 함이, 읽는 중에는 뚜껑이 들썩임. 다홍 "카메라로 찍기" + 종이 "갤러리에서 고르기"
- **문장 고르기**: 선택하면 모래색 카드 + 선택 순서 번호 낙관(다홍/옥/치자)
- **담기**: 한 줄 입력은 알약, 여러 줄 입력(구절·메모)은 20px 모서리. 저장하면 함이 + 낙관 연출
- **상세**: 노리개 + 2겹 코너, 구절은 Jua 22pt 카드에 세로 '구절함' 낙관, 책 제목·칩·메모 카드, 원본 사진은 접히는 카드
- **설정**: 둥근 카드 묶음, 다홍 스위치, 갈먹 "지금 동기화" 버튼

### 그 밖의 변경
- **서체를 앱에 포함**: `assets/google_fonts/`에 Jua-Regular.ttf, GowunDodum-Regular.ttf(약 9MB, OFL)를 넣고 `GoogleFonts.config.allowRuntimeFetching = false`로 설정. 오프라인 첫 실행에도 가이드 서체가 나옴. OFL 라이선스는 앱 라이선스 목록에 등록함
- **실행 직후 배경**: Android `launch_background`·`windowBackground`, iOS LaunchScreen을 한지 미색으로 변경
- **앱 아이콘**: `tool/app_icon_test.dart`로 Android mipmap 5종, iOS AppIcon 15종을 생성
- **화면 미리보기 도구**: `tool/screens_preview_test.dart` → `build/preview/*.png`(9개 화면). 실기기 없이 디자인을 확인하는 용도
- `router.dart`: 시작 경로를 받을 수 있게 `buildRouter()`로 분리함

### 주의
- 상세 화면의 `『』` 겹낫표는 Jua에 글리프가 없어서 책 아이콘 + 제목으로 바꿈
- 스플래시의 '句節函' 한자는 Jua·고운돋움에 없음. 기기에서는 시스템 서체로 대체되어 보이지만, 미리보기 PNG에서는 빈 네모로 나옴
- 서체를 포함한 탓에 앱 크기가 약 9MB 늘어남

### 검증
- `flutter analyze`: 오류 0건
- `flutter test`: 25개 모두 통과
- `flutter build apk --debug`: 성공
- 미리보기 PNG 9장을 렌더링해 눈으로 확인함. 실기기에서는 아직 확인하지 않음

## 10. 기능 추가 — 부분 지정 · 마음에 새기기 · 보내기 (2026-10-27)

### 부분 지정(사진에서 원하는 부분만 추출)
- 흐름: 촬영 → OCR → **부분 지정**(`/capture/region`, 새 화면) → 문장 고르기 → 담기
- `OcrService.recognize`가 문장 대신 줄·단어(`OcrLine`/`OcrWord`)와 위치를 돌려줌. ML Kit `TextElement` 단위
- `lib/core/ocr_region.dart`: 영역 안 단어만 골라 문장으로 나누는 순수 함수. 단어 상자의 **중심**이 영역 안에 있으면 포함하므로 줄 중간을 잘라도 됨
- 화면: 사진 위를 손가락으로 끌어 네모를 그림. 읽은 단어 자리를 옅은 치자색으로, 네모 안 단어는 진하게 칠하고, 네모 밖은 어둡게 함. "전체 문장"은 지정 없이 진행
- 좌표: Flutter가 디코딩한 이미지 크기(EXIF 회전 반영)를 기준으로 함. ML Kit도 회전을 반영한 좌표를 준다는 전제. **실기기에서 세로·가로 사진 모두 확인 필요**

### 마음에 새기기('좋아요')
- 이름: 마음에 **새기다** + 낙관을 **새기다**. 표시는 '새김' 낙관
- 스키마 2: `quotes.cherished_at`(TEXT, nullable) 추가, `onUpgrade`에서 `addColumn`
- 상세: "마음에 새기기" 토글(새기면 다홍 버튼 + 카드 왼쪽 위에 '새김' 낙관이 0.4초 동안 찍힘). 홈: 새긴 카드는 '담' 대신 '새김' 낙관, "모든 구절 / 새긴 구절" 칩으로 거르기
- 새기기·거두기도 `updated_at`을 갱신하므로 Drive에 동기화됨. 동기화 형식 version은 1 그대로이고 `cherished_at`은 선택 필드로 추가함
- 주의: 이 기능이 없는 옛 앱이 다른 기기에서 더 늦게 고쳐 올리면, 그 구절의 새김이 지워질 수 있음

### 보내기(공유)
- 패키지 추가: `share_plus ^13.3.1`
- 상세의 "보내기" → 아래에서 올라오는 창에 구절 카드(한지 바탕, 구름 코너, '구절함' 낙관, 4:5) 미리보기
  - "카드로 보내기": 카드를 3배 해상도 PNG로 만들어 임시 폴더에 저장한 뒤 OS 공유 창으로 보냄(글도 함께)
  - "글로 보내기": `구절 / — 책 · 저자 · 쪽 / #구절함`
- 서버를 두지 않는다는 원칙에 맞춰 OS 공유 창을 씀. 링크로 열어 보는 공개 페이지나 다른 사람의 구절 피드는 서버가 있어야 해서 하지 않음

### 테스트·검증
- 새 테스트: `test/ocr_region_test.dart`(4), `test/migration_test.dart`(1, 스키마 1→2), DAO 새기기(1), 동기화 `cherished_at` 왕복(1) → 모두 32개 통과
- `flutter analyze`: 오류 0건
- 미리보기 추가: `10_region`, `11_home_cherished`, `12_detail_cherished`, `13_share`
- 실기기 확인은 아직 하지 않음: 부분 지정 좌표 정확도, 공유 창(특히 iPad의 sharePositionOrigin)

## 11. 문장 고치기 · 색 테마 · 입력 안내 (2026-10-27)

- **문장 고치기**: 문장 고르기 화면에서 문장마다 연필 버튼 → 아래 창에서 잘못 읽힌 글자를 고침. 모두 지우면 그 문장을 목록에서 빼고, 뒤 문장의 선택 번호를 당김(`CaptureSessionNotifier.editSentence`). 담기 화면에도 "담기 전에 한 번 더 고칠 수 있어요" 안내를 넣음
- **색 테마**: 설정 맨 위 "색 테마"에서 한지(기본) · 벚꽃 · 연두 · 하늘 · 라일락 · 유자 중에서 고름
  - `theme.dart`의 `_Palette` 상수를 `AppPalette` enum으로 바꿈. `buildAppTheme(palette)`. 위젯은 모두 `context.hanji`를 쓰므로 화면 코드는 바꾸지 않음
  - 고른 값은 앱 지원 폴더의 `app_settings.json`에 저장함(기기 전용, 동기화하지 않음). 앱을 시작하기 전에 읽어 첫 화면부터 그 색으로 보임
  - 앱 아이콘과 실행 직후 배경(launch screen)은 한지색 그대로 둠
- **입력 안내**: 책 제목·저자·쪽수는 원래 필수가 아니었음. 라벨에 "(선택)"을 붙여 분명하게 함
- 테스트 `test/capture_session_test.dart`(2) 추가 → 34개 통과. 미리보기 `14_sentence_edit`, `20_theme_*`, `21_settings_pink`

## 12. Google 연동 점검 · 다음 단계 (2026-10-27)

- **원인**: 저장소에 `google_oauth.json`이 없어 클라이언트 ID가 빈 값으로 빌드됨. Android는 `serverClientId`가 없으면 로그인 창도 띄우지 않고 실패함(`serverClientId must be provided on Android`). Drive 동기화 코드 자체에서는 문제를 찾지 못함
- **수정**: 설정이 빠진 빌드에서 연동을 켜거나 동기화하면 한국어로 이유를 알려 줌(`GoogleAuth.isConfigured`, `S.googleNotConfigured`)
- 이 PC의 디버그 키 SHA-1: `72:0C:AD:FC:99:32:FF:EC:18:8F:28:55:19:A0:F3:DA:D0:2B:79:82`
- 등록 없이도 Android 자동 백업은 켜져 있음(매니페스트에서 `allowBackup`을 끄지 않음). 실기기에서 확인하지는 않음

### 다음 단계
1. **Google Cloud 등록 안내**: Drive API 사용 설정, 동의 화면(drive.appdata, 테스트 사용자), 웹·Android 클라이언트 → `google_oauth.json` 만들기 → `--dart-define-from-file`로 빌드하고 실기기에서 연동·동기화 확인
2. **백업 파일 내보내기/가져오기**: 설정에서 `quotes.json`(동기화 형식과 같음)을 공유 창으로 내보내고, 파일을 골라 가져와 병합. Google 등록 없이 쓰는 백업 수단
