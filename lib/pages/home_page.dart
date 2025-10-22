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
import '../widgets/badge_pill.dart';
import '../widgets/warnings_panel.dart';
import '../widgets/recent_phieu_panel.dart';

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
    _future = DashboardService.fetchDashboard();
  }

  void _refresh() =>
      setState(() => _future = DashboardService.fetchDashboard());

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
            icon: const Icon(Icons.refresh),
            tooltip: "Làm mới dữ liệu",
            onPressed: _refresh,
          ),
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
                    trailing: BadgePill(text: "${data.warnings.length} mục"),
                    child: WarningsPanel(warnings: data.warnings),
                  ),

                  const SizedBox(height: 16),
                  CardSection(
                    title: "🧾 Phiếu gần đây",
                    child: RecentPhieuPanel(items: data.recentPhieu),
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
