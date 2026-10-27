import 'dart:ui';

import 'sentence_splitter.dart';

/// OCR이 읽은 단어 하나와 사진 위 위치(원본 픽셀 좌표).
class OcrWord {
  const OcrWord(this.text, this.box);

  final String text;
  final Rect box;
}

/// OCR이 읽은 한 줄. 단어는 왼쪽부터 차례대로.
class OcrLine {
  const OcrLine(this.words);

  final List<OcrWord> words;

  String get text => words.map((w) => w.text).join(' ');
}

/// 사진 전체의 문장.
List<String> sentencesOf(List<OcrLine> lines) =>
    SentenceSplitter.fromLines([for (final l in lines) l.text]);

/// [region] 안에 있는 단어인지. 단어 상자의 중심이 영역 안에 들어오면 포함한다.
bool wordInRegion(OcrWord w, Rect region) => region.contains(w.box.center);

/// [region](원본 픽셀 좌표) 안의 단어만 남겨 문장으로 나눈다.
/// 줄 중간을 자르면 그 줄에서도 영역 안 단어만 쓴다.
List<String> sentencesInRegion(List<OcrLine> lines, Rect region) {
  final picked = <String>[];
  for (final line in lines) {
    final words = [
      for (final w in line.words)
        if (wordInRegion(w, region)) w.text,
    ];
    if (words.isNotEmpty) picked.add(words.join(' '));
  }
  return SentenceSplitter.fromLines(picked);
}
