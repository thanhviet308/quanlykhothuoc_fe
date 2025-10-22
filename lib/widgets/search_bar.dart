import 'package:flutter/material.dart';

class SearchBarSimple extends StatefulWidget {
  final void Function(String) onSubmit;
  const SearchBarSimple({super.key, required this.onSubmit});

  @override
  State<SearchBarSimple> createState() => _SearchBarSimpleState();
}

class _SearchBarSimpleState extends State<SearchBarSimple> {
  final _c = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: _c,
      decoration: InputDecoration(
        hintText: "Tìm thuốc theo tên hoặc mã...",
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _c.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Xoá',
                onPressed: () {
                  setState(() => _c.clear());
                  widget.onSubmit('');
                },
                icon: const Icon(Icons.close),
              ),
        filled: true,
        fillColor: cs.surface,
      ),
      onChanged: (_) => setState(() {}),
      onSubmitted: widget.onSubmit,
    );
  }
}
