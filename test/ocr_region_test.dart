import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:gujeolham/core/ocr_region.dart';

/// 한 줄에 단어를 100px 간격(폭 80)으로 놓는다. y는 줄 번호 × 50.
OcrLine _line(int row, String text) => OcrLine([
  for (final (i, w) in text.split(' ').indexed)
    OcrWord(w, Rect.fromLTWH(i * 100.0, row * 50.0, 80, 30)),
]);

void main() {
  final lines = [
    _line(0, '그는 창밖을 보았다.'),
    _line(1, '무엇을 아끼는지가 곧'),
    _line(2, '그 사람이다. 소유는'),
    _line(3, '붙드는 일이다.'),
  ];

  test('전체는 줄을 이어 문장으로 나눈다', () {
    expect(sentencesOf(lines), [
      '그는 창밖을 보았다.',
      '무엇을 아끼는지가 곧 그 사람이다.',
      '소유는 붙드는 일이다.',
    ]);
  });

  test('영역에 걸친 줄만 쓴다', () {
    // 1~2번째 줄 전체
    final region = Rect.fromLTRB(0, 45, 400, 135);
    expect(sentencesInRegion(lines, region), [
      '무엇을 아끼는지가 곧 그 사람이다.',
      '소유는',
    ]);
  });

  test('줄 중간을 자르면 영역 안 단어만 쓴다(단어 중심 기준)', () {
    // 왼쪽 두 단어 폭(0~190)만. 세 번째 단어(200~280)의 중심 240은 밖.
    final region = Rect.fromLTRB(0, 45, 190, 135);
    expect(sentencesInRegion(lines, region), ['무엇을 아끼는지가 그 사람이다.']);
    expect(wordInRegion(lines[1].words[2], region), isFalse);
  });

  test('영역에 글자가 없으면 빈 목록', () {
    expect(sentencesInRegion(lines, const Rect.fromLTRB(500, 500, 600, 600)), isEmpty);
  });
}
