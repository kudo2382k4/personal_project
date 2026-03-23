import 'dart:math';

enum OtpResult { valid, expired, wrong }

class _OtpEntry {
  final String otp;
  final DateTime expiry;
  _OtpEntry(this.otp, this.expiry);
  bool get isExpired => DateTime.now().isAfter(expiry);
}

/// OTP service hoàn toàn in-memory.
/// OTP hết hạn sau 3 phút, Resend chỉ được sau khi timer về 0.
class OtpService {
  OtpService._();
  static final OtpService instance = OtpService._();

  final Map<String, _OtpEntry> _store = {};
  static const Duration _ttl = Duration(minutes: 3);

  /// Tạo và lưu OTP mới cho [contact] (email hoặc SĐT).
  /// Trả về chuỗi OTP 6 chữ số.
  String generateAndStore(String contact) {
    final otp = (100000 + Random().nextInt(900000)).toString();
    _store[contact] = _OtpEntry(otp, DateTime.now().add(_ttl));
    return otp;
  }

  /// Xác minh OTP mà người dùng nhập.
  OtpResult verify(String contact, String inputOtp) {
    final entry = _store[contact];
    if (entry == null) return OtpResult.wrong;
    if (entry.isExpired) return OtpResult.expired;
    if (entry.otp != inputOtp.trim()) return OtpResult.wrong;
    _store.remove(contact); // Dùng 1 lần
    return OtpResult.valid;
  }

  /// Còn lại bao nhiêu giây trước khi OTP hết hạn (0 nếu đã hết).
  int secondsRemaining(String contact) {
    final entry = _store[contact];
    if (entry == null || entry.isExpired) return 0;
    return entry.expiry.difference(DateTime.now()).inSeconds.clamp(0, 180);
  }

  /// Có thể gửi lại không (true khi đã hết timer).
  bool canResend(String contact) => secondsRemaining(contact) == 0;
}
