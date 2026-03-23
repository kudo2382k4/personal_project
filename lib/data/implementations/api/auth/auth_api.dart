import 'package:sqflite/sqflite.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../dtos/auth/login/login_request_dto.dart';
import '../../../dtos/auth/login/login_response_dto.dart';
import '../../../dtos/auth/login/user_dto.dart';
import '../../../dtos/auth/register/register_request_dto.dart';
import '../../../interfaces/api/auth/iauth_api.dart';
import '../../local/app_database.dart';
import '../../local/password_hasher.dart';

class AuthApi implements IAuthApi {
  final AppDatabase database;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  AuthApi(this.database);

  @override
  Future<LoginResponseDto> login(LoginRequestDto req) async {
    final db = await database.db;

    // --- Bước 1: Kiểm tra SQLite (nguồn xác thực chính) ---
    final rows = await db.query(
      'users',
      where: 'phone_number = ?',
      whereArgs: [req.phoneNumber],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw Exception('Sai số điện thoại hoặc mật khẩu.');
    }
    final userRow = rows.first;
    final storeHash = (userRow['password_hash'] ?? '').toString();
    final inputHash = PasswordHasher.sha256Hash(req.password);
    if (storeHash != inputHash) {
      throw Exception('Sai số điện thoại hoặc mật khẩu.');
    }

    // --- Bước 2: Đồng bộ Firebase (optional, không chặn login) ---
    // SQLite đã xác thực thành công → đồng bộ Firebase để giữ consistency.
    // Nếu Firebase fail (mất mạng, hoặc password bị lệch sau forgot-password)
    // thì vẫn login thành công dựa trên SQLite.
    final fakeEmail = '${req.phoneNumber}@bmapp.local';
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: fakeEmail,
        password: req.password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        // Firebase account chưa tồn tại → tạo mới để sync
        try {
          await _firebaseAuth.createUserWithEmailAndPassword(
            email: fakeEmail,
            password: req.password,
          );
        } catch (_) { /* ignore */ }
      }
      // Các lỗi khác (wrong-password, invalid-credential, network) → ignore.
      // SQLite đã xác thực, login vẫn tiếp tục.
    } catch (_) { /* ignore mọi lỗi Firebase khác */ }

    // --- Bước 3: Tạo session local ---
    final userId = userRow['id'] as int;
    final token = 'token_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now().toIso8601String();

    await db.insert(
      'session',
      {'id': 1, 'user_id': userId, 'token': token, 'created_at': now},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return LoginResponseDto(token: token, user: UserDto.fromMap(userRow));
  }

  @override
  Future<void> register(RegisterRequestDto req) async {
    final db = await database.db;

    // Kiểm tra số điện thoại đã tồn tại trong SQLite chưa
    final existing = await db.query(
      'users',
      where: 'phone_number = ?',
      whereArgs: [req.phoneNumber],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      throw Exception('Số điện thoại đã được đăng ký!');
    }

    // Kiểm tra độ dài mật khẩu tối thiểu (Firebase yêu cầu ≥ 6 ký tự)
    if (req.password.length < 6) {
      throw Exception('Mật khẩu phải có ít nhất 6 ký tự.');
    }

    // Ghi vào SQLite trước (nguồn xác thực chính)
    await db.insert('users', {
      'name': req.name,
      'phone_number': req.phoneNumber,
      'address': req.address,
      'password_hash': PasswordHasher.sha256Hash(req.password),
    });

    // Đồng bộ Firebase Auth (optional, không chặn đăng ký nếu Firebase fail)
    final fakeEmail = '${req.phoneNumber}@bmapp.local';
    try {
      print('[AUTH] Đang tạo tài khoản Firebase: $fakeEmail');
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: fakeEmail,
        password: req.password,
      );
      await userCredential.user?.updateDisplayName(req.name);
      print('[AUTH] ✅ Firebase tạo thành công: ${userCredential.user?.uid}');
    } on FirebaseAuthException catch (e) {
      print('[AUTH] ⚠️ Firebase error code: ${e.code}, message: ${e.message}');
      if (e.code == 'email-already-in-use') {
        // Firebase đã có account → thử sign in để đồng bộ
        try {
          await _firebaseAuth.signInWithEmailAndPassword(
            email: fakeEmail,
            password: req.password,
          );
          print('[AUTH] ✅ Firebase đã sign in với account cũ');
        } catch (e2) {
          print('[AUTH] ⚠️ Firebase sign in thất bại: $e2');
        }
      }
      // Mọi lỗi Firebase khác: ignore vì SQLite đã lưu thành công
    } catch (e) {
      print('[AUTH] ❌ Firebase exception khác: $e');
    }
  }

  @override
  Future<LoginResponseDto?> getCurrentSession() async {
    final db = await database.db;
    final s = await db.query('session', where: 'id = 1', limit: 1);
    if (s.isEmpty) return null;

    final sessionRow = s.first;
    final userId = sessionRow['user_id'] as int;
    final token = (sessionRow['token'] ?? '').toString();

    final users = await db.query('users', where: 'id = ?', whereArgs: [userId], limit: 1);
    if (users.isEmpty) return null;

    return LoginResponseDto(token: token, user: UserDto.fromMap(users.first));
  }

  @override
  Future<void> logout() async {
    final db = await database.db;
    await db.delete('session', where: 'id = 1');
    // Sign out Firebase nếu đang sign in
    try { await _firebaseAuth.signOut(); } catch (_) {}
  }

  /// Đăng nhập bằng Google: upsert user theo google_uid, tạo session local
  Future<LoginResponseDto> loginWithGoogle({
    required String googleUid,
    required String name,
    required String email,
  }) async {
    final db = await database.db;

    List<Map<String, dynamic>> rows = await db.query(
      'users',
      where: 'google_uid = ?',
      whereArgs: [googleUid],
      limit: 1,
    );

    int userId;
    if (rows.isEmpty) {
      userId = await db.insert('users', {
        'name': name,
        'phone_number': '',
        'address': '',
        'password_hash': '',
        'google_uid': googleUid,
      });
      rows = await db.query('users', where: 'id = ?', whereArgs: [userId], limit: 1);
    } else {
      userId = rows.first['id'] as int;
      await db.update('users', {'name': name}, where: 'id = ?', whereArgs: [userId]);
      rows = await db.query('users', where: 'id = ?', whereArgs: [userId], limit: 1);
    }

    final token = 'google_token_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now().toIso8601String();

    await db.insert(
      'session',
      {'id': 1, 'user_id': userId, 'token': token, 'created_at': now},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return LoginResponseDto(token: token, user: UserDto.fromMap(rows.first));
  }
}