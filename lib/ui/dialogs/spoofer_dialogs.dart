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
  final controller = TextEditingController(text: suggestedName);
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Save route'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          hintText: 'Route name',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}

Future<String?> showRenameWaypointDialog({
  required BuildContext context,
  required String currentName,
}) async {
  final controller = TextEditingController();
  final focusNode = FocusNode();
  var canSave = false;
  final result = await showDialog<String>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          title: const Text('Rename waypoint'),
          content: TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: true,
            decoration: InputDecoration(
              hintText: currentName,
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) {
              final nextCanSave = value.trim().isNotEmpty;
              if (nextCanSave != canSave) {
                setDialogState(() {
                  canSave = nextCanSave;
                });
              }
            },
            onSubmitted: (value) {
              if (value.trim().isEmpty) {
                return;
              }
              Navigator.of(context).pop(value.trim());
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: canSave
                  ? () => Navigator.of(context).pop(controller.text.trim())
                  : null,
              child: const Text('Save'),
            ),
          ],
        );
      },
    ),
  );
  focusNode.dispose();
  controller.dispose();
  return result;
}

Future<void> showTermsOfUseDialog({
  required BuildContext context,
  required Future<void> Function() onAgree,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => PopScope<void>(
      canPop: false,
      child: AlertDialog(
        title: const Text('Terms of Use'),
        content: const SingleChildScrollView(
          child: Text(
            'This tool is for testing and development only. You are responsible for using it legally and with permission. Location accuracy is not guaranteed, and you assume all risks from use.',
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
