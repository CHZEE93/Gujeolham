import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/hanji_page.dart';
import '../../core/widgets/puffy.dart';
import '../../data/app_settings.dart';
import '../../sync/backup_service.dart';
import '../../sync/sync_controller.dart';
import '../../sync/sync_merge.dart';

final _packageInfoProvider = FutureProvider<PackageInfo>(
  (ref) => PackageInfo.fromPlatform(),
);

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _linking = false;
  bool _backupBusy = false;

  SyncController get _sync => ref.read(syncControllerProvider.notifier);
  BackupService get _backup => ref.read(backupServiceProvider);

  void _toast(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _toggle(bool on) async {
    if (on) {
      setState(() => _linking = true);
      final error = await _sync.link();
      if (!mounted) return;
      setState(() => _linking = false);
      _toast(error ?? S.syncDone);
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => const ConfirmDialog(
        title: S.unlinkConfirmTitle,
        body: S.unlinkConfirmBody,
        confirm: S.unlink,
      ),
    );
    if (ok == true) await _sync.unlink();
  }

  Future<void> _syncNow() async {
    final ok = await _sync.syncNow(interactive: true);
    if (!mounted) return;
    _toast(
      ok
          ? S.syncDone
          : (ref.read(syncControllerProvider).lastError ?? S.unknownError),
    );
  }

  Future<void> _runBackup(Future<void> Function() action) async {
    if (_backupBusy) return;
    setState(() => _backupBusy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _backupBusy = false);
    }
  }

  /// iPad에서는 공유 창을 띄울 기준 위치가 필요하다.
  Rect? _origin(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    return box == null ? null : box.localToGlobal(Offset.zero) & box.size;
  }

  Future<void> _export(Rect? origin) => _runBackup(() async {
    try {
      final file = await _backup.writeBackupFile();
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/json')],
          sharePositionOrigin: origin,
        ),
      );
    } catch (_) {
      if (mounted) _toast(S.exportFailed);
    }
  });

  Future<void> _import() => _runBackup(() async {
    String message;
    try {
      final picked = await FilePicker.pickFile();
      if (picked == null) return;
      final n = await _backup.importBytes(await picked.readAsBytes());
      if (n > 0) _sync.syncSilently();
      message = n > 0 ? S.importDone(n) : S.importNothing;
    } on UnsupportedRemoteFormat {
      message = S.importNewerFormat;
    } on FormatException {
      message = S.importFormatError;
    } catch (_) {
      message = S.importFailed;
    }
    if (mounted) _toast(message);
  });

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(syncControllerProvider);
    final version = ref.watch(_packageInfoProvider).value;
    final c = context.hanji;
    final busy = _linking || s.syncing;
    final fmt = DateFormat(S.dateFormat, S.locale);

    return HanjiPage(
      title: S.settingsTitle,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        children: [
          _SectionTitle(S.themeSection),
          const _PalettePicker(),
          const SizedBox(height: 28),
          _SectionTitle(S.googleSection),
          PuffyCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(S.googleLink, style: context.text.titleSmall),
                            const SizedBox(height: 2),
                            Text(
                              S.googleLinkDesc,
                              style: context.text.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: s.linked,
                        onChanged: (!s.ready || busy) ? null : _toggle,
                      ),
                    ],
                  ),
                ),
                const _Line(),
                _Row(label: S.linkedEmail, value: s.email ?? S.notLinked),
                const _Line(),
                _Row(
                  label: S.lastSyncAt,
                  value: s.lastSyncAt == null
                      ? S.neverSynced
                      : fmt.format(s.lastSyncAt!.toLocal()),
                ),
                if (s.lastError != null) ...[
                  const _Line(),
                  _Row(
                    label: S.lastError,
                    value: s.lastError!,
                    valueColor: c.dahong,
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                  child: PillButton(
                    label: busy ? S.syncing : S.syncNow,
                    icon: Icons.sync_rounded,
                    tone: PillTone.dark,
                    height: 48,
                    onPressed: (!s.linked || busy) ? null : _syncNow,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _SectionTitle(S.backupSection),
          PuffyCard(
            padding: const EdgeInsets.fromLTRB(20, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(S.backupDesc, style: context.text.bodySmall),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Builder(
                        builder: (context) => PillButton(
                          label: S.exportBackup,
                          icon: Icons.upload_file_rounded,
                          tone: PillTone.light,
                          height: 48,
                          onPressed: _backupBusy
                              ? null
                              : () => _export(_origin(context)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: PillButton(
                        label: S.importBackup,
                        icon: Icons.download_rounded,
                        tone: PillTone.light,
                        height: 48,
                        onPressed: _backupBusy ? null : _import,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _SectionTitle(S.appSection),
          PuffyCard(
            padding: EdgeInsets.zero,
            child: _Row(
              label: S.appVersion,
              value: version == null
                  ? '-'
                  : '${version.version} (${version.buildNumber})',
            ),
          ),
        ],
      ),
    );
  }
}

/// 색 테마 고르기. 한 줄에 셋씩, 테마마다 바탕 위에 주요·보조 색 점을 보여 준다.
class _PalettePicker extends ConsumerWidget {
  const _PalettePicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(paletteProvider);
    return LayoutBuilder(
      builder: (context, box) {
        const gap = 10.0;
        final width = (box.maxWidth - gap * 2) / 3;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final p in AppPalette.values)
              SizedBox(
                width: width,
                child: _PaletteTile(
                  palette: p,
                  selected: p == current,
                  onTap: () => ref.read(paletteProvider.notifier).select(p),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PaletteTile extends StatelessWidget {
  const _PaletteTile({
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final AppPalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = palette.colors;
    final c = context.hanji;
    Widget dot(Color color, double size) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );

    return Semantics(
      button: true,
      selected: selected,
      label: palette.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
          decoration: BoxDecoration(
            color: p.hanji,
            borderRadius: BorderRadius.circular(kCardRadius - 4),
            border: Border.all(
              color: selected ? c.galmuk : p.line,
              width: selected ? 2 : 1,
            ),
            boxShadow: [BoxShadow(color: p.cardDrop, offset: const Offset(0, kDrop))],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  dot(p.dahong, 22),
                  const SizedBox(width: 4),
                  dot(p.ok, 14),
                  const SizedBox(width: 3),
                  dot(p.chija, 14),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (selected) ...[
                    Icon(Icons.check_rounded, size: 15, color: p.galmuk),
                    const SizedBox(width: 2),
                  ],
                  Text(
                    palette.label,
                    style: juaStyle(
                      context.text.titleSmall?.copyWith(color: p.galmuk),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 8, bottom: 10),
    child: Text(text, style: context.text.titleSmall),
  );
}

class _Line extends StatelessWidget {
  const _Line();

  @override
  Widget build(BuildContext context) =>
      const Divider(indent: 20, endIndent: 20);
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(label, style: context.text.bodyMedium),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: context.text.bodyMedium?.copyWith(
              color: valueColor ?? context.hanji.galmukSub,
            ),
          ),
        ),
      ],
    ),
  );
}
