import 'package:flutter/material.dart';
import 'package:http/http.dart'
    as http; // 💡 Cần thêm dependency: http: ^latest
import 'dart:convert'; // For json encoding
// import 'package:frontend/widgets/warnings_panel.dart'; // Đã loại bỏ để dùng ListView.builder

// *** LƯU Ý QUAN TRỌNG: Cần Định nghĩa API_BASE_URL và Token ***
// Thay thế bằng URL thực tế của bạn
const String API_BASE_URL = "http://localhost:3000/api";

class ExpiredListScreen extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final String title;
  const ExpiredListScreen({
    super.key,
    required this.items,
    this.title = 'Thuốc hết hạn',
  });

  @override
  State<ExpiredListScreen> createState() => _ExpiredListScreenState();
}

class _ExpiredListScreenState extends State<ExpiredListScreen> {
  final _searchCtrl = TextEditingController();
  late List<Map<String, dynamic>> _filtered;

  // Utility to get the auth token (needs to be implemented based on app state)
  String? _getAuthToken() {
    // 💡 HÃY THAY THẾ BẰNG LOGIC LẤY TOKEN THỰC TẾ CỦA ỨNG DỤNG BẠN
    return "YOUR_AUTH_TOKEN";
  }

  String _formatDate(dynamic v) {
    if (v == null) return '-';
    DateTime? dt;
    if (v is DateTime) {
      dt = v;
    } else if (v is String) {
      try {
        dt = DateTime.tryParse(v)?.toLocal();
      } catch (_) {
        dt = null;
      }
    } else if (v is int) {
      try {
        var millis = v;
        if (millis < 1000000000000) millis *= 1000; // seconds -> ms
        dt = DateTime.fromMillisecondsSinceEpoch(millis).toLocal();
      } catch (_) {
        dt = null;
      }
    }
    // Handle date strings in DD/MM/YYYY format if they come from the API already formatted.
    if (dt == null && v is String) {
      final parts = v.split('/');
      if (parts.length == 3) {
        dt = DateTime.tryParse('${parts[2]}-${parts[1]}-${parts[0]}');
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
    _filtered = List<Map<String, dynamic>>.from(widget.items);
    _searchCtrl.addListener(() => _apply(_searchCtrl.text));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _apply(String q) {
    final text = q.trim().toLowerCase();
    if (text.isEmpty) {
      setState(() => _filtered = List<Map<String, dynamic>>.from(widget.items));
      return;
    }
    setState(() {
      _filtered = widget.items.where((w) {
        final haystack =
            [
                  w['thuoc'],
                  w['ten_thuoc'] ?? w['ten'],
                  w['ma_thuoc'],
                  w['so_lo'],
                  _formatDate(w['han_dung']),
                ]
                .where((e) => e != null)
                .map((e) => e.toString().toLowerCase())
                .join(' | ');
        return haystack.contains(text);
      }).toList();
    });
  }

  // 💡 HÀM MỚI: Cập nhật trạng thái thuốc thành "Ngừng hoạt động"
  Future<void> _updateDrugStatus(int thuocId, String maThuoc) async {
    final token = _getAuthToken();
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi: Không tìm thấy token xác thực.')),
      );
      return;
    }

    // 1. Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận Ngừng Hoạt động'),
        content: Text(
          'Bạn có chắc chắn muốn ngừng hoạt động thuốc $maThuoc không? Thao tác này áp dụng cho TẤT CẢ các lô của thuốc này.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // 2. Perform API call (PUT /api/thuoc/:id)
    final url = Uri.parse('$API_BASE_URL/thuoc/$thuocId');
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'hoat_dong': false, // Set drug status to inactive
        }),
      );

      // 3. Handle response
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã cập nhật thuốc $maThuoc sang trạng thái "Ngừng hoạt động" thành công.',
            ),
          ),
        );
      } else {
        final error =
            jsonDecode(response.body)['message'] ?? 'Lỗi không xác định.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cập nhật thất bại (${response.statusCode}): $error'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi mạng: $e')));
    }
  }

  // 💡 HELPER MỚI: Widget hiển thị từng mục cảnh báo với nút hành động
  Widget _buildWarningTile(Map<String, dynamic> w) {
    // Thuốc ID cần được lấy từ data, hãy đảm bảo dashboard API trả về nó.
    // Ví dụ: w['thuoc_id'] phải là ID của Thuoc, không phải LoThuoc
    final thuocId = w['thuoc_id'];
    final maThuoc = w['ma_thuoc'] ?? '-';
    final tenThuoc = w['ten_thuoc'] ?? w['thuoc'] ?? '-';
    final hanDung = _formatDate(w['han_dung']);
    final soLo = w['so_lo'] ?? '-';
    final lyDo = w['ly_do'] ?? 'Cảnh báo';
    final soLuongTon = w.containsKey('so_luong_ton')
        ? w['so_luong_ton']
        : (w.containsKey('so_luong') ? w['so_luong'] : 0);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      child: ListTile(
        leading: Icon(
          lyDo.contains('Quá hạn') ? Icons.error : Icons.warning,
          color: lyDo.contains('Quá hạn') ? Colors.red : Colors.orange,
        ),
        title: Text(
          '$tenThuoc ($maThuoc)',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Lô: $soLo | Hạn Dùng: $hanDung\nTồn kho: $soLuongTon | Lý do: $lyDo',
        ),
        isThreeLine: true,
        // Chỉ hiển thị nút nếu có thuocId hợp lệ
        trailing: thuocId != null && thuocId is int
            ? IconButton(
                icon: const Icon(Icons.block, color: Colors.red),
                tooltip: 'Ngừng hoạt động thuốc này (Khóa Thuốc)',
                onPressed: () => _updateDrugStatus(thuocId, maThuoc),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Center(
              child: Text(
                'Tổng: ${_filtered.length} mục',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(58),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Tìm theo tên thuốc, số lô, hạn dùng...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchCtrl.clear();
                          _apply('');
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              onSubmitted: _apply,
            ),
          ),
        ),
      ),
      // 💡 Thay thế WarningsPanel bằng ListView.builder
      body: _filtered.isEmpty
          ? const Center(child: Text('Không có mục cảnh báo nào.'))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _filtered.length,
              itemBuilder: (context, index) {
                return _buildWarningTile(_filtered[index]);
              },
            ),
    );
  }
}
