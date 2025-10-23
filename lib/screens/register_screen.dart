import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  bool _busy = false;
  bool _showPass = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      // Hiển thị cảnh báo rõ ràng khi form chưa hợp lệ
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền thông tin hợp lệ.')),
      );
      return;
    }
    FocusScope.of(context).unfocus();

    try {
      setState(() => _busy = true);
      final (ok, msg) = await ApiService.register(
        username: _usernameCtrl.text.trim(),
        password: _passwordCtrl.text,
        fullName: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      if (ok) {
        // Quay về màn đăng nhập; nếu không có route trước đó, thử replace sang '/login'
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // final api = ApiService.baseUrl; // hiển thị khi cần debug endpoint

    return Scaffold(
      // Nền xanh dược đồng bộ với Login
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F9D58), Color(0xFF0A7F46)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // vài “viên thuốc” trang trí
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

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.local_pharmacy,
                          size: 40,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Quản Lý Kho Thuốc',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Card form
                    Card(
                      elevation: 12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                        child: Form(
                          key: _formKey,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 12),

                              // Username
                              TextFormField(
                                controller: _usernameCtrl,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Tài khoản',
                                  hintText: 'vd: admin',
                                  prefixIcon: Icon(Icons.person_outline),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Nhập tài khoản';
                                  }
                                  if (!RegExp(
                                    r'^[a-zA-Z0-9._-]{3,}$',
                                  ).hasMatch(v.trim())) {
                                    return 'Tối thiểu 3 ký tự, chỉ chữ/số/._-';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              // Password
                              TextFormField(
                                controller: _passwordCtrl,
                                obscureText: !_showPass,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText: 'Mật khẩu (6 chữ số)',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  border: const OutlineInputBorder(),
                                  suffixIcon: IconButton(
                                    onPressed: _busy
                                        ? null
                                        : () => setState(
                                            () => _showPass = !_showPass,
                                          ),
                                    icon: Icon(
                                      _showPass
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(6),
                                ],
                                validator: (v) {
                                  final s = v ?? '';
                                  if (!RegExp(r'^\d{6}$').hasMatch(s)) {
                                    return 'Mật khẩu phải gồm đúng 6 chữ số';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              // Confirm
                              TextFormField(
                                controller: _confirmCtrl,
                                obscureText: !_showConfirm,
                                decoration: InputDecoration(
                                  labelText: 'Nhập lại mật khẩu',
                                  prefixIcon: const Icon(Icons.lock_reset),
                                  border: const OutlineInputBorder(),
                                  suffixIcon: IconButton(
                                    onPressed: _busy
                                        ? null
                                        : () => setState(
                                            () => _showConfirm = !_showConfirm,
                                          ),
                                    icon: Icon(
                                      _showConfirm
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(6),
                                ],
                                validator: (v) {
                                  final s = v ?? '';
                                  if (!RegExp(r'^\d{6}$').hasMatch(s)) {
                                    return 'Nhập lại mật khẩu 6 chữ số';
                                  }
                                  if (s != _passwordCtrl.text)
                                    return 'Không khớp';
                                  return null;
                                },
                              ),

                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _nameCtrl,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Họ tên',
                                  prefixIcon: Icon(
                                    Icons.account_circle_outlined,
                                  ),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email_outlined),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return null;
                                  final ok = RegExp(
                                    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                  ).hasMatch(v);
                                  return ok ? null : 'Email không hợp lệ';
                                },
                              ),
                              const SizedBox(height: 20),

                              // Submit
                              SizedBox(
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
                                      : const Icon(Icons.person_add_alt),
                                  label: Text(
                                    _busy ? 'Đang tạo...' : 'Đăng ký',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Đã có tài khoản? → Đăng nhập
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('Đã có tài khoản?'),
                                  TextButton(
                                    onPressed: _busy
                                        ? null
                                        : () {
                                            if (Navigator.of(
                                              context,
                                            ).canPop()) {
                                              Navigator.of(context).pop();
                                            } else {
                                              Navigator.of(
                                                context,
                                              ).pushReplacementNamed('/login');
                                            }
                                          },
                                    child: const Text('Đăng nhập ngay'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),
                    Opacity(
                      opacity: 0.9,
                      child: Text(
                        '© ${DateTime.now().year} Kho Dược — Tạo tài khoản nhân sự kho.',
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

  // Trang trí “viên thuốc” như Login
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
