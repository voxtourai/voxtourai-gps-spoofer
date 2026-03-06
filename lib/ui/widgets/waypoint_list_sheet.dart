import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/route/spoofer_route_bloc.dart';
import '../../bloc/route/spoofer_route_state.dart';

typedef WaypointLoadRoute = Future<bool> Function();
typedef WaypointRename = Future<void> Function(int index);
typedef WaypointReorder = void Function(int oldIndex, int newIndex);
typedef WaypointIndexAction = void Function(int index);
typedef WaypointNameResolver = String Function(int index);

Future<void> showWaypointListSheet({
  required BuildContext context,
  required VoidCallback onSaveRoute,
  required WaypointLoadRoute onLoadRoute,
  required WaypointReorder onReorder,
  required WaypointIndexAction onSelect,
  required WaypointRename onRename,
  required WaypointIndexAction onDelete,
  required WaypointNameResolver defaultWaypointName,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      final height = MediaQuery.of(context).size.height * 0.6;
      return SafeArea(
        child: SizedBox(
          height: height,
          child: BlocBuilder<SpooferRouteBloc, SpooferRouteState>(
            builder: (context, routeState) {
              final hasPoints = routeState.waypointPoints.isNotEmpty;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Row(
                      children: [
                        Text(
                          'Waypoints',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Save route',
                          icon: const Icon(Icons.save),
                          onPressed: hasPoints ? onSaveRoute : null,
                        ),
                        IconButton(
                          tooltip: 'Load route',
                          icon: const Icon(Icons.folder_open),
                          onPressed: () async {
                            final loaded = await onLoadRoute();
                            if (loaded && context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: hasPoints
                        ? ReorderableListView.builder(
                            itemCount: routeState.waypointPoints.length,
                            buildDefaultDragHandles: false,
                            onReorder: onReorder,
                            itemBuilder: (context, index) {
                              final name =
                                  routeState.waypointNames.length > index
                                  ? routeState.waypointNames[index]
                                  : defaultWaypointName(index);
                              final position = routeState.waypointPoints[index];
                              return ListTile(
                                key: ValueKey('wp_item_$index'),
                                dense: true,
                                title: Text(name),
                                subtitle: Text(
                                  '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}',
                                ),
                                leading: CircleAvatar(
                                  radius: 14,
                                  child: Text(
                                    '${index + 1}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  onSelect(index);
                                },
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      tooltip: 'Rename',
                                      onPressed: () => onRename(index),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      tooltip: 'Delete',
                                      onPressed: () => onDelete(index),
                                    ),
                                    ReorderableDragStartListener(
                                      index: index,
                                      child: const Icon(Icons.drag_handle),
                                    ),
                                  ],
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Text(
                              'No waypoints yet. Tap and hold on the map to add points.',
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}
