import 'package:flutter/material.dart';

class QuickActions extends StatelessWidget {
  final VoidCallback onNhap, onXuat, onCanhBao;
  const QuickActions({
    super.key,
    required this.onNhap,
    required this.onXuat,
    required this.onCanhBao,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.download,
            label: "Nhập kho",
            onTap: onNhap,
            tint: cs.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.upload,
            label: "Xuất kho",
            onTap: onXuat,
            tint: cs.tertiary,
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color tint;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [tint.withOpacity(.14), tint.withOpacity(.06)],
          ),
          border: Border.all(color: cs.outlineVariant.withOpacity(.6)),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: tint),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
