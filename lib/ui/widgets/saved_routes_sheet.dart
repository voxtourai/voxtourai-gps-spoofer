import 'package:flutter/material.dart';

typedef SavedRoutesDelete =
    Future<List<Map<String, Object?>>> Function(int index);

Future<bool> showSavedRoutesSheet({
  required BuildContext context,
  required List<Map<String, Object?>> routes,
  required ValueChanged<int> onApply,
  required SavedRoutesDelete onDelete,
}) async {
  var loaded = false;
  final items = List<Map<String, Object?>>.from(routes);
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          if (items.isEmpty) {
            return Center(
              child: Text(
                'No saved routes yet.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              final name = item['name']?.toString() ?? 'Route';
              final points = (item['points'] as List?) ?? const <Object>[];
              return ListTile(
                title: Text(name),
                subtitle: Text('${points.length} points'),
                onTap: () {
                  onApply(index);
                  loaded = true;
                  Navigator.of(context).pop();
                },
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    final updated = await onDelete(index);
                    if (!context.mounted) {
                      return;
                    }
                    setSheetState(() {
                      items
                        ..clear()
                        ..addAll(updated);
                    });
                  },
                ),
              );
            },
          );
        },
      );
    },
  );
  return loaded;
}
