import 'package:flutter/material.dart';

class SpooferAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SpooferAppBar({
    super.key,
    required this.onTitleTap,
    required this.onSearchTap,
    required this.onHelpTap,
    required this.onSettingsTap,
  });

  final VoidCallback onTitleTap;
  final VoidCallback onSearchTap;
  final VoidCallback onHelpTap;
  final VoidCallback onSettingsTap;

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 48,
      title: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTitleTap,
        child: const Text('GPS Spoofer'),
      ),
      actions: [
        IconButton(
          tooltip: 'Search',
          icon: const Icon(Icons.search),
          onPressed: onSearchTap,
        ),
        IconButton(
          tooltip: 'Help',
          icon: const Icon(Icons.help_outline),
          onPressed: onHelpTap,
        ),
        IconButton(
          tooltip: 'Settings',
          icon: const Icon(Icons.settings),
          onPressed: onSettingsTap,
        ),
      ],
    );
  }
}
