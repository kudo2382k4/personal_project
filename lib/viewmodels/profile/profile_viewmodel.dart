import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../../data/implementations/local/app_database.dart';

class ProfileViewmodel extends ChangeNotifier {
  final int userId;
  ProfileViewmodel({required this.userId});

  bool loading = false;
  bool saving = false;
  String? error;
  String? successMessage;

  // Dữ liệu hiển thị
  String name = '';
  String phone = '';
  String email = '';
  String address = '';
  String? avatarPath; // đường dẫn ảnh avatar local

  /// Tải thông tin user từ DB
  Future<void> loadProfile() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final db = await AppDatabase.instance.db;
      final rows = await db.query('users', where: 'id = ?', whereArgs: [userId]);
      if (rows.isNotEmpty) {
        final row = rows.first;
        name = (row['name'] as String?) ?? '';
        phone = (row['phone_number'] as String?) ?? '';
        email = (row['email'] as String?) ?? '';
        address = (row['address'] as String?) ?? '';
        avatarPath = row['avatar_path'] as String?;
      }
    } catch (e) {
      error = 'Không tải được thông tin: $e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Cập nhật thông tin cơ bản
  Future<bool> updateProfile({
    required String newName,
    required String newPhone,
    required String newEmail,
    required String newAddress,
  }) async {
    saving = true;
    error = null;
    successMessage = null;
    notifyListeners();
    try {
      final db = await AppDatabase.instance.db;
      await db.update(
        'users',
        {
          'name': newName.trim(),
          'phone_number': newPhone.trim(),
          'email': newEmail.trim(),
          'address': newAddress.trim(),
        },
        where: 'id = ?',
        whereArgs: [userId],
      );
      name = newName.trim();
      phone = newPhone.trim();
      email = newEmail.trim();
      address = newAddress.trim();
      successMessage = 'Cập nhật thông tin thành công!';
      return true;
    } catch (e) {
      error = 'Lỗi cập nhật: $e';
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  /// Cập nhật ảnh đại diện và lưu đường dẫn vào DB
  Future<bool> updateAvatar(String path) async {
    try {
      final db = await AppDatabase.instance.db;
      await db.update('users', {'avatar_path': path}, where: 'id = ?', whereArgs: [userId]);
      avatarPath = path;
      notifyListeners();
      return true;
    } catch (e) {
      error = 'Lỗi lưu ảnh: $e';
      notifyListeners();
      return false;
    }
  }

  /// Đổi mật khẩu — xác thực mật khẩu cũ trước
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    saving = true;
    error = null;
    successMessage = null;
    notifyListeners();
    try {
      final db = await AppDatabase.instance.db;
      final oldHash = sha256.convert(utf8.encode(oldPassword)).toString();

      // Kiểm tra mật khẩu cũ
      final rows = await db.query(
        'users',
        where: 'id = ? AND password_hash = ?',
        whereArgs: [userId, oldHash],
      );
      if (rows.isEmpty) {
        error = 'Mật khẩu hiện tại không đúng!';
        return false;
      }

      final newHash = sha256.convert(utf8.encode(newPassword)).toString();
      await db.update(
        'users',
        {'password_hash': newHash},
        where: 'id = ?',
        whereArgs: [userId],
      );
      successMessage = 'Đổi mật khẩu thành công!';
      return true;
    } catch (e) {
      error = 'Lỗi đổi mật khẩu: $e';
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }
}
