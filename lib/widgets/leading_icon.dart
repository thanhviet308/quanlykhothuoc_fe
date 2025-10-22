import 'package:flutter/material.dart';

class LeadingIcon extends StatelessWidget {
  final IconData? icon;
  final String? text;
  final bool isCircle;

  const LeadingIcon._(this.icon, this.text, this.isCircle, {super.key});

  factory LeadingIcon.circle({required IconData icon}) =>
      LeadingIcon._(icon, null, true);

  factory LeadingIcon.tag({required String text}) =>
      LeadingIcon._(null, text, false);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (isCircle) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: cs.secondary.withOpacity(.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: cs.secondary),
      );
    }
    return CircleAvatar(
      radius: 18,
      backgroundColor: cs.tertiary.withOpacity(.12),
      child: Text(
        (text ?? '?').characters.first.toUpperCase(),
        style: TextStyle(color: cs.tertiary, fontWeight: FontWeight.w800),
      ),
    );
  }
}
