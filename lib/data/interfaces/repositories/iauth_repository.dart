import '../../../domain/entities/auth_session.dart';

abstract class IAuthRepository {
  Future<AuthSession> login(String phoneNumber, String password);
  Future<void> register({
    required String name,
    required String phoneNumber,
    required String address,
    required String password,
  });
  Future<AuthSession?> getCurrentSession();
  Future<void> logout();
  Future<AuthSession> loginWithGoogle({
    required String googleUid,
    required String name,
    required String email,
  });
}