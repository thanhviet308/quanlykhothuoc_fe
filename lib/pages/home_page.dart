import 'package:flutter/material.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/services/api_service.dart';
import '../models/dashboard_data.dart';
import '../services/dashboard_service.dart';
import '../theme/app_theme.dart';
import '../widgets/search_bar.dart';
import '../widgets/kpi.dart';
import '../widgets/quick_actions.dart';
import '../widgets/card_section.dart';

class HomePage extends StatefulWidget {
  final String apiBase; // để sau này gắn API
  final String token;
  const HomePage({super.key, required this.apiBase, required this.token});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<DashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = DashboardService.fetchDashboardMock();
  }

  void _refresh() =>
      setState(() => _future = DashboardService.fetchDashboardMock());

  // các hành động (chưa điều hướng thật)
  void _gotoNhap() {}
  void _gotoXuat() {}
  void _gotoCanhBao() {}
  void _gotoSearch(String q) {}

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kho Dược — Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final (ok, msg) = await ApiService.logout();
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(msg)));

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<DashboardData>(
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
            onRefresh: () async => _refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SearchBarSimple(onSubmit: _gotoSearch),
                  const SizedBox(height: 14),

                  // KPI
                  KpiRow(
                    items: [
                      KpiItem(
                        label: "Thuốc đang hoạt động",
                        value: "${data.totalDrugs}",
                        icon: Icons.medication,
                        accent: AppTheme.success,
                      ),
                      KpiItem(
                        label: "Sắp hết hạn",
                        value: "${data.nearExpiry}",
                        icon: Icons.warning_amber_rounded,
                        accent: AppTheme.warning,
                      ),
                      KpiItem(
                        label: "Hết hạn",
                        value: "${data.expired}",
                        icon: Icons.event_busy,
                        accent: AppTheme.danger,
                      ),
                      KpiItem(
                        label: "Tồn tổng",
                        value: "${data.totalOnHand}",
                        icon: Icons.inventory_2,
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  QuickActions(
                    onNhap: _gotoNhap,
                    onXuat: _gotoXuat,
                    onCanhBao: _gotoCanhBao,
                  ),

                  const SizedBox(height: 18),
                  CardSection(
                    title: "⚠️ Cảnh báo sắp hết hạn (60 ngày)",
                    trailing: _Badge(text: "${data.warnings.length} mục"),
                    child: data.warnings.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(8),
                            child: Text("Không có cảnh báo"),
                          )
                        : Column(
                            children: data.warnings.map((w) {
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                leading: _LeadingIcon.circle(
                                  icon: Icons.timelapse,
                                ),
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
                  CardSection(
                    title: "🧾 Phiếu gần đây",
                    child: data.recentPhieu.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(8),
                            child: Text("Chưa có phiếu"),
                          )
                        : Column(
                            children: data.recentPhieu.map((p) {
                              final loai = (p['loai'] ?? '?').toString();
                              final isNhap = loai.toUpperCase() == 'NHAP';
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                leading: _LeadingIcon.tag(text: loai),
                                title: Text("Phiếu #${p['id']} — $loai"),
                                subtitle: Text(
                                  "${p['ngay_phieu']} • ${p['ghi_chu'] ?? ''}",
                                ),
                                trailing: Chip(
                                  label: Text(isNhap ? 'Nhập' : 'Xuất'),
                                  visualDensity: VisualDensity.compact,
                                  side: BorderSide.none,
                                  backgroundColor:
                                      (isNhap ? cs.primary : cs.error)
                                          .withOpacity(.12),
                                  labelStyle: TextStyle(
                                    color: isNhap ? cs.primary : cs.error,
                                  ),
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

class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withOpacity(.6)),
      ),
      child: Text(
        text,
        style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  final IconData? icon;
  final String? text;
  final bool isCircle;

  const _LeadingIcon._(this.icon, this.text, this.isCircle);

  factory _LeadingIcon.circle({required IconData icon}) =>
      _LeadingIcon._(icon, null, true);
  factory _LeadingIcon.tag({required String text}) =>
      _LeadingIcon._(null, text, false);

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
