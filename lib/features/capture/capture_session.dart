import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 촬영 → 문장 고르기 → 담기 흐름 동안 유지되는 상태.
class CaptureSession {
  const CaptureSession({
    this.imagePath,
    this.sentences = const [],
    this.selected = const [],
  });

  /// image_picker가 돌려준 임시 파일 경로(저장 시 앱 디렉토리로 복사).
  final String? imagePath;
  final List<String> sentences;

  /// 선택된 문장 인덱스. 선택한 순서를 유지한다.
  final List<int> selected;

  String get joinedSelection =>
      selected.map((i) => sentences[i]).join(' ');

  CaptureSession copyWith({List<int>? selected}) => CaptureSession(
    imagePath: imagePath,
    sentences: sentences,
    selected: selected ?? this.selected,
  );
}

class CaptureSessionNotifier extends Notifier<CaptureSession> {
  @override
  CaptureSession build() => const CaptureSession();

  void start(String imagePath, List<String> sentences) =>
      state = CaptureSession(imagePath: imagePath, sentences: sentences);

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
