import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../core/ocr_region.dart';

/// ML Kit 한국어 인식 → 줄·단어와 위치.
class OcrService {
  Future<List<OcrLine>> recognize(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.korean);
    try {
      final result = await recognizer.processImage(
        InputImage.fromFilePath(imagePath),
      );
      return [
        for (final block in result.blocks)
          for (final line in block.lines)
            OcrLine([
              for (final e in line.elements)
                if (e.text.trim().isNotEmpty) OcrWord(e.text, e.boundingBox),
            ]),
      ].where((l) => l.words.isNotEmpty).toList();
    } finally {
      await recognizer.close();
    }
  }
}

final ocrServiceProvider = Provider<OcrService>((ref) => OcrService());
