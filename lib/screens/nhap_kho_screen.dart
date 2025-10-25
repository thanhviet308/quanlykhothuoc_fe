// lib/screens/nhap_kho_screen.dart

import 'package:flutter/material.dart';
import 'package:frontend/services/inventory_service.dart';

class NhapKhoScreen extends StatefulWidget {
  const NhapKhoScreen({super.key});

  @override
  State<NhapKhoScreen> createState() => _NhapKhoScreenState();
}

class _NhapKhoScreenState extends State<NhapKhoScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _busy = false;

  // State mới cho Dropdown
  List<dynamic> _drugs = [];
  int? _selectedDrugId;
  bool _loadingDrugs = true;

  final _phieuNoCtrl = TextEditingController(
    text: 'PN${DateTime.now().millisecondsSinceEpoch % 1000}',
  );
  final _ghiChuCtrl = TextEditingController();
  final _soLuongCtrl = TextEditingController(text: '100');
  final _donGiaCtrl = TextEditingController(text: '12.5');
  final _soLoCtrl = TextEditingController(text: 'LOTOX-123');
  // 💡 KHỞI TẠO HẠN DÙNG MẶC ĐỊNH LÀ 1 NĂM SAU
  final _hanDungCtrl = TextEditingController(
    text: DateTime.now()
        .add(const Duration(days: 365))
        .toIso8601String()
        .split('T')[0],
  );

  @override
  void initState() {
    super.initState();
    _loadDrugs();
  }

  // Hỗ trợ nhập số theo thói quen VN: cho phép "." làm phân tách hàng nghìn và "," làm dấu thập phân
  double? _parseVnNumber(String? v) {
    if (v == null) return null;
    final s = v
        .replaceAll(RegExp(r'\s'), '') // bỏ khoảng trắng
        .replaceAll('.', '') // bỏ dấu chấm ngăn cách nghìn
        .replaceAll(',', '.'); // chuyển dấu phẩy thành dấu chấm thập phân
    return double.tryParse(s);
  }

  // 💡 HÀM MỚI: MỞ DATE PICKER
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(), // Không cho chọn ngày trong quá khứ
      lastDate: DateTime(2050),
    );
    if (picked != null) {
      setState(() {
        // Cập nhật trường điều khiển với định dạng YYYY-MM-DD
        _hanDungCtrl.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  Future<void> _loadDrugs() async {
    // ... (logic load drugs giữ nguyên)
    final (ok, data, msg) = await InventoryService.getDrugs();
    if (ok && data != null) {
      setState(() {
        _drugs = data;
        _loadingDrugs = false;
      });
    } else {
      // Xử lý lỗi tải thuốc
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải danh sách thuốc: $msg')),
        );
        setState(() => _loadingDrugs = false);
      }
    }
  }

  @override
  void dispose() {
    _phieuNoCtrl.dispose();
    _ghiChuCtrl.dispose();
    _soLuongCtrl.dispose();
    _donGiaCtrl.dispose();
    _soLoCtrl.dispose();
    _hanDungCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // ... (logic submit giữ nguyên)
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDrugId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn thuốc cần nhập.')),
        );
      }
      return;
    }

    FocusScope.of(context).unfocus();

    try {
      setState(() => _busy = true);

      final payload = {
        "so_phieu": _phieuNoCtrl.text.trim(),
        "loai": "NHAP",
        "ngay_phieu": DateTime.now().toIso8601String().split('T')[0],
        "ghi_chu": _ghiChuCtrl.text.trim(),
        "chi_tiets": [
          {
            "thuoc_id": _selectedDrugId,
            "so_luong": int.tryParse(_soLuongCtrl.text),
            "don_gia": _parseVnNumber(_donGiaCtrl.text),
            "so_lo": _soLoCtrl.text.trim(),
            "han_dung": _hanDungCtrl.text.trim(), // Định dạng BE cần
            "lo_id": null,
          },
        ],
      };

      final (ok, msg) = await InventoryService.sendNhapKho(payload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

      if (ok) {
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("📝 Tạo Phiếu Nhập Kho")),
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
                  labelText: 'Số Phiếu Nhập (Tự động)',
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
                "Chi tiết Thuốc (Nhập Lô Mới)",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // THAY THẾ TEXTFIELD BẰNG DROPDOWN
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
                        setState(() {
                          _selectedDrugId = newValue;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Vui lòng chọn thuốc' : null,
                    ),

              const SizedBox(height: 12),
              // ... (Các trường khác)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _soLoCtrl,
                      decoration: const InputDecoration(labelText: 'Số Lô'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Bắt buộc' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _hanDungCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Hạn Dùng (YYYY-MM-DD)',
                        // 💡 THÊM ICON LỊCH
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      // 💡 ĐẶT READONLY VÀ ONTAP
                      readOnly: true,
                      onTap: _selectDate,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Bắt buộc' : null,
                      keyboardType: TextInputType.datetime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _soLuongCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Số lượng nhập',
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
                      controller: _donGiaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Đơn giá nhập',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) => _parseVnNumber(v) == null
                          ? 'Đơn giá phải là số'
                          : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              // NÚT LƯU
              FilledButton.icon(
                onPressed: _busy || _loadingDrugs ? null : _submit,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(_busy ? 'Đang tạo phiếu...' : 'Lưu Phiếu Nhập'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
