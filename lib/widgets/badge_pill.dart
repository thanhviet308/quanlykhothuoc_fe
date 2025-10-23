import 'package:flutter/material.dart';

class BadgePill extends StatelessWidget {
  final String text;
  final Color? color;
  const BadgePill({super.key, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = color ?? cs.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withOpacity(.6)),
      ),
      child: Text(
        text,
        style: TextStyle(color: c, fontWeight: FontWeight.w700),
      ),
    );
  }
}
