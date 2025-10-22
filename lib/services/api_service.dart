import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Auth-only API service
class ApiService {
  /// Với Android emulator, backend chạy trên máy host thì dùng: http://10.0.2.2:3000
  static String baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  static const _storage = FlutterSecureStorage();

  // ===== Token helpers =====
  static Future<String?> get token async => await _storage.read(key: 'token');

  static Future<void> setToken(String? value) async {
    if (value == null) {
      await _storage.delete(key: 'token');
    } else {
      await _storage.write(key: 'token', value: value);
    }
  }

  static Uri _uri(String path) => Uri.parse('$baseUrl$path');

  // ====== AUTH APIs ======

  /// Đăng ký (nếu cần dùng). Backend: POST /api/auth/register
  static Future<(bool ok, String message)> register({
    required String username,
    required String password,
    String? fullName,
    String? email,
  }) async {
    try {
      final resp = await http
          .post(
            _uri('/api/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': username,
              'password': password,
              if (fullName != null) 'ho_ten': fullName,
              if (email != null) 'email': email,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (resp.statusCode == 201) {
        return (true, 'Đăng ký thành công');
      }
      return (false, _errorFrom(resp));
    } catch (_) {
      return (false, 'Không thể kết nối máy chủ.');
    }
  }

  /// Đăng nhập. Backend: POST /api/auth/login -> { token, user }
  static Future<(bool ok, String message)> login({
    required String username,
    required String password,
  }) async {
    try {
      final resp = await http
          .post(
            _uri('/api/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final t = (data['token'] as String?)?.trim();
        if (t == null || t.isEmpty) return (false, 'Không nhận được token.');
        await setToken(t); // lưu token để dùng cho các API cần xác thực
        return (true, 'Đăng nhập thành công');
      }
      return (false, _errorFrom(resp));
    } catch (_) {
      return (false, 'Không thể kết nối máy chủ.');
    }
  }

  /// Lấy thông tin người dùng hiện tại. Backend: GET /api/auth/me
  static Future<(bool ok, Map<String, dynamic>? user, String message)>
  me() async {
    try {
      final t = await token;
      if (t == null || t.isEmpty) return (false, null, 'Chưa đăng nhập.');
      final resp = await http
          .get(_uri('/api/auth/me'), headers: {'Authorization': 'Bearer $t'})
          .timeout(const Duration(seconds: 12));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return (true, data, 'OK');
      }
      return (false, null, _errorFrom(resp));
    } catch (_) {
      return (false, null, 'Không thể kết nối máy chủ.');
    }
  }

  /// Đổi mật khẩu. Backend: POST /api/auth/change-password {old, new}
  static Future<(bool ok, String message)> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final t = await token;
      if (t == null || t.isEmpty) return (false, 'Chưa đăng nhập.');
      final resp = await http
          .post(
            _uri('/api/auth/change-password'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $t',
            },
            body: jsonEncode({'old': oldPassword, 'new': newPassword}),
          )
          .timeout(const Duration(seconds: 15));

      if (resp.statusCode == 200) {
        return (true, 'Đổi mật khẩu thành công');
      }
      return (false, _errorFrom(resp));
    } catch (_) {
      return (false, 'Không thể kết nối máy chủ.');
    }
  }

  /// Đăng xuất người dùng (gọi API + xoá token cục bộ)
  static Future<(bool ok, String message)> logout() async {
    try {
      final t = await token;
      if (t == null || t.isEmpty) {
        await setToken(null);
        return (true, 'Đã đăng xuất (chưa đăng nhập)');
      }

      final resp = await http
          .post(
            _uri('/api/auth/logout'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $t',
            },
          )
          .timeout(const Duration(seconds: 12));

      // Dù có lỗi thì vẫn xoá token cục bộ để tránh treo đăng nhập
      await setToken(null);

      if (resp.statusCode == 200) {
        return (true, 'Đăng xuất thành công');
      } else {
        return (false, _errorFrom(resp));
      }
    } catch (_) {
      // lỗi mạng hoặc timeout → vẫn xoá token cho an toàn
      await setToken(null);
      return (false, 'Không thể kết nối máy chủ.');
    }
  }

  // ===== Helpers =====
  static String _errorFrom(http.Response r) {
    try {
      final data = jsonDecode(r.body);
      return data['message']?.toString() ?? 'Lỗi ${r.statusCode}';
    } catch (_) {
      return 'Lỗi ${r.statusCode}';
    }
  }
}
