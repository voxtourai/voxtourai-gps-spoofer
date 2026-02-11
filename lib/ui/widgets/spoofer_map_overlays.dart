import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'map_action_buttons.dart';
import 'waypoint_action_row.dart';

class SpooferMapOverlays extends StatelessWidget {
  const SpooferMapOverlays({
    super.key,
    required this.hasRoute,
    required this.hasPoints,
    required this.isUsingCustomRoute,
    required this.selectedWaypointIndex,
    required this.isPlaying,
    required this.currentPosition,
    required this.autoFollowEnabled,
    required this.overlayBottom,
    required this.onLoadOrClear,
    required this.onTogglePlayback,
    required this.onOpenWaypoints,
    required this.onFitRoute,
    required this.onRecenter,
    required this.onRenameSelected,
    required this.onDeleteSelected,
  });

  final bool hasRoute;
  final bool hasPoints;
  final bool isUsingCustomRoute;
  final int? selectedWaypointIndex;
  final bool isPlaying;
  final LatLng? currentPosition;
  final bool autoFollowEnabled;
  final double overlayBottom;
  final VoidCallback onLoadOrClear;
  final VoidCallback? onTogglePlayback;
  final VoidCallback onOpenWaypoints;
  final VoidCallback onFitRoute;
  final VoidCallback onRecenter;
  final VoidCallback onRenameSelected;
  final VoidCallback onDeleteSelected;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          right: 12,
          top: 12,
          child: MapActionButtons(
            hasRoute: hasRoute,
            hasPoints: hasPoints,
            isPlaying: isPlaying,
            showWaypoints: !(hasRoute && !isUsingCustomRoute),
            onLoadOrClear: onLoadOrClear,
            onTogglePlayback: onTogglePlayback,
            onOpenWaypoints: onOpenWaypoints,
          ),
        ),
        Positioned(
          right: 12,
          bottom: overlayBottom,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasRoute) ...[
                FloatingActionButton.small(
                  heroTag: 'fitRoute',
                  onPressed: onFitRoute,
                  tooltip: 'Fit route',
                  child: const Icon(Icons.fit_screen),
                ),
                const SizedBox(height: 8),
              ],
              FloatingActionButton.small(
                heroTag: 'recenter',
                onPressed: currentPosition == null ? null : onRecenter,
                tooltip: 'Recenter',
                child: Icon(
                  autoFollowEnabled
                      ? Icons.my_location
                      : Icons.center_focus_strong,
                ),
              ),
            ],
          ),
        ),
        if (selectedWaypointIndex != null)
          Positioned(
            left: 12,
            right: 72,
            bottom: overlayBottom,
            child: WaypointActionRow(
              onRename: onRenameSelected,
              onDelete: onDeleteSelected,
            ),
          ),
      ],
    );
  }
}
