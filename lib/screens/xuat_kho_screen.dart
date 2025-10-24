import 'package:flutter/material.dart';
import 'package:frontend/services/inventory_service.dart';

class XuatKhoScreen extends StatefulWidget {
  const XuatKhoScreen({super.key});

  @override
  State<XuatKhoScreen> createState() => _XuatKhoScreenState();
}

class _XuatKhoScreenState extends State<XuatKhoScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _busy = false;

  // TRẠNG THÁI MỚI CHO DROPDOWN
  List<dynamic> _drugs = [];
  int? _selectedDrugId;
  bool _loadingDrugs = true;
  // Lô theo thuốc đã chọn
  List<dynamic> _selectedLots = [];
  bool _loadingLots = false;
  bool _hasValidLots = true;

  final _phieuNoCtrl = TextEditingController(
    text: 'PX${DateTime.now().millisecondsSinceEpoch % 1000}',
  );
  final _ghiChuCtrl = TextEditingController();
  final _soLuongCtrl = TextEditingController(text: '10');
  final _donGiaXuatCtrl = TextEditingController(text: '15.0');

  @override
  void initState() {
    super.initState();
    _loadDrugs(); // Tải danh sách thuốc khi màn hình khởi tạo
  }

  Future<void> _loadDrugs() async {
    final (ok, data, msg) = await InventoryService.getDrugs();
    if (ok && data != null) {
      setState(() {
        _drugs = data;
        _loadingDrugs = false;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải danh sách thuốc: $msg')),
        );
        setState(() => _loadingDrugs = false);
      }
    }
  }

  // Khi chọn thuốc, tải lô tương ứng và kiểm tra HSD
  Future<void> _onDrugSelected(int? id) async {
    setState(() {
      _selectedDrugId = id;
      _selectedLots = [];
      _loadingLots = true;
      _hasValidLots = true;
    });

    if (id == null) {
      setState(() {
        _loadingLots = false;
      });
      return;
    }

    final (ok, data, msg) = await InventoryService.getLots(drugId: id);
    if (!(ok && data != null)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải lô thuốc: $msg')));
      }
      setState(() {
        _loadingLots = false;
        _selectedLots = [];
        _hasValidLots = false;
      });
      return;
    }

    // Kiểm tra xem có lô nào chưa hết hạn hay không
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    bool hasValid = false;
    for (final l in data) {
      final han = l['han_dung'];
      DateTime? dt;
      if (han is String) {
        // Try ISO first
        dt = DateTime.tryParse(han);
        if (dt == null && han.contains('/')) {
          final parts = han.split('/');
          if (parts.length == 3) {
            final d = int.tryParse(parts[0]);
            final m = int.tryParse(parts[1]);
            final y = int.tryParse(parts[2]);
            if (d != null && m != null && y != null) dt = DateTime(y, m, d);
          }
        }
      } else if (han is int) {
        var millis = han;
        if (millis < 1000000000000) millis *= 1000;
        dt = DateTime.fromMillisecondsSinceEpoch(millis);
      }
      if (dt != null && !dt.isBefore(today)) {
        hasValid = true;
        break;
      }
    }

    setState(() {
      _selectedLots = data;
      _loadingLots = false;
      _hasValidLots = hasValid;
    });
  }

  @override
  void dispose() {
    _phieuNoCtrl.dispose();
    _ghiChuCtrl.dispose();
    _soLuongCtrl.dispose();
    _donGiaXuatCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // KIỂM TRA BẮT BUỘC CHỌN THUỐC
    if (_selectedDrugId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn thuốc cần xuất.')),
        );
      }
      return;
    }

    FocusScope.of(context).unfocus();

    try {
      setState(() => _busy = true);

      final payload = {
        "so_phieu": _phieuNoCtrl.text.trim(),
        "loai": "XUAT",
        "ngay_phieu": DateTime.now().toIso8601String().split('T')[0],
        "ghi_chu": _ghiChuCtrl.text.trim(),
        "chi_tiets": [
          {
            "thuoc_id": _selectedDrugId, // SỬ DỤNG ID ĐÃ CHỌN
            "so_luong": int.tryParse(_soLuongCtrl.text),
            "don_gia": double.tryParse(_donGiaXuatCtrl.text),
          },
        ],
      };

      final (ok, msg) = await InventoryService.sendXuatKho(payload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

      if (ok) {
        Navigator.of(context).pop(true);
      }
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("📤 Tạo Phiếu Xuất Kho")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // THÔNG TIN PHIẾU CHUNG
              TextFormField(
                controller: _phieuNoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Số Phiếu Xuất (Tự động)',
                ),
                readOnly: true,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ghiChuCtrl,
                decoration: const InputDecoration(labelText: 'Ghi chú'),
                keyboardType: TextInputType.multiline,
              ),
              const Divider(height: 30),

              // CHI TIẾT THUỐC (Sử dụng Dropdown)
              const Text(
                "Chi tiết Thuốc",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // 💡 DROPDOWN THAY THẾ TEXTFIELD
              _loadingDrugs
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'Chọn Thuốc',
                      ),
                      value: _selectedDrugId,
                      items: _drugs.map<DropdownMenuItem<int>>((drug) {
                        return DropdownMenuItem<int>(
                          value: drug['id'] as int,
                          child: Text(
                            '${drug['ten_thuoc']} (${drug['ma_thuoc']})',
                          ),
                        );
                      }).toList(),
                      onChanged: (int? newValue) {
                        _onDrugSelected(newValue);
                      },
                      validator: (value) =>
                          value == null ? 'Vui lòng chọn thuốc' : null,
                    ),

              const SizedBox(height: 12),
              // Hiển thị trạng thái lô theo thuốc đã chọn
              if (_loadingLots)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_selectedDrugId != null && !_hasValidLots)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Không có lô còn hạn cho thuốc này — không thể xuất.',
                    style: TextStyle(color: Colors.red),
                  ),
                )
              else if (_selectedDrugId != null && _selectedLots.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Lô khả dụng: ${_selectedLots.length} — xuất sẽ dùng lô có hạn dùng còn hiệu lực.',
                    style: const TextStyle(color: Colors.green),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _soLuongCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Số lượng xuất',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => int.tryParse(v ?? '') == null
                          ? 'Số lượng phải là số'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _donGiaXuatCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Đơn giá xuất',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => double.tryParse(v ?? '') == null
                          ? 'Đơn giá phải là số'
                          : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              // NÚT LƯU
              FilledButton.icon(
                onPressed: _busy || _loadingDrugs || !_hasValidLots
                    ? null
                    : _submit, // Disable nếu đang bận, đang tải hoặc không có lô hợp lệ
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(_busy ? 'Đang tạo phiếu...' : 'Lưu Phiếu Xuất'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
