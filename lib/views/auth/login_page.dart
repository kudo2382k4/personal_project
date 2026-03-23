import 'package:flutter/material.dart';
import '../../di.dart';
import '../../viewmodels/login/login_viewmodel.dart';
import '../home/home_page.dart';
import 'forgot_password_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = true;
  bool _obscurePassword = true;

  late final LoginViewmodel _vm;

  // Màu chủ đạo theo chủ đề Tết
  static const Color _primaryRed = Color(0xFFB71C1C);
  static const Color _darkRed = Color(0xFF8B0000);
  static const Color _gold = Color(0xFFFFD700);

  @override
  void initState() {
    super.initState();
    _vm = buildLoginVM();
    _vm.addListener(_onVmChanged);
  }

  void _onVmChanged() {
    if (!mounted) return;

    // Đăng nhập thành công → chuyển sang HomePage
    if (_vm.session != null && !_vm.loading) {
      final userName = _vm.session!.user.name;
      final userId = int.tryParse(_vm.session!.user.id) ?? 0;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(userName: userName, userId: userId),
        ),
      );
      return;
    }

    // Đăng nhập thất bại
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
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryRed,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Banner Tết thật từ assets ──
            _buildTetBanner(),

            // ── Phần nội dung đăng nhập ──
            Container(
              color: _primaryRed,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
              child: Column(
                children: [
                  // Logo Chợ Tết thật từ assets
                  _buildLogoSection(),
                  const SizedBox(height: 24),

                  // Input Số điện thoại
                  _buildLabel('Số điện thoại'),
                  const SizedBox(height: 6),
                  _buildPhoneField(),
                  const SizedBox(height: 16),

                  // Input Mật khẩu
                  _buildLabel('mật khẩu'),
                  const SizedBox(height: 6),
                  _buildPasswordField(),
                  const SizedBox(height: 12),

                  // Checkbox + Quên mật khẩu
                  _buildRememberRow(),
                  const SizedBox(height: 20),

                  // Nút Đăng nhập
                  _buildLoginButton(),
                  const SizedBox(height: 16),

                  // ── Divider hoặc ──
                  _buildOrDivider(),
                  const SizedBox(height: 16),

                  // ── Nút đăng nhập Google ──
                  _buildGoogleSignInButton(),
                  const SizedBox(height: 16),

                  // Đăng ký
                  _buildRegisterRow(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Banner thật từ assets/images/banner.png ──
  Widget _buildTetBanner() {
    return SizedBox(
      width: double.infinity,
      height: 200,
      child: Image.asset(
        'assets/images/banner.png',
        fit: BoxFit.cover,
      ),
    );
  }

  // ── Logo thật từ assets/images/logo.png ──
  Widget _buildLogoSection() {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _gold, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/logo.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  // ── Label chữ vàng ──
  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          color: _gold,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ── Input số điện thoại ──
  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        color: _gold,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        style: const TextStyle(
          color: _darkRed,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
          hintText: 'Nhập số điện thoại',
          hintStyle: TextStyle(color: _darkRed.withOpacity(0.5), fontSize: 14),
        ),
      ),
    );
  }

  // ── Input mật khẩu ──
  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: _gold,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        style: const TextStyle(
          color: _darkRed,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
          hintText: 'Nhập mật khẩu',
          hintStyle: TextStyle(color: _darkRed.withOpacity(0.5), fontSize: 14),
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _obscurePassword = !_obscurePassword),
            child: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: _darkRed.withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }

  // ── Hàng checkbox + Quên mật khẩu ──
  Widget _buildRememberRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: _rememberMe,
                onChanged: (v) => setState(() => _rememberMe = v ?? false),
                checkColor: _darkRed,
                activeColor: _gold,
                side: const BorderSide(color: _gold, width: 1.5),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'lưu thông tin đăng nhập',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
            );
          },
          child: const Text(
            'Quên mật khẩu?',
            style: TextStyle(
              color: _gold,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor: _gold,
            ),
          ),
        ),
      ],
    );
  }

  // ── Nút Đăng nhập ──
  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _vm.loading ? null : _onLoginPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _gold,
          foregroundColor: _darkRed,
          elevation: 6,
          disabledBackgroundColor: _gold.withOpacity(0.6),
          shadowColor: Colors.black.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: _vm.loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFF8B0000),
                ),
              )
            : const Text(
                'Đăng nhập',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: Color(0xFF8B0000),
                ),
              ),
      ),
    );
  }

  // ── Dòng đăng ký ──
  Widget _buildRegisterRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Bạn chưa có tài khoản? ',
          style: TextStyle(color: Colors.white, fontSize: 13),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RegisterPage()),
            );
          },
          child: const Text(
            'Đăng ký',
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
    );
  }

  void _onLoginPressed() {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    if (phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập số điện thoại và mật khẩu!'),
          backgroundColor: Color(0xFF8B0000),
        ),
      );
      return;
    }

    // Gọi ViewModel để xác thực đăng nhập
    _vm.login(phone, password);
  }

  // ── Divider "hoặc" ──
  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Colors.white.withAlpha(100),
            thickness: 1,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'hoặc',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Colors.white.withAlpha(100),
            thickness: 1,
          ),
        ),
      ],
    );
  }

  // ── Nút đăng nhập bằng Google ──
  Widget _buildGoogleSignInButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _vm.loading ? null : _onGoogleSignInPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF3C4043),
          elevation: 4,
          disabledBackgroundColor: Colors.white60,
          shadowColor: Colors.black.withAlpha(80),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: BorderSide(
              color: Colors.white.withAlpha(60),
              width: 1,
            ),
          ),
        ),
        child: _vm.loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFF8B0000),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Google
                  Image.asset(
                    'assets/images/logo_google.png',
                    width: 24,
                    height: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Đăng nhập với Google',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3C4043),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _onGoogleSignInPressed() async {
    final success = await _vm.loginWithGoogle();
    if (!success && _vm.error != null && mounted) {
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
  }
}


