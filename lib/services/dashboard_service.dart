import 'dart:async';
import '../models/dashboard_data.dart';
import 'api_service.dart';

/// Service để lấy dữ liệu Dashboard
class DashboardService {
  // 💡 CẬP NHẬT: Thay thế hàm mock cũ bằng hàm gọi API thực tế
  static Future<DashboardData> fetchDashboard() async {
    final (ok, data, msg) = await ApiService.getDashboardData();

    if (!ok || data == null) {
      // Ném exception nếu API thất bại (hoặc không đăng nhập)
      throw Exception(msg);
    }

    // Mapping response từ BE
    // Lưu ý: Các keys được sử dụng là keys trả về từ BE (src/controllers/dashboardController.js)
    return DashboardData(
      totalDrugs: data["totalDrugs"] ?? 0,
      nearExpiry: data["nearExpiry"] ?? 0,
      expired: data["expired"] ?? 0,
      totalOnHand: data["totalOnHand"] ?? 0,
      // Chuyển List<dynamic> từ JSON thành List<Map<String, dynamic>>
      warnings: List<Map<String, dynamic>>.from(data["warnings"] ?? []),
      recentPhieu: List<Map<String, dynamic>>.from(data["recentPhieu"] ?? []),
      expiredItems: List<Map<String, dynamic>>.from(data["expiredItems"] ?? []),
    );
  }
}
