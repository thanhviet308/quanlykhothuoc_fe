import 'package:flutter/material.dart';
import 'leading_icon.dart';

class WarningsPanel extends StatelessWidget {
  final List<Map<String, dynamic>> warnings;
  const WarningsPanel({super.key, required this.warnings});

  @override
  Widget build(BuildContext context) {
    if (warnings.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: Text("Không có cảnh báo"),
      );
    }

    return Column(
      children: warnings.map((w) {
        final drugName = "${w['ten_thuoc']}";
        final soLo = w['so_lo'] ?? 'N/A';
        final ton = w['so_luong_ton'] ?? 0;
        final hanDung = w['han_dung'] ?? 'N/A';
        final reason = w['ly_do'] ?? 'Cảnh báo';

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: LeadingIcon.circle(icon: Icons.timelapse),
          title: Text("$drugName — Lô $soLo"),
          subtitle: Text("Hạn: $hanDung  •  Tồn: $ton • $reason"),
          onTap: () {},
        );
      }).toList(),
    );
  }
}
