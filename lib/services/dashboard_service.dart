import 'dart:async';
import '../models/dashboard_data.dart';

/// Service mock — sau này thay bằng API thật.
class DashboardService {
  static Future<DashboardData> fetchDashboardMock() async {
    await Future.delayed(const Duration(milliseconds: 600));

    final sum = {
      "totalDrugs": 58,
      "nearExpiry": 4,
      "expired": 2,
      "totalOnHand": 12430,
    };

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

    return DashboardData(
      totalDrugs: sum["totalDrugs"] ?? 0,
      nearExpiry: sum["nearExpiry"] ?? 0,
      expired: sum["expired"] ?? 0,
      totalOnHand: sum["totalOnHand"] ?? 0,
      warnings: List<Map<String, dynamic>>.from(warns),
      recentPhieu: List<Map<String, dynamic>>.from(phieu["data"] ?? []),
    );
  }
}
