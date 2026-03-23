import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Gửi OTP qua email sử dụng EmailJS REST API.
class EmailOtpService {
  EmailOtpService._();
  static final EmailOtpService instance = EmailOtpService._();

  static const String _apiUrl = 'https://api.emailjs.com/api/v1.0/email/send';

  String get _serviceId => dotenv.env['EMAILJS_SERVICE_ID'] ?? '';
  String get _templateId => dotenv.env['EMAILJS_TEMPLATE_ID'] ?? '';
  String get _publicKey => dotenv.env['EMAILJS_PUBLIC_KEY'] ?? '';

  /// Gửi email chứa mã [otp] đến [toEmail].
  /// Ném [Exception] nếu gửi thất bại.
  Future<void> sendOtp({
    required String toEmail,
    required String otp,
    required String recipientName,
  }) async {
    final body = jsonEncode({
      'service_id': _serviceId,
      'template_id': _templateId,
      'user_id': _publicKey,
      'template_params': {
        'to_email': toEmail,
        'to_name': recipientName,
        'otp_code': otp,
        'expiry_minutes': '3',
      },
    });

    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'origin': 'http://localhost',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Gửi email thất bại (${response.statusCode}): ${response.body}');
    }
  }
}
