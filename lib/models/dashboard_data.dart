class DashboardData {
  final int totalDrugs;
  final int nearExpiry;
  final int expired;
  final int totalOnHand;
  final List<Map<String, dynamic>> warnings;
  final List<Map<String, dynamic>> recentPhieu;
  final List<Map<String, dynamic>> expiredItems;

  DashboardData({
    required this.totalDrugs,
    required this.nearExpiry,
    required this.expired,
    required this.totalOnHand,
    required this.warnings,
    required this.recentPhieu,
    required this.expiredItems,
  });
}
