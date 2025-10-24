import 'package:flutter/material.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/nhap_kho_screen.dart';
import 'package:frontend/screens/xuat_kho_screen.dart';
import 'package:frontend/services/api_service.dart';
import '../models/dashboard_data.dart';
import '../services/dashboard_service.dart';
import '../theme/app_theme.dart';
import '../widgets/search_bar.dart';
import '../widgets/kpi.dart';
import 'package:frontend/screens/drug_list_screen.dart';
import 'package:frontend/screens/warning_list_screen.dart';
import 'package:frontend/screens/expired_list_screen.dart';
import 'package:frontend/screens/ton_kho_chi_tiet_screen.dart';
import '../widgets/quick_actions.dart';
import '../widgets/card_section.dart';
import '../widgets/badge_pill.dart';
import '../widgets/warnings_panel.dart';
import '../widgets/recent_phieu_panel.dart';
// import 'package:frontend/services/inventory_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<DashboardData> _future;

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    // Already a DateTime
    if (v is DateTime) return v;
    // Milliseconds/seconds epoch
    if (v is int) {
      try {
        var millis = v;
        if (millis < 1000000000000) millis *= 1000; // seconds -> ms
        return DateTime.fromMillisecondsSinceEpoch(millis).toLocal();
      } catch (_) {
        return null;
      }
    }
    // Strings: support both ISO (YYYY-MM-DD[...]) and DD/MM/YYYY
    final s = v.toString().trim();
    // Try ISO first
    final iso = DateTime.tryParse(s.length >= 10 ? s.substring(0, 10) : s);
    if (iso != null) return iso.toLocal();
    // Try DD/MM/YYYY
    if (s.contains('/')) {
      final parts = s.split('/');
      if (parts.length == 3) {
        final d = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final y = int.tryParse(parts[2]);
        if (d != null && m != null && y != null) {
          try {
            return DateTime(y, m, d);
          } catch (_) {}
        }
      }
    }
    return null;
  }

  // Hàm lọc chỉ lấy thuốc ĐÃ HẾT HẠN
  List<Map<String, dynamic>> _expiredFromWarnings(
    List<Map<String, dynamic>> ws,
  ) {
    final now = DateTime.now();
    return ws.where((w) {
      final d = _parseDate(w['han_dung']);
      return d != null && d.isBefore(DateTime(now.year, now.month, now.day));
    }).toList();
  }

  // Hàm lọc chỉ lấy thuốc SẮP HẾT HẠN (chưa hết hạn)
  List<Map<String, dynamic>> _nearExpiryFromWarnings(
    List<Map<String, dynamic>> ws,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Define a reasonable "near expiry" window (60 days)
    final end = today.add(const Duration(days: 60));
    return ws.where((w) {
      final d = _parseDate(w['han_dung']);
      // Keep items with a valid date that are between today and end (inclusive)
      return d != null && !d.isBefore(today) && !d.isAfter(end);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _future = DashboardService.fetchDashboard();
  }

  Future<void> _refresh() async {
    // 1. Tạo một Future MỚI để fetch dữ liệu
    final newFuture = DashboardService.fetchDashboard();

    // 2. Cập nhật state với Future MỚI (buộc widget rebuild)
    setState(() {
      _future = newFuture;
    });

    // 3. CHỜ cho Future mới hoàn thành.
    // Điều này đảm bảo nút Refresh / Pull-to-Refresh (nếu dùng) chờ cho đến khi dữ liệu có.
    await newFuture;
  }

  // các hành động (chưa điều hướng thật)
  void _gotoNhap() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        // BỎ const ở đây
        builder: (_) => NhapKhoScreen(),
      ),
    );
    if (result == true) _refresh();
  }

  void _gotoXuat() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        // BỎ const ở đây
        builder: (_) => XuatKhoScreen(),
      ),
    );
    if (result == true) _refresh();
  }

  void _gotoCanhBao() {}
  void _gotoSearch(String q) {}

  @override
  Widget build(BuildContext context) {
    // final cs = Theme.of(context).colorScheme; // not used currently

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kho Dược — Bảng điều khiển"),
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
          // <--- Tham số là 'snap'
          if (snap.connectionState == ConnectionState.waiting) {
            // <--- Dùng 'snap'
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            // <--- Dùng 'snap'
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
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const DrugListScreen(),
                            ),
                          );
                        },
                      ),
                      KpiItem(
                        label: "Sắp hết hạn",
                        value: "${data.nearExpiry}",
                        icon: Icons.warning_amber_rounded,
                        accent: AppTheme.warning,
                        onTap: () {
                          // Đã sửa: Chỉ truyền danh sách thuốc SẮP HẾT HẠN
                          final items = _nearExpiryFromWarnings(data.warnings);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => WarningListScreen(
                                warnings: items,
                                title: 'Thuốc sắp hết hạn',
                              ),
                            ),
                          );
                        },
                      ),
                      KpiItem(
                        label: "Hết hạn",
                        value: "${data.expired}",
                        icon: Icons.event_busy,
                        accent: AppTheme.danger,
                        onTap: () {
                          // Prefer the backend-provided full expired list if available;
                          // otherwise fall back to deriving expired items from warnings.
                          // Defensive: additionally ensure items are truly expired (date < today)
                          final now = DateTime.now();
                          final today = DateTime(now.year, now.month, now.day);
                          final backendExpired = data.expiredItems.where((w) {
                            final d = _parseDate(w['han_dung']);
                            return d != null && d.isBefore(today);
                          }).toList();

                          final items = (backendExpired.isNotEmpty)
                              ? backendExpired
                              : _expiredFromWarnings(data.warnings);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ExpiredListScreen(
                                items: items,
                                title: 'Thuốc hết hạn',
                              ),
                            ),
                          );
                        },
                      ),
                      KpiItem(
                        label: "Tồn tổng",
                        value: "${data.totalOnHand}",
                        icon: Icons.inventory_2,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const TonKhoChiTietScreen(),
                            ),
                          );
                        },
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
                    title: "⚠️ Cảnh báo ",
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
