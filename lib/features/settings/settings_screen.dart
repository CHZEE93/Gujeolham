import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/hanji_page.dart';
import '../../core/widgets/puffy.dart';
import '../../sync/sync_controller.dart';

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

  SyncController get _sync => ref.read(syncControllerProvider.notifier);

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
