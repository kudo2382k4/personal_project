import 'package:buy_management_project/data/dtos/auth/login/user_dto.dart';

class LoginResponseDto {
  final String token;
  final UserDto user;

  const LoginResponseDto({
    required this.token,
    required this.user,
  });

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) {
    return LoginResponseDto(
      token: (json['token'] ?? '').toString(),
      user: UserDto.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
    'token': token,
    'user': user.toJson(),
  };
}