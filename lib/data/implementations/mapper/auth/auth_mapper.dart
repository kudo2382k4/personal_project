import 'package:buy_management_project/data/dtos/auth/login/login_response_dto.dart';
import 'package:buy_management_project/data/interfaces/mapper/imapper.dart';

import '../../../../domain/entities/auth_session.dart';
import '../../../../domain/entities/user.dart';

class AuthMapper implements IMapper<LoginResponseDto,AuthSession>{
  @override
  AuthSession map(LoginResponseDto input){
    return AuthSession(
      token: input.token,
      user: User(
        id: input.user.id,
        name: input.user.name,
        phoneNumber: input.user.phoneNumber,
        googleUid: input.user.googleUid,
      ),
    );
  }
}