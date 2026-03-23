import 'package:flutter/material.dart';
import '../../di.dart';
import '../../viewmodels/register/register_viewmodel.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  late final RegisterViewmodel _vm;

  static const Color _primaryRed = Color(0xFF6B0000);
  static const Color _darkRed = Color(0xFF4A0000);
  static const Color _gold = Color(0xFFFFD700);

  @override
  void initState() {
    super.initState();
    _vm = buildRegisterVM();
    _vm.addListener(_onVmChanged);
  }

  void _onVmChanged() {
    if (!mounted) return;

    // Đăng ký thành công → quay về đăng nhập
    if (_vm.success && !_vm.loading) {
      _vm.cleanSuccess(); // reset ngay để tránh gọi lại nhiều lần
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Đăng ký tài khoản thành công!',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2E7D32),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      // Quay về LoginPage sau 1.5 giây
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) Navigator.pop(context);
      });
    }

    // Đăng ký thất bại
    if (_vm.error != null && !_vm.loading) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _vm.error!,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF4A0000),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      _vm.cleanError();
    }

    setState(() {});
  }

  @override
  void dispose() {
    _vm.removeListener(_onVmChanged);
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryRed,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: Nút back + Logo ──
              _buildHeader(context),
              const SizedBox(height: 28),

              // ── Tiêu đề ──
              const Center(
                child: Text(
                  'Đăng ký tài khoản',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Tên
              _buildLabel('Tên'),
              const SizedBox(height: 6),
              _buildTextField(controller: _nameController, hint: 'Nhập tên của bạn'),
              const SizedBox(height: 16),

              // Số điện thoại
              _buildLabel('Số điện thoại'),
              const SizedBox(height: 6),
              _buildTextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                hint: 'Nhập số điện thoại',
              ),
              const SizedBox(height: 16),

              // Địa chỉ
              _buildLabel('Địa chỉ'),
              const SizedBox(height: 6),
              _buildTextField(controller: _addressController, hint: 'Nhập địa chỉ'),
              const SizedBox(height: 16),

              // Mật khẩu
              _buildLabel('mật khẩu'),
              const SizedBox(height: 6),
              _buildPasswordField(
                controller: _passwordController,
                hint: 'Nhập mật khẩu',
                obscure: _obscurePassword,
                onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              const SizedBox(height: 16),

              // Xác nhận mật khẩu
              _buildLabel('xác nhận mật khẩu'),
              const SizedBox(height: 6),
              _buildPasswordField(
                controller: _confirmPasswordController,
                hint: 'Nhập lại mật khẩu',
                obscure: _obscureConfirm,
                onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              const SizedBox(height: 28),

              // Nút Đăng ký
              _buildRegisterButton(context),
              const SizedBox(height: 16),

              // Đã có tài khoản?
              _buildLoginRow(context),
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
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _gold, width: 2),
          ),
          child: ClipOval(
            child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(color: _gold, fontSize: 14, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    required String hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _gold,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 3)),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: _darkRed, fontSize: 15, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          hintText: hint,
          hintStyle: TextStyle(color: _darkRed.withOpacity(0.45), fontSize: 14),
        ),
      ),
    );
  }

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
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 3)),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: _darkRed, fontSize: 15, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          hintText: hint,
          hintStyle: TextStyle(color: _darkRed.withOpacity(0.45), fontSize: 14),
          suffixIcon: GestureDetector(
            onTap: onToggle,
            child: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: _darkRed.withOpacity(0.7)),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _vm.loading ? null : () => _onRegisterPressed(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: _gold,
          disabledBackgroundColor: _gold.withOpacity(0.6),
          elevation: 6,
          shadowColor: Colors.black.withOpacity(0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: _vm.loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF4A0000)),
              )
            : const Text(
                'Đăng ký',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF4A0000), letterSpacing: 1.0),
              ),
      ),
    );
  }

  Widget _buildLoginRow(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Bạn đã có tài khoản? ', style: TextStyle(color: Colors.white70, fontSize: 13)),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Text(
              'Đăng nhập',
              style: TextStyle(
                color: _gold,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
                decorationColor: _gold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onRegisterPressed(BuildContext context) {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (name.isEmpty || phone.isEmpty || address.isEmpty || password.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng điền đầy đủ thông tin!'),
          backgroundColor: Color(0xFF4A0000),
        ),
      );
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mật khẩu không khớp!'),
          backgroundColor: Color(0xFF4A0000),
        ),
      );
      return;
    }

    // Gọi ViewModel để đăng ký
    _vm.register(name: name, phoneNumber: phone, address: address, password: password);
  }
}
