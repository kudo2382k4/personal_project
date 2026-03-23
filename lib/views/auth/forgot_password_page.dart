import 'package:flutter/material.dart';
import '../../viewmodels/auth/forgot_password_viewmodel.dart';
import 'otp_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _contactController = TextEditingController();
  final _vm = ForgotPasswordViewmodel();

  static const Color _primaryRed = Color(0xFF6B0000);
  static const Color _darkRed = Color(0xFF4A0000);
  static const Color _gold = Color(0xFFFFD700);

  @override
  void dispose() {
    _contactController.dispose();
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryRed,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 60),

              const Center(
                child: Text(
                  'Quên mật khẩu',
                  style: TextStyle(color: _gold, fontSize: 24, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Nhập số điện thoại đã đăng ký\nMã OTP sẽ được gửi qua SMS',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
              const SizedBox(height: 32),

              _buildContactField(),
              const SizedBox(height: 8),

              // Hiển thị lỗi từ ViewModel
              ListenableBuilder(
                listenable: _vm,
                builder: (_, child) {
                  if (_vm.error != null) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text('⚠️ ${_vm.error}',
                          style: TextStyle(color: Colors.yellow.shade200, fontSize: 12)),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 24),

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

  Widget _buildContactField() {
    return Container(
      decoration: BoxDecoration(
        color: _gold,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: TextField(
        controller: _contactController,
        keyboardType: TextInputType.phone,
        style: const TextStyle(color: _darkRed, fontSize: 16, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          hintText: 'Số điện thoại (ví dụ: 0901234567)',
          hintStyle: TextStyle(color: _darkRed.withValues(alpha: 0.45), fontSize: 14),
          prefixIcon: Icon(Icons.phone_outlined, color: _darkRed.withValues(alpha: 0.6)),
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
            : const Text('Gửi mã OTP', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF4A0000), letterSpacing: 0.5)),
      ),
    );
  }

  Future<void> _onConfirmPressed(BuildContext context) async {
    final input = _contactController.text.trim();
    if (input.isEmpty) {
      _showSnack('Vui lòng nhập email hoặc số điện thoại!');
      return;
    }

    // Bước 1: Kiểm tra user tồn tại trong DB
    final found = await _vm.lookupUser(input);
    if (!found || !context.mounted) return;

    // Bước 2: Gửi OTP thực tế
    final result = await _vm.sendOtpToContact(input);
    if (!context.mounted) return;

    switch (result) {
      case OtpEmailSent():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📧 Mã OTP đã gửi đến $input – kiểm tra hộp thư!'),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 4),
          ),
        );

      case OtpFirebaseSmsSent():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📱 Mã OTP đã gửi qua SMS đến $input'),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 4),
          ),
        );

      case OtpPhoneDevMode(:final otp):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔑 [Dev] OTP SĐT: $otp (hiệu lực 3 phút)',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.orange.shade700,
            duration: const Duration(seconds: 10),
          ),
        );

      case OtpSendFailed():
        return; // lỗi hiển thị qua _vm.error trong ListenableBuilder
    }

    await Future.delayed(const Duration(milliseconds: 300));
    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpPage(contact: input, userId: _vm.foundUserId!, vm: _vm),
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: _darkRed),
    );
  }
}
