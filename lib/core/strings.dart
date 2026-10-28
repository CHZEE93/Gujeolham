/// 앱에서 사용하는 모든 한국어 문자열.
abstract final class S {
  static const appName = '구절함';
  static const appNameHanja = '句節函';

  // 홈
  static String quoteCount(int n) => '담긴 구절 $n';
  static const back = '뒤로';
  static const searchHint = '구절·책 제목·저자 검색';
  static const emptyQuotes = '아직 담긴 구절이 없습니다';
  static const emptySearch = '찾는 구절이 없습니다';
  static const emptyCherished = '아직 마음에 새긴 구절이 없습니다';
  static const filterAll = '모든 구절';
  static const filterCherished = '새긴 구절';
  static String cherishedCount(int n) => '새긴 구절 $n';
  static const fabCapture = '담기';
  static const settings = '설정';

  // 촬영
  static const captureTitle = '촬영';
  static const captureGuide = '마음에 닿은 문장이 있는 쪽을\n찍어 주세요';
  static const takePhoto = '카메라로 찍기';
  static const pickFromGallery = '갤러리에서 고르기';
  static const recognizing = '글자를 읽는 중입니다…';
  static const ocrFailed = '글자를 읽지 못했습니다. 다시 시도해 주세요.';
  static const ocrEmpty = '사진에서 글자를 찾지 못했습니다';
  static const imagePickFailed = '사진을 가져오지 못했습니다';

  // 부분 지정
  static const regionTitle = '부분 지정';
  static const regionGuide = '담고 싶은 부분을 손가락으로 그어 네모를 그리세요';
  static const regionEmpty = '네모 안에 읽은 글자가 없습니다. 다시 그려 주세요';
  static const regionAll = '전체 문장';
  static const regionButton = '이 부분만 읽기';
  static const regionReset = '다시 그리기';

  // 문장 고르기
  static const selectTitle = '문장 고르기';
  static const selectGuide = '담을 문장을 차례로 눌러 고르세요. 연필을 누르면 글자를 고칠 수 있어요';
  static const sentenceEdit = '문장 고치기';
  static const sentenceEditGuide = '잘못 읽힌 글자를 바로잡아 주세요. 모두 지우면 목록에서 빠집니다';
  static const sentenceEditDone = '고치기';
  static const saveEditGuide = '담기 전에 구절을 한 번 더 고칠 수 있어요';
  static String selectButton(int n) => '$n개 문장 담기';
  static const selectNone = '문장을 골라 주세요';

  // 담기
  static const saveTitle = '담기';
  static const contentLabel = '구절';
  static const bookTitleLabel = '책 제목 (선택)';
  static const authorLabel = '저자 (선택)';
  static const pageLabel = '쪽수 (선택)';
  static const memoLabel = '메모';
  static const saveButton = '함에 담기';
  static const contentRequired = '구절을 입력해 주세요';
  static const pageInvalid = '숫자만 입력해 주세요';
  static const saved = '담았습니다';
  static const sealDam = '담';
  static const sealAppName = '구절함';

  // 상세
  static const detailTitle = '구절';
  static const edit = '고치기';
  static const delete = '버리기';
  static const update = '고쳐 담기';
  static const cancel = '취소';
  static const deleteConfirmTitle = '구절을 버릴까요?';
  static const deleteConfirmBody = '버린 구절은 함에서 사라집니다.';
  static const originalImage = '원본 사진';
  static const imageMissing = '원본 사진을 찾을 수 없습니다';
  static const notFound = '구절을 찾을 수 없습니다';
  static String pageSuffix(int p) => '$p쪽';
  static const cherish = '마음에 새기기';
  static const cherished = '마음에 새김';
  static const uncherish = '새김 거두기';
  static const sealCherished = '새김';
  static const createdAtLabel = '담은 날';
  static const updatedAtLabel = '고친 날';

  // 보내기(공유)
  static const share = '보내기';
  static const shareTitle = '구절 보내기';
  static const shareModeCard = '카드';
  static const shareModeText = '글';
  static const shareCardBasic = '기본';
  static const shareCardPrestige = '프레스티지';
  static const shareSendCard = '이 카드 보내기';
  static const shareSendText = '이 글 보내기';
  static const shareFailed = '보내지 못했습니다';
  static const shareTag = '#구절함';

  // 설정
  static const settingsTitle = '설정';
  static const themeSection = '색 테마';
  static const googleSection = 'Google 드라이브 백업';
  static const googleLink = 'Google 계정 연동';
  static const googleLinkDesc = '내 Google 드라이브의 앱 전용 공간에 구절을 보관합니다';
  static const linkedEmail = '연동된 계정';
  static const notLinked = '연동되지 않음';
  static const lastSyncAt = '마지막 동기화';
  static const neverSynced = '아직 없음';
  static const syncNow = '지금 동기화';
  static const syncing = '동기화 중…';
  static const syncDone = '동기화했습니다';
  static const lastError = '마지막 오류';
  static const appSection = '앱 정보';
  static const appVersion = '앱 버전';
  static const signInFailed = 'Google 로그인에 실패했습니다';
  static const googleNotConfigured =
      '이 빌드에는 Google 연동 설정(클라이언트 ID)이 없습니다. google_oauth.json을 넣고 다시 빌드해 주세요';
  static const signInCanceled = '로그인을 취소했습니다';
  static const authorizationDenied = 'Drive 접근 권한이 허용되지 않았습니다';
  static const syncNotLinked = 'Google 계정이 연동되어 있지 않습니다';
  static const unlinkConfirmTitle = '연동을 해제할까요?';
  static const unlinkConfirmBody = '기기에 저장된 구절은 그대로 남습니다.';
  static const unlink = '해제';
  static const networkError = '네트워크에 연결할 수 없습니다';
  static const driveError = 'Google 드라이브 요청이 실패했습니다';
  static const remoteFormatError = '드라이브의 백업 파일을 읽을 수 없습니다';

  // 백업 파일
  static const backupSection = '백업 파일';
  static const backupDesc = '구절을 파일 하나로 내보내 두었다가, 다른 기기나 다시 설치한 앱에서 가져와 합칠 수 있습니다. 원본 사진은 담기지 않습니다';
  static const exportBackup = '내보내기';
  static const importBackup = '가져오기';
  static const exportFailed = '백업 파일을 만들지 못했습니다';
  static String importDone(int n) => '구절 $n개를 가져왔습니다';
  static const importNothing = '새로 가져올 구절이 없습니다';
  static const importFormatError = '구절함 백업 파일이 아니거나 읽을 수 없습니다';
  static const importNewerFormat = '더 새로운 버전의 앱에서 만든 파일입니다. 앱을 업데이트해 주세요';
  static const importFailed = '백업 파일을 가져오지 못했습니다';

  // 공통
  static const unknownError = '알 수 없는 오류가 발생했습니다';
  static const dateFormat = 'yyyy.MM.dd HH:mm';
  static const dateFormatShort = 'yyyy.MM.dd';
  static const locale = 'ko_KR';
}
