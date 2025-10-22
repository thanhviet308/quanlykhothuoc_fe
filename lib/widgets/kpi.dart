import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Item dữ liệu cho mỗi KPI
class KpiItem {
  final String label;
  final String value;
  final IconData icon;
  final Color? accent;

  KpiItem({
    required this.label,
    required this.value,
    required this.icon,
    this.accent,
  });
}

/// Hàng KPI responsive, KHÔNG dùng GridView để tránh overflow
class KpiRow extends StatelessWidget {
  final List<KpiItem> items;
  const KpiRow({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;

        // Chia cột theo độ rộng
        final cols = w >= 900 ? 4 : (w >= 600 ? 3 : 2);
        const gap = 12.0;

        // Tính width cho từng thẻ (trừ khoảng cách giữa các cột)
        final itemWidth = (w - (cols - 1) * gap) / cols;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: items
              .map(
                (e) => SizedBox(
                  width: itemWidth,
                  child: _KpiCard(item: e),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

/// Thẻ KPI hiển thị từng chỉ số
class _KpiCard extends StatelessWidget {
  final KpiItem item;
  const _KpiCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = item.accent ?? cs.primary;

    return Container(
      constraints: const BoxConstraints(
        minHeight: 68,
      ), // đảm bảo đủ cao, ko ép thấp
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withOpacity(0.15), accent.withOpacity(0.03)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(.5)),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, size: 22, color: accent),
          ),
          const SizedBox(width: 10),
          // Chặn text scale quá lớn gây tràn: clamp 0.9..1.2
          MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: MediaQuery.of(
                context,
              ).textScaler.clamp(minScaleFactor: 0.9, maxScaleFactor: 1.2),
            ),
            child: Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.1,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 17, // giảm nhẹ để chắc chắn không tràn
                      fontWeight: FontWeight.w800,
                      letterSpacing: .2,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Màu tiện ích cho KPI
extension KpiColors on KpiItem {
  static Color get success => AppTheme.success;
  static Color get warn => AppTheme.warning;
  static Color get danger => AppTheme.danger;
}
