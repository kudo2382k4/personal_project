import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../data/implementations/repositories/auth_repository.dart';
import '../../domain/entities/auth_session.dart';

class LoginViewmodel extends ChangeNotifier {
  final AuthRepository repo;
  LoginViewmodel(this.repo);

  bool loading = false;
  String? error;
  AuthSession? session;

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  Future<bool> login(String userName, String password) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final u = userName.trim();
      final p = password.trim();

      if (u.isEmpty || p.isEmpty) {
        error = 'Username or password cannot be empty';
        loading = false;
        notifyListeners();
        return false;
      }
      session = await repo.login(u, p);
      loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      session = null;
      error = e.toString().replaceAll('Exception: ', '');
      loading = false;
      notifyListeners();
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Đăng nhập bằng Google
  Future<bool> loginWithGoogle() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      // Mở Google account picker
      final googleAccount = await _googleSignIn.signIn();
      if (googleAccount == null) {
        // Người dùng huỷ chọn tài khoản
        loading = false;
        notifyListeners();
        return false;
      }

      final googleUid = googleAccount.id;
      final name = googleAccount.displayName ?? googleAccount.email;
      final email = googleAccount.email;

      session = await repo.loginWithGoogle(
        googleUid: googleUid,
        name: name,
        email: email,
      );
      loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      session = null;
      error = e.toString().replaceAll('Exception: ', '');
      loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await repo.logout();
    // Cũng sign out khỏi Google nếu đang login bằng Google
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    session = null;
    error = null;
    notifyListeners();
  }

  void cleanError() {
    if (error != null) {
      error = null;
      notifyListeners();
    }
  }
}
