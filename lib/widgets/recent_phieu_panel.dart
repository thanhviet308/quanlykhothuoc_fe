import 'package:flutter/material.dart';
import 'leading_icon.dart';

class RecentPhieuPanel extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const RecentPhieuPanel({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: Text("Chưa có phiếu"),
      );
    }

    return Column(
      children: items.map((p) {
        final loai = (p['loai'] ?? '?').toString();
        final isNhap = loai.toUpperCase() == 'NHAP';
        final soPhieu = p['so_phieu'] ?? '#N/A';
        final nguoiLap = p['nguoi_lap'] ?? 'System';
        final ngayPhieu = p['ngay_phieu'] ?? 'N/A';

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: LeadingIcon.tag(text: loai),
          title: Text("Phiếu $soPhieu — $loai"),
          subtitle: Text("$ngayPhieu • Người lập: $nguoiLap"),
          trailing: Chip(
            label: Text(isNhap ? 'Nhập' : 'Xuất'),
            visualDensity: VisualDensity.compact,
            side: BorderSide.none,
            backgroundColor: (isNhap ? cs.primary : cs.error).withOpacity(.12),
            labelStyle: TextStyle(color: isNhap ? cs.primary : cs.error),
          ),
          onTap: () {},
        );
      }).toList(),
    );
  }
}
