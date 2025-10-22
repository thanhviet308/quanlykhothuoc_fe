import 'package:flutter/material.dart';
import 'package:frontend/pages/home_page.dart';
import '../services/api_service.dart';
import 'register_screen.dart';
// đảm bảo file này chứa class HomePage

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    try {
      setState(() => _busy = true);

      final (ok, msgOrToken) = await ApiService.login(
        username: _usernameCtrl.text.trim(),
        password: _passwordCtrl.text,
      );

      if (!mounted) return;

      if (ok) {
        final token = msgOrToken; // JWT từ backend
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => HomePage(
              apiBase:
                  '${ApiService.baseUrl}/api', // ví dụ: http://10.0.2.2:3000/api
              token: token,
            ),
          ),
        );
      } else {
        _showSnack(msgOrToken);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Nền gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F9D58), Color(0xFF0A7F46)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Trang trí “viên thuốc”
          Positioned(
            top: -30,
            right: -20,
            child: _pillDecoration(160, 48, 18, 0.08),
          ),
          Positioned(
            bottom: 60,
            left: -10,
            child: _pillDecoration(120, 40, -12, 0.06),
          ),
          Positioned(
            bottom: -30,
            right: -30,
            child: _pillDecoration(220, 54, 14, 0.05),
          ),

          // Nội dung chính
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.local_pharmacy,
                          size: 44,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Quản Lý Kho Thuốc',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Đăng nhập để tiếp tục',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 22),

                    Card(
                      elevation: 12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _usernameCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Tài khoản',
                                  hintText: 'vd: kho01',
                                  prefixIcon: Icon(Icons.person_outline),
                                  border: OutlineInputBorder(),
                                ),
                                textInputAction: TextInputAction.next,
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? 'Nhập tài khoản'
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _passwordCtrl,
                                obscureText: _obscure,
                                decoration: InputDecoration(
                                  labelText: 'Mật khẩu',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  border: const OutlineInputBorder(),
                                  suffixIcon: IconButton(
                                    onPressed: _busy
                                        ? null
                                        : () => setState(
                                            () => _obscure = !_obscure,
                                          ),
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                    tooltip: _obscure
                                        ? 'Hiện mật khẩu'
                                        : 'Ẩn mật khẩu',
                                  ),
                                ),
                                onFieldSubmitted: (_) => _submit(),
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Nhập mật khẩu'
                                    : null,
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: FilledButton.icon(
                                  onPressed: _busy ? null : _submit,
                                  icon: _busy
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.login),
                                  label: Text(
                                    _busy ? 'Đang đăng nhập...' : 'Đăng nhập',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('Chưa có tài khoản?'),
                                  TextButton(
                                    onPressed: _busy
                                        ? null
                                        : () => Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const RegisterScreen(),
                                            ),
                                          ),
                                    child: const Text('Đăng ký ngay'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    Opacity(
                      opacity: 0.9,
                      child: Text(
                        '© ${DateTime.now().year} Kho Dược — Hệ thống quản lý tồn kho, hạn dùng & cảnh báo.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pillDecoration(double w, double h, double tilt, double opacity) {
    return Opacity(
      opacity: opacity,
      child: Transform.rotate(
        angle: tilt * 3.1415926535 / 180,
        child: Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(h),
            gradient: const LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFFE8F5E9)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: const [
              BoxShadow(
                blurRadius: 18,
                offset: Offset(0, 6),
                color: Color(0x33000000),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
