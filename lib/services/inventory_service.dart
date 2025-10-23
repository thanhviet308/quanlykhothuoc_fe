// lib/services/inventory_service.dart

import 'package:frontend/services/api_service.dart';

// Service chuyên biệt cho các nghiệp vụ liên quan đến Kho hàng
class InventoryService {
  // Sử dụng các hàm helper tĩnh từ ApiService để thực hiện mạng

  // API: GET /api/thuoc
  // lib/services/inventory_service.dart (Logic cần thiết)

  // 💡 CẬP NHẬT: Thêm tham số q cho hàm getDrugs
  static Future<(bool ok, List<dynamic>? data, String message)> getDrugs({
    String? q,
  }) async {
    final query = q != null && q.isNotEmpty ? '?q=$q' : '';
    // Gọi helper để fetch dữ liệu với query string
    return await ApiService.getData('/api/thuoc$query');
  }

  // API: GET /api/lo-thuoc (chỉ lấy lô còn tồn)
  static Future<(bool ok, List<dynamic>? data, String message)> getLots({
    int? drugId,
    String? q,
  }) async {
    final qp = <String, String>{};
    if (drugId != null) qp['thuoc_id'] = '$drugId';
    if (q != null && q.trim().isNotEmpty) qp['q'] = q.trim();
    // Mặc định chỉ lấy lô còn tồn, có thể giới hạn số lượng cho UI
    qp['include_zero'] = '0';
    qp['limit'] = '200';
    final query = qp.isEmpty
        ? ''
        : '?' +
              qp.entries
                  .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
                  .join('&');

    // /api/lo-thuoc trả về dạng { data: [...], total, limit, offset } -> dùng getJson
    final (ok, json, msg) = await ApiService.getJson('/api/lo-thuoc$query');
    if (!(ok && json != null)) return (false, null, msg);
    final list = (json['data'] as List?) ?? const [];
    return (true, list, 'OK');
  }

  // API: GET /api/ton-kho/tong — Tổng tồn theo thuốc
  static Future<(bool ok, List<dynamic>? data, String message)> getTonTong({
    String? by,
  }) async {
    final query = (by != null && by.isNotEmpty) ? '?by=$by' : '';
    return await ApiService.getData('/api/ton-kho/tong$query');
  }

  // API: POST /api/phieu-kho/nhap
  static Future<(bool ok, String message)> sendNhapKho(
    Map<String, dynamic> payload,
  ) async {
    // Sử dụng ApiService.postData cho các request POST/PUT/DELETE
    return await ApiService.postData('/api/phieu-kho/nhap', payload);
  }

  // API: POST /api/phieu-kho/xuat
  static Future<(bool ok, String message)> sendXuatKho(
    Map<String, dynamic> payload,
  ) async {
    return await ApiService.postData('/api/phieu-kho/xuat', payload);
  }
}
