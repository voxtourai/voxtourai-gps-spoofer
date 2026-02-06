import 'package:flutter/material.dart';

class MapActionButtons extends StatelessWidget {
  const MapActionButtons({
    super.key,
    required this.hasRoute,
    required this.hasPoints,
    required this.isPlaying,
    required this.showWaypoints,
    required this.onLoadOrClear,
    required this.onTogglePlayback,
    required this.onOpenWaypoints,
  });

  final bool hasRoute;
  final bool hasPoints;
  final bool isPlaying;
  final bool showWaypoints;
  final VoidCallback onLoadOrClear;
  final VoidCallback? onTogglePlayback;
  final VoidCallback onOpenWaypoints;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        FloatingActionButton.small(
          heroTag: 'load',
          onPressed: onLoadOrClear,
          tooltip: hasPoints ? 'Clear route' : 'Load route',
          child: Icon(hasPoints ? Icons.close : Icons.upload),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: 'play',
          onPressed: onTogglePlayback,
          backgroundColor: hasRoute ? null : theme.colorScheme.surfaceVariant,
          foregroundColor: hasRoute ? null : theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
          tooltip: isPlaying ? 'Pause' : 'Play',
          child: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
        ),
        if (showWaypoints) ...[
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'waypoints',
            onPressed: onOpenWaypoints,
            tooltip: 'Waypoints',
            child: const Icon(Icons.list_alt),
          ),
        ],
      ],
    );
  }
}
