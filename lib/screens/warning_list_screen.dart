// lib/screens/warning_list_screen.dart

import 'package:flutter/material.dart';
import 'package:frontend/widgets/warnings_panel.dart';

class WarningListScreen extends StatefulWidget {
  final List<Map<String, dynamic>> warnings;
  final String title;

  const WarningListScreen({
    super.key,
    required this.warnings,
    required this.title,
  });

  @override
  State<WarningListScreen> createState() => _WarningListScreenState();
}

class _WarningListScreenState extends State<WarningListScreen> {
  final _searchCtrl = TextEditingController();
  late List<Map<String, dynamic>> _filtered;

  String _formatDate(dynamic v) {
    if (v == null) return '-';
    final dt = _parseDate(v);
    if (dt == null) return v.toString();
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    return '$d/$m/$y';
  }

  // Robust date parser: supports DateTime, ISO string, dd/MM/yyyy and epoch
  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is int) {
      try {
        var millis = v;
        if (millis < 1000000000000) millis *= 1000;
        return DateTime.fromMillisecondsSinceEpoch(millis).toLocal();
      } catch (_) {
        return null;
      }
    }
    final s = v.toString().trim();
    // Try ISO
    final iso = DateTime.tryParse(s.length >= 10 ? s.substring(0, 10) : s);
    if (iso != null) return iso.toLocal();
    // Try dd/MM/yyyy
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

  @override
  void initState() {
    super.initState();
    // Nếu tiêu đề chứa 'sắp' => chỉ hiện SẮP HẾT HẠN (loại bỏ đã hết hạn)
    // Nếu tiêu đề chứa 'hết' => chỉ hiện ĐÃ HẾT HẠN
    // Ngược lại giữ nguyên danh sách
    final title = widget.title.toLowerCase();
    final isNearExpiry = title.contains('sắp');
    final isExpiredView = title.contains('hết');
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (isNearExpiry) {
      _filtered = widget.warnings
          .where((w) {
            final d = _parseDate(w['han_dung']);
            return d != null
                ? !d.isBefore(today)
                : true; // nếu không có ngày thì giữ
          })
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } else if (isExpiredView) {
      _filtered = widget.warnings
          .where((w) {
            final d = _parseDate(w['han_dung']);
            return d != null
                ? d.isBefore(today)
                : false; // chỉ giữ có ngày và đã hết hạn
          })
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } else {
      _filtered = List<Map<String, dynamic>>.from(widget.warnings);
    }
    _searchCtrl.addListener(() => _applyFilter(_searchCtrl.text));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyFilter(String q) {
    final text = q.trim().toLowerCase();
    if (text.isEmpty) {
      setState(
        () => _filtered = List<Map<String, dynamic>>.from(widget.warnings),
      );
      return;
    }
    setState(() {
      _filtered = widget.warnings.where((w) {
        // Ghép các trường hay dùng để tìm
        final haystack =
            [
                  w['thuoc'],
                  w['so_lo'],
                  _formatDate(w['han_dung']), // tìm theo dd/MM/yyyy
                  w['ten'],
                  w['ma_thuoc'],
                ]
                .where((e) => e != null)
                .map((e) => e.toString().toLowerCase())
                .join(' | ');
        return haystack.contains(text);
      }).toList();
    });
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
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _applyFilter('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              onSubmitted: _applyFilter,
            ),
          ),
        ),
      ),
      body: _filtered.isEmpty
          ? const Center(child: Text('Không có mục cảnh báo nào.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: WarningsPanel(
                warnings: _filtered
                    .map(
                      (w) => {
                        ...w,
                        // ép hiển thị HSD theo dd/MM/yyyy
                        'han_dung': _formatDate(w['han_dung']),
                      },
                    )
                    .toList(),
              ),
            ),
    );
  }
}
