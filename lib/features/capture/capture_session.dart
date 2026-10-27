import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ocr_region.dart';

/// 촬영 → 부분 지정 → 문장 고르기 → 담기 흐름 동안 유지되는 상태.
class CaptureSession {
  const CaptureSession({
    this.imagePath,
    this.lines = const [],
    this.sentences = const [],
    this.selected = const [],
  });

  /// image_picker가 돌려준 임시 파일 경로(저장 시 앱 디렉토리로 복사).
  final String? imagePath;

  /// OCR이 읽은 줄과 단어 위치(부분 지정용).
  final List<OcrLine> lines;
  final List<String> sentences;

  /// 선택된 문장 인덱스. 선택한 순서를 유지한다.
  final List<int> selected;

  String get joinedSelection =>
      selected.map((i) => sentences[i]).join(' ');

  CaptureSession copyWith({List<String>? sentences, List<int>? selected}) =>
      CaptureSession(
        imagePath: imagePath,
        lines: lines,
        sentences: sentences ?? this.sentences,
        selected: selected ?? this.selected,
      );
}

class CaptureSessionNotifier extends Notifier<CaptureSession> {
  @override
  CaptureSession build() => const CaptureSession();

  void start(String imagePath, List<OcrLine> lines) => state = CaptureSession(
    imagePath: imagePath,
    lines: lines,
    sentences: sentencesOf(lines),
  );

  /// 문장 후보를 [region](원본 픽셀 좌표) 안으로 좁힌다. null이면 사진 전체.
  void useRegion(Rect? region) => state = state.copyWith(
    sentences: region == null
        ? sentencesOf(state.lines)
        : sentencesInRegion(state.lines, region),
    selected: const [],
  );

  /// 잘못 읽힌 문장을 고친다. 비우면 그 문장을 목록에서 뺀다.
  void editSentence(int index, String text) {
    final t = text.trim();
    final sentences = [...state.sentences];
    if (t.isNotEmpty) {
      sentences[index] = t;
      state = state.copyWith(sentences: sentences);
      return;
    }
    sentences.removeAt(index);
    state = state.copyWith(
      sentences: sentences,
      selected: [
        for (final i in state.selected)
          if (i != index) i > index ? i - 1 : i,
      ],
    );
  }

  void toggle(int index) {
    final next = [...state.selected];
    if (!next.remove(index)) next.add(index);
    state = state.copyWith(selected: next);
  }

  void clear() => state = const CaptureSession();
}

final captureSessionProvider =
    NotifierProvider<CaptureSessionNotifier, CaptureSession>(
      CaptureSessionNotifier.new,
    );
