// lib/screens/drug_list_screen.dart (Hiển thị thông tin, nhưng không mở chi tiết)

import 'package:flutter/material.dart';
import 'package:frontend/services/inventory_service.dart';
import 'package:frontend/widgets/badge_pill.dart';

class DrugListScreen extends StatefulWidget {
  const DrugListScreen({super.key});

  @override
  State<DrugListScreen> createState() => _DrugListScreenState();
}

class _DrugListScreenState extends State<DrugListScreen> {
  late Future<List<dynamic>> _futureDrugs;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _futureDrugs = _fetchDrugs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<dynamic>> _fetchDrugs() async {
    final (ok, data, msg) = await InventoryService.getDrugs(q: _searchQuery);
    if (ok && data != null) return data;
    throw Exception(msg);
  }

  Future<void> _refresh() async {
    setState(() {
      _futureDrugs = _fetchDrugs();
    });
  }

  void _performSearch(String query) {
    final q = query.trim();
    if (_searchQuery != q) {
      setState(() {
        _searchQuery = q;
        _futureDrugs = _fetchDrugs();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Danh Sách Thuốc Đang Hoạt Động"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm theo Tên hoặc Mã thuốc...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10.0)),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
                contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
              ),
              onSubmitted: _performSearch,
              textInputAction: TextInputAction.search,
            ),
          ),

          // Danh sách
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _futureDrugs,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    _searchQuery.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text("Lỗi tải dữ liệu: ${snapshot.error}"),
                  );
                }

                final drugs = snapshot.data ?? [];

                if (drugs.isEmpty && _searchQuery.isNotEmpty) {
                  return Center(
                    child: Text("Không tìm thấy kết quả cho: '$_searchQuery'."),
                  );
                }
                if (drugs.isEmpty) {
                  return const Center(
                    child: Text("Chưa có thuốc nào được khai báo."),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    itemCount: drugs.length,
                    itemBuilder: (context, index) {
                      final drug = drugs[index];
                      final hoatDong = drug['hoat_dong'] == true;

                      return ListTile(
                        leading: const Icon(
                          Icons.medical_services_outlined,
                          color: Colors.blueGrey,
                        ),
                        title: Text(drug['ten_thuoc'] ?? 'N/A'),
                        // vẫn hiển thị thông tin phụ
                        subtitle: Text(
                          'Mã: ${drug['ma_thuoc'] ?? 'N/A'} | Ngưỡng cảnh báo: ${drug['nguong_canh_bao'] ?? 0}',
                        ),
                        trailing: BadgePill(
                          text: hoatDong ? "Hoạt động" : "Ngừng HĐ",
                          color: hoatDong ? Colors.green : Colors.grey,
                        ),
                        // không mở chi tiết khi bấm
                        onTap: null,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
