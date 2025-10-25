import 'package:flutter/material.dart';
// import 'package:frontend/widgets/warnings_panel.dart'; // Đã loại bỏ để dùng ListView.builder

// (Đã lược bỏ API gọi cập nhật trạng thái để đơn giản giao diện)

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

  // (Loại bỏ chức năng thao tác trạng thái thuốc từ màn danh sách)

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

  // 💡 HELPER MỚI: Widget hiển thị từng mục cảnh báo với nút hành động
  Widget _buildWarningTile(Map<String, dynamic> w) {
    // Thuốc ID cần được lấy từ data, hãy đảm bảo dashboard API trả về nó.
    // Ví dụ: w['thuoc_id'] phải là ID của Thuoc, không phải LoThuoc
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
        // Bỏ biểu tượng ngừng hoạt động theo yêu cầu
        trailing: null,
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
