import 'package:flutter/material.dart';

import '../../bloc/settings/spoofer_settings_state.dart';

typedef SettingsBoolChanged = void Function(bool value);
typedef SettingsDarkModeChanged = void Function(DarkModeSetting value);
typedef SettingsAsyncVoidCallback = Future<void> Function();

Future<void> showSpooferSettingsSideSheet({
  required BuildContext context,
  required SpooferSettingsState initialSettings,
  required SettingsBoolChanged onShowSetupBarChanged,
  required SettingsBoolChanged onShowDebugPanelChanged,
  required SettingsBoolChanged onShowMockMarkerChanged,
  required SettingsDarkModeChanged onDarkModeChanged,
  required SettingsAsyncVoidCallback onDisableMockLocation,
  required SettingsAsyncVoidCallback onOpenDeveloperOptions,
  required SettingsAsyncVoidCallback onOpenPrivacyPolicy,
  required VoidCallback onRunSetupChecks,
  required WidgetBuilder debugPanelBuilder,
}) async {
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Settings',
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _SpooferSettingsSideSheet(
        initialSettings: initialSettings,
        onShowSetupBarChanged: onShowSetupBarChanged,
        onShowDebugPanelChanged: onShowDebugPanelChanged,
        onShowMockMarkerChanged: onShowMockMarkerChanged,
        onDarkModeChanged: onDarkModeChanged,
        onDisableMockLocation: onDisableMockLocation,
        onOpenDeveloperOptions: onOpenDeveloperOptions,
        onOpenPrivacyPolicy: onOpenPrivacyPolicy,
        onRunSetupChecks: onRunSetupChecks,
        debugPanelBuilder: debugPanelBuilder,
      );
    },
    transitionBuilder: (context, anim, secondaryAnimation, child) {
      final offset = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
      return SlideTransition(position: offset, child: child);
    },
  );
}

class _SpooferSettingsSideSheet extends StatefulWidget {
  const _SpooferSettingsSideSheet({
    required this.initialSettings,
    required this.onShowSetupBarChanged,
    required this.onShowDebugPanelChanged,
    required this.onShowMockMarkerChanged,
    required this.onDarkModeChanged,
    required this.onDisableMockLocation,
    required this.onOpenDeveloperOptions,
    required this.onOpenPrivacyPolicy,
    required this.onRunSetupChecks,
    required this.debugPanelBuilder,
  });

  final SpooferSettingsState initialSettings;
  final SettingsBoolChanged onShowSetupBarChanged;
  final SettingsBoolChanged onShowDebugPanelChanged;
  final SettingsBoolChanged onShowMockMarkerChanged;
  final SettingsDarkModeChanged onDarkModeChanged;
  final SettingsAsyncVoidCallback onDisableMockLocation;
  final SettingsAsyncVoidCallback onOpenDeveloperOptions;
  final SettingsAsyncVoidCallback onOpenPrivacyPolicy;
  final VoidCallback onRunSetupChecks;
  final WidgetBuilder debugPanelBuilder;

  @override
  State<_SpooferSettingsSideSheet> createState() =>
      _SpooferSettingsSideSheetState();
}

class _SpooferSettingsSideSheetState extends State<_SpooferSettingsSideSheet> {
  late bool _showSetupBar;
  late bool _showDebugPanel;
  late bool _showMockMarker;
  late DarkModeSetting _darkModeSetting;

  static const _compactDensity = VisualDensity(horizontal: -2, vertical: -4);

  @override
  void initState() {
    super.initState();
    final state = widget.initialSettings;
    _showSetupBar = state.showSetupBar;
    _showDebugPanel = state.showDebugPanel;
    _showMockMarker = state.showMockMarker;
    _darkModeSetting = state.darkModeSetting;
  }

  String _darkModeLabel(DarkModeSetting setting) {
    switch (setting) {
      case DarkModeSetting.on:
        return 'On';
      case DarkModeSetting.uiOnly:
        return 'UI only';
      case DarkModeSetting.mapOnly:
        return 'Map only';
      case DarkModeSetting.off:
        return 'Off';
    }
  }

  @override
  Widget build(BuildContext context) {
    final denseStyle = Theme.of(context).textTheme.bodySmall;
    return Align(
      alignment: Alignment.centerRight,
      child: SafeArea(
        child: Material(
          elevation: 6,
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.horizontal(
            left: Radius.circular(12),
          ),
          child: SizedBox(
            width: 280,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              children: [
                Row(
                  children: [
                    Text(
                      'Settings',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      splashRadius: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _buildToggle(
                  title: 'Show setup bar',
                  value: _showSetupBar,
                  denseStyle: denseStyle,
                  onChanged: (value) {
                    setState(() {
                      _showSetupBar = value;
                    });
                    widget.onShowSetupBarChanged(value);
                  },
                ),
                _buildToggle(
                  title: 'Show debug panel',
                  value: _showDebugPanel,
                  denseStyle: denseStyle,
                  onChanged: (value) {
                    setState(() {
                      _showDebugPanel = value;
                    });
                    widget.onShowDebugPanelChanged(value);
                  },
                ),
                _buildToggle(
                  title: 'Show mocked marker',
                  value: _showMockMarker,
                  denseStyle: denseStyle,
                  onChanged: (value) {
                    setState(() {
                      _showMockMarker = value;
                    });
                    widget.onShowMockMarkerChanged(value);
                  },
                ),
                ListTile(
                  dense: true,
                  visualDensity: _compactDensity,
                  contentPadding: EdgeInsets.zero,
                  title: Text('Dark mode', style: denseStyle),
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<DarkModeSetting>(
                      isDense: true,
                      value: _darkModeSetting,
                      items: DarkModeSetting.values
                          .map(
                            (setting) => DropdownMenuItem(
                              value: setting,
                              child: Text(_darkModeLabel(setting)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _darkModeSetting = value;
                        });
                        widget.onDarkModeChanged(value);
                      },
                    ),
                  ),
                ),
                const Divider(height: 16),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    visualDensity: _compactDensity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    textStyle: Theme.of(context).textTheme.bodySmall,
                  ),
                  onPressed: widget.onDisableMockLocation,
                  icon: const Icon(Icons.location_off),
                  label: const Text('Disable mock location'),
                ),
                const SizedBox(height: 6),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    visualDensity: _compactDensity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    textStyle: Theme.of(context).textTheme.bodySmall,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onRunSetupChecks();
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Run setup checks'),
                ),
                const SizedBox(height: 6),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    visualDensity: _compactDensity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    textStyle: Theme.of(context).textTheme.bodySmall,
                  ),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await widget.onOpenDeveloperOptions();
                  },
                  icon: const Icon(Icons.developer_mode_outlined),
                  label: const Text('Open developer options'),
                ),
                const SizedBox(height: 6),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    visualDensity: _compactDensity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    textStyle: Theme.of(context).textTheme.bodySmall,
                  ),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await widget.onOpenPrivacyPolicy();
                  },
                  icon: const Icon(Icons.privacy_tip_outlined),
                  label: const Text('Privacy policy'),
                ),
                if (_showDebugPanel) ...[
                  const Divider(height: 16),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: widget.debugPanelBuilder(context),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggle({
    required String title,
    required bool value,
    required TextStyle? denseStyle,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      dense: true,
      visualDensity: _compactDensity,
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: denseStyle),
      trailing: Transform.scale(
        scale: 0.85,
        child: Switch(
          value: value,
          onChanged: onChanged,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      onTap: () => onChanged(!value),
    );
  }
}
