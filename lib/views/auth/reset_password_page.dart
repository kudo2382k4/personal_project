import 'package:flutter/material.dart';
import '../../viewmodels/auth/forgot_password_viewmodel.dart';
import 'login_page.dart';

class ResetPasswordPage extends StatefulWidget {
  final int userId;

  const ResetPasswordPage({super.key, required this.userId});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _vm = ForgotPasswordViewmodel();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  static const Color _primaryRed = Color(0xFF6B0000);
  static const Color _darkRed = Color(0xFF4A0000);
  static const Color _gold = Color(0xFFFFD700);

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryRed,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 40),

              const Text(
                'Đặt mật khẩu mới',
                style: TextStyle(color: _gold, fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Mật khẩu phải có ít nhất 6 ký tự',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 28),

              _buildLabel('Mật khẩu mới'),
              const SizedBox(height: 8),
              _buildPasswordField(
                controller: _passwordController,
                hint: 'Nhập mật khẩu mới',
                obscure: _obscurePassword,
                onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              const SizedBox(height: 16),

              _buildLabel('Xác nhận mật khẩu'),
              const SizedBox(height: 8),
              _buildPasswordField(
                controller: _confirmController,
                hint: 'Nhập lại mật khẩu mới',
                obscure: _obscureConfirm,
                onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              const SizedBox(height: 32),

              // Hiển thị lỗi từ VM
              ListenableBuilder(
                listenable: _vm,
                builder: (_, child) {
                  if (_vm.error != null) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text('⚠️ ${_vm.error}',
                          style: TextStyle(color: Colors.yellow.shade200, fontSize: 12)),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              ListenableBuilder(
                listenable: _vm,
                builder: (_, child) => _buildConfirmButton(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
        ),
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _gold, width: 2)),
          child: ClipOval(child: Image.asset('assets/images/logo.png', fit: BoxFit.cover)),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) => Text(text,
      style: const TextStyle(color: _gold, fontSize: 14, fontWeight: FontWeight.w600));

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _gold,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: _darkRed, fontSize: 16, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          hintText: hint,
          hintStyle: TextStyle(color: _darkRed.withValues(alpha: 0.45), fontSize: 14),
          suffixIcon: GestureDetector(
            onTap: onToggle,
            child: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: _darkRed.withValues(alpha: 0.7)),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _vm.loading ? null : () => _onConfirmPressed(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: _gold,
          elevation: 6,
          shadowColor: Colors.black.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: _vm.loading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF4A0000)))
            : const Text('Đổi mật khẩu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF4A0000), letterSpacing: 0.5)),
      ),
    );
  }

  Future<void> _onConfirmPressed(BuildContext context) async {
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (password.isEmpty || confirm.isEmpty) {
      _showSnack('Vui lòng nhập đầy đủ mật khẩu!');
      return;
    }
    if (password.length < 6) {
      _showSnack('Mật khẩu phải có ít nhất 6 ký tự!');
      return;
    }
    if (password != confirm) {
      _showSnack('Mật khẩu không khớp!');
      return;
    }

    final success = await _vm.resetPassword(widget.userId, password);
    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Đổi mật khẩu thành công! Vui lòng đăng nhập lại.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      await Future.delayed(const Duration(seconds: 2));
      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: _darkRed),
    );
  }
}
