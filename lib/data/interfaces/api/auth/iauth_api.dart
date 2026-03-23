import '../../../dtos/auth/login/login_request_dto.dart';
import '../../../dtos/auth/login/login_response_dto.dart';
import '../../../dtos/auth/register/register_request_dto.dart';

abstract class IAuthApi {
  Future<LoginResponseDto> login(LoginRequestDto req);
  Future<void> register(RegisterRequestDto req);
  Future<LoginResponseDto?> getCurrentSession();
  Future<void> logout();
}