import 'package:flutter/material.dart';

import '../strings.dart';
import '../theme.dart';
import 'hami.dart';
import 'puffy.dart';

/// 함이가 묻는 둥근 확인 대화상자. 확인하면 true를 돌려준다.
class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.title,
    required this.body,
    required this.confirm,
  });

  final String title;
  final String body;
  final String confirm;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Hami(size: 64),
            const SizedBox(height: 12),
            Text(title, style: context.text.titleMedium),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium?.copyWith(
                color: context.hanji.galmukSub,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: PillButton(
                    label: S.cancel,
                    tone: PillTone.light,
                    height: 46,
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PillButton(
                    label: confirm,
                    height: 46,
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
