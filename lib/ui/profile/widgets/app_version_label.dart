import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../core/themes/themes.dart';

class AppVersionLabel extends StatefulWidget {
  const AppVersionLabel({super.key});

  @override
  State<AppVersionLabel> createState() => _AppVersionLabelState();
}

class _AppVersionLabelState extends State<AppVersionLabel> {
  PackageInfo? _info;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then(
      (info) {
        if (!mounted) return;
        setState(() => _info = info);
      },
      onError: (_) {
        // Plugin not registered yet (e.g. hot restart after add) — render empty.
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final l10n = AppLocalizations.of(context);

    final info = _info;
    final label = info == null
        ? ''
        : l10n.profileAppVersion(info.appName, info.version, info.buildNumber);

    return SizedBox(
      height: 24,
      child: Center(
        child: Text(
          label,
          style: text.bodySmall?.copyWith(color: colors.textDimmer),
        ),
      ),
    );
  }
}
