import 'dart:async';

import 'package:flutter/material.dart';

/// A [SearchBar] wrapper that debounces [onQueryChanged] and exposes a clear
/// button when the field is non-empty.
class DebouncedSearchBar extends StatefulWidget {
  final String hintText;
  final ValueChanged<String> onQueryChanged;
  final Duration debounce;
  final bool enabled;
  final List<Widget>? trailing;

  const DebouncedSearchBar({
    super.key,
    required this.hintText,
    required this.onQueryChanged,
    this.debounce = const Duration(milliseconds: 300),
    this.enabled = true,
    this.trailing,
  });

  @override
  State<DebouncedSearchBar> createState() => _DebouncedSearchBarState();
}

class _DebouncedSearchBarState extends State<DebouncedSearchBar> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  bool _hasText = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _handleChanged(String value) {
    final hasText = value.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
    _debounce?.cancel();
    _debounce = Timer(widget.debounce, () {
      widget.onQueryChanged(value);
    });
  }

  void _handleClear() {
    _controller.clear();
    _debounce?.cancel();
    setState(() => _hasText = false);
    widget.onQueryChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      controller: _controller,
      hintText: widget.hintText,
      enabled: widget.enabled,
      leading: const Icon(Icons.search),
      trailing: [
        if (_hasText)
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Clear',
            onPressed: _handleClear,
          ),
        ...?widget.trailing,
      ],
      onChanged: _handleChanged,
    );
  }
}
