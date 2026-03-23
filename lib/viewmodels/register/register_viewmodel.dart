import 'package:flutter/foundation.dart';
import '../../data/implementations/repositories/auth_repository.dart';

class RegisterViewmodel extends ChangeNotifier {
  final AuthRepository repo;
  RegisterViewmodel(this.repo);

  bool loading = false;
  String? error;
  bool success = false;

  Future<bool> register({
    required String name,
    required String phoneNumber,
    required String address,
    required String password,
  }) async {
    loading = true;
    error = null;
    success = false;
    notifyListeners();

    try {
      await repo.register(
        name: name,
        phoneNumber: phoneNumber,
        address: address,
        password: password,
      );
      success = true;
      loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      loading = false;
      notifyListeners();
      return false;
    }
  }

  void cleanSuccess() {
    if (success) {
      success = false;
      notifyListeners();
    }
  }

  void cleanError() {
    if (error != null) {
      error = null;
      notifyListeners();
    }
  }
}
