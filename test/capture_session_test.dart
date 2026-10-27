import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gujeolham/core/ocr_region.dart';
import 'package:gujeolham/features/capture/capture_session.dart';

void main() {
  late ProviderContainer c;
  CaptureSessionNotifier notifier() => c.read(captureSessionProvider.notifier);
  CaptureSession session() => c.read(captureSessionProvider);

  setUp(() {
    c = ProviderContainer();
    notifier().start('a.jpg', [
      for (final s in ['첫 문장.', '두번째 뮨장.', '셋째 문장.'])
        OcrLine([OcrWord(s, Rect.zero)]),
    ]);
  });
  tearDown(() => c.dispose());

  test('문장을 고치면 선택 순서는 그대로, 담을 글에 고친 내용이 들어간다', () {
    notifier()
      ..toggle(1)
      ..toggle(0)
      ..editSentence(1, '  두번째 문장.  ');
    expect(session().sentences[1], '두번째 문장.');
    expect(session().selected, [1, 0]);
    expect(session().joinedSelection, '두번째 문장. 첫 문장.');
  });

  test('모두 지우면 그 문장이 빠지고 뒤 문장의 선택 번호가 당겨진다', () {
    notifier()
      ..toggle(2)
      ..toggle(0)
      ..toggle(1)
      ..editSentence(0, '   ');
    expect(session().sentences, ['두번째 뮨장.', '셋째 문장.']);
    expect(session().selected, [1, 0]);
    expect(session().joinedSelection, '셋째 문장. 두번째 뮨장.');
  });
}
