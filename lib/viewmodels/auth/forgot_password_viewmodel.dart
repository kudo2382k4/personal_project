import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/implementations/local/app_database.dart';
import '../../data/implementations/services/email_otp_service.dart';
import '../../data/implementations/services/otp_service.dart';

// --------------------  Result types  --------------------

sealed class OtpSendResult {
  const OtpSendResult();
}

/// Gửi email thành công qua EmailJS.
final class OtpEmailSent extends OtpSendResult {
  const OtpEmailSent();
}

/// Firebase Phone Auth đã gửi SMS thành công.
final class OtpFirebaseSmsSent extends OtpSendResult {
  const OtpFirebaseSmsSent();
}

/// Gửi thất bại (lỗi mạng / API).
final class OtpSendFailed extends OtpSendResult {
  const OtpSendFailed();
}

/// Chế độ dev cho SĐT: OTP được tạo local, chưa gửi qua SMS thật.
final class OtpPhoneDevMode extends OtpSendResult {
  final String otp;
  const OtpPhoneDevMode(this.otp);
}

// --------------------  ViewModel  --------------------

class ForgotPasswordViewmodel extends ChangeNotifier {
  bool loading = false;
  String? error;

  int? foundUserId;
  String? foundContact;
  String? foundName;

  // Firebase Phone Auth state
  String? _verificationId;
  String? get verificationId => _verificationId;

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Tra cứu user trong DB theo SĐT.
  /// Trả về true nếu tìm thấy.
  Future<bool> lookupUser(String input) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final db = await AppDatabase.instance.db;
      final isEmail = input.contains('@');
      final List<Map<String, dynamic>> rows;

      if (isEmail) {
        rows = await db.query('users', where: 'email = ?', whereArgs: [input.trim()]);
      } else {
        rows = await db.query('users', where: 'phone_number = ?', whereArgs: [input.trim()]);
      }

      if (rows.isEmpty) {
        error = isEmail
            ? 'Không tìm thấy tài khoản với email này'
            : 'Không tìm thấy tài khoản với số điện thoại này';
        return false;
      }

      foundUserId = rows.first['id'] as int;
      foundContact = input.trim();
      foundName = (rows.first['name'] as String?) ?? 'Bạn';
      return true;
    } catch (e) {
      error = 'Lỗi hệ thống: ${e.toString()}';
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Gửi OTP đến [contact].
  /// - Email → gửi qua EmailJS
  /// - SĐT  → gửi qua Firebase Phone Auth SMS thật
  Future<OtpSendResult> sendOtpToContact(String contact) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      if (contact.contains('@')) {
        // Email flow: dùng in-memory OTP + EmailJS
        final otp = OtpService.instance.generateAndStore(contact);
        await EmailOtpService.instance.sendOtp(
          toEmail: contact,
          otp: otp,
          recipientName: foundName ?? 'Bạn',
        );
        loading = false;
        notifyListeners();
        return const OtpEmailSent();
      } else {
        // Phone flow: dùng Firebase Phone Auth
        // Chuẩn hoá SĐT sang định dạng quốc tế (+84...)
        String phone = contact.trim();
        if (phone.startsWith('0')) {
          phone = '+84${phone.substring(1)}';
        } else if (!phone.startsWith('+')) {
          phone = '+84$phone';
        }

        final completer = _CompleterResult<OtpSendResult>();

        await _firebaseAuth.verifyPhoneNumber(
          phoneNumber: phone,
          timeout: const Duration(seconds: 60),
          verificationCompleted: (PhoneAuthCredential credential) {
            // Auto-verify (thường chỉ xảy ra trên Android với SIM thật)
            // Không xử lý ở đây, để user tự nhập
          },
          verificationFailed: (FirebaseAuthException e) {
            error = 'Gửi OTP thất bại: ${e.message ?? e.code}';
            completer.complete(const OtpSendFailed());
          },
          codeSent: (String vId, int? resendToken) {
            _verificationId = vId;
            completer.complete(const OtpFirebaseSmsSent());
          },
          codeAutoRetrievalTimeout: (String vId) {
            _verificationId = vId;
          },
        );

        final result = await completer.future;
        loading = false;
        notifyListeners();
        return result;
      }
    } catch (e) {
      error = 'Gửi OTP thất bại: ${e.toString()}';
      loading = false;
      notifyListeners();
      return const OtpSendFailed();
    }
  }

  /// Xác minh OTP email (in-memory).
  OtpResult verifyOtp(String contact, String otp) {
    return OtpService.instance.verify(contact, otp);
  }

  /// Xác minh OTP Firebase Phone Auth.
  /// Chỉ dùng để xác nhận mã OTP hợp lệ — KHÔNG giữ session Firebase.
  /// Trả về true nếu OTP đúng.
  Future<bool> verifyFirebaseOtp(String smsCode) async {
    if (_verificationId == null) {
      error = 'Phiên xác thực đã hết hạn. Vui lòng gửi lại OTP.';
      notifyListeners();
      return false;
    }

    loading = true;
    error = null;
    notifyListeners();

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      // Đăng nhập Firebase chỉ để xác minh mã OTP hợp lệ
      await _firebaseAuth.signInWithCredential(credential);
      // Sign out ngay lập tức — không để lại session Phone Auth Firebase
      // (SQLite là nguồn xác thực chính)
      await _firebaseAuth.signOut();
      loading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-verification-code') {
        error = 'Mã OTP không đúng. Vui lòng thử lại!';
      } else if (e.code == 'session-expired') {
        error = 'Phiên OTP đã hết hạn. Vui lòng gửi lại!';
      } else {
        error = 'Xác thực thất bại: ${e.message ?? e.code}';
      }
      loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      error = 'Lỗi: ${e.toString()}';
      loading = false;
      notifyListeners();
      return false;
    }
  }

  /// Đổi mật khẩu cho [userId] trong SQLite.
  Future<bool> resetPassword(int userId, String newPassword) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final hash = sha256.convert(utf8.encode(newPassword)).toString();
      final db = await AppDatabase.instance.db;
      final count = await db.update(
        'users',
        {'password_hash': hash},
        where: 'id = ?',
        whereArgs: [userId],
      );
      return count > 0;
    } catch (e) {
      error = 'Lỗi đổi mật khẩu: ${e.toString()}';
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}

// Helper để chờ callback từ Firebase verifyPhoneNumber (không dùng async trực tiếp)
class _CompleterResult<T> {
  final _completer = _FutureCompleter<T>();
  void complete(T value) => _completer.complete(value);
  Future<T> get future => _completer.future;
}

class _FutureCompleter<T> {
  T? _value;
  bool _completed = false;
  final List<void Function(T)> _listeners = [];

  void complete(T value) {
    _value = value;
    _completed = true;
    for (final l in _listeners) {
      l(value);
    }
  }

  Future<T> get future async {
    if (_completed) return _value as T;
    // Poll mỗi 100ms tối đa 60 giây
    for (int i = 0; i < 600; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (_completed) return _value as T;
    }
    throw Exception('Timeout chờ Firebase Phone Auth');
  }
}
