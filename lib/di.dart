import 'package:buy_management_project/viewmodels/login/login_viewmodel.dart';
import 'package:buy_management_project/viewmodels/register/register_viewmodel.dart';
import 'package:buy_management_project/viewmodels/shopping/shopping_viewmodel.dart';

import 'data/implementations/api/auth/auth_api.dart';
import 'data/implementations/api/shopping/shopping_api.dart';
import 'data/implementations/local/app_database.dart';
import 'data/implementations/mapper/auth/auth_mapper.dart';
import 'data/implementations/repositories/auth_repository.dart';
import 'data/implementations/repositories/shopping_repository.dart';

AuthRepository _buildRepo() {
  final api = AuthApi(AppDatabase.instance);
  final mapper = AuthMapper();
  return AuthRepository(api, mapper);
}

LoginViewmodel buildLoginVM() {
  return LoginViewmodel(_buildRepo());
}

RegisterViewmodel buildRegisterVM() {
  return RegisterViewmodel(_buildRepo());
}

ShoppingViewmodel buildShoppingVM(int userId) {
  final api = ShoppingApi(AppDatabase.instance);
  final repo = ShoppingRepository(api);
  return ShoppingViewmodel(repo, userId: userId);
}