import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../core/sentence_splitter.dart';

/// ML Kit 한국어 인식 → 문장 목록.
class OcrService {
  Future<List<String>> recognizeSentences(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.korean);
    try {
      final result = await recognizer.processImage(
        InputImage.fromFilePath(imagePath),
      );
      final lines = [
        for (final block in result.blocks)
          for (final line in block.lines) line.text,
      ];
      return SentenceSplitter.fromLines(lines);
    } finally {
      await recognizer.close();
    }
  }
}

final ocrServiceProvider = Provider<OcrService>((ref) => OcrService());
