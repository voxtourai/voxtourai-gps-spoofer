import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

Future<void> showAppInfoDialog({
  required BuildContext context,
  required PackageInfo? packageInfo,
}) async {
  await showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('App info'),
        content: packageInfo == null
            ? const Text('Version info unavailable.')
            : DefaultTextStyle.merge(
                style: Theme.of(context).textTheme.bodySmall,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Version: ${packageInfo.version}'),
                    Text('Build: ${packageInfo.buildNumber}'),
                    Text('App ID: ${packageInfo.packageName}'),
                  ],
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}

Future<bool> showSpooferConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String actionLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(actionLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<String?> showSaveRouteDialog({
  required BuildContext context,
  required String suggestedName,
}) async {
  return showDialog<String>(
    context: context,
    builder: (context) => _SaveRouteDialog(suggestedName: suggestedName),
  );
}

Future<String?> showRenameWaypointDialog({
  required BuildContext context,
  required String currentName,
}) async {
  return showDialog<String>(
    context: context,
    builder: (context) => _RenameWaypointDialog(currentName: currentName),
  );
}

Future<void> showTermsOfUseDialog({
  required BuildContext context,
  required Future<void> Function() onAgree,
  required Future<void> Function() onOpenPrivacyPolicy,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => PopScope<void>(
      canPop: false,
      child: AlertDialog(
        title: const Text('Terms of Use'),
        content: SingleChildScrollView(
          child: DefaultTextStyle.merge(
            style: Theme.of(context).textTheme.bodyMedium,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This tool is intended for testing and development use only.',
                ),
                const SizedBox(height: 10),
                const Text(
                  'You are responsible for using it lawfully, with permission, and in compliance with any applicable policies or restrictions.',
                ),
                const SizedBox(height: 10),
                const Text(
                  'Mocked or simulated location results may be inaccurate, interrupted, or unavailable, and you assume the risks of relying on them.',
                ),
                const SizedBox(height: 10),
                const Text(
                  'By continuing, you acknowledge and accept the Privacy Policy.',
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: onOpenPrivacyPolicy,
                    child: const Text('View Privacy Policy'),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () async {
              await onAgree();
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('I agree'),
          ),
        ],
      ),
    ),
  );
}

class _SaveRouteDialog extends StatefulWidget {
  const _SaveRouteDialog({required this.suggestedName});

  final String suggestedName;

  @override
  State<_SaveRouteDialog> createState() => _SaveRouteDialogState();
}

class _SaveRouteDialogState extends State<_SaveRouteDialog> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.suggestedName);
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _close(String? value) {
    _focusNode.unfocus();
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Save route'),
      content: TextField(
        controller: _controller,
        focusNode: _focusNode,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Route name',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (value) => _close(value.trim()),
      ),
      actions: [
        TextButton(onPressed: () => _close(null), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => _close(_controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _RenameWaypointDialog extends StatefulWidget {
  const _RenameWaypointDialog({required this.currentName});

  final String currentName;

  @override
  State<_RenameWaypointDialog> createState() => _RenameWaypointDialogState();
}

class _RenameWaypointDialogState extends State<_RenameWaypointDialog> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _canSave = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleChanged(String value) {
    final nextCanSave = value.trim().isNotEmpty;
    if (nextCanSave == _canSave) {
      return;
    }
    setState(() {
      _canSave = nextCanSave;
    });
  }

  void _close(String? value) {
    _focusNode.unfocus();
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename waypoint'),
      content: TextField(
        controller: _controller,
        focusNode: _focusNode,
        autofocus: true,
        decoration: InputDecoration(
          hintText: widget.currentName,
          border: const OutlineInputBorder(),
        ),
        onChanged: _handleChanged,
        onSubmitted: (value) {
          final trimmed = value.trim();
          if (trimmed.isEmpty) {
            return;
          }
          _close(trimmed);
        },
      ),
      actions: [
        TextButton(onPressed: () => _close(null), child: const Text('Cancel')),
        FilledButton(
          onPressed: _canSave ? () => _close(_controller.text.trim()) : null,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
