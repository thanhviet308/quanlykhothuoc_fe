// lib/screens/ton_kho_chi_tiet_screen.dart
import 'package:flutter/material.dart';
import 'package:frontend/services/inventory_service.dart';

class TonKhoChiTietScreen extends StatefulWidget {
  const TonKhoChiTietScreen({super.key});

  @override
  State<TonKhoChiTietScreen> createState() => _TonKhoChiTietScreenState();
}

class _TonKhoChiTietScreenState extends State<TonKhoChiTietScreen> {
  // Future tường minh: danh sách lô còn tồn
  late Future<List<Map<String, dynamic>>> _futureLots;
  final _searchCtrl = TextEditingController();
  String _currentQuery = '';

  String _formatDate(dynamic v) {
    if (v == null) return 'N/A';
    DateTime? dt;
    if (v is DateTime) {
      dt = v;
    } else if (v is String) {
      // Backend trả 'YYYY-MM-DD' hoặc ISO. Thử parse an toàn.
      try {
        dt = DateTime.parse(v);
      } catch (_) {
        dt = null;
      }
    } else if (v is int) {
      // Hỗ trợ epoch (s hoặc ms)
      try {
        var millis = v;
        if (millis < 1000000000000) millis *= 1000; // nếu là giây
        dt = DateTime.fromMillisecondsSinceEpoch(millis);
      } catch (_) {
        dt = null;
      }
    }
    if (dt == null) return v.toString();
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    return '$d/$m/$y';
  }

  @override
  void initState() {
    super.initState();
    _futureLots = _fetchLots();
  }

  // Lấy danh sách lô thuốc còn tồn kho
  Future<List<Map<String, dynamic>>> _fetchLots({String? q}) async {
    // InventoryService.getLots() trả về (bool ok, List<dynamic>? data, String message)
    final (ok, data, msg) = await InventoryService.getLots(
      q: q ?? _currentQuery,
    );

    if (ok && data != null) {
      // Ép kiểu an toàn từ List<dynamic> -> List<Map<String, dynamic>>
      return List<Map<String, dynamic>>.from(data);
    }

    // Nếu lỗi, ném exception để FutureBuilder hiển thị
    throw Exception(msg.isNotEmpty ? msg : 'Không lấy được dữ liệu lô tồn');
  }

  Future<void> _refresh() async {
    setState(() {
      _futureLots = _fetchLots();
    });
    await _futureLots;
  }

  void _applySearch(String q) {
    _currentQuery = q.trim();
    setState(() {
      _futureLots = _fetchLots(q: _currentQuery);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi Tiết Tồn Kho (Theo Lô)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Làm mới',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(58),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: TextField(
              controller: _searchCtrl,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Tìm theo số lô...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _applySearch('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              onSubmitted: _applySearch,
              onChanged: (v) {
                // Optional: simple debounce-lite; only trigger when cleared
                if (v.isEmpty && _currentQuery.isNotEmpty) {
                  _applySearch('');
                }
              },
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureLots,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Lỗi tải dữ liệu: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final lots = snapshot.data ?? const <Map<String, dynamic>>[];
          if (lots.isEmpty) {
            return const Center(child: Text('Kho không còn tồn lô hàng nào.'));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: lots.length,
              itemBuilder: (context, index) {
                final lot = lots[index];

                final tenThuoc = (lot['ten_thuoc'] ?? 'N/A').toString();
                final soLo = (lot['so_lo'] ?? 'N/A').toString();
                final hanDung = _formatDate(lot['han_dung']);
                final soLuong = (lot['so_luong'] ?? '0').toString();

                return ListTile(
                  leading: const Icon(Icons.inventory_2),
                  title: Text(
                    tenThuoc,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text('Lô: $soLo | HSD: $hanDung'),
                  trailing: Text(
                    soLuong,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Xem chi tiết Lô $soLo')),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
