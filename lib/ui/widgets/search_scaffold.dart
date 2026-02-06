import 'package:flutter/material.dart';

class SearchScaffold extends StatelessWidget {
  const SearchScaffold({
    super.key,
    required this.title,
    required this.controller,
    required this.hintText,
    required this.body,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.suffixIcon,
    this.helper,
    this.actions,
    this.fieldPadding = const EdgeInsets.fromLTRB(16, 12, 16, 12),
    this.helperPadding = const EdgeInsets.fromLTRB(16, 0, 16, 8),
  });

  final String title;
  final TextEditingController controller;
  final String hintText;
  final Widget body;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final Widget? suffixIcon;
  final Widget? helper;
  final List<Widget>? actions;
  final EdgeInsets fieldPadding;
  final EdgeInsets helperPadding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: fieldPadding,
              child: TextField(
                controller: controller,
                autofocus: autofocus,
                decoration: InputDecoration(
                  hintText: hintText,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: suffixIcon,
                  border: const OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.search,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
              ),
            ),
            if (helper != null)
              Padding(
                padding: helperPadding,
                child: helper,
              ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}
