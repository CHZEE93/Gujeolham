import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/router.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../core/widgets/hami.dart';
import '../../core/widgets/hanji_page.dart';
import '../../core/widgets/puffy.dart';
import 'capture_session.dart';
import 'ocr_service.dart';

class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  final _picker = ImagePicker();
  bool _busy = false;

  Future<void> _pick(ImageSource source) async {
    final messenger = ScaffoldMessenger.of(context);
    XFile? file;
    try {
      file = await _picker.pickImage(source: source, maxWidth: 3000);
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text(S.imagePickFailed)));
      return;
    }
    if (file == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final sentences = await ref
          .read(ocrServiceProvider)
          .recognizeSentences(file.path);
      if (!mounted) return;
      if (sentences.isEmpty) {
        messenger.showSnackBar(const SnackBar(content: Text(S.ocrEmpty)));
        return;
      }
      ref.read(captureSessionProvider.notifier).start(file.path, sentences);
      context.push(Routes.select);
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text(S.ocrFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return HanjiPage(
      title: S.captureTitle,
      bottom: _busy
          ? null
          : BottomBar(
              child: Column(
                children: [
                  PillButton(
                    label: S.takePhoto,
                    icon: Icons.photo_camera_rounded,
                    onPressed: () => _pick(ImageSource.camera),
                  ),
                  const SizedBox(height: 10),
                  PillButton(
                    label: S.pickFromGallery,
                    icon: Icons.photo_library_rounded,
                    tone: PillTone.light,
                    onPressed: () => _pick(ImageSource.gallery),
                  ),
                ],
              ),
            ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _busy ? const _ReadingHami() : const Hami(size: 140, lidOpen: 0.35),
            const SizedBox(height: 24),
            Text(
              _busy ? S.recognizing : S.captureGuide,
              textAlign: TextAlign.center,
              style: context.text.bodyLarge?.copyWith(
                color: context.hanji.galmukSub,
              ),
            ),
            if (_busy) ...[
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: const SizedBox(
                  width: 140,
                  child: LinearProgressIndicator(minHeight: 6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 글자를 읽는 동안 뚜껑을 들썩이는 함이.
class _ReadingHami extends StatefulWidget {
  const _ReadingHami();

  @override
  State<_ReadingHami> createState() => _ReadingHamiState();
}

class _ReadingHamiState extends State<_ReadingHami>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, _) => Hami(
      size: 140,
      lidOpen: 0.1 + Curves.easeInOut.transform(_c.value) * 0.3,
    ),
  );
}
