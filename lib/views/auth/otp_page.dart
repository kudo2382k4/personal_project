import 'dart:async';
import 'package:flutter/material.dart';
import '../../viewmodels/auth/forgot_password_viewmodel.dart';
import '../../data/implementations/services/otp_service.dart';
import 'reset_password_page.dart';

class OtpPage extends StatefulWidget {
  final String contact;
  final int userId;
  // ViewModel được chia sẻ từ ForgotPasswordPage để giữ verificationId Firebase
  final ForgotPasswordViewmodel vm;

  const OtpPage({
    super.key,
    required this.contact,
    required this.userId,
    required this.vm,
  });

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  Timer? _timer;
  int _secondsLeft = 180;
  bool _otpExpired = false;

  bool get _isPhoneFlow => !widget.contact.contains('@');

  static const Color _primaryRed = Color(0xFF6B0000);
  static const Color _darkRed = Color(0xFF4A0000);
  static const Color _gold = Color(0xFFFFD700);

  @override
  void initState() {
    super.initState();
    // Chỉ dùng OtpService timer với email flow
    if (!_isPhoneFlow) {
      _startTimer();
    } else {
      // Firebase flow: đặt timer 60 giây (timeout của Firebase)
      _secondsLeft = 60;
      _startCountdown();
    }
  }

  void _startTimer() {
    _secondsLeft = OtpService.instance.secondsRemaining(widget.contact);
    if (_secondsLeft <= 0) {
      setState(() => _otpExpired = true);
      return;
    }
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      final remaining = OtpService.instance.secondsRemaining(widget.contact);
      setState(() {
        _secondsLeft = remaining;
        _otpExpired = remaining == 0;
      });
      if (remaining == 0) t.cancel();
    });
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          _otpExpired = true;
          t.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) { c.dispose(); }
    for (var f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  String get _timerLabel {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryRed,
      // Dùng resizeToAvoidBottomInset để Scaffold tự xử lý bàn phím
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 40),

                  const Center(
                    child: Text('Nhập mã OTP',
                        style: TextStyle(color: _gold, fontSize: 24, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Mã OTP đã gửi đến\n${widget.contact}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 32),

                  _buildOtpFields(),
                  const SizedBox(height: 24),

                  Center(child: _buildTimerWidget()),
                  const SizedBox(height: 28),

                  // Hiển thị lỗi từ ViewModel
                  ListenableBuilder(
                    listenable: widget.vm,
                    builder: (_, __) {
                      if (widget.vm.error != null) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            '⚠️ ${widget.vm.error}',
                            style: TextStyle(color: Colors.yellow.shade200, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  ListenableBuilder(
                    listenable: widget.vm,
                    builder: (_, child) => _buildConfirmButton(context),
                  ),
                  const SizedBox(height: 16),

                  Center(child: _buildResendButton(context)),
                  const Spacer(),
                ],
              ),
            ),
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

  Widget _buildOtpFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Container(
            width: 46, height: 56,
            decoration: BoxDecoration(
              color: _otpExpired ? Colors.grey.shade400 : _gold,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 3))],
            ),
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              enabled: !_otpExpired && !widget.vm.loading,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              style: const TextStyle(color: _darkRed, fontSize: 22, fontWeight: FontWeight.w900),
              decoration: const InputDecoration(
                border: InputBorder.none,
                counterText: '',
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) {
                if (value.isNotEmpty && index < 5) {
                  FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
                } else if (value.isEmpty && index > 0) {
                  FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
                }
                // Auto-submit khi nhập đủ 6 số
                if (index == 5 && value.isNotEmpty) {
                  final otp = _controllers.map((c) => c.text).join();
                  if (otp.length == 6) _onConfirmPressed(context);
                }
              },
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTimerWidget() {
    if (_otpExpired) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: Colors.red.shade800, borderRadius: BorderRadius.circular(20)),
        child: const Text('⏰ Mã OTP đã hết hạn!',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.timer_outlined, color: Colors.white70, size: 18),
        const SizedBox(width: 6),
        Text(
          'Hết hạn sau $_timerLabel',
          style: TextStyle(
            color: _secondsLeft <= 30 ? Colors.yellow.shade300 : Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmButton(BuildContext context) {
    final canConfirm = !_otpExpired && !widget.vm.loading;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: canConfirm ? () => _onConfirmPressed(context) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _gold,
          disabledBackgroundColor: Colors.grey.shade600,
          elevation: 6,
          shadowColor: Colors.black.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: widget.vm.loading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF4A0000)))
            : const Text('Xác nhận', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF4A0000), letterSpacing: 0.5)),
      ),
    );
  }

  Widget _buildResendButton(BuildContext context) {
    final canResend = _isPhoneFlow
        ? _otpExpired
        : OtpService.instance.canResend(widget.contact);
    return TextButton(
      onPressed: canResend ? () => _onResend(context) : null,
      child: Text(
        canResend ? '🔄 Gửi lại mã OTP' : 'Gửi lại sau $_timerLabel',
        style: TextStyle(
          color: canResend ? _gold : Colors.white38,
          fontSize: 14,
          fontWeight: canResend ? FontWeight.bold : FontWeight.normal,
          decoration: canResend ? TextDecoration.underline : null,
          decorationColor: _gold,
        ),
      ),
    );
  }

  Future<void> _onConfirmPressed(BuildContext context) async {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length < 6 || otp.contains(' ')) {
      _showSnack('Vui lòng nhập đủ 6 chữ số OTP!');
      return;
    }

    if (_isPhoneFlow) {
      // Firebase Phone Auth flow
      final success = await widget.vm.verifyFirebaseOtp(otp);
      if (!context.mounted) return;
      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ResetPasswordPage(userId: widget.userId)),
        );
      }
      // Lỗi hiển thị qua ListenableBuilder
    } else {
      // Email OTP flow (in-memory)
      final result = widget.vm.verifyOtp(widget.contact, otp);
      switch (result) {
        case OtpResult.valid:
          if (context.mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => ResetPasswordPage(userId: widget.userId)),
            );
          }
        case OtpResult.expired:
          setState(() => _otpExpired = true);
          _showSnack('Mã OTP đã hết hạn. Vui lòng gửi lại!');
        case OtpResult.wrong:
          _showSnack('Mã OTP không đúng. Vui lòng thử lại!');
          for (var c in _controllers) { c.clear(); }
          FocusScope.of(context).requestFocus(_focusNodes[0]);
      }
    }
  }

  Future<void> _onResend(BuildContext context) async {
    for (var c in _controllers) { c.clear(); }
    setState(() {
      _otpExpired = false;
      _secondsLeft = _isPhoneFlow ? 60 : 180;
    });

    final result = await widget.vm.sendOtpToContact(widget.contact);
    if (!context.mounted) return;

    if (_isPhoneFlow) {
      _startCountdown();
    } else {
      _startTimer();
    }

    switch (result) {
      case OtpEmailSent():
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('📧 Đã gửi lại OTP đến ${widget.contact}'),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 4),
        ));
      case OtpFirebaseSmsSent():
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('📱 Đã gửi lại SMS OTP đến ${widget.contact}'),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 4),
        ));
      case OtpPhoneDevMode(:final otp):
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('🔑 [Dev] OTP mới: $otp (3 phút)',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.orange.shade700,
          duration: const Duration(seconds: 10),
        ));
      case OtpSendFailed():
        _showSnack('Gửi lại OTP thất bại. Vui lòng thử lại!');
    }

    FocusScope.of(context).requestFocus(_focusNodes[0]);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: _darkRed),
    );
  }
}
