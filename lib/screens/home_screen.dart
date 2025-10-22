import 'dart:async';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  final String apiBase; // không dùng khi fake, giữ để sau này cắm API
  final String token; // không dùng khi fake
  const HomePage({super.key, required this.apiBase, required this.token});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<_DashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchDashboard(); // chỉ lấy mock
  }

  // 🔹 FAKE DATA ở đây
  Future<_DashboardData> _fetchDashboard() async {
    await Future.delayed(const Duration(milliseconds: 600)); // giả lập loading

    // KPI giả
    final sum = {
      "totalDrugs": 58,
      "nearExpiry": 4,
      "expired": 2,
      "totalOnHand": 12430,
    };

    // Cảnh báo sắp hết hạn giả
    final warns = [
      {
        "thuoc": "Ceftriaxone 1g",
        "so_lo": "CFX01",
        "han_dung": "2025-12-31",
        "ton": 50,
      },
      {
        "thuoc": "Paracetamol 500mg",
        "so_lo": "L02",
        "han_dung": "2025-12-15",
        "ton": 120,
      },
      {
        "thuoc": "Vitamin C 1000mg",
        "so_lo": "VC01",
        "han_dung": "2025-11-20",
        "ton": 35,
      },
    ];

    // Phiếu gần đây giả
    final phieu = {
      "data": [
        {
          "id": 101,
          "loai": "NHAP",
          "ngay_phieu": "2025-10-22 09:00",
          "ghi_chu": "Nhập lô L01",
        },
        {
          "id": 102,
          "loai": "XUAT",
          "ngay_phieu": "2025-10-22 10:30",
          "ghi_chu": "Xuất Paracetamol",
        },
        {
          "id": 103,
          "loai": "NHAP",
          "ngay_phieu": "2025-10-23 08:15",
          "ghi_chu": "Nhập Vitamin C",
        },
      ],
    };

    return _DashboardData(
      totalDrugs: sum["totalDrugs"] ?? 0,
      nearExpiry: sum["nearExpiry"] ?? 0,
      expired: sum["expired"] ?? 0,
      totalOnHand: sum["totalOnHand"] ?? 0,
      warnings: List<Map<String, dynamic>>.from(warns),
      recentPhieu: List<Map<String, dynamic>>.from(phieu["data"] ?? []),
    );
  }

  void _gotoNhap() {}
  void _gotoXuat() {}
  void _gotoCanhBao() {}
  void _gotoSearch(String q) {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kho Dược — Dashboard (mock)"),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.logout))],
      ),
      body: FutureBuilder<_DashboardData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text("Lỗi: ${snap.error}"));
          }
          final data = snap.data!;
          return RefreshIndicator(
            onRefresh: () async => setState(() => _future = _fetchDashboard()),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _SearchBar(onSubmit: _gotoSearch),
                  const SizedBox(height: 12),
                  _KpiRow(
                    items: [
                      KpiItem(
                        label: "Thuốc đang hoạt động",
                        value: "${data.totalDrugs}",
                        icon: Icons.medication,
                      ),
                      KpiItem(
                        label: "Sắp hết hạn",
                        value: "${data.nearExpiry}",
                        icon: Icons.warning_amber_rounded,
                      ),
                      KpiItem(
                        label: "Hết hạn",
                        value: "${data.expired}",
                        icon: Icons.event_busy,
                      ),
                      KpiItem(
                        label: "Tồn tổng",
                        value: "${data.totalOnHand}",
                        icon: Icons.inventory_2,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _QuickActions(
                    onNhap: _gotoNhap,
                    onXuat: _gotoXuat,
                    onCanhBao: _gotoCanhBao,
                  ),

                  const SizedBox(height: 16),
                  _CardSection(
                    title: "⚠️ Cảnh báo sắp hết hạn (60 ngày)",
                    child: data.warnings.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text("Không có cảnh báo"),
                          )
                        : Column(
                            children: data.warnings.map((w) {
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                leading: const Icon(Icons.timelapse),
                                title: Text("${w['thuoc']} — Lô ${w['so_lo']}"),
                                subtitle: Text(
                                  "Hạn: ${w['han_dung']}  •  Tồn: ${w['ton']}",
                                ),
                                onTap: () {},
                              );
                            }).toList(),
                          ),
                  ),

                  const SizedBox(height: 16),
                  _CardSection(
                    title: "🧾 Phiếu gần đây",
                    child: data.recentPhieu.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text("Chưa có phiếu"),
                          )
                        : Column(
                            children: data.recentPhieu.map((p) {
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                leading: CircleAvatar(
                                  child: Text(
                                    (p['loai'] ?? '?').toString().substring(
                                      0,
                                      1,
                                    ),
                                  ),
                                ),
                                title: Text("Phiếu #${p['id']} — ${p['loai']}"),
                                subtitle: Text(
                                  "${p['ngay_phieu']} • ${p['ghi_chu'] ?? ''}",
                                ),
                                onTap: () {},
                              );
                            }).toList(),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DashboardData {
  final int totalDrugs;
  final int nearExpiry;
  final int expired;
  final int totalOnHand;
  final List<Map<String, dynamic>> warnings;
  final List<Map<String, dynamic>> recentPhieu;
  _DashboardData({
    required this.totalDrugs,
    required this.nearExpiry,
    required this.expired,
    required this.totalOnHand,
    required this.warnings,
    required this.recentPhieu,
  });
}

// ===== UI components (giữ nguyên như bạn có) =====

class _SearchBar extends StatefulWidget {
  final void Function(String) onSubmit;
  const _SearchBar({required this.onSubmit});

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final _c = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _c,
      decoration: InputDecoration(
        hintText: "Tìm thuốc theo tên hoặc mã...",
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onSubmitted: widget.onSubmit,
    );
  }
}

class _KpiRow extends StatelessWidget {
  final List<KpiItem> items;
  const _KpiRow({required this.items});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;
    final crossAxis = isWide ? 4 : 2;
    return GridView.count(
      crossAxisCount: crossAxis,
      childAspectRatio: 2.3,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: items.map((e) => _KpiCard(item: e)).toList(),
    );
  }
}

class KpiItem {
  final String label;
  final String value;
  final IconData icon;
  KpiItem({required this.label, required this.value, required this.icon});
}

class _KpiCard extends StatelessWidget {
  final KpiItem item;
  const _KpiCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(item.icon, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final VoidCallback onNhap, onXuat, onCanhBao;
  const _QuickActions({
    required this.onNhap,
    required this.onXuat,
    required this.onCanhBao,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.download,
            label: "Nhập kho",
            onTap: onNhap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionButton(
            icon: Icons.upload,
            label: "Xuất kho",
            onTap: onXuat,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionButton(
            icon: Icons.warning_amber,
            label: "Cảnh báo",
            onTap: onCanhBao,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Theme.of(context).colorScheme.primary.withOpacity(.08),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardSection extends StatelessWidget {
  final String title;
  final Widget child;
  const _CardSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}
