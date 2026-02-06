import 'package:flutter/material.dart';

import '../../models/help_section.dart';
import '../widgets/search_scaffold.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key, required this.helpSections});

  final List<HelpSection> helpSections;

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final sections = widget.helpSections.where((section) {
      if (query.isEmpty) {
        return true;
      }
      if (section.title.toLowerCase().contains(query)) {
        return true;
      }
      return section.items.any((item) => item.toLowerCase().contains(query));
    }).toList();

    return SearchScaffold(
      title: 'Help',
      controller: _controller,
      hintText: 'Search help...',
      onChanged: (value) {
        setState(() {
          _query = value;
        });
      },
      body: sections.isEmpty
          ? const Center(child: Text('No matching help topics.'))
          : ListView.builder(
              itemCount: sections.length,
              itemBuilder: (context, index) {
                final section = sections[index];
                final body = section.items.map((item) => '- $item').join('\n');
                return ExpansionTile(
                  title: Text(section.title),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(body),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
