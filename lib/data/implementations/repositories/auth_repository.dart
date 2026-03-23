import 'package:buy_management_project/data/interfaces/repositories/iauth_repository.dart';

import '../../../domain/entities/auth_session.dart';
import '../../dtos/auth/login/login_request_dto.dart';
import '../../dtos/auth/login/login_response_dto.dart';
import '../../dtos/auth/register/register_request_dto.dart';
import '../../interfaces/mapper/imapper.dart';
import '../api/auth/auth_api.dart';

class AuthRepository implements IAuthRepository {
  final AuthApi _authApi;
  final IMapper<LoginResponseDto, AuthSession> _authSessionMapper;

  AuthRepository(this._authApi, this._authSessionMapper);

  @override
  Future<AuthSession> login(String phoneNumber, String password) async {
    final req = LoginRequestDto(phoneNumber: phoneNumber, password: password);
    final dto = await _authApi.login(req);
    return _authSessionMapper.map(dto);
  }

  @override
  Future<void> register({
    required String name,
    required String phoneNumber,
    required String address,
    required String password,
  }) async {
    final req = RegisterRequestDto(
      name: name,
      phoneNumber: phoneNumber,
      address: address,
      password: password,
    );
    await _authApi.register(req);
  }

  @override
  Future<AuthSession?> getCurrentSession() async {
    final dto = await _authApi.getCurrentSession();
    if (dto == null) return null;
    return _authSessionMapper.map(dto);
  }

  @override
  Future<void> logout() => _authApi.logout();

  @override
  Future<AuthSession> loginWithGoogle({
    required String googleUid,
    required String name,
    required String email,
  }) async {
    final dto = await _authApi.loginWithGoogle(
      googleUid: googleUid,
      name: name,
      email: email,
    );
    return _authSessionMapper.map(dto);
  }
}