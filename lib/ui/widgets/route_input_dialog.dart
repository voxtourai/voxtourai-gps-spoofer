import 'package:flutter/material.dart';

typedef PolylineDetector = String? Function(String input);

class RouteInputDialog extends StatefulWidget {
  const RouteInputDialog({
    super.key,
    required this.initialValue,
    required this.sampleRoute,
    required this.detectPolyline,
    this.onDemoFilled,
  });

  final String initialValue;
  final String sampleRoute;
  final PolylineDetector detectPolyline;
  final VoidCallback? onDemoFilled;

  @override
  State<RouteInputDialog> createState() => _RouteInputDialogState();
}

class _RouteInputDialogState extends State<RouteInputDialog> {
  late final TextEditingController _controller;
  String? _detectedPolyline;

  bool get _isEmpty => _controller.text.trim().isEmpty;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _controller.addListener(_onTextChanged);
    _onTextChanged();
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final trimmed = _controller.text.trim();
    setState(() {
      _detectedPolyline = trimmed.isEmpty
          ? null
          : widget.detectPolyline(trimmed);
    });
  }

  void _fillDemo() {
    _controller.text = widget.sampleRoute;
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
    widget.onDemoFilled?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      title: Text(
        'Load route',
        style: theme.textTheme.titleMedium?.copyWith(fontSize: 16),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: 'Paste encoded polyline or Routes API JSON',
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.fromLTRB(12, 10, 12, 10),
            ),
          ),
          if (_isEmpty) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Input required to load a route.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ] else if (_detectedPolyline != null) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Polyline detected.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Clear',
          icon: const Icon(Icons.delete_outline),
          onPressed: _controller.clear,
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _fillDemo, child: const Text('Demo')),
        FilledButton(
          onPressed: _isEmpty
              ? null
              : () => Navigator.of(context).pop(_controller.text),
          child: const Text('Load'),
        ),
      ],
    );
  }
}
