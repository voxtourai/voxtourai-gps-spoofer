import 'package:flutter/material.dart';

typedef PolylineDetector = String? Function(String input);
typedef RouteInputFilePicker = Future<RouteInputPickedFile?> Function();
typedef RouteInputFileLoaded = void Function(String? fileName);

class RouteInputPickedFile {
  const RouteInputPickedFile({required this.text, this.name});

  final String text;
  final String? name;
}

class RouteInputDialog extends StatefulWidget {
  const RouteInputDialog({
    super.key,
    required this.initialValue,
    required this.sampleRoute,
    required this.detectPolyline,
    this.onDemoFilled,
    this.onFileLoaded,
    this.pickFile,
  });

  final String initialValue;
  final String sampleRoute;
  final PolylineDetector detectPolyline;
  final VoidCallback? onDemoFilled;
  final RouteInputFileLoaded? onFileLoaded;
  final RouteInputFilePicker? pickFile;

  @override
  State<RouteInputDialog> createState() => _RouteInputDialogState();
}

class _RouteInputDialogState extends State<RouteInputDialog> {
  late final TextEditingController _controller;
  String? _detectedPolyline;
  bool _showEmptyError = false;
  bool _pickingFile = false;

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
      if (trimmed.isNotEmpty) {
        _showEmptyError = false;
      }
      _detectedPolyline = trimmed.isEmpty
          ? null
          : widget.detectPolyline(trimmed);
    });
  }

  void _clearInput() {
    _controller.clear();
    setState(() {
      _showEmptyError = false;
    });
  }

  void _fillDemo() {
    _controller.text = widget.sampleRoute;
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
    widget.onDemoFilled?.call();
  }

  Future<void> _pickFile() async {
    final pickFile = widget.pickFile;
    if (pickFile == null || _pickingFile) {
      return;
    }

    setState(() {
      _pickingFile = true;
    });

    try {
      final result = await pickFile();
      if (!mounted || result == null) {
        return;
      }
      _controller.text = result.text;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
      setState(() {
        _showEmptyError = false;
      });
      widget.onFileLoaded?.call(result.name);
    } finally {
      if (mounted) {
        setState(() {
          _pickingFile = false;
        });
      }
    }
  }

  void _submit() {
    if (_isEmpty) {
      setState(() {
        _showEmptyError = true;
      });
      return;
    }
    Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.sizeOf(context);
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final maxDialogHeight = media.height - viewInsets.bottom - 40;
    final dialogWidth = media.width > 460 ? 420.0 : media.width - 40;
    final dialogHeight = maxDialogHeight > 360 ? 360.0 : maxDialogHeight;
    const actionGap = 6.0;
    final utilityButtonStyle = TextButton.styleFrom(
      visualDensity: VisualDensity.compact,
      minimumSize: const Size(0, 38),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    final outlinedUtilityButtonStyle = OutlinedButton.styleFrom(
      visualDensity: VisualDensity.compact,
      minimumSize: const Size(0, 38),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    final primaryButtonStyle = FilledButton.styleFrom(
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      minimumSize: const Size(0, 38),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Load route',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close),
                    splashRadius: 18,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  expands: true,
                  minLines: null,
                  maxLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    hintText: 'Paste encoded polyline or Routes API JSON',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.fromLTRB(12, 10, 12, 10),
                  ),
                ),
              ),
              if (_showEmptyError) ...[
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
              const SizedBox(height: 10),
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 36,
                    child: IconButton(
                      tooltip: 'Clear',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 24,
                        height: 36,
                      ),
                      splashRadius: 16,
                      icon: const Icon(Icons.delete_outline),
                      onPressed: _clearInput,
                    ),
                  ),
                  const SizedBox(width: actionGap),
                  Expanded(
                    child: TextButton.icon(
                      style: utilityButtonStyle,
                      onPressed: _fillDemo,
                      icon: const Icon(Icons.bolt_outlined, size: 14),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Demo', softWrap: false),
                      ),
                    ),
                  ),
                  if (widget.pickFile != null) const SizedBox(width: actionGap),
                  if (widget.pickFile != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        style: outlinedUtilityButtonStyle,
                        onPressed: _pickingFile ? null : _pickFile,
                        icon: _pickingFile
                            ? const SizedBox.square(
                                dimension: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.upload_file_outlined, size: 14),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _pickingFile ? 'Loading...' : 'File',
                            softWrap: false,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: actionGap),
                  Expanded(
                    child: FilledButton(
                      style: primaryButtonStyle,
                      onPressed: _submit,
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Load', softWrap: false),
                      ),
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
